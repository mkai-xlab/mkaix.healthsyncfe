# API Integration

## Current State

The frontend does not currently call a backend API.

When API integration is added, place implementation details in the data layer and keep UI code dependent on domain use cases instead of direct HTTP calls.

## Planned Package Ownership

| Package | Responsibility |
| --- | --- |
| `data/datasources` | Low-level HTTP clients and endpoint calls. |
| `data/models` | Request/response DTOs and serialization. |
| `data/repositories` | Convert data models into domain entities and implement domain repository contracts. |
| `domain/interface_repositories` | Abstract repository contracts. |
| `domain/usecases` | Application actions consumed by view models. |
| `presentation/viewmodels` | Calls use cases and exposes UI-ready state. |

## Request Rules

- Read the API base URL from environment configuration, not from widgets.
- Keep endpoint paths centralized in the data layer.
- Convert API responses into typed models before they reach domain code.
- Convert API failures into app-level errors before they reach UI code.
- Keep authentication headers and token refresh behavior out of page widgets.

## Response Rules

- Do not expose raw JSON maps to presentation code.
- Data models should handle serialization and parsing.
- Domain entities should represent business concepts without transport-specific fields unless those fields are required by the UI.
- Repository implementations should hide backend response shape differences from use cases.

## Error Mapping

| Backend/API Condition | Frontend Mapping |
| --- | --- |
| Network unavailable | Network error state with retry option. |
| `400` validation error | Field or form validation message. |
| `401` unauthorized | Session expired or login-required state. |
| `403` forbidden | Permission error state. |
| `404` not found | Empty or not-found state depending on screen. |
| `500` server error | Generic server error with retry option. |

## Documentation Maintenance

When a new API is added, document:

- Endpoint purpose.
- Request parameters.
- Response model.
- Error cases.
- Owning datasource/repository/use case.
- Screens or view models using it.
