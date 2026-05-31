# Build And Release

## Current State

The app uses the default Flutter generated platform folders for Android, web, and macOS.

## Common Commands

Analyze and test before every release:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Build Android APK:

```bash
flutter build apk --release
```

Build Android App Bundle:

```bash
flutter build appbundle --release
```

Build web:

```bash
flutter build web --release
```

Build macOS:

```bash
flutter build macos --release
```

## Versioning

Version is currently defined in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Use this format:

```text
major.minor.patch+buildNumber
```

## Release Checklist

- Update `CHANGELOG.md`.
- Confirm `pubspec.yaml` version is correct.
- Run `dart format --set-exit-if-changed .`.
- Run `flutter analyze`.
- Run `flutter test`.
- Build the target platform artifact.
- Smoke test the built artifact.
- Confirm no secrets or local config files are included.

## Signing

Signing is not configured in this repository yet.

When Android or store releases are required, document:

- Keystore generation and storage policy.
- Required Gradle properties.
- CI secret names.
- Store upload steps.
