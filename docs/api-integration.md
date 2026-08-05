# API Integration

## Source

- OpenAPI version: `3.1.0`
- API version: `v1`
- Base URL: `http://54.254.113.71:8000/api/v1`
- Frontend endpoint constants: `lib/core/constants/api_constants.dart`
- Last OpenAPI refresh: `2026-08-05`

Keep endpoint paths centralized in `ApiConstants`. Datasources should own HTTP calls, repositories should map models to domain entities, and presentation code should call use cases instead of calling HTTP directly.

## Latest OpenAPI Changes

- OpenAPI is now `3.1.0` / API `v1` and keeps base URL `http://54.254.113.71:8000/api/v1`.
- The `2026-08-05` spec has no added or removed paths/schemas compared with `2026-08-04`; it confirms the current v1 contract.
- Auth is bearer-token based. Login returns `accessToken`, `refreshToken`, `role`, `username`, `fullName`, and a full `permissions` array.
- First-time login is explicitly modeled as `FirstTimeLoginRequired` with body `{ error: "FIRST_TIME_LOGIN_REQUIRED", message: "..." }`.
- `GET /examinations/total`, `/total-verified`, `/total-unverified`, and `/total-severe` require query `userId` and optionally accept `isPersonal`.
- For doctor/current-user views, every endpoint that supports `isPersonal` must send `isPersonal=true`.
- The current-user dashboard counters remain available as `/examinations/my-total*`, which do not require `userId`.
- Examination status filter enum is `AI_PROCESSING`, `AI_FAILED`, `NEED_VERIFY`, `VERIFIED`, `REPORT_GENERATED`.
- Examination responses now include richer clinical/report fields: `studyTime`, `visitTime`, `chiefComplaint`, `clinicalNotes`, `priority`, `finalDiagnosis`, `description`, `patient`, `doctorId`, `images`, `isViewed`, and `maxPredictedGrade`.
- `ExaminationImageDto` now exposes DICOM-level AI status and error: `aiAnalysisStatus`, `aiErrorMessage`, plus nested `aiResults`.
- `AiPredictionResultDto` includes review-aware fields: `confirmedGrade`, `effectiveGrade`, `reviewDecision`, `reviewNote`, `reviewedByDoctorId`, `reviewedAt`, and image URLs.
- New diagnosis review flow is documented: `PUT /ai/results/{aiResultId}/confirm` and `PUT /ai/results/{aiResultId}/kl-grade` return `DiagnosisReviewResponse`.
- New/confirmed image endpoint: `GET /ai/image/{imageId}` for clinical/ROI/annotated images, beside `GET /ai/heatmap/{aiResultId}` and `GET /dicom/instances/{id}/image`.
- Report generation returns `ReportResponse`: `POST /examinations/{id}/generate-report`; preview/download use examination id via `/reports/{examinationId}/preview|download`.
- Doctors now support profile editing and avatar upload through `GET|PUT /doctors/profile` and `PUT /doctors/profile/avatar`.
- Doctor deactivation is available both as `DELETE /doctors/{id}` with optional `reason` query and as `POST /doctors/{id}/deactivate`; activation uses `POST /doctors/{id}/activate`.
- Doctor `fullName` validation is stricter on create/edit/profile update: it must match `^[\p{L}\s]+$`, so names with numbers or punctuation can fail validation.
- Patient create requires `patientCode` and `fullName`; patient responses expose both `patientCode` and compatibility alias `patient_id`.
- Permission management is feature-based: `/permissions/tree`, `/features`, and role assignment through `/permissions/role/{roleName}`. Role assignment replaces the whole permission list and uses numeric permission IDs.
- Delete endpoints are documented for permissions, features, patients, and doctors.
- `GET /audit-logs` returns `PageResponseAuditLogResponse`; `AuditLogResponse` fields are `id`, `username`, `title`, `description`, `ipAddress`, `userAgent`, and `timeStamp`.
- Notification APIs now include `GET /notifications` for all notifications, `GET /notifications/unread`, `PUT /notifications/{id}/read`, and test send `POST /notifications/send`.
- New notification bulk-read endpoint: `PUT /notifications/read-all`, returning `MarkAllNotificationsReadResponse` with `updatedCount`.
- Utility/test endpoints are documented: `GET /mail-test/send`, `POST /files/upload-avatar`, and `POST /s3/test-upload`.

## Frontend Change Checklist

