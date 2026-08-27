# The Little Nursery

Parent portal mobile app for [The Little Nursery](https://thelittlenursery.bg) —
an art studio and socialization center for babies and children with two
locations in Sofia, Bulgaria (ul. Solunska 60, and The House on
ul. Tsanko Tserkovski 50).

Built with Flutter + Firebase.

## Features (v0.1)

- **Parent accounts** — email/password sign up and sign in.
- **Children profiles** — add/edit/remove your children under your account.
- **Workshop calendar** — browse upcoming art, Montessori, sensory-play and
  socialization workshops at either location.
- **Booking** — reserve a spot for a specific child at a workshop; capacity
  is enforced server-side via a Firestore transaction so two parents can't
  double-book the last spot. Cancel from "My bookings" in your profile.
- **Parent library** — read articles mirroring the site's "Библиотека за
  родители" section.
- **Locations & contact** — addresses, descriptions, tap-to-call/email.
- **Push notifications** — the device registers its FCM token on the
  parent's profile so the studio can send booking reminders and
  announcements from the backend (sending itself is a server-side/Cloud
  Functions concern, not implemented in this client).
- **Studio admin** — a sixth "Admin" tab, visible only to accounts granted
  admin rights (see below), for creating/editing/deleting workshops and
  parent-library articles directly from the app.
- **Store** — physical merch and a premium-membership pass, paid for with
  Stripe. Browse the shop, add items and/or a membership to a cart, and
  check out with Stripe's payment sheet; physical orders are picked up at
  one of the two studio locations (no shipping). A successful payment
  extends the parent's premium membership and/or is tracked through to
  pickup — see "Store & payments" below. Admins manage products, plans,
  and order fulfillment from the Admin tab.

## Project structure

```
lib/
  main.dart              Entry point, Firebase/Stripe init, provider wiring
  app.dart                Root widget: auth gate (login vs. app shell)
  firebase_options.dart   Placeholder — regenerate with flutterfire configure
  stripe_config.dart      Stripe publishable key (safe to be public — see file)
  theme/                  App color palette & ThemeData
  models/                 Plain Dart data classes (Child, Booking, Order, ...)
  services/               Firebase Auth/Firestore/Messaging/Functions integrations
  screens/
    auth/                 Login, sign up
    home/                 Dashboard with upcoming workshops
    calendar/             Month calendar + day list + event detail/booking
    library/               Parent library article list + detail
    locations/             Studio locations & contact info
    store/                  Shop, membership plans, cart, checkout (Stripe)
    profile/                Parent info, children CRUD, bookings, orders
    admin/                  Admin-only: workshops, articles, products, plans, orders
    root_shell.dart         Bottom navigation shell (adds "Admin" for admins)

functions/               Cloud Functions (TypeScript) — the payment backend.
  src/index.ts             createPaymentIntent (callable) + stripeWebhook (HTTP)
```

## Getting started

1. **Install Flutter** (stable channel) — https://docs.flutter.dev/get-started/install
2. **Generate platform folders.** This repo ships only the Dart source; run
   once from the project root to scaffold `android/`, `ios/`, `web/`, etc.:
   ```sh
   flutter create --org bg.thelittlenursery --project-name the_little_nursery .
   ```
3. **Install dependencies:**
   ```sh
   flutter pub get
   ```

### Firebase setup

The app needs a Firebase project with **Authentication** (Email/Password),
**Cloud Firestore**, **Cloud Messaging**, and (for the store) **Cloud
Functions** enabled — Functions requires the project be on the Blaze
(pay-as-you-go) plan; Stripe's own fees are separate from that.

1. Create a project at https://console.firebase.google.com.
2. Install the CLI tools and log in:
   ```sh
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools   # if you don't already have it
   firebase login
   ```
3. From the project root, generate real config (replaces the placeholder
   `lib/firebase_options.dart`):
   ```sh
   flutterfire configure
   ```
4. Link the CLI to your project and deploy the security rules and
   composite indexes:
   ```sh
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. **Make your account an admin**, so the app's "Admin" tab appears and you
   can add workshops/articles yourself instead of seeding data by hand:
   1. Sign up in the running app once, normally, with the account you want
      to manage the studio's content.
   2. In the Firebase console → **Authentication**, copy that user's UID.
   3. In **Firestore Database**, create a collection named `admins` and add
      a document whose **document ID** is that UID (the document's
      contents don't matter — its existence is the permission check, see
      `firestore.rules`).
   4. Restart the app (or sign out and back in) — the "Admin" tab appears,
      with screens to create/edit/delete workshops and library articles.

### Store & payments (Stripe)

Money only ever moves through the `functions/` Cloud Functions — the
Flutter app never holds a Stripe secret key, and never gets to say what
the final charge is (see the comments in `functions/src/index.ts` for
why). Set this up once:

1. Create a [Stripe](https://dashboard.stripe.com/register) account (test
   mode is fine to start). From **Developers → API keys**, copy the
   **Publishable key** and paste it into `lib/stripe_config.dart`.
2. Install the Cloud Functions dependencies and store the **Secret key**
   from the same page as a Functions secret (never commit it — this
   command prompts for the value and stores it in Secret Manager):
   ```sh
   cd functions && npm install && cd ..
   firebase functions:secrets:set STRIPE_SECRET_KEY
   ```
3. Deploy the functions:
   ```sh
   firebase deploy --only functions
   ```
4. In the Stripe dashboard → **Developers → Webhooks**, add an endpoint
   pointing at the deployed `stripeWebhook` function's URL (printed by the
   deploy command, looks like
   `https://<region>-<project-id>.cloudfunctions.net/stripeWebhook`),
   subscribed to the `payment_intent.succeeded` and
   `payment_intent.payment_failed` events. Copy its **Signing secret**
   and store it the same way:
   ```sh
   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
   firebase deploy --only functions
   ```
5. As an admin in the app, add at least one product and one membership
   plan (Admin tab → *Manage products* / *Manage membership plans*) so
   the Store tab isn't empty.
6. Use one of
   [Stripe's test card numbers](https://docs.stripe.com/testing) (e.g.
   `4242 4242 4242 4242`, any future expiry, any CVC) to try a real
   checkout end to end while `STRIPE_SECRET_KEY` is a `sk_test_...` key.

### Run

```sh
flutter run
```

## Firestore schema

```
admins/{uid}
  (no fields — existence of the document is the permission)

parents/{uid}
  name: string
  email: string
  phone: string | null
  fcmToken: string | null
  membershipExpiresAt: Timestamp | null   # set only by stripeWebhook
  children/{childId}
    name: string
    birthDate: ISO8601 string
    notes: string | null

events/{eventId}
  title: string
  description: string
  locationId: "center" | "house"
  startTime: Timestamp
  endTime: Timestamp
  capacity: number
  bookedCount: number

bookings/{bookingId}
  eventId: string
  parentUid: string
  childId: string
  childName: string
  status: "confirmed" | "cancelled"
  createdAt: Timestamp

articles/{articleId}
  title: string
  summary: string
  body: string
  imageUrl: string | null
  publishedAt: Timestamp

products/{productId}
  name: string
  description: string
  priceCents: number        # minor units (stotinki) — never a float
  currency: string          # "bgn"
  imageUrl: string | null
  stock: number
  active: boolean

membershipPlans/{planId}
  name: string
  description: string
  priceCents: number
  currency: string
  durationDays: number       # fixed-term pass, not auto-renewing (yet)
  perks: string[]
  active: boolean

orders/{orderId}
  parentUid: string
  lines: [{ type: "product" | "membership", refId, name,
            unitPriceCents, quantity }]
  totalCents: number
  currency: string
  fulfillmentLocationId: "center" | "house" | null
  status: "pendingPayment" | "paid" | "readyForPickup"
        | "completed" | "cancelled"
  stripePaymentIntentId: string | null
  createdAt: Timestamp
```

`events`, `articles`, `products`, and `membershipPlans` are written by
admin accounts, in-app (see the "Studio admin" feature above) — regular
parent accounts only read them, aside from the `bookedCount` field on
`events`, which any signed-in parent's booking transaction may adjust.
`orders` are created by the owning parent in `pendingPayment` status and
otherwise only written by the Cloud Functions (via the Admin SDK) or by
admins updating fulfillment status. See `firestore.rules` for the full
access policy.
