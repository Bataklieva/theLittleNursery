/// Stripe's publishable key is safe to ship in client code by design —
/// unlike the *secret* key (which only ever lives in the Cloud Functions
/// environment, see functions/src/index.ts) it can't move money on its
/// own. Replace this with your real key from
/// https://dashboard.stripe.com/apikeys before running the app; keep the
/// `pk_test_...` key for development and swap to `pk_live_...` for
/// production builds.
const stripePublishableKey = 'pk_test_REPLACE_ME';