- `ApiConstants` is mostly aligned with the v1 spec. Keep the current base URL and existing constants for auth, DICOM, AI batch, reports, notifications, permissions, and examinations.
- Add a constant for `GET /ai/image/{imageId}` if the UI needs to render ROI/clinical/annotated images by image id. Current constants cover only heatmap and DICOM instance image.
- Add a constant and datasource method for `PUT /doctors/profile/avatar` if profile avatar upload is used. Current profile datasource supports `GET` and `PUT /doctors/profile`, but not the multipart avatar endpoint.
- Add frontend validation for doctor `fullName` before create/edit/profile update: allow letters and spaces only, and avoid punctuation or numeric suffixes that backend now rejects.
- Decide whether admin doctor deactivate should use `DELETE /doctors/{id}?reason=...` or the existing `POST /doctors/{id}/deactivate`. The spec supports both, but `DELETE` is now documented as a soft deactivate with an optional reason.
- Add create/update/delete patient methods in `PatientRemoteDataSource` if patient management screens need them. Current patient datasource only fetches the paged list.
- Update `PatientModel.fromJson` to fall back from `patientCode` to `patient_id`; the new response may include both, but existing parser currently ignores `patient_id`.
- Add patient upload-date filter support for `GET /patients/filter/upload-date` if the patient list has upload-date filtering.
- Doctor patient and examination lists must include `isPersonal=true` on supported endpoints so backend scopes data to the logged-in doctor.
- Review examination image parsing: `ExaminationImageModel` currently ignores `aiAnalysisStatus` and `aiErrorMessage`. Add fields to the entity/model if the UI should show AI progress or per-image AI failures.
- Use `confirmedGrade` or `effectiveGrade` for final clinical display when available. `predictedGrade` alone is no longer enough after doctor review.
- Confirm KL-grade UI should call `PUT /ai/results/{aiResultId}/confirm` for accept and `PUT /ai/results/{aiResultId}/kl-grade` for adjustment with `confirmedKlGrade` and required `reviewNote`.
- Admin dashboard counters using `/examinations/total*` must send `userId` and optional `isPersonal`. Doctor dashboard should keep using `/examinations/my-total*`.
- Permission role management already sends numeric `permissionIds`; keep that behavior. Add delete calls for permissions/features if the admin UI exposes deletion.
- `PermissionRemoteDataSource` currently assumes known roles `ADMIN` and `DOCTOR`. If backend adds more medical/staff roles through `/users/staff` or other role sources, replace the hardcoded role list.
- `CreateDoctorRequest` only requires `fullName`, `email`, and `phone`; optional fields `yearsOfExperience`, `degree`, and `biography` can be added to the create/edit UI without contract changes.
- Error handling should parse standard `ErrorResponse.message` for `400`, `401`, `403`, `415`, and `500`. Keep the special first-time-login branch for `FIRST_TIME_LOGIN_REQUIRED`.
- Add a notification datasource method for `PUT /notifications/read-all` if the notification panel needs a "mark all as read" action. Parse `updatedCount` and refresh unread count/list after success.

## Authentication

| Method | Path | Purpose | Request | Response |
| --- | --- | --- | --- | --- |
| `POST` | `/auth/login` | Sign in | `LoginRequest` with `username`, `password` | `LoginResponse` with `accessToken`, `refreshToken`, `role`, `username`, `fullName`, `permissions` |
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
| `POST` | `/examinations/{id}/generate-report` | Generate PDF report | `ReportResponse` |
| `GET` | `/examinations/patient/{patientId}` | Get examinations by patient | `ExaminationDto[]` or paged response |
| `GET` | `/examinations/patient/{patientId}/filter/study-month` | Filter patient examinations by study month | `PageResponseExaminationDto` |
| `GET` | `/examinations/doctor/{doctorId}` | Get examinations by doctor | `PageResponseExaminationDto` |
| `GET` | `/examinations/status` | Filter by status. Required `status` enum: `AI_PROCESSING`, `AI_FAILED`, `NEED_VERIFY`, `VERIFIED`, `REPORT_GENERATED`; required `pageable` | `PageResponseExaminationDto` |
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
| `POST` | `/examinations/{id}/generate-report` | Generate/export PDF report for an examination | `ReportResponse` |
| `GET` | `/reports/{examinationId}/preview` | Preview generated PDF report for an examination | binary PDF |
| `GET` | `/reports/{examinationId}/download` | Download generated PDF report for an examination | binary PDF |

`ReportResponse` fields: `reportId`, `examinationId`, `fileName`, `fileSize`, `contentType`, `generatedAt`, `previewUrl`, `downloadUrl`.

Export report flow:

1. Call `POST /examinations/{id}/generate-report` with the examination id.
2. Store or use the returned `ReportResponse`.
3. Call `GET /reports/{examinationId}/preview` for in-app preview, or `GET /reports/{examinationId}/download` for file download.

## Notifications And Audit

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/notifications` | Get all notifications | `NotificationDto[]` |
| `GET` | `/notifications/unread` | Get unread notifications | `NotificationDto[]` |
| `PUT` | `/notifications/{id}/read` | Mark notification as read | `string` |
| `PUT` | `/notifications/read-all` | Mark all current-user unread notifications as read | `MarkAllNotificationsReadResponse` |
| `POST` | `/notifications/send` | Send test notification | `string` |
| `GET` | `/mail-test/send` | Send test email. Required query: `to`, `title`, `message` | `string` |
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

