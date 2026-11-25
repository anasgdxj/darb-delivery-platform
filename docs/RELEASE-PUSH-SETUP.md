# DARB release push notifications setup

This integration sends an `APP_UPDATE` notification after the signed APK is published. The Android app opens its update flow when the user taps the notification. It also stores an in-app notification for users with registered devices.

## 1. Firebase Admin credentials on Render

1. Open the Firebase project used by the Android app.
2. Open **Project settings → Service accounts** and generate a new private key.
3. In the Render service environment, set `FIREBASE_SERVICE_ACCOUNT_JSON` to the **entire service-account JSON document**. Do not use the Firebase Web API key or the Android `google-services.json` file.
4. The credential must contain `project_id`, `client_email`, and `private_key`. The backend accepts standard JSON, a JSON string containing JSON, or base64-encoded JSON (optionally prefixed with `base64:`).
5. Ensure Firebase Cloud Messaging is enabled for the same Firebase project configured in the Android application, then redeploy the backend.

The backend never logs credential values. If initialization fails, it reports only which required field names are missing.

## 2. Protect the release webhook

Create a random token of at least 32 characters, for example with:

```bash
openssl rand -hex 32
```

Store the **same token** in both places:

- Render service environment: `DARB_RELEASE_WEBHOOK_TOKEN`
- GitHub repository Actions secret: `DARB_RELEASE_WEBHOOK_TOKEN`

Do not commit the token, put it in a workflow file, or send it in a URL. The internal endpoint accepts only the official DARB `latest/app-release.apk` URL.

## 3. Release preflight

Before publishing the APK, GitHub Actions calls the protected readiness endpoint. It verifies that the same webhook token is configured on Render and that Firebase Admin messaging initialized successfully. If either check fails, the workflow stops before replacing the public `latest` release.

The readiness endpoint returns only a boolean status; it never returns credentials, service-account fields, or device tokens.

## 4. Verify delivery

1. Install a current signed DARB APK and sign in so the device registers its FCM token.
2. Confirm the Render logs contain `Firebase Admin initialized` for the expected Firebase project.
3. Publish a signed release using the protected release workflow.
4. Confirm the workflow summary reports the number of registered devices and FCM-accepted messages.
5. Tap the notification on Android and verify that the in-app update screen opens.

If there are no registered devices, the release workflow reports that no push was sent rather than claiming delivery. If FCM is disabled or all sends fail, the notification step fails visibly; the APK release itself may already have been published.

## Android notification permission

On Android 13 and later, users must grant notification permission. A device with permission denied may register its token but will not display a system notification. The app should keep the in-app notification inbox available as a fallback.
