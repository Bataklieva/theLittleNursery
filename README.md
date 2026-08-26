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

## Project structure

```
lib/
  main.dart              Entry point, Firebase init, provider wiring
  app.dart                Root widget: auth gate (login vs. app shell)
  firebase_options.dart   Placeholder — regenerate with flutterfire configure
  theme/                  App color palette & ThemeData
  models/                 Plain Dart data classes (Child, Booking, ...)
  services/               Firebase Auth/Firestore/Messaging integrations
  screens/
    auth/                 Login, sign up
    home/                 Dashboard with upcoming workshops
    calendar/             Month calendar + day list + event detail/booking
    library/               Parent library article list + detail
    locations/             Studio locations & contact info
    profile/                Parent info, children CRUD, my bookings
    admin/                  Admin-only: manage workshops & articles
    root_shell.dart         Bottom navigation shell (adds "Admin" for admins)
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
**Cloud Firestore**, and **Cloud Messaging** enabled.

1. Create a project at https://console.firebase.google.com.
2. Install the CLI tools and log in:
   ```sh
   dart pub global activate flutterfire_cli
   firebase login
   ```
3. From the project root, generate real config (replaces the placeholder
   `lib/firebase_options.dart`):
   ```sh
   flutterfire configure
   ```
4. Deploy the security rules and composite indexes:
   ```sh
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
```

`events` and `articles` are written by admin accounts, in-app (see the
"Studio admin" feature above) — regular parent accounts only read them,
aside from the `bookedCount` field on `events`, which any signed-in
parent's booking transaction may adjust. See `firestore.rules` for the
full access policy.
