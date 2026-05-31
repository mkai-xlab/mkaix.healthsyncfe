# Project Overview

## Purpose

This repository contains the Flutter frontend for the Capstone project.

The current implementation is still a starter counter app, but the repository is prepared for a layered frontend structure that separates UI, application logic, domain contracts, and data access.

## Current Scope

The app currently includes:

- Flutter application bootstrap in `lib/main.dart`.
- A simple stateful counter screen.
- A widget smoke test in `test/widget_test.dart`.
- Package folders under `lib` reserved for future features.

## Future Scope

As product features are added, the frontend should own:

- User-facing screens and navigation.
- UI state and validation.
- Backend API integration.
- Domain use case orchestration.
- Error, loading, and empty-state presentation.
- Platform-aware build and release behavior.

## Documentation Map

| Document | Purpose |
| --- | --- |
| `README.md` | Quick project introduction and setup. |
| `docs/architecture.md` | Frontend architecture and package dependency direction. |
| `docs/package-diagram.md` | UML package diagram and package relationship list. |
| `docs/development.md` | Local workflow and daily development commands. |
| `docs/environment.md` | Runtime configuration and environment rules. |
| `docs/api-integration.md` | Backend communication conventions. |
| `docs/state-management.md` | UI state ownership and view model rules. |
| `docs/routing.md` | Navigation and route organization. |
| `docs/testing-strategy.md` | Test types, expectations, and naming. |
| `docs/ui-guidelines.md` | UI consistency, responsiveness, and accessibility. |
| `docs/error-handling.md` | Error, loading, empty, and validation state behavior. |
| `docs/build-and-release.md` | Build, versioning, and release checklist. |
| `CONTRIBUTING.md` | Contribution workflow and PR checklist. |
| `SECURITY.md` | Secret handling and security reporting. |
| `CHANGELOG.md` | User-visible changes by version. |

## Maintenance Rule

Whenever a new feature is added, update the docs that changed with it. At minimum, check `architecture.md`, `package-diagram.md`, `api-integration.md`, `state-management.md`, `routing.md`, and `testing-strategy.md`.
