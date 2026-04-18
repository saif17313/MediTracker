# Firebase Setup

This branch expects Firebase Authentication and Cloud Firestore to be configured for the iOS bundle ID `com.medireminder.app`.

## 1. Create the Firebase project

1. Go to Firebase Console.
2. Create a new project.
3. Open the project and click **Add app**.
4. Choose **iOS**.
5. Use the bundle ID `com.medireminder.app`.
6. Download `GoogleService-Info.plist`.

## 2. Add the Firebase config file

1. Copy the downloaded file to:
   `MediReminder/Resources/GoogleService-Info.plist`
2. Run:

```bash
xcodegen generate
open MediReminder.xcodeproj
```

The repo ignores this file on purpose so your Firebase project config does not get committed accidentally.

## 3. Enable Authentication

1. In Firebase Console, open **Authentication**.
2. Click **Get started**.
3. Enable **Email/Password**.

This branch currently uses email/password sign in and account creation.

## 4. Create Firestore

1. In Firebase Console, open **Firestore Database**.
2. Click **Create database**.
3. Start in the mode you prefer for development.
4. After the database is created, publish the rules from `firebase/firestore.rules`.

If you use the Firebase CLI:

```bash
firebase login
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
```

## 5. Data model used by the app

The app stores user-scoped data under:

- `users/{uid}`
- `users/{uid}/devices/{installationId}`
- `users/{uid}/medicines/{medicineId}`
- `users/{uid}/reminders/{reminderId}`
- `users/{uid}/doseHistory/{recordId}`

## 6. Build and run

1. Open the generated Xcode project.
2. Build and run the app.
3. Create an account from the sign-in screen.
4. Add medicines and reminders.
5. Confirm documents appear only under that user's path in Firestore.

## 7. Important behavior

- The signed-in user only sees their own medicines, reminders, and history.
- Local notifications are rescheduled from the signed-in user's Firestore-backed cache on the current device.
- Signing out clears the local cache and cancels pending reminders on that device.
