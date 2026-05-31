# Security

## Supported Status

This project is currently in active development for a Capstone frontend.

## Secret Handling

- Do not commit API keys, access tokens, refresh tokens, keystores, passwords, or private certificates.
- Do not hardcode production URLs with embedded credentials.
- Use environment configuration such as `--dart-define` for non-secret runtime values.
- Store real secrets in a secure external system, not in Git.

## Client-Side Storage

When authentication is added:

- Prefer secure storage for sensitive tokens.
- Avoid storing secrets in plain text shared preferences or local files.
- Clear session data on logout.
- Document token refresh and expiration behavior in `docs/api-integration.md`.

## Logging

- Do not log access tokens, passwords, or personally identifiable information.
- Keep verbose logs disabled in production builds.

## Reporting Issues

For now, report security issues directly to the project maintainers through the team communication channel used for the Capstone project.

Do not publish security-sensitive details in public issues until the issue is reviewed.
