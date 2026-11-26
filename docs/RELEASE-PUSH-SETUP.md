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

Create a separate random webhook token of 64 hexadecimal characters, for example with:

```bash
openssl rand -hex 32
```

Store the **same token** in both places:

- Render service environment: `DARB_RELEASE_WEBHOOK_TOKEN`
- GitHub repository Actions secret: `DARB_RELEASE_WEBHOOK_TOKEN`

**This token is not the Firebase service-account JSON and must never contain a private key, JSON, spaces, or line breaks.** `FIREBASE_SERVICE_ACCOUNT_JSON` belongs only in Render as the Firebase credential. `DARB_RELEASE_WEBHOOK_TOKEN` is a separate random value; use the exact same 64-character token in Render and the GitHub Actions secret. The workflow rejects multiline or JSON-shaped values before it can replace the public APK.

Do not commit the token, put it in a workflow file, or send it in a URL. The internal endpoint accepts only the official DAZREVO `latest/app-release.apk` URL.

## 3. Release preflight and delivery

Before replacing the public `latest` APK, GitHub Actions validates the token format and calls the protected readiness endpoint. The endpoint returns ready only when the token matches and Firebase Admin Messaging initialized. If the check fails, the existing release assets are left untouched. After deployment, a manual workflow run with `publish_release=false` can verify readiness without publishing an APK or sending a push notification.


1. Install a current signed DARB APK and sign in so the device registers its FCM token.
2. Confirm the Render logs contain `Firebase Admin initialized` for the expected Firebase project.
3. Publish a signed release using the protected release workflow.
4. Confirm the workflow summary reports the number of registered devices and FCM-accepted messages.
5. Tap the notification on Android and verify that the in-app update screen opens.

If there are no registered devices, the release workflow reports that no push was sent rather than claiming delivery. A delivery failure after publication is still reported as a failed workflow; the preflight prevents known configuration failures from replacing the current APK, but a physical-device push test remains required.

If the Firebase service-account JSON was ever entered as the webhook token or appeared in an Actions log, treat that private key as compromised: replace the Render Firebase credential and revoke the exposed service-account key in Google Cloud IAM.

## Android notification permission

On Android 13 and later, users must grant notification permission. A device with permission denied may register its token but will not display a system notification. The app should keep the in-app notification inbox available as a fallback.
