# DAZREVO automatic Android updates

## Behavior

- Automatic update checks run when the app starts and when it returns to the foreground, with a ten-minute in-process throttle.
- Checks use the existing GitHub `latest` release manifest; the existing manual update action remains available.
- Automatic download is enabled by default for non-Play-Store APK builds.
- Downloads are queued through Android `DownloadManager`. The default network policy is `NETWORK_WIFI`, so Android waits for Wi-Fi and does not transfer the APK over mobile data.
- Users may turn automatic updates off or allow mobile-network downloads from Settings.
- The download-complete receiver verifies the downloaded APK against the manifest SHA-256 before marking it ready.
- Android's package installer remains the final installation step. The app cannot silently install updates on ordinary consumer devices; users must approve the system installation prompt and grant the Android install-unknown-apps permission if it has not already been granted.
- Play Store builds keep the self-hosted APK updater disabled and must use the store's update mechanism.

## Settings

The settings sheet stores two preferences in Android private SharedPreferences:

- `auto_update_enabled` (default: `true`)
- `wifi_only` (default: `true`)

Changing the network policy affects newly enqueued downloads. A download already queued by Android retains the policy with which it was created.

## Operational boundaries

This implementation does not perform unattended installation and does not promise a background version check while the app has never been opened after a release is published. It rechecks on launch/resume; Android DownloadManager can then continue or wait for Wi-Fi even after the app is closed. A future WorkManager periodic release poll can extend discovery while the app is closed, but should be added only with the Android build dependency and battery-policy validation.
