# DAZREVO website update release publication

This publication includes the official website-hosted Android update flow.

- Android updater reads the release manifest from the DAZREVO website first.
- GitHub Releases remain the fallback source.
- The public website deployment publishes the verified universal APK and a matching manifest.
- The website manifest is generated from the signed release manifest and verifies the APK SHA-256 before deployment.
- The Arabic home page displays version, file size, publication date, and SHA-256.
- Arabic, English, and Turkish download links use the website-hosted APK.

Publish only after the signed APK and Play Store AAB pass the release workflow checks. After publishing, sync the generated manifest to main so the Pages deployment publishes the matching APK and metadata.
