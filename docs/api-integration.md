# API Integration

## Source

- OpenAPI version: `3.1.0`
- API version: `v0`
- Base URL: `http://54.254.113.71:8000/api/v1`
- Frontend endpoint constants: `lib/core/constants/api_constants.dart`
- Last OpenAPI refresh: `2026-07-30`

Keep endpoint paths centralized in `ApiConstants`. Datasources should own HTTP calls, repositories should map models to domain entities, and presentation code should call use cases instead of calling HTTP directly.

## Latest OpenAPI Changes

- `GET /examinations/total`, `/total-verified`, `/total-unverified`, and `/total-severe` now require query `userId`.
- `GET /audit-logs` only documents Spring `pageable`; no `keyword`, `actor`, `action`, `status`, or `sort` filters are documented in the latest spec.
- New/confirmed upload endpoints: `PUT /doctors/profile/avatar`, `POST /files/upload-avatar`, and `POST /s3/test-upload`.
- New/confirmed report file endpoints: `GET /reports/{reportId}/preview` and `GET /reports/{reportId}/download`.
- New/confirmed image endpoint: `GET /ai/image/{imageId}`.
- New/confirmed patient date endpoint: `GET /patients/filter/upload-date`.
- Delete endpoints are documented for permissions, features, patients, and doctors.
- `AuditLogResponse` fields are `id`, `username`, `title`, `description`, `ipAddress`, `userAgent`, `timeStamp`.
- `LoginResponse` includes `fullName`.
- `CreateDoctorRequest` requires `fullName`, `email`, and `phone`.
- `ChangePasswordRequest` requires `username`, `oldPassword`, and `newPassword`.

## Authentication

| Method | Path | Purpose | Request | Response |
| --- | --- | --- | --- | --- |
| `POST` | `/auth/login` | Sign in | `LoginRequest` with `username`, `password` | `LoginResponse` with `accessToken`, `refreshToken`, `role`, `username`, `permissions` |
| `POST` | `/auth/forgot-password` | Request reset token | `ForgotPasswordRequest` | `200 OK` |
| `POST` | `/auth/reset-password` | Reset password | `ResetPasswordRequest` | `200 OK` |
| `POST` | `/auth/change-password` | Change first-time/current password | `ChangePasswordRequest` | `200 OK` |
| `POST` | `/auth/logout` | Logout session | Header `Authorization`, `LogoutRequest` with `refreshToken` | `200 OK` |

Authenticated requests should send `Authorization: Bearer <accessToken>`.

## Users And Doctors

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `POST` | `/users` | Create user account | `UserResponse` |
| `GET` | `/users/staff` | Get staff users | `UserResponse[]` |
| `GET` | `/doctors` | Paginated doctors, optional `keyword`, `specialization`, `status`, `page`, `size`, `sort` | `PageResponseDoctorResponse` |
| `POST` | `/doctors` | Create doctor | `DoctorResponse` |
| `PUT` | `/doctors/{id}` | Edit doctor | `DoctorResponse` |
| `DELETE` | `/doctors/{id}` | Deactivate doctor | `200 OK` |
| `POST` | `/doctors/{id}/activate` | Activate doctor | `200 OK` |
| `POST` | `/doctors/{id}/deactivate` | Deactivate doctor | `200 OK` |
| `GET` | `/doctors/active` | Get active doctors | `DoctorResponse[]` |
| `GET` | `/doctors/profile` | Get current doctor profile | `DoctorResponse` |
| `PUT` | `/doctors/profile` | Edit current doctor profile | `DoctorResponse` |
| `PUT` | `/doctors/profile/avatar` | Upload current doctor avatar as multipart `file` | `DoctorResponse` |

## Patients

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/patients` | Paginated patient list. Query can include patient filter fields plus `page`, `size`, `sort` | `PageResponsePatientResponse` |
| `POST` | `/patients` | Create patient | `PatientResponse` |
| `PUT` | `/patients/{id}` | Edit patient | `PatientResponse` |
| `DELETE` | `/patients/{id}` | Delete patient | `200 OK` |
| `GET` | `/patients/{patientId}/details` | Patient details with recent examinations/images | `PatientDetailsResponse` |
| `GET` | `/patients/filter/upload-date` | Patients filtered by upload date. Required `date`, `pageable` | `PageResponsePatientResponse` |

## Examinations

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/examinations` | Paginated examination list | `PageResponseExaminationDto` |
| `GET` | `/examinations/{id}` | Get examination by id | `ExaminationDto` |
| `PUT` | `/examinations/{id}/view` | Mark examination as viewed | `200 OK` |
| `POST` | `/examinations/{id}/generate-report` | Generate PDF report | `string` |
| `GET` | `/examinations/patient/{patientId}` | Get examinations by patient | `ExaminationDto[]` or paged response |
| `GET` | `/examinations/patient/{patientId}/filter/study-month` | Filter patient examinations by study month | `PageResponseExaminationDto` |
| `GET` | `/examinations/doctor/{doctorId}` | Get examinations by doctor | `PageResponseExaminationDto` |
| `GET` | `/examinations/status` | Filter by status | `PageResponseExaminationDto` |
| `GET` | `/examinations/grade` | Filter by AI grade | `PageResponseExaminationDto` |
| `GET` | `/examinations/filter/upload-date` | Filter by upload date | `PageResponseExaminationDto` |
| `GET` | `/examinations/filter/study-date` | Filter by study date | `PageResponseExaminationDto` |
| `GET` | `/examinations/sort/upload-date` | Sort by upload date | `PageResponseExaminationDto` |
| `GET` | `/examinations/sort/study-date` | Sort by study date | `PageResponseExaminationDto` |
| `GET` | `/examinations/total` | Total examinations for required `userId` | `number` |
| `GET` | `/examinations/total-verified` | Total verified examinations for required `userId` | `number` |
| `GET` | `/examinations/total-unverified` | Total unverified examinations for required `userId` | `number` |
| `GET` | `/examinations/total-severe` | Total severe examinations for required `userId` | `number` |
| `GET` | `/examinations/my-total` | Current doctor's total examinations | `number` |
| `GET` | `/examinations/my-total-verified` | Current doctor's verified examinations | `number` |
| `GET` | `/examinations/my-total-unverified` | Current doctor's unverified examinations | `number` |
| `GET` | `/examinations/my-total-severe` | Current doctor's severe examinations | `number` |
| `GET` | `/examinations/statistics/patients-by-grade` | Patient count by predicted grade | `PatientGradeStatsDto[]` |

