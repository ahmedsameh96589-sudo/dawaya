# 💊 Dawaya — Smart Pharmacy App

Graduation project (Computer Science, 2026). Dawaya is a Flutter app that brings the pharmacy to your phone. You can scan a prescription, find medicine substitutes, chat with a doctor and order to your door.

This repo is the **Flutter mobile app**. It talks to a Node.js / Express / MongoDB REST API.

## Features

- **Prescription scanning** with on-device OCR (Google ML Kit) and the camera
- **Doctor consultations** with live chat and a rating after each consultation
- **Medicine substitutes**: alternatives with the same active ingredient
- **Push notifications** through Firebase Cloud Messaging
- **Shopping flow**: categories, product details, cart, checkout address, payment, order history
- **Authentication**: email & password, Google sign-in, OTP verification, password reset
- **Admin tools** for managing products, creating doctor accounts and reviewing prescriptions
- **Arabic & English** localization
- Favorites, profile editing and a news feed

## Tech stack

| Layer | Tools |
|-------|-------|
| Mobile | Flutter, Dart, `camera`, `google_mlkit_text_recognition`, `image_picker`, `google_sign_in` |
| Notifications | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Backend (separate repo) | Node.js, Express, MongoDB/Mongoose, JWT, Firebase Admin, Nodemailer, Twilio |

## Project structure

```
lib/
├── app/            # App widget & routing
├── core/
│   ├── config/     # API host, Firebase & Google auth config
│   ├── localization/
│   ├── services/   # API client, auth session, push notifications
│   └── theme/
└── features/
    ├── auth/       # Splash, onboarding, login, signup, OTP, password reset
    ├── catalog/    # Categories, products, prescription scan & requests
    ├── cart/       # Cart, checkout, payment
    ├── chat/       # Doctors, consultations, chat, ratings
    ├── orders/
    ├── profile/    # Profile, favorites
    ├── news/
    ├── notifications/
    └── admin/
```

## Running locally

```bash
flutter pub get
flutter run
```

The app expects the API at `http://localhost:5001/api` (`http://10.0.2.2:5001/api` on the Android emulator). You can change it in `lib/core/config/app_config.dart`. For push notification setup, see [FIREBASE_PUSH_SETUP.md](FIREBASE_PUSH_SETUP.md).

---

Built by [Ahmed Sameh](https://ahmedsameh96589-sudo.github.io)
