# Error Handling

## Current State

The current counter app has no network, validation, or application error states.

When real features are added, every async screen should define loading, success, empty, and error states.

## UI States

| State | Required UI Behavior |
| --- | --- |
| Loading | Show progress indicator or skeleton. |
| Success | Show the requested data or completed action. |
| Empty | Explain that no data exists and offer the next action if available. |
| Validation error | Show actionable field-level or form-level message. |
| Network error | Explain connectivity issue and provide retry. |
| Unauthorized | Redirect to login or show session-expired message. |
| Unknown error | Show safe generic message and avoid exposing stack traces. |

## Error Boundaries

Flutter does not use React-style error boundaries. Handle expected errors in view models and reserve global error handling for unexpected crashes.

## Rules

- Do not show raw backend errors directly to users.
- Keep technical logs out of production UI.
- Map data-layer exceptions into domain/app errors.
- Let view models decide the UI state from use case results.
- Give users a recovery path when possible.

## Future Error Model

When domain errors are introduced, prefer a small controlled set such as:

- `NetworkFailure`
- `ValidationFailure`
- `UnauthorizedFailure`
- `ForbiddenFailure`
- `NotFoundFailure`
- `ServerFailure`
- `UnknownFailure`
