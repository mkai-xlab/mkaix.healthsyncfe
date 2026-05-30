# Development Guide

## Local Setup

Install Flutter dependencies:

```bash
flutter pub get
```

Check Flutter installation and target devices:

```bash
flutter doctor
flutter devices
```

Run the app:

```bash
flutter run
```

## Quality Checks

Run analyzer checks:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Format Dart code:

```bash
dart format .
```

## Current Test Coverage

The current test suite contains a single widget smoke test in `test/widget_test.dart`.

It verifies that:

- The counter starts at `0`.
- The counter does not initially show `1`.
- Tapping the add button increments the counter to `1`.

## Development Notes

- Keep UI changes small and testable.
- Add widget tests for important screens and user flows.
- Add unit tests when domain use cases are introduced.
- Keep generated platform folders updated through Flutter tooling instead of editing generated files manually unless platform-specific behavior is required.
- Update `docs/package-diagram.md` and `docs/diagrams/package-diagrams.*` when adding package folders or package dependency relationships.
