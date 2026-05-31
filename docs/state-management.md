# State Management

## Current State

The current app uses local `StatefulWidget` state and `setState()` in `lib/main.dart` for the counter demo.

This is acceptable for the starter screen only. Product features should move stateful screen logic into view models or the selected state management solution.

## Planned Ownership

| State Type | Owner |
| --- | --- |
| Temporary widget-only state | Widget or local `State`. |
| Screen state | `presentation/viewmodels`. |
| Business workflow state | `domain/usecases`. |
| Persisted or remote state | `data/repositories` through domain contracts. |
| App-wide constants | `core/constants`. |

## Rules

- Keep widgets focused on rendering and user interaction.
- Keep async calls out of `build()` methods.
- View models should expose UI-ready state, not raw API models.
- Use cases should not import Flutter widgets.
- Data repositories should not expose transport details to presentation code.

## Future Decision

The project has not selected a global state management library yet.

When the app grows, choose one approach and update this document:

- Provider or ChangeNotifier for simple app state.
- Riverpod for testable dependency injection and scalable state.
- Bloc/Cubit for event-driven state transitions.

## View Model Pattern

When view models are introduced, each screen should have:

- A state object representing loading, data, empty, and error states.
- Public methods for user actions.
- Dependencies injected through constructors.
- Tests covering successful and failing state transitions.
