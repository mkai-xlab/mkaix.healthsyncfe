# Capstone Frontend

Flutter frontend application for the Capstone project.

The current codebase is a minimal Flutter counter application generated from the default Flutter starter template. The repository already includes documentation and architecture notes so the project can grow into a layered frontend structure as features are added.

## Tech Stack

- Flutter
- Dart SDK `^3.12.0`
- Material Design widgets
- `flutter_lints` for static analysis
- `flutter_test` for widget tests

## Project Structure

```text
fe/
├── lib/
│   └── main.dart              # Application entry point and current counter UI
├── test/
│   └── widget_test.dart       # Counter smoke test
├── docs/
│   ├── project-overview.md    # Product and repository overview
│   ├── architecture.md        # Current and planned frontend architecture
│   ├── api-integration.md     # Backend communication conventions
│   ├── build-and-release.md   # Build and release workflow
│   ├── development.md         # Local development workflow
│   ├── environment.md         # Runtime configuration rules
│   ├── error-handling.md      # Error and UI state handling
│   ├── package-diagram.md     # lib package dependency diagram
│   ├── routing.md             # Navigation strategy
│   ├── state-management.md    # State ownership rules
│   ├── testing-strategy.md    # Test expectations
│   ├── ui-guidelines.md       # UI and accessibility guidelines
│   └── diagrams/
│       ├── package-diagrams.drawio
│       └── package-diagrams.png
├── CHANGELOG.md               # Notable changes by version
├── CONTRIBUTING.md            # Contribution workflow
├── LICENSE                    # Project license terms
├── SECURITY.md                # Security and secret handling
├── pubspec.yaml               # Flutter package metadata and dependencies
└── analysis_options.yaml      # Dart analyzer and lint configuration
```

## Getting Started

### Prerequisites

- Flutter SDK installed
- A configured device, emulator, or supported desktop/web target

Check your environment:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Current Application

The app starts in `lib/main.dart`:

- `main()` calls `runApp(const MyApp())`.
- `MyApp` configures a `MaterialApp` with a seeded Material theme.
- `MyHomePage` displays a counter and increments it through a `FloatingActionButton`.
- `test/widget_test.dart` verifies the counter increments from `0` to `1`.

## Documentation

- [Project Overview](docs/project-overview.md)
- [Architecture](docs/architecture.md)
- [Package Diagram](docs/package-diagram.md)
- [Development Guide](docs/development.md)
- [Environment Configuration](docs/environment.md)
- [API Integration](docs/api-integration.md)
- [State Management](docs/state-management.md)
- [Routing](docs/routing.md)
- [Testing Strategy](docs/testing-strategy.md)
- [UI Guidelines](docs/ui-guidelines.md)
- [Error Handling](docs/error-handling.md)
- [Build And Release](docs/build-and-release.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Changelog](CHANGELOG.md)

## Architecture Direction

The repository currently has a single Dart source file, but the intended direction is a layered Flutter frontend:

- Presentation layer for pages, widgets, and view models.
- Domain layer for entities, repository contracts, and use cases.
- Data layer for API clients, DTO/models, and repository implementations.

The planned structure is documented in `docs/architecture.md` and visualized in `docs/diagrams/package-diagrams.png`.

## Documentation Maintenance

When adding or updating a feature, update the related docs in the same change. At minimum, check architecture, package diagram, API integration, state management, routing, testing, UI, and error handling docs.
