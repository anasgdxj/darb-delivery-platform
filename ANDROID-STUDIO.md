# Preparing DARB for Android Studio

The canonical mobile source is stored in `DARB-source.zip`. Current Flutter and Android integration changes are maintained in `mobile-overrides/`. Do not open the repository root as if it were the Flutter app, and do not copy override files manually.

Run on Linux, macOS, or Git Bash with Flutter stable, Java 17, Python 3, unzip, zip, and curl installed:

```bash
bash prepare-android-studio.sh
```

The script creates `DARB-Android-Studio/`, applies the mobile override set, downloads and bundles the attributed Syrian city photographs, adds the update receiver and FileProvider configuration, and prepares the Flutter dependencies.

**Android safety:** the script deliberately preserves the Android Gradle project already present in the source archive. It does not regenerate the Android platform, replace Firebase/OAuth files, alter signing configuration, or change the installed application's package identity. It stops if the existing applicationId cannot be verified as `com.darb.darb`, rather than risking an incompatible update.

Open the generated `DARB-Android-Studio/` directory in Android Studio — specifically the directory containing `pubspec.yaml`.

The GitHub Actions workflow `Package DARB for Android Studio` runs the preparation, resolves packages, analyzes Dart sources, builds a debug APK, and uploads both the ZIP and APK as temporary artifacts. It does not use or modify release-signing secrets.
