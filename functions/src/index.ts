import * as admin from "firebase-admin";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

admin.initializeApp();
const db = admin.firestore();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

const MS_PER_DAY = 24 * 60 * 60 * 1000;

type OrderLine = {
  type: "product" | "membership";
  refId: string;
  name: string;
  unitPriceCents: number;
  quantity: number;
};

type OrderDoc = {
  parentUid: string;
  lines: OrderLine[];
  totalCents: number;
  currency: string;
  status: string;
  fulfillmentLocationId?: string | null;
  stripePaymentIntentId?: string | null;
};

/**
 * Creates (or re-derives) a Stripe PaymentIntent for a pending order.
 *
 * The charge amount is always recomputed here from the current
 * `products`/`membershipPlans` documents — the order's own
 * `unitPriceCents`/`totalCents` are only a client-side cache from
 * add-to-cart time and are never trusted for the actual charge. This is
 * what stops a modified client from paying less than the real price.
 */
export const createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const orderId = request.data?.orderId;
    if (typeof orderId !== "string" || orderId.length === 0) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const order = orderSnap.data() as OrderDoc;

    if (order.parentUid !== uid) {
      throw new HttpsError("permission-denied", "This isn't your order.");
    }
    if (order.status !== "pendingPayment") {
      throw new HttpsError(
        "failed-precondition",
        "This order has already been processed."
      );
    }
    if (order.lines.length === 0) {
      throw new HttpsError("failed-precondition", "Order has no items.");
    }

    let totalCents = 0;
    const recomputedLines: OrderLine[] = [];

    for (const line of order.lines) {
      if (line.type === "product") {
        const productSnap = await db
          .collection("products")
          .doc(line.refId)
          .get();
        if (!productSnap.exists) {
          throw new HttpsError(
            "failed-precondition",
            `"${line.name}" is no longer available.`
          );
        }
        const product = productSnap.data()!;
        const stock = (product.stock as number | undefined) ?? 0;
        if (stock < line.quantity) {
          throw new HttpsError(
            "failed-precondition",
            `Not enough stock left for "${product.name}".`
          );
        }
        const unitPriceCents = product.priceCents as number;
        totalCents += unitPriceCents * line.quantity;
        recomputedLines.push({
          ...line,
          name: product.name as string,
          unitPriceCents,
        });
      } else {
        const planSnap = await db
          .collection("membershipPlans")
          .doc(line.refId)
          .get();
        if (!planSnap.exists) {
          throw new HttpsError(
            "failed-precondition",
            `"${line.name}" is no longer available.`
          );
        }
        const plan = planSnap.data()!;
        const unitPriceCents = plan.priceCents as number;
        totalCents += unitPriceCents * line.quantity;
        recomputedLines.push({
          ...line,
          name: plan.name as string,
          unitPriceCents,
        });
      }
    }

    if (totalCents <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Order total must be greater than zero."
      );
    }

    const stripe = new Stripe(stripeSecretKey.value());
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalCents,
      currency: order.currency || "bgn",
      metadata: { orderId },
      automatic_payment_methods: { enabled: true },
    });

    // Persist the server-verified amounts so the order record reflects
    // what was actually charged, not the client's stale cart snapshot.
    await orderRef.update({
      lines: recomputedLines,
      totalCents,
      stripePaymentIntentId: paymentIntent.id,
    });

    return { clientSecret: paymentIntent.client_secret };
  }
);

/**
 * Stripe webhook endpoint. Configure this URL in the Stripe dashboard for
 * the `payment_intent.succeeded` and `payment_intent.payment_failed`
 * events (see SETUP.md).
 */
export const stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    const stripe = new Stripe(stripeSecretKey.value());
    const signature = req.headers["stripe-signature"];

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature as string,
        stripeWebhookSecret.value()
      );
    } catch (err) {
      console.error("Stripe webhook signature verification failed", err);
      res.status(400).send("Invalid signature");
      return;
    }

    if (event.type === "payment_intent.succeeded") {
      await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
    } else if (event.type === "payment_intent.payment_failed") {
      await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
    }

    res.status(200).send("ok");
  }
);

async function handlePaymentSucceeded(intent: Stripe.PaymentIntent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;
  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return;
    const order = orderSnap.data() as OrderDoc;

    // Idempotency guard: Stripe may redeliver the same event.
    if (order.status !== "pendingPayment") return;

    // Phase 1 — reads. Firestore transactions require every read to
    // happen before any write, so we resolve all the docs we'll need
    // first and only start writing once every line has been read.
    const productReads = new Map<
      string,
      { ref: FirebaseFirestore.DocumentReference; stock: number }
    >();
    let parentRef: FirebaseFirestore.DocumentReference | null = null;
    let currentExpiryMs: number | null = null;
    let membershipDurationDays = 0;
    let hasMembershipLine = false;

    for (const line of order.lines) {
      if (line.type === "product" && !productReads.has(line.refId)) {
        const ref = db.collection("products").doc(line.refId);
        const snap = await tx.get(ref);
        if (snap.exists) {
          productReads.set(line.refId, {
            ref,
            stock: (snap.data()!.stock as number | undefined) ?? 0,
          });
        }
      } else if (line.type === "membership") {
        hasMembershipLine = true;
        const planSnap = await tx.get(
          db.collection("membershipPlans").doc(line.refId)
        );
        membershipDurationDays =
          (planSnap.data()?.durationDays as number | undefined) ??
          membershipDurationDays;
        parentRef = db.collection("parents").doc(order.parentUid);
        const parentSnap = await tx.get(parentRef);
        const existingExpiry = parentSnap.data()?.membershipExpiresAt as
          | FirebaseFirestore.Timestamp
          | undefined;
        currentExpiryMs = existingExpiry ? existingExpiry.toMillis() : null;
      }
    }

    // Phase 2 — writes.
    for (const line of order.lines) {
      if (line.type === "product") {
        const entry = productReads.get(line.refId);
        if (!entry) continue;
        entry.stock = Math.max(0, entry.stock - line.quantity);
        tx.update(entry.ref, { stock: entry.stock });
      }
    }

    if (hasMembershipLine && parentRef) {
      const nowMs = Date.now();
      const baseMs =
        currentExpiryMs && currentExpiryMs > nowMs ? currentExpiryMs : nowMs;
      const newExpiry = admin.firestore.Timestamp.fromMillis(
        baseMs + membershipDurationDays * MS_PER_DAY
      );
      tx.set(parentRef, { membershipExpiresAt: newExpiry }, { merge: true });
    }

    tx.update(orderRef, { status: "paid" });
  });
}

async function handlePaymentFailed(intent: Stripe.PaymentIntent) {
  const orderId = intent.metadata?.orderId;
  if (!orderId) return;
  const orderRef = db.collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (snap.exists && snap.data()?.status === "pendingPayment") {
    await orderRef.update({ status: "cancelled" });
  }
}
