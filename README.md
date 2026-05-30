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
│   ├── architecture.md        # Current and planned frontend architecture
│   ├── development.md         # Local development workflow
│   └── diagrams/
│       ├── fe-architecture.drawio
│       └── fe-architecture.png
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

- [Architecture](docs/architecture.md)
- [Development Guide](docs/development.md)
- [Frontend Architecture Diagram](docs/diagrams/fe-architecture.png)

## Architecture Direction

The repository currently has a single Dart source file, but the intended direction is a layered Flutter frontend:

- Presentation layer for pages, widgets, and view models.
- Domain layer for entities, repository contracts, and use cases.
- Data layer for API clients, DTO/models, and repository implementations.

The planned structure is documented in `docs/architecture.md` and visualized in `docs/diagrams/fe-architecture.png`.
