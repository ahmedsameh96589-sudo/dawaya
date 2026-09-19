# Firebase Push Notifications — DAWAYA Setup

Push notifications alert doctors when patients send chat messages, and patients when doctors reply. In-app notifications continue to work even if Firebase is not configured.

---

## Overview

| Layer | What happens |
|-------|----------------|
| **Flutter app** | Gets FCM device token after login, sends it to backend |
| **Backend** | Stores token on `User` / `Doctor`, sends FCM when chat messages are created |
| **Fallback** | Without Firebase credentials, app and API work normally with in-app notifications only |

---

## Part 1 — Firebase Console (required)

### 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. **Add project** → name it (e.g. `dawaya-prod`)
3. Disable Google Analytics if you don't need it

### 2. Register Android app

1. Project overview → **Add app** → **Android**
2. **Android package name:** `com.example.dawayaa` (must match `android/app/build.gradle.kts`)
3. Download **`google-services.json`**
4. Place it at:

   ```
   dawayaa/android/app/google-services.json
   ```

5. Skip SHA-1 for now unless you need other Firebase features

### 3. Register iOS app

1. **Add app** → **iOS**
2. **Bundle ID:** `com.example.dawayaa` (must match Xcode / `Info.plist`)
3. Download **`GoogleService-Info.plist`**
4. Place it at:

   ```
   dawayaa/ios/Runner/GoogleService-Info.plist
   ```

5. Open `ios/Runner.xcworkspace` in Xcode:
   - Select **Runner** target → **Signing & Capabilities**
   - Click **+ Capability** → add **Push Notifications**
   - Add **Background Modes** → enable **Remote notifications**

### 4. Enable Cloud Messaging

1. Firebase Console → **Build** → **Cloud Messaging**
2. No extra toggle is needed for FCM; ensure the project is active

### 5. Create service account (backend)

1. Firebase Console → **Project settings** (gear) → **Service accounts**
2. **Generate new private key** → download JSON
3. Save as (example):

   ```
   dawaya-v2/firebase-service-account.json
   ```

4. **Do not commit this file.** Add to `.gitignore`.

---

## Part 2 — Backend setup

### 1. Install dependency

```bash
cd dawaya-v2
npm install
```

### 2. Configure environment

Add to `.env`:

```env
FIREBASE_SERVICE_ACCOUNT=./firebase-service-account.json
```

Use an absolute or relative path to the downloaded service account JSON.

### 3. Restart the server

```bash
npm run dev
```

On startup you should see:

```
🔔 Firebase Admin ready for push notifications.
```

If `FIREBASE_SERVICE_ACCOUNT` is unset, you'll see:

```
🔔 Push disabled: set FIREBASE_SERVICE_ACCOUNT in .env
```

The API still works; only push is skipped.

---

## Part 3 — Flutter setup

### Option A — FlutterFire CLI (recommended)

```bash
cd dawayaa
dart pub global activate flutterfire_cli
flutterfire configure
```

This updates `lib/core/config/firebase_options.dart` and platform config files.

### Option B — Manual `firebase_options.dart`

Edit `lib/core/config/firebase_options.dart` and replace placeholders:

- `YOUR_FIREBASE_API_KEY`
- `YOUR_FIREBASE_APP_ID`
- `YOUR_FIREBASE_MESSAGING_SENDER_ID`
- `YOUR_FIREBASE_PROJECT_ID`

Values are in Firebase Console → **Project settings** → **Your apps** → each platform app.

### Option C — `--dart-define` (CI / no committed secrets)

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=AIza... \
  --dart-define=FIREBASE_APP_ID=1:123:android:abc \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 \
  --dart-define=FIREBASE_PROJECT_ID=dawaya-prod
```

### Install packages

```bash
flutter pub get
```

### Android note

The Google Services Gradle plugin is applied **only when** `android/app/google-services.json` exists. Without that file, the app builds and runs with in-app notifications only.

### iOS note

`GoogleService-Info.plist` is required for FCM on a real device. Simulator push delivery is limited; test on a physical iPhone when possible.

---

## Part 4 — How it works

1. User or doctor logs in → app requests notification permission → FCM token sent to `PUT /api/notifications/fcm-token`
2. Patient sends message → backend creates in-app notification + FCM to doctor's `fcmToken`
3. Doctor replies → backend creates in-app notification + FCM to patient's `fcmToken`
4. Tapping a push opens the consultation chat (when `consultationId` is in the payload)
5. Foreground messages show a local notification banner (iOS/Android)

Token refresh is handled automatically via `onTokenRefresh`.

---

## Testing

### Prerequisites

- Backend running with `FIREBASE_SERVICE_ACCOUNT` set
- Two devices or simulators (or one device + one emulator)
- Patient account and doctor account

### Test flow

1. **Doctor device**
   - Log in as doctor
   - Allow notifications when prompted
   - Put app in background

2. **Patient device**
   - Log in as patient
   - Start/open a consultation with that doctor
   - Send a chat message

3. **Expected:** Doctor receives push notification; in-app notification appears in Notifications tab

4. **Reverse test**
   - Doctor replies from doctor account
   - Patient (backgrounded) receives push

5. **Foreground test**
   - Keep recipient app open
   - Send a message from the other party
   - Local notification banner should appear

6. **Without Firebase**
   - Remove / unset `FIREBASE_SERVICE_ACCOUNT`
   - Leave Flutter placeholders as `YOUR_*`
   - App should start normally; in-app notifications still work via polling

### Debug tips

- Check backend logs for `🔔 Push send failed` or `🔔 Firebase Admin ready`
- Confirm token saved: `PUT /api/notifications/fcm-token` returns 200 after login
- Android 13+: notification permission must be granted
- iOS: Push Notifications capability + physical device for reliable testing

---

## Files reference

| File | Purpose |
|------|---------|
| `dawayaa/lib/core/config/firebase_options.dart` | Flutter Firebase config |
| `dawayaa/lib/core/services/push_notification_service.dart` | FCM init, foreground display, tap handling |
| `dawayaa/android/app/google-services.json` | Android Firebase config (you add) |
| `dawayaa/ios/Runner/GoogleService-Info.plist` | iOS Firebase config (you add) |
| `dawaya-v2/src/utils/pushNotification.js` | Server-side FCM sender |
| `dawaya-v2/.env` → `FIREBASE_SERVICE_ACCOUNT` | Service account path |

---

## Security

- Never commit `firebase-service-account.json`, `google-services.json`, or `GoogleService-Info.plist` to public repos if you treat them as sensitive
- Rotate service account keys if exposed
- FCM tokens are stored on user/doctor documents and updated on each login
