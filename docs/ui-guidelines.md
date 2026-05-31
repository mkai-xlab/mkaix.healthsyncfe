# UI Guidelines

## Current State

The current UI uses Flutter Material widgets with a seeded `ThemeData` in `lib/main.dart`.

## Design Principles

- Keep screens readable on mobile and desktop sizes.
- Use theme values instead of hardcoded colors where possible.
- Keep spacing consistent across pages.
- Prefer reusable widgets when UI patterns repeat.
- Avoid placing business logic inside widget build methods.

## Responsiveness

Every new screen should be checked on:

- Small mobile viewport.
- Large mobile or tablet viewport.
- Web or desktop viewport if that platform is supported.

## Accessibility

New UI should support:

- Readable contrast.
- Tap targets large enough for mobile use.
- Text scaling where practical.
- Meaningful labels for icons and interactive controls.
- Keyboard navigation for web/desktop flows when relevant.

## Components

When reusable components are introduced, place them under `presentation/widgets` or a feature-specific widget folder.

Document major shared widgets here once they exist:

| Component | Purpose | Location |
| --- | --- | --- |
| None yet. | Shared widgets have not been introduced. | Not applicable. |
