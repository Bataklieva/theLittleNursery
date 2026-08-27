---
name: little-nursery-app
description: >
  Context and conventions for The Little Nursery Flutter app — the parent
  portal for a Sofia-based art studio and children's socialization center
  (booking, parent library, admin content management, and a Stripe-backed
  store/premium membership). Use this skill whenever working in this
  repository: adding or changing screens, models, or Firebase/Firestore
  logic; touching the admin role; touching anything payment- or
  membership-related; or when the user asks to "continue" the app, add a
  feature to it, or references the store, bookings, workshops, admin tab,
  or Stripe checkout. Read this BEFORE editing lib/, functions/, or
  firestore.rules — it holds security invariants that are easy to
  accidentally break (e.g. trusting a client-supplied price) and aren't
  obvious from any single file.
---

# The Little Nursery app

Parent-portal mobile app for [The Little Nursery](https://thelittlenursery.bg)
— an art studio / socialization center for babies and children, two
locations in Sofia, Bulgaria. Flutter client + Firebase backend + Stripe
for payments.

This skill is a map and a set of hard-won invariants, not a duplicate of
the docs. For anything not covered here:
- **README.md** — full feature list, Firestore schema, Firebase/Stripe
  setup steps.
- **SETUP.md** — the Mac toolchain (Flutter, Xcode, Android Studio,
  Firebase/FlutterFire CLI, Node).
- **firestore.rules** — the actual access-control source of truth; read
  it before assuming what's allowed.
- **functions/src/index.ts** — the payment backend; read it before
  touching anything checkout-related.

## Where things are

```
lib/
  main.dart / app.dart     Provider wiring, Firebase/Stripe init, auth gate
  models/                  Plain Dart classes, one file each, with
                            fromMap/toMap (Firestore) and copyWith
  services/                One class per collection/concern, talks
                            directly to Firebase SDKs; screens never call
                            Firebase APIs directly, only through a service
  screens/
    auth/ home/ calendar/ library/ locations/ profile/ store/
    admin/                 Admin-only screens (see "Admin role" below)
    root_shell.dart         Bottom-nav shell; tabs shown depend on
                             AuthService.isAdmin
  theme/, utils/            AppTheme, formatCents() money helper

functions/                 Cloud Functions (TypeScript) — the only code
  src/index.ts               allowed to touch Stripe secrets or grant
                              membership. `cd functions && npx tsc --noEmit`
                              actually type-checks (Node is available in
                              this environment; the Flutter SDK is not).

firestore.rules            Access control. Read before changing schema.
firestore.indexes.json     Composite indexes — add one whenever a new
                            `.where(...).orderBy(...)` combo needs it.
firebase.json               Ties rules/indexes/functions together for the
                             Firebase CLI.
```

## The pattern to follow for a new feature

Every existing feature (bookings, library, store) follows the same shape
— match it rather than inventing a new one:

1. **Model** in `lib/models/`: fields, `fromMap`/`toMap` (Firestore uses
   `Timestamp`, not `DateTime`, on the wire — convert at the model
   boundary), `copyWith`.
2. **Service** in `lib/services/`: one class wrapping a Firestore
   collection (or Cloud Function calls), exposing `Stream<List<T>>` for
   live lists and plain `Future` methods for writes. Screens depend on
   services via `context.read<T>()`/`context.watch<T>()` (the `provider`
   package), never on `FirebaseFirestore.instance` directly.
3. **Screens** in `lib/screens/<feature>/`: list screen (StreamBuilder),
   detail screen, and a form screen if the feature is user-editable.
4. **Firestore rules**: add a `match` block. Default to
   `allow read: if request.auth != null;` for anything a signed-in parent
   should see, and think explicitly about who can write — see "Security
   invariants" below before allowing any client write.
5. Wire navigation from `root_shell.dart` (bottom nav) or a card/ListTile
   on an existing screen (Home and Profile both link out to
   less-frequently-used sections — that's deliberate, see "Bottom nav is
   full" below).

## Admin role

`admins/{uid}` is a Firestore collection where a document's mere
*existence* (no fields needed) is the permission — granted by hand in the
Firebase console, never by any client write (`firestore.rules`:
`allow write: if false;` on that collection). `AuthService.isAdmin`
reads it once at sign-in. `root_shell.dart` adds a 6th "Admin" tab only
when `isAdmin` is true.

Admin-writable collections (`events`, `articles`, `products`,
`membershipPlans`) follow the same rule shape:
```
allow read: if request.auth != null;
allow write: if isAdmin();
```
`events.bookedCount` is the one exception — any signed-in parent may
update *just that field* (via a `diff().affectedKeys().hasOnly([...])`
clause), because `BookingService`'s transaction needs to touch it. That
pattern — admin owns the document, but one specific field is carved out
for a specific client-side transaction — is worth reusing rather than
loosening the whole rule if a similar need comes up.

## Security invariants (read before touching store/payments/membership)

These aren't style preferences — breaking any of them is a real
vulnerability, not just a code-quality issue:

- **Never trust a client-supplied price or total.** `OrderService` on the
  client caches prices at add-to-cart time purely for UI display. The
  *charge* is always recomputed in `createPaymentIntent`
  (`functions/src/index.ts`) from the live `products`/`membershipPlans`
  documents. If you add a new purchasable thing, its price must be
  re-read server-side before charging for it — don't charge whatever the
  order document says.
- **`parents/{uid}.membershipExpiresAt` is never client-writable.** The
  Firestore rule restricts a parent's own profile update to an explicit
  field allowlist (`name`, `phone`, `fcmToken`) specifically so this
  can't be self-granted. Only `stripeWebhook`, using the Admin SDK (which
  bypasses rules entirely), sets it — after payment actually succeeds.
  If you add another field that grants some privilege or entitlement,
  it needs the same treatment: keep it out of the client's `toMap()` and
  out of the update rule's allowlist.
- **Stripe secret key and webhook signing secret live only in Cloud
  Functions secrets** (`firebase functions:secrets:set`), never in
  `lib/`. `lib/stripe_config.dart` holds only the *publishable* key,
  which is safe to ship client-side by design — don't confuse the two or
  "simplify" by moving anything secret into the Flutter app.
- **Firestore transactions: all reads before any writes.** The Admin SDK
  (and client SDK) both enforce this — see the two-phase read/write loop
  in `stripeWebhook`'s `handlePaymentSucceeded` for the pattern when a
  transaction needs to touch a variable number of documents (one per
  cart line).
- **Webhook idempotency.** Stripe redelivers events at least once.
  `handlePaymentSucceeded` checks `order.status !== "pendingPayment"`
  before doing anything, inside the transaction — keep that guard if you
  touch this function.

## Bottom nav is full

Home, Calendar, Store, Library, Profile (+ Admin for admins) is
deliberately the cap for the bottom nav. Locations was moved out to a
card on Home and a link in Profile when Store was added, because it's
static info checked far less often — that's the model for adding more:
new frequently-used flows get a tab; occasional-use info gets a card/link
from Home or Profile instead of growing the nav bar further.

## Working in this environment

- **No Flutter SDK is installed here.** Dart/Flutter changes can't be
  compiled or run in this session — review carefully (check imports
  resolve, brace/paren balance, API signatures like
  `DropdownButtonFormField`'s `value:` param) rather than assuming a
  build would catch mistakes.
- **Node *is* installed**, so `functions/` changes can and should be
  verified for real: `cd functions && npm install && npx tsc --noEmit`.
  Treat a TypeScript error there as a real bug to fix before committing,
  the same as a failing test.
- **Git branch**: work happens on `claude/create-thelittlenursery-repo-x2j0h1`,
  pushed to `origin` at `Bataklieva/theLittleNursery`. PR #1 tracks it
  into `main`.
- The app **cannot actually run yet** without a human completing the
  Flutter SDK install, `flutter create .` (platform folders aren't
  committed — see `.gitignore`), `flutterfire configure`, and the Stripe
  setup in README.md. Don't claim a feature "works" beyond "reviewed
  carefully and type-checks where that's possible" until someone has
  actually run it on a device.
