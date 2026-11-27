# Release trigger

This file records the explicit publication request for the verified DAZREVO customer-order refresh fix.

- Application source commit: e246b7244844b504214a97abe0544457d4ecc5f7
- Flutter analysis and tests: 45964609786 — passed.
- Source archive validation and build: 45964609905 — passed.
- Signed Android release build: 45964609882 — passed; APK and AAB artifacts uploaded.

Publish the signed APK and its matching app-update.json as the public latest release. The application source is unchanged by this release-trigger document; the release workflow rebuilds and verifies the exact main-branch source before replacing latest.

- Publication trigger: [publish-apk]