## Examination Statistics

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/examinations/total` | Total examinations for required `userId` | number |
| `GET` | `/examinations/total-verified` | Total verified examinations for required `userId` | number |
| `GET` | `/examinations/total-unverified` | Total unverified examinations for required `userId` | number |
| `GET` | `/examinations/total-severe` | Total severe examinations for required `userId` | number |
| `GET` | `/examinations/my-total` | Current doctor's total examinations | number |
| `GET` | `/examinations/my-total-verified` | Current doctor's verified examinations | number |
| `GET` | `/examinations/my-total-unverified` | Current doctor's unverified examinations | number |
| `GET` | `/examinations/my-total-severe` | Current doctor's severe examinations | number |
| `GET` | `/examinations/statistics/patients-by-grade` | Patient count by predicted grade | `PatientGradeStatsDto[]` |

## DICOM And AI

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `POST` | `/dicom/upload` | Upload one DICOM file as multipart `file` | `DicomTagResponse[]` |
| `POST` | `/dicom/upload/batch` | Upload multiple DICOM files as multipart `files` | `BatchDicomUploadResponse` or accepted status |
| `POST` | `/dicom/upload/zip-batch` | Upload ZIP as multipart `file` | `BatchDicomUploadResponse` or accepted status |
| `POST` | `/dicom/verify` | Verify upload session | object |
| `GET` | `/dicom/upload-session/{sessionId}` | Get upload session status/details | object |
| `GET` | `/dicom/instances/{id}/image` | Get rendered DICOM image | binary/image |
| `GET` | `/dicom/instances/{id}/raw` | Get raw DICOM instance | binary |
| `GET` | `/dicom/total-studies` | Total DICOM studies | number |
| `POST` | `/ai/predict-batch` | Run AI prediction for DICOM instances | `ExaminationDto[]` |
| `GET` | `/ai/heatmap/{aiResultId}` | Get heatmap image | binary/image |
| `GET` | `/ai/image/{imageId}` | Get AI image | binary/image |
| `PUT` | `/ai/results/{aiResultId}/kl-grade` | Adjust KL grade | `DiagnosisReviewResponse` |
| `PUT` | `/ai/results/{aiResultId}/confirm` | Confirm AI grade | `DiagnosisReviewResponse` |
| `POST` | `/files/upload-avatar` | Upload avatar as multipart `file` | `Map<String, String>` |
| `POST` | `/s3/test-upload` | Test S3 upload with required `folderName`, `fileName`, multipart `file` | `string` |

## Permissions And Features

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/permissions/tree` | Get permission catalog tree | permission tree |
| `POST` | `/permissions` | Create permission | `PermissionResponse` |
| `PUT` | `/permissions/{id}` | Update permission | `PermissionResponse` |
| `DELETE` | `/permissions/{id}` | Delete permission | `200 OK` |
| `GET` | `/permissions/role/{roleName}` | Get permission ids for role | `int64[]` |
| `PUT` | `/permissions/role/{roleName}` | Replace role permissions | `200 OK` |
| `POST` | `/features` | Create feature | `FeatureResponse` |
| `PUT` | `/features/{id}` | Update feature | `FeatureResponse` |
| `DELETE` | `/features/{id}` | Delete feature | `200 OK` |

## Reports

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/reports/{reportId}/preview` | Preview generated report | binary |
| `GET` | `/reports/{reportId}/download` | Download generated report | binary |

## Notifications And Audit

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/notifications` | Get all notifications | `NotificationDto[]` |
| `GET` | `/notifications/unread` | Get unread notifications | `NotificationDto[]` |
| `PUT` | `/notifications/{id}/read` | Mark notification as read | `string` |
| `POST` | `/notifications/send` | Send test notification | `string` |
| `GET` | `/audit-logs` | Get audit logs. Latest spec documents only Spring `pageable` query | `PageResponseAuditLogResponse` |

## Request Rules

- Use `Content-Type: application/json; charset=UTF-8` for JSON request bodies.
- Use multipart form data for DICOM uploads.
- Keep pagination query names aligned with Spring `Pageable`: `page`, `size`, `sort`.
- Convert IDs to integers when the schema expects `int64`.
- Keep response parsing tolerant of both paged objects and arrays where existing screens already support both.

## Error Mapping

| Backend/API Condition | Frontend Mapping |
| --- | --- |
| Network unavailable or timeout | Network error state with retry option |
| `400` validation error | Field or form validation message |
| `401` unauthorized | Session expired or login-required state |
| `403` forbidden | Permission error state |
| `404` not found | Empty or not-found state depending on screen |
| `500` server error | Generic server error with retry option |

