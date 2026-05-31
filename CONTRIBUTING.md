# Contributing

## Workflow

1. Create a feature branch from the main development branch.
2. Keep changes focused on one feature or fix.
3. Update docs when behavior, architecture, packages, routes, APIs, or setup changes.
4. Run formatting, analysis, and tests before opening a pull request.

## Branch Names

Use short descriptive names:

```text
feature/auth-login
fix/counter-test
docs/package-diagram
```

## Commit Style

Use concise imperative messages:

```text
Add package dependency diagram
Fix login validation state
Update API integration docs
```

## Required Checks

Run before submitting changes:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Pull Request Checklist

- Code is formatted.
- Analyzer passes.
- Tests pass or missing tests are explained.
- Documentation is updated.
- New package folders include `.gitkeep` if empty.
- No secrets, tokens, generated build output, or local config files are committed.

## Documentation Rule

If a change adds or updates a feature, check whether these docs need updates:

- `docs/architecture.md`
- `docs/package-diagram.md`
- `docs/api-integration.md`
- `docs/state-management.md`
- `docs/routing.md`
- `docs/testing-strategy.md`
- `docs/ui-guidelines.md`
- `docs/error-handling.md`
