# Anchor

A single-user, cross-device habit tracker built around one philosophy:
**never miss twice.** One missed day doesn't break a streak — two in a row do.

Deliberately quiet: one tap is always enough, history is honest, and the only
encouragement is identity-level micro-copy — never guilt or gamification.

A Flutter **Web** app (PWA-installable) backed by Firebase (Auth + Firestore +
Hosting). See [anchor-final-spec.md](anchor-final-spec.md) for the full spec.

## Stack

Flutter Web · Firebase (Auth, Firestore, Hosting) · Bloc · go_router

## Develop

```bash
flutter pub get
firebase emulators:start                              # local Auth + Firestore
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Emulators are the dev environment — fake data, works offline, resets freely.
The real Firebase project is production only.

## Deploy

```bash
flutter build web --release
firebase deploy --only hosting
firebase deploy --only firestore:rules   # whenever rules change
```

## Setup notes

- Add a **backup IAM Owner** to the Firebase project (Firebase console → one
  click) so account recovery is possible. See [docs/RECOVERY.md](docs/RECOVERY.md).

## License

[MIT](LICENSE)
