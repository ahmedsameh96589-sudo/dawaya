# 💊 Dawaya — Smart Pharmacy App

Graduation project (Computer Science, 2026). Dawaya is a Flutter app that brings the pharmacy to your phone. You can scan a prescription, find medicine substitutes, chat with a doctor and order to your door.

This repo is the **Flutter mobile app**. It talks to a Node.js / Express / MongoDB REST API.

## Features

- **Scan to Cart**: photograph a prescription, on-device OCR (Google ML Kit) reads the medicines, and each line is matched to the catalog, tolerating OCR typos and brand variants. In-stock items go to the cart in one tap, prescription-only items open the approval flow, and out-of-stock items offer a substitute.
- **Order tracking**: a status timeline (placed, confirmed, preparing, on its way, delivered) with push notifications on every change, and cancellation while the pharmacy has not started.
- **Medicine reminders**: daily local notifications for any medicine, set from the product page, that keep working when the app is closed.
- **Doctor consultations**: real-time chat over Socket.IO with image attachments and a rating after each consultation.
- **Medicine substitutes**: alternatives with the same active ingredient.
- **Shopping flow**: categories, product details, cart, checkout address, demo payment, order history.
- **Authentication**: email & password, Google sign-in, OTP verification, password reset. Sessions persist in the device keychain.
- **Admin tools** for managing products, creating doctor accounts and reviewing prescriptions.
- Push notifications (Firebase Cloud Messaging), Arabic & English localization, favorites, profile editing and a health-news feed.

## Tech stack

| Layer | Tools |
|-------|-------|
| Mobile | Flutter, Dart, Riverpod, `camera`, `google_mlkit_text_recognition`, `socket_io_client`, `flutter_secure_storage` |
| Notifications | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Backend ([dawaya-backend](https://github.com/ahmedsameh96589-sudo/dawaya-backend)) | Node.js, Express, MongoDB/Mongoose, JWT, Firebase Admin, Nodemailer, Twilio |

## Project structure

```
lib/
├── app/            # App widget & routing
├── core/
│   ├── config/     # API host, Firebase & Google auth config
│   ├── localization/
│   ├── network/    # ApiClient (HTTP), RealtimeClient (Socket.IO), upload URLs
│   ├── services/   # Auth session (keychain), push notifications
│   ├── theme/
│   └── widgets/    # Shared loading / error / empty states
└── features/       # One folder per feature: data/ (repositories), models/, presentation/
    ├── auth/       # Splash, onboarding, login, signup, OTP, password reset
    ├── catalog/    # Categories, products, prescription scan, OCR parser, catalog matcher
    ├── cart/       # Cart, checkout, payment
    ├── chat/       # Doctors, consultations, real-time chat, ratings
    ├── orders/     # Order history and tracking timeline
    ├── reminders/  # Medicine reminders (local notifications)
    ├── profile/    # Profile, favorites
    ├── news/
    ├── notifications/
    └── admin/
```

Every feature talks to the backend through a repository built on one `ApiClient`, which owns the base URL, auth header, timeouts, JSON decoding and error messages. A signed-in request that gets a 401 signs the user out. Repositories are provided with Riverpod so tests can swap the HTTP client.

## Tests

```bash
flutter analyze
flutter test
```

Unit tests cover the prescription parser, the catalog matcher, models, the persisted session, the API client and repositories, reminders and the realtime client; widget tests cover the order tracking and reminders screens. GitHub Actions runs both commands on every push and pull request.

## Running locally

```bash
flutter pub get
flutter run
```

By default the app expects the API at `http://localhost:5001/api` (`http://10.0.2.2:5001/api` on the Android emulator). To point it at a deployed backend:

```bash
flutter run --dart-define=API_HOST=https://your-api.example.com
``` For push notification setup, see [FIREBASE_PUSH_SETUP.md](FIREBASE_PUSH_SETUP.md).

---

Built by [Ahmed Sameh](https://ahmedsameh96589-sudo.github.io)
