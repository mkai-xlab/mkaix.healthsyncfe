# Testing Strategy

## Current State

The project currently has one widget smoke test in `test/widget_test.dart`.

Run tests with:

```bash
flutter test
```

## Test Types

| Test Type | Use For | Location |
| --- | --- | --- |
| Unit test | Use cases, validators, mappers, pure functions. | `test/...` |
| Widget test | Screens and reusable widgets. | `test/...` |
| Integration test | Full user flows across screens and services. | `integration_test/...` when introduced. |

## Minimum Expectations

For each new feature, add tests for:

- Successful user flow.
- Loading state if async work exists.
- Empty state if the feature can return no data.
- Error state for failed API or validation behavior.
- Mapping or parsing logic for API models.

## Naming

Use descriptive test names:

```dart
testWidgets('shows validation message when email is invalid', (tester) async {
  // ...
});
```

## Mocking

When repositories and use cases are introduced:

- Mock repository interfaces, not concrete API clients, in domain and view model tests.
- Keep mock data close to the test unless reused across many tests.
- Prefer deterministic tests without real network calls.

## CI Gate

Before merging a feature, these commands should pass:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
