# Mac setup

Everything needed to build and run this app locally on macOS.

## 1. Flutter SDK

```sh
brew install --cask flutter
flutter doctor
```

Re-run `flutter doctor` after each step below — it tells you what's still
missing.

## 2. Xcode (for iOS — install from the Mac App Store first, then)

```sh
xcode-select --install
sudo xcodebuild -license accept
```

## 3. CocoaPods (iOS dependency manager Flutter needs)

```sh
brew install cocoapods
```

## 4. Android Studio (for Android + an emulator)

```sh
brew install --cask android-studio
```

Open it once and run through the setup wizard so it installs the Android
SDK. Then in Android Studio: **Settings → Plugins** → install the
*Flutter* and *Dart* plugins.

## 5. Firebase CLI + FlutterFire CLI

Needed for the `flutterfire configure` step later.

```sh
brew install node   # if you don't already have it
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## 6. An editor (pick one)

- VS Code: `brew install --cask visual-studio-code`, then install the
  *Flutter* extension
- or use Android Studio itself (already has the Flutter/Dart plugins from
  step 4)

## 7. Git

Likely already installed; if not: `brew install git`

## Clone and run

```sh
git clone https://github.com/Bataklieva/theLittleNursery.git
cd theLittleNursery
git checkout claude/create-thelittlenursery-repo-x2j0h1
flutter pub get
flutter create --org bg.thelittlenursery --project-name the_little_nursery .
flutterfire configure
flutter run
```

See `README.md` for the Firestore schema and security rules this app
expects once `flutterfire configure` has created a real Firebase project.
