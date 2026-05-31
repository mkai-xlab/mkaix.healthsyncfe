# Routing

## Current State

The app currently uses `MaterialApp(home: MyHomePage(...))` and has no named routes.

## Planned Routing Package

Route definitions should live under `lib/core/routing` when navigation grows beyond a single screen.

## Route Rules

- Use named routes or a router package once there are multiple screens.
- Keep route names centralized.
- Avoid constructing deep widget trees directly from unrelated pages.
- Use route guards for authenticated or role-protected screens.
- Keep navigation decisions in view models or coordinators when business rules are involved.

## Suggested Route Table Format

When routes are added, maintain a table like this:

| Route | Screen | Access | Purpose |
| --- | --- | --- | --- |
| `/` | Home screen | Public | Initial app entry. |

## Deep Links

Deep links are not currently configured.

If added, document:

- Supported URL patterns.
- Required route parameters.
- Fallback behavior for invalid links.
- Auth behavior for protected links.
