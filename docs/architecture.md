# Frontend Architecture

This document describes the current Flutter frontend and the intended architecture as the Capstone app grows.

## Current State

The current implementation is a default Flutter counter app contained in `lib/main.dart`.

Runtime flow:

1. `main()` starts the Flutter application with `runApp(const MyApp())`.
2. `MyApp` creates a `MaterialApp` and configures the app theme.
3. `MyHomePage` renders the counter screen.
4. `_MyHomePageState` owns the local `_counter` value.
5. Pressing the floating action button calls `_incrementCounter()`.
6. `_incrementCounter()` calls `setState()`, updates `_counter`, and triggers a rebuild.

Package dependency diagram:

![Frontend package dependencies](diagrams/package-diagrams.png)

## Current Components

| Component | File | Responsibility |
| --- | --- | --- |
| `main()` | `lib/main.dart` | Flutter application entry point. |
| `MyApp` | `lib/main.dart` | Root widget and `MaterialApp` configuration. |
| `MyHomePage` | `lib/main.dart` | Stateful counter page configuration. |
| `_MyHomePageState` | `lib/main.dart` | Counter state, increment logic, and UI rendering. |
| `widget_test.dart` | `test/widget_test.dart` | Smoke test for the counter behavior. |

## Planned Layered Structure

The existing diagram also captures the recommended direction for future frontend features. When the app grows beyond the starter screen, split code by responsibility:

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── routing/
│   └── theme/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── interface_repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── viewmodels/
    └── widgets/
```

## Layer Responsibilities

| Layer | Responsibility | Should Depend On |
| --- | --- | --- |
| Presentation | Screens, widgets, user interactions, state exposed to UI. | Domain, core UI utilities. |
| Domain | Business entities, use cases, repository interfaces. | Core only. |
| Data | API clients, persistence, DTOs, repository implementations. | Domain contracts, core networking/errors. |
| Core | Shared constants, theme, routing, common errors, utility code. | Framework and package APIs only. |

## Dependency Rules

- UI code should call use cases instead of directly calling APIs.
- Domain code should not import Flutter widgets or data models.
- Data repositories should convert external models into domain entities.
- Shared constants and app-wide utilities belong in `core`, not in feature pages.
- Tests should cover user-visible behavior and important domain logic as it is introduced.

## Suggested Feature Layout

For a larger app, prefer feature-first grouping inside each layer when files increase:

```text
lib/
├── features/
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── core/
```

Use the flatter layer-based layout first if the app is still small. Move to feature-first organization only when multiple product areas make the global folders hard to navigate.

## Diagram Maintenance

Editable source: `docs/diagrams/package-diagrams.drawio`

Rendered image: `docs/diagrams/package-diagrams.png`

Update both files whenever package folders or dependency relationships change significantly.

Also update `docs/package-diagram.md` when relationships change.
