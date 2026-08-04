# Environment Configuration

## Required Tooling

| Tool | Current Requirement |
| --- | --- |
| Flutter SDK | Installed locally and available through `flutter`. |
| Dart SDK | Managed by Flutter, project constraint is `^3.12.0`. |
| Android toolchain | Required for Android builds. |
| Browser target | Required for Flutter web builds. |
| macOS toolchain | Required only for macOS builds. |

Verify local setup:

```bash
flutter doctor
flutter devices
```

## Current Configuration

The project reads the backend API URL from the `API_BASE_URL` compile-time
environment value, with a development fallback defined in
`lib/core/constants/api_constants.dart`.

Pass a value through `--dart-define` when running or building:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

Access values in Dart with:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://54.254.113.71:8000/api/v1',
);
```

## Expected Environments

| Environment | Purpose | Example API URL |
| --- | --- | --- |
| Local | Developer machine. | `http://localhost:8080` |
| Development | Shared non-production backend. | To be defined. |
| Staging | Release candidate validation. | To be defined. |
| Production | Live users. | To be defined. |

## Rules

- Do not hardcode backend URLs inside pages or widgets.
- Do not commit secrets, access tokens, API keys, or local-only credentials.
- Keep configuration access centralized under `lib/core` when configuration code is introduced.
- Document every new `--dart-define` key in this file.
- Use safe defaults only for local development.

## Future Variables

| Key | Required | Description |
| --- | --- | --- |
| `API_BASE_URL` | Yes, once backend integration exists. | Base URL for backend API requests. |
| `APP_ENV` | Optional. | Environment label such as `local`, `dev`, `staging`, or `prod`. |
| `ENABLE_LOGGING` | Optional. | Enables verbose client logging in non-production builds. |
