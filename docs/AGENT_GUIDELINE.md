# AGENT_GUIDELINE.md
> Tài liệu ghi lại các quy tắc, bài học và quyết định kiến trúc được học trong quá trình phát triển dự án **MKAix HealthSync FE**.  
> Cập nhật liên tục. Agent phải đọc file này trước khi thực hiện thay đổi lớn.
> Từ 24/06/2026: mọi điều agent học được từ tài liệu, API doc, yêu cầu hoặc chỉ dẫn mới của user phải được ghi lại vào file này khi có giá trị tái sử dụng cho các lần làm việc sau.

---

## 0. Quy ước làm việc với Agent

- Trước khi thực hiện thay đổi lớn, agent phải đọc `docs/AGENT_GUIDELINE.md`.
- Khi user dạy thêm quy tắc, quyết định nghiệp vụ, API mới, pattern UI/code, hoặc bài học debug có thể tái sử dụng, agent phải cập nhật lại file này.
- Nếu thông tin mới mâu thuẫn với nội dung cũ, không xóa vội: ghi rõ nguồn/tình trạng và đánh dấu điểm cần kiểm chứng.
- Ưu tiên cập nhật guideline bằng tiếng Việt, ngắn gọn, có ví dụ endpoint/schema/pattern khi cần.

## 1. Kiến trúc tổng thể

### 1.1 Clean Architecture
Dự án theo **Clean Architecture** 3 tầng:
```
data/          ← models, datasources, repositories impl
domain/        ← entities, interface repositories, usecases
presentation/  ← viewmodels (ChangeNotifier), pages
```

### 1.2 Navigation
- Dùng **GoRouter** cho navigation cấp route (login, doctor, admin).
- Dùng **`Navigator.push`** cho navigation nội bộ trong cùng role (ví dụ: danh sách BN → chi tiết BN).
- Không dùng `context.go()` cho trang con trong cùng Scaffold.

### 1.3 First-time login flow (đã hoàn thiện)
```
Login → 403 + first_time_login
  → FirstTimeLoginException(username, oldPassword)
  → ViewModel: isFirstTimeLogin=true, lưu pendingUsername/pendingOldPassword
  → GoRouter redirect → /change-password
  → User nhập mật khẩu mới → changePassword()
  → Trong changePassword(): gọi login(username, newPassword) luôn
  → currentUser != null → GoRouter tự redirect → /admin hoặc /doctor
  → KHÔNG cần logout rồi mới login lại
```

**Nút bấm trên ChangePasswordPage:** "Xác nhận & Đăng nhập" (không phải "Xác nhận đổi mật khẩu")  
**Màn hình thành công:** Hiện spinner "Đang đăng nhập vào hệ thống..." thay vì nút "Đăng nhập ngay" — GoRouter tự redirect khi `currentUser` được set.

### 1.4 State Management
- **Provider + ChangeNotifier** cho toàn bộ state.
- ViewModel được đăng ký global qua `MultiProvider` trong `main.dart`.
- Ngoại lệ: `PermissionViewModel` được đăng ký **local** (cục bộ) trong `_buildMainContent` của admin để tránh lỗi Provider không tìm thấy trong GoRouter context.

### 2.1 Provider không tìm thấy (ProviderNotFoundError)
**Nguyên nhân phổ biến:** GoRouter render route trong một `Navigator` overlay — đôi khi context chain bị đứt với hot-reload, hoặc widget được build trước khi provider tree mount xong.

**Giải pháp ưu tiên:** Wrap trực tiếp bằng `ChangeNotifierProvider` cục bộ tại nơi dùng:
```dart
// Trong _buildMainContent
if (_selectedNavIndex == 2) {
  return ChangeNotifierProvider(
    create: (_) => PermissionViewModel(PermissionRemoteDataSourceImpl(http.Client())),
    child: const PermissionPage(),
  );
}
```

### 2.2 Hot-reload vs Hot-restart
Khi thêm Provider mới vào `main.dart`, luôn **hot-restart** (không phải hot-reload) để Provider được mount vào widget tree.

---

## 3. Xử lý state trong initState

### 3.1 Lưu data từ ViewModel trước khi clear state
Khi `clearXxxState()` gọi `notifyListeners()` → GoRouter rebuild → builder chạy lại → data có thể bị mất.

**Pattern đúng** — lưu vào local field **đồng bộ** trong `initState`, TRƯỚC khi postFrameCallback:
```dart
@override
void initState() {
  super.initState();
  // ✅ Lưu đồng bộ NGAY LẬP TỨC — trước mọi rebuild
  _username = context.read<AuthViewModel>().pendingUsername ?? '';
  _oldPassword = context.read<AuthViewModel>().pendingOldPassword ?? '';

  // ❌ Không đọc từ widget.xxx vì có thể là '' sau rebuild
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) context.read<AuthViewModel>().clearChangePasswordState();
  });
}
```

**Áp dụng cho:**
- `ChangePasswordPage` — lưu `_username`, `_oldPassword` từ `pendingUsername/pendingOldPassword`
- `ResetPasswordPage` — lưu `_email` từ `widget.email`

---

## 4. API & Datasource

### 4.1 Endpoints đã dùng trước đó (base cũ: `https://api.vietnguyendang.xyz/api/v1`)
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/auth/login` | POST | `{username, password}` |
| `/auth/forgot-password` | POST | `{email}` |
| `/auth/reset-password` | POST | `{email, token, newPassword}` — **cần email** |
| `/auth/change-password` | POST | `{username, oldPassword, newPassword}` |
| `/users` | GET | Danh sách tất cả user (thay `/doctors` cho list) |
| `/users` | POST | `{fullName, email, phone, roleId}` — tạo user mới |
| `/doctors` | GET | `?keyword=&status=&pageable=` — search dùng `keyword` không phải `name` |
| `/doctors/{id}/activate` | POST | Kích hoạt |
| `/doctors/{id}/deactivate` | POST | Khóa |
| `/patients` | GET | `?fullName=&patientCode=&gender=&page=&size=` + Bearer token |
| `/patients` | POST | Tạo bệnh nhân |

> Lưu ý 24/06/2026: API doc OpenAPI mới user cung cấp dùng base URL `http://171.244.143.241:8000/api/v1`. Một số endpoint/query có thay đổi so với danh sách cũ, đặc biệt doc mới **không có `GET /users`** dù guideline cũ đang ghi dùng endpoint này cho danh sách user. Cần kiểm chứng với backend trước khi sửa phần danh sách user.

### 4.1.1 OpenAPI doc 24/06/2026 (base mới: `http://171.244.143.241:8000/api/v1`)

**Auth**
| Endpoint | Method | Request/Response chính |
|---|---|---|
| `/auth/login` | POST | `{username, password}` → `LoginResponse {accessToken, refreshToken, role, username, permissions[]}` |
| `/auth/forgot-password` | POST | `{email}` → string |
| `/auth/reset-password` | POST | `{email, token, newPassword}` → string |
| `/auth/change-password` | POST | `{username, oldPassword, newPassword}` → string |

**Users / Doctors**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/users` | POST | Tạo user `{fullName, email, phone, roleId}` → `UserResponse` |
| `/doctors` | GET | Query: `keyword`, `specialization`, `status`, `pageable` → `PageResponseDoctorResponse` |
| `/doctors` | POST | Tạo doctor bằng `CreateDoctorRequest`; từ 26/06/2026, màn admin tạo tài khoản bác sĩ phải dùng endpoint này thay vì `POST /users` vì backend đang xử lý tạo bác sĩ ở đây |
| `/doctors/active` | GET | Danh sách doctor active |
| `/doctors/{id}/activate` | POST | Kích hoạt doctor |
| `/doctors/{id}/deactivate` | POST | Khóa doctor |
| `/doctors/{id}` | DELETE | OperationId cũng là deactivateDoctor |

**Patients**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/patients` | GET | Query object: `filter` (`PatientFilterRequest`) + `pageable` |
| `/patients` | POST | Tạo bệnh nhân bằng `CreatePatientRequest`; required: `patientCode`, `fullName` |
| `/patients/{patientId}/details` | GET | Tạm dùng để lấy `PatientDetailsResponse {patient, recentExaminations[]}` cho dữ liệu ca khám; `patientId` trong path hiện ưu tiên mã bệnh nhân `patientCode`/`patient_id` (vd `2600056713`), không phải DB `id`; vì chưa có endpoint examination tổng, trang danh sách ca khám tổng hợp bằng cách lấy `/patients` rồi gọi detail từng bệnh nhân |
| `/patients/{id}` | PUT | Cập nhật bệnh nhân bằng `EditPatientRequest` |
| `/patients/{id}` | DELETE | Xóa bệnh nhân |

**Permissions / Features**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/permissions/tree` | GET | Trả `FeatureResponse[]`, mỗi feature có `permissions[]` |
| `/permissions` | POST | Tạo permission; schema mới ưu tiên `code`, `featureId`, `priority`, `presentation`, `requiresPermissionId` |
| `/permissions/{id}` | PUT | Cập nhật permission với payload tương tự, dùng `id` trong path |
| `/permissions/role/{roleName}` | GET | Trả danh sách permission id (`int64[]`) |
| `/permissions/role/{roleName}` | PUT | Cập nhật quyền role bằng `{permissionIds: [...]}` |
| `/features` | POST | Tạo feature `{name, description}` |
| `/features/{id}` | PUT | Cập nhật feature `{name, description}` |
| `/roles` | GET | Backend hiện chưa có/chưa ổn định endpoint này. Tạm thời popup tạo user dùng role cố định: `1 = Admin`, `2 = Doctor` theo yêu cầu 25/06/2026. |

**Permission admin phase 1**
- Màn admin quản lý permission/feature nên bám theo schema mới của backend: tab riêng cho `Features`, `Permissions`, `Roles`.
- UI CRUD ưu tiên tạo/sửa trước; nếu docs chưa có DELETE thì không nên tự dựng nút xóa.
- `FeatureResponse.permissions[]` là nguồn dữ liệu để hiển thị permission con theo feature; danh sách phẳng permission nên sort theo `priority` rồi theo tên/code để dễ đọc.
- Khi render permission theo cây cha-con trong admin, luôn ưu tiên hiển thị permission cha trước, rồi đến các permission con ngay bên dưới cha trong cùng nhóm resource/feature để dễ đọc và dễ bật/tắt.
- `presentation` là khóa liên kết sang màn frontend, còn `priority` là thứ tự hiển thị trên sidebar hoặc trong nhóm permission.
- Doctor shell hiện đã tách `patient_list_page` thành page riêng: `PatientListPage` dùng trong shell, còn `PatientDetailPage` vẫn mở theo callback từ list để giữ sidebar/top bar.
- Sidebar doctor chỉ hiển thị permission cha (`isParent == true`); không fallback sang permission con nếu backend chưa trả permission cha.
- Khi login doctor chỉ trả permission dạng code thô như `READ_PATIENT_LIST`, shell phải tự map code sang route key và nhãn hiển thị thân thiện; không render trực tiếp code lên sidebar và không chỉ dựa vào `presentation` có thể bị thiếu trong response login.
- Sau khi RBAC ổn định, bỏ hẳn fallback key cũ trong doctor shell và các điểm vào page; chỉ dùng `presentation` làm route key chính thức.

**Notifications / Upload**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/notifications/unread` | GET | Trả `NotificationDto[]` |
| `/notifications/{id}/read` | PUT | Mark as read |
| `/notifications/send` | POST | Test notification `{userId, title, message, type}` |
| `/dicom/upload` | POST | Multipart `file` → `DicomTagResponse[]` |
| `/dicom/upload/batch` | POST | Multipart `files` (array binary) → `BatchDicomUploadResponse {errors[], successfulPatients[]}` |
| `/s3/test-upload` | POST | Multipart `file`, query `folderName`, `fileName` → string |

**Schema lưu ý**
- Password mới trong login/reset/change-password: `minLength: 8`, `maxLength: 32`.
- `ResetPasswordRequest` bắt buộc đủ `email`, `token`, `newPassword`; `token` đúng 6 ký tự.
- `CreateUserRequest` bắt buộc `fullName`, `email`, `roleId`; `phone` chỉ gồm chữ số nếu có.
- `CreateDoctorRequest` theo OpenAPI 24/06 từng bắt buộc `doctorCode`, `email`, `fullName`, `hospitalName`, `licenseNumber`, `phone`, `specialization`; nhưng OpenAPI 08/07 đã thay schema mới, xem mục 4.1.2 trước khi sửa form tạo bác sĩ.
- Gender dùng enum `MALE`, `FEMALE`, `OTHER`.
- Doctor status dùng enum `ACTIVE`, `INACTIVE`.
- Doctor position dùng enum `DEPARTMENT_HEAD`, `NORMAL`.
- `BatchDicomUploadResponse` trả `errors[]` gồm `{filename, errorReason}` và `successfulPatients[]` gồm `{patient, recentExaminations[]}`; UI upload batch hiển thị số bệnh nhân thành công và số file lỗi, không dựa vào `DicomTagResponse[]`.

**MockAPI:** `https://6a21b474b1d0aaf32b4fe12a.mockapi.io`
- `/permission` — danh sách quyền
- `/role` — danh sách vai trò, PUT `{permissions: [...]}` để cập nhật

### 4.1.2 OpenAPI doc 08/07/2026 (base mới: `http://54.254.113.71:8000/api/v1`)

> Nguồn: file OpenAPI user gửi ngày 08/07/2026 và Swagger UI `http://54.254.113.71:8000/api/v1/swagger-ui/index.html#/`. Link Swagger UI chỉ dùng để xem docs; app gọi API bằng base `http://54.254.113.71:8000/api/v1`. Nếu mâu thuẫn với ghi chú cũ, giữ cả hai nguồn và ưu tiên kiểm chứng backend trước khi sửa luồng đang chạy.

- Base URL đổi từ `http://171.244.143.241:8000/api/v1` sang `http://54.254.113.71:8000/api/v1`.
- Có nhóm endpoint ca khám chính thức: `GET /examinations`, `GET /examinations/{id}`, `GET /examinations/patient/{patientId}`, `GET /examinations/doctor/{doctorId}`. Các endpoint list trả `PageResponseExaminationDto`, dùng `pageable`; `patientId`/`doctorId` trong path là `int64`. Với Doctor role, danh sách ca khám tổng hợp chỉ được hiển thị ca khám của bác sĩ hiện tại nên dùng `GET /examinations/doctor/{doctorId}`, không tự gom toàn bộ bệnh nhân nữa.
- `GET /patients/{patientId}/details` vẫn còn và `patientId` là string, trả `PatientDetailsResponse {patient, recentExaminations[]}`; có thể tiếp tục dùng cho màn chi tiết bệnh nhân khi cần gom patient + exam + images.
- `ExaminationDto` mở rộng nhiều field: `studyTime`, `chiefComplaint`, `clinicalNotes`, `priority`, `finalDiagnosis`, `description`, `patient`, `doctor`, `images[]`.
- DICOM có thêm `POST /dicom/upload/zip-batch` để upload một file zip batch và `GET /dicom/instances/{id}/image` trả binary image.
- Upload DICOM mới nhận 2 chế độ tách biệt: nhiều file `.dcm` gọi `POST /dicom/upload/batch` với multipart field `files`; file `.zip` gọi `POST /dicom/upload/zip-batch` với multipart field `file`. Từ cập nhật 15/07/2026, FE cho chọn nhiều file `.zip` trong một lượt nhưng gửi tuần tự từng ZIP qua `/dicom/upload/zip-batch`, gom các `DICOM_BATCH_RESULT` lại để xác nhận; không upload lẫn `.zip` và `.dcm` trong cùng một lượt.
- Luồng upload cần tương thích cả backend trả kết quả ngay qua HTTP và backend trả ACK/`202 Accepted`: nếu chưa có `{errors[], successfulPatients[]}` trong HTTP response thì frontend chờ WebSocket STOMP tại `/api/v1/ws`, subscribe `/user/queue/notifications`, nhận progress `SYSTEM` và kết quả cuối `DICOM_BATCH_RESULT`. Với `DICOM_BATCH_RESULT`, field `message` là JSON string lồng bên trong nên phải decode thêm một lần.
- Thực tế runtime 15/07/2026 gần như luôn trả HTTP ACK dạng `{message, status: PROCESSING}` sau upload; FE phải coi WebSocket là bắt buộc cho luồng lấy danh sách bệnh nhân. Cần kết nối WebSocket thành công trước khi gửi file để tránh upload xong nhưng không nhận được `DICOM_BATCH_RESULT`.
- Nếu STOMP chỉ nhận progress `SYSTEM` rồi không nhận frame cuối, FE vẫn phải poll `GET /notifications/unread` theo mốc `notification.id` trước lúc upload để bắt `DICOM_BATCH_RESULT` đã được lưu nhưng không push realtime.
- Poll fallback chỉ được dùng khi lấy baseline `/notifications/unread` thành công; nếu baseline lỗi thì chờ WebSocket để tránh bắt nhầm `DICOM_BATCH_RESULT` cũ còn unread. FE cũng phải parse batch result từ cả `message` JSON string và `data` object, đồng thời coi `SYSTEM` có title `DICOM Upload Complete` + `Session:` là lỗi backend hoàn tất nhưng không trả danh sách bệnh nhân.
- Runtime WebSocket 15/07/2026 có thể trả list bệnh nhân bằng notification `type: DICOM_BATCH_RESULT`, title `DICOM Upload Complete (Pending Verify)`, còn toàn bộ `BatchDicomUploadResponse` nằm trong field `message` dạng JSON string. Parser FE phải coi notification có title bắt đầu bằng `DICOM Upload Complete` và `message` decode ra `{uploadSessionId, errors, successfulPatients}` là batch result hợp lệ, kể cả khi cần poll lại từ `/notifications/unread`.
- Không đặt timeout cho giai đoạn upload/đợi kết quả cuối WebSocket trong DICOM batch vì thực tế có thể upload hàng trăm file DCM/ZIP; chỉ nên báo lỗi khi API/WebSocket trả lỗi hoặc kết nối WebSocket ban đầu không thiết lập được.
- Sau upload, backend có thể trả `successfulPatients[].recentExaminations[]` với `status: NEED_VERIFY` cho ca cần xác nhận lần đầu hoặc `NEED_REVERIFY` cho ca cần xác nhận lại. Khi bác sĩ xác nhận, FE gom toàn bộ `successfulPatients[].recentExaminations[].images[].dicomInstanceId` thành list int và gọi `POST /ai/predict-batch` với payload `{dicomInstanceIds: [...]}`. Response là `ExaminationDto[]` có `status: AI_COMPLETED` và `images[].aiResult`.
- UI xác nhận sau upload phải là checklist bệnh nhân rõ ràng; mặc định chọn tất cả bệnh nhân backend xử lý thành công, bác sĩ có thể bỏ chọn. FE chỉ gửi `dicomInstanceId` thuộc các bệnh nhân đang được chọn/xác nhận.
- `CreateDoctorRequest` mới đơn giản hơn: required `fullName`, `email`, `phone`. Không còn các field cũ như `doctorCode`, `hospitalName`, `licenseNumber`, `specialization` trong schema mới.
- Permission schema đổi trọng tâm sang `code`, `priority`, `presentation`; `CreatePermissionRequest` required `code`, `featureId`, không required `name`.

### 4.1.3 OpenAPI doc 15/07/2026 (base giữ nguyên: `http://54.254.113.71:8000/api/v1`)

> Nguồn: file OpenAPI user gửi ngày 15/07/2026. Nếu mâu thuẫn với ghi chú 08/07 hoặc websocket guide, ưu tiên kiểm chứng backend/runtime trước khi sửa luồng đang chạy vì OpenAPI vẫn chưa mô tả đầy đủ WebSocket STOMP.

**Điểm mới/khác đáng chú ý**
- Thêm `POST /dicom/verify` với payload `DicomVerifyRequest {uploadSessionId, acceptedPatientCodes[]}` và response object. Đây là bước xác nhận upload/session riêng, tách khỏi AI prediction.
- DICOM upload batch/zip trong OpenAPI 15/07 đang khai báo response là `object additionalProperties<string>` cho cả `POST /dicom/upload/batch` và `POST /dicom/upload/zip-batch`, không còn mô tả rõ `errors[]`/`successfulPatients[]` trong schema OpenAPI. Tuy nhiên luồng FE hiện vẫn phải hỗ trợ runtime cũ: HTTP trả kết quả trực tiếp hoặc ACK/pending rồi chờ WebSocket `DICOM_BATCH_RESULT`.
- Thêm endpoint ảnh DICOM raw: `GET /dicom/instances/{id}/raw` trả binary, bên cạnh `GET /dicom/instances/{id}/image`.
- Thêm `GET /ai/heatmap/{aiResultId}` trả binary heatmap; AI result trong `ExaminationImageDto` là `aiResults[]`, không phải field đơn `aiResult`.
- Thêm `PUT /examinations/{id}/view` để mark ca khám đã xem.
- `ExaminationDto` trong doc 15/07 có `doctorId` thay vì object `doctor`; có thêm `isViewed` và `maxPredictedGrade`. FE parse model nên chịu được thiếu object doctor và dùng `doctorId` khi có.
- `ExaminationImageDto` có `dicomInstanceId`, `imageUrl`, `aiResults[]`, `status`, `visitTime`, `bodyPart`; khi gọi AI batch vẫn gửi list `dicomInstanceIds`.
- Thêm nhóm hồ sơ bác sĩ: `GET /doctors/profile`, `PUT /doctors/profile`; thêm `PUT /doctors/{id}` để sửa bác sĩ.
- `CreateDoctorRequest` vẫn required `fullName`, `email`, `phone`, nhưng schema có thêm optional `avatarUrl`, `yearsOfExperience`, `degree`, `biography`.
- `EditDoctorRequest` gồm `fullName`, `email`, `phone`, `avatarUrl`, `yearsOfExperience`, `degree`, `biography`; không thấy lại các field cũ như `doctorCode`, `hospitalName`, `licenseNumber`, `specialization`.
- `DoctorResponse.role` là string trong doc 15/07; `UserResponse.role` vẫn là object `Role`.
- Vẫn không có `GET /users`; chỉ còn `POST /users`, nên danh sách tài khoản admin/doctor không nên phụ thuộc vào `GET /users` nếu chưa kiểm chứng backend live.

### 4.1.4 Exam API runtime 21-22/07/2026

Nguon: bang API user cung cap ngay 22/07/2026.

- Cac API dem tong `/examinations/total`, `/examinations/total-severe`, `/examinations/total-verified`, `/examinations/total-unverified` can FE truyen `userId` cua user hien hanh; backend dung `userId` de lay role va dem theo DOCTOR/DEPARTMENT_HEAD.
- Cac API list/filter/sort exam moi KHONG truyen `userId`; FE chi gui access token header. Backend tu resolve user/role tu token.
- Loc status dung `GET /examinations/status?status={STATUS_NAME}&page={page}&size={size}`.
- Loc max predicted grade dung `GET /examinations/grade?grade={GRADE_NUMBER}&page={page}&size={size}`.
- Thong ke benh nhan theo grade dung `GET /examinations/statistics/patients-by-grade`, khong query param.
- Sort ngay chup dung `GET /examinations/sort/study-date?direction=asc|desc&page={page}&size={size}`.
- Sort ngay upload dung `GET /examinations/sort/upload-date?direction=asc|desc&page={page}&size={size}`.
- Filter ngay chup dung `GET /examinations/filter/study-date?date=YYYY-MM-DD&page={page}&size={size}`.
- Filter ngay upload dung `GET /examinations/filter/upload-date?date=YYYY-MM-DD&page={page}&size={size}`.
- Loc exam cua mot benh nhan theo thang chup dung `/examinations/patient/{patientId}/filter/study-month?year=YYYY&month=M&page={page}&size={size}`.
- `POST /dicom/verify` runtime moi tra `List<PatientGradeStatsDto>` gom `{grade, patientCount}` cho rieng batch vua verify/AI thanh cong, khong con mac dinh tra `List<ExaminationDto>`.
- Notification dropdown tren doctor topbar tam dung `GET /notifications/unread` de lay tat ca thong bao chua doc cua user hien tai; API nay chua paging public, nen FE paging gia bang `visibleCount` ban dau 10 va moi lan "Xem them" tang 1 item. `PUT /notifications/{id}/read` duoc dung khi user bam vao notification.

### 4.2 Patient list không dùng mock fallback
Danh sách bệnh nhân trong Doctor role phải lấy dữ liệu thật từ backend `/patients`. Không fallback sang `MockPatients.samples`; nếu API trả rỗng thì hiển thị rỗng, nếu API lỗi thì báo lỗi để tránh nhầm dữ liệu tạm là dữ liệu thật.

### 4.3 First-time login (403 + first_time_login)
- Backend trả `403` với body `{ "error": "first_time_login..." }` khi lần đầu đăng nhập.
- Datasource throw `FirstTimeLoginException(username, oldPassword)`.
- ViewModel catch và set `isFirstTimeLogin = true`, lưu `pendingUsername/pendingOldPassword`.
- GoRouter redirect bắt buộc sang `/change-password`.

---

## 5. UI Patterns

### 5.0 Màu giao diện chuẩn
Palette chuẩn của dự án:

- Primary: `#0B4F43`
- Primary Dark: `#00614F`
- Primary Light: `#0E7C66`
- Primary XLight: `#97F4D9`
- Success: `#336E61`
- Success Light: `#B1EFDE`
- Warning: `#735C00`
- Warning Light: `#CCA72F`
- Error: `#BA1A1A`
- Error Light: `#FFDAD6`
- Info: `#6B7280`
- Info Light: `#E3E2DF`
- Text Primary: `#1B1C1A`
- Text Secondary: `#6E7A75`
- Text Disabled: `#BDC9C4`
- Border: `#E9E8E4`
- Border Strong: `#BDC9C4`
- Surface 1: `#FAF9F5`
- Surface 2: `#EFEEEA`
- Surface 3: `#1B1C1A`
- White: `#FFFFFF`

Quy ước dùng:

- `Primary` cho nút hành động chính, sidebar active, focus ring.
- `Primary Dark` cho hover/emphasis.
- `Primary Light` cho nút phụ, underline tab, progress fill.
- `Primary XLight` cho highlight chọn, badge/tag fill, selected row.
- `Surface 1` làm nền trang sáng; `Surface 2` cho card; `Surface 3` cho sidebar/top bar tối.
- `Text Primary` và `Text Secondary` là màu chữ mặc định thay cho các xám cũ rải rác.
- `Border` và `Border Strong` là màu viền chuẩn cho input/table/card.
- Khi thêm màn mới hoặc sửa shell chung, ưu tiên lấy màu từ `lib/core/constants/app_colors.dart`; tránh hardcode mã màu lặp lại nếu cùng ý nghĩa thiết kế.

### 5.1 Layout Admin Homepage (SPA pattern)
Admin homepage không chuyển trang — dùng `_selectedNavIndex` để switch nội dung:
```dart
Widget _buildMainContent(BuildContext context) {
  if (_selectedNavIndex == 1) return _buildUserManagementPage(context);
  if (_selectedNavIndex == 2) return ChangeNotifierProvider(...); // permission
  return _buildDashboard(context); // mặc định index 0
}
```

Các trang/tab trong Admin phải dùng chung layout cha của `AdminHomepage`: sidebar/drawer và top bar được dựng ở `AdminHomepage`, page con chỉ render phần nội dung. Nếu page con vẫn cần chạy độc lập thì thêm option như `showTopBar`, nhưng khi nhúng trong admin phải tắt top bar riêng để tránh lệch navbar.

Doctor homepage cũng dùng pattern shell tương tự: sidebar/drawer và top bar cố định ở `DoctorHomepage`, phần `_buildMainContent` chỉ đổi nội dung tab. Sidebar doctor lấy item theo permission cha trong `currentUser.permissionItems` từ login response (`parent_id`/`parentId`/`requiresPermissionId` rỗng hoặc null). Các item sidebar doctor hiện chỉ là điểm vào theo quyền; khi chưa link tính năng cụ thể thì nội dung page hiển thị trạng thái "đang cập nhật", không tự route sang danh sách bệnh nhân hay dashboard cứng.

### 5.2 Tab động (không dùng TabController với length thay đổi)
`TabController` không handle tốt việc `length` thay đổi sau khi data load. Thay bằng **custom tab row + `setState` index**:
```dart
int _selectedRoleIndex = 0;

// Tab row
GestureDetector(
  onTap: () => setState(() => _selectedRoleIndex = i),
  child: Container(/* border bottom indicator */),
)
```

### 5.3 Tránh overflow trong Row
Row dài với nhiều widget cứng → dùng `Wrap` thay `Row` cho phần thông tin:
```dart
// ❌ Dễ overflow
Row(children: [field1, SizedBox(24), field2, SizedBox(24), field3, Spacer(), badge])

// ✅ Tự wrap khi không đủ chỗ
Wrap(spacing: 28, runSpacing: 8, children: [field1, field2, field3])
```

### 5.4 Debounce search
Tìm kiếm debounce 500ms — pattern chuẩn dùng trong cả admin và doctor:
```dart
void searchByNameDebounced(String name, String token) {
  _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    // reset và fetch
  });
}
```

### 5.5 Top bar đồng nhất (Doctor)
Tất cả trang của Doctor role dùng cùng một style top bar:
- Height: 38px cho search field
- Padding: `horizontal: 16, vertical: 10`
- Không hiển thị logo trong top bar vì sidebar/drawer đã có logo
- Top bar của bác sĩ luôn có thanh tìm kiếm bệnh nhân, không chỉ riêng tab danh sách bệnh nhân
- Avatar (radius 15) + tên bác sĩ + chức danh "Chẩn đoán hình ảnh"
- Icon notification size 20
- Permission doctor `READ_PATIENT_LIST` là màn xem danh sách bệnh nhân.
- Khi bấm một bệnh nhân trong danh sách, mở `PatientDetailPage(embedded: true)` ngay trong doctor shell để giữ sidebar/topbar. Màn chi tiết bệnh nhân không dùng mock: phần trên hiển thị thông tin bệnh nhân, phần dưới là các thẻ lần khám thật lấy từ `/patients/{patientId}/details`, sắp xếp giảm dần theo thời gian khám. Thẻ lần khám dùng ngày giờ khám làm tiêu đề chính, không lặp thêm mục meta "Thời gian khám". Bấm thẻ lần khám mở popup chi tiết có ảnh X-quang, thông tin ca khám, và panel cuộn bên phải chỉ hiển thị các ca khám khác. Khi chọn một ca khác làm ca khám phụ, popup chuyển sang so sánh hai ca song song: ca chính bên trái, ca phụ bên phải; nút X ở ca phụ tắt chế độ so sánh và quay lại panel chọn ca phụ. Popup so sánh không hiển thị chữ "ca khám chính/phụ", không hiển thị ID ca khám hoặc encounter code; tiêu đề ca khám trong danh sách dùng ngày giờ khám làm thông tin chính. Khi so sánh hai ca, hai cột chi tiết phải nằm trong cùng vùng cuộn để bác sĩ kéo scroll song song cả hai bên. Ca đang xem bên trái được nhấn bằng badge "Đang xem" và nền mint nhạt, không dùng viền nổi bật quanh nội dung.
- Permission doctor `CREATE_PATIENT_EXAM` là entry "Danh sách ca khám": mở trực tiếp `ExaminationListPage` tổng hợp tất cả ca khám, không qua bước chọn bệnh nhân. Nguồn dữ liệu tạm thời vẫn phải gom từ `/patients/{patientId}/details`.
- Cập nhật 11/07/2026: `ExaminationListPage` có chip phân loại theo status mới (`NEED_VERIFY`, `NEED_REVERIFY`, `AI_COMPLETED`, `COMPLETED`, `PENDING`, `ANALYZING`, `AWAITING_REVIEW`). Vì API `/examinations` chưa có query filter status trong OpenAPI, chip hiện lọc trên dữ liệu của trang hiện tại, còn phân trang vẫn gọi backend bằng `page`, `size`, `sort`.
- Các danh sách dùng API pageable phải có phân trang thật với lựa chọn page size `5 / 10 / 20`; không dùng infinite "Tải thêm" cho các màn chính như bệnh nhân, tài khoản bác sĩ/admin, và ca khám. FE gửi query phẳng `page`, `size` (và `sort` khi cần) vì backend Spring bind được vào `Pageable`.
- `ExaminationListPage` hiện chỉ hiển thị các trường tối thiểu: ID ca khám, tên bệnh nhân, ngày tháng năm sinh, giới tính, ngày chụp; chưa hiển thị ảnh/thumbnail trong list.
- Bấm một ca khám trong `ExaminationListPage` mở `ExaminationDetailPage` ngay trong content doctor shell để giữ nguyên sidebar/topbar. Detail gồm thanh thông tin bệnh nhân/ca khám phía trên, vùng ảnh lớn ở giữa/trái, và panel thông tin ca khám bên phải.
- Một examination có thể có nhiều ảnh; `ExaminationDetailPage` hiển thị ảnh đang chọn ở viewer lớn, có thanh thumbnail nhỏ để đổi ảnh, và nút toàn màn hình mở ảnh hiện tại trong viewer có thể zoom/pan.
- Permission doctor `UPLOAD_DICOM_IMAGE` là màn upload DICOM. Màn này cho chọn/kéo-thả nhiều file `.DCM/.dcm` hoặc nhiều file `.zip`; nhiều file DICOM upload lên `/dicom/upload/batch`, còn nhiều ZIP được gửi tuần tự từng file lên `/dicom/upload/zip-batch`.
- Flow upload mới được dựng ở `FileUploadPage` (`lib/presentation/pages/doctor/file_upload_page.dart`) để giữ lại `DicomUploadPage` cũ làm phương án rollback. Doctor shell hiện route permission `dicom_upload_page` sang `FileUploadPage` và hiển thị mini progress bar toàn cục ở góc phải khi upload/processing/verify/AI đang chạy.
- Màn upload DICOM ưu tiên layout gọn trong một viewport desktop: bên trái là danh sách file chờ gửi, có nút xóa từng file; sau khi upload batch thành công tự clear file chờ. Bên phải hiển thị danh sách bệnh nhân trong `successfulPatients[]` của response, không hiển thị lịch sử file đã upload.
- Thông báo trong app dùng toast overlay chung (`AppToast`) ở góc dưới bên phải, dạng thanh nhỏ, tự ẩn sau 5 giây và có nút `X` để đóng sớm. Không dùng `SnackBar` riêng cho từng màn nữa.
- Cập nhật 22/07/2026: toast notification từ WebSocket chỉ hiển thị `title` và nội dung thật của `message`; nếu backend/log gửi chuỗi kiểu `message:"..."` thì FE phải bỏ tiền tố `message:`. Toast notification không tự thay thế khi có toast mới; các toast xếp chồng lên nhau từ góc dưới bên phải, từng toast tự tắt sau 5 giây hoặc đóng sớm khi người dùng bấm `X`.
- Sau upload batch, panel response có nút "Đi tới ca khám" để mở `ExaminationListPage` trong doctor shell và truyền các `recentExaminations[]` vừa trả về. `ExaminationListPage` luôn có chip đầu tiên và mặc định là "Ca khám mới"; chip đó hiển thị dữ liệu từ response upload, còn các chip trạng thái còn lại vẫn đọc dữ liệu ca khám theo luồng patient detail/tổng hợp hiện có.

---

## 6. Assets

### 6.1 Khai báo assets
Mọi ảnh mới phải khai báo trong `pubspec.yaml`:
```yaml
flutter:
  assets:
    - lib/presentation/images/banner1.jpg
    - lib/presentation/images/logo1.jpg
    - lib/presentation/images/logo2.jpg
    - lib/presentation/images/BaSinh_GoiThang1.png
    - lib/presentation/images/BaSinh_GoiThang2.png
```
Sau khi thêm assets: **hot-restart** (không phải hot-reload).

### 6.2 Image error fallback
Luôn cung cấp `errorBuilder` cho `Image.asset`:
```dart
Image.asset(path, fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, color: _primaryGreen))
```

---

## 7. Dữ liệu mock exam

### 7.1 Cấu trúc mock exam
```dart
class MockExam {
  final String id, diagnosis, device, protocol;
  final DateTime examDate;
  final List<String> images; // asset paths
}
```
Tra cứu bằng `MockExams.forPatient(patientCode)`.

---

## 8. Các quyết định đặc biệt

| Quyết định | Lý do |
|---|---|
| Danh sách user dùng `GET /users` thay `GET /doctors` | API doc mới trả về `UserResponse` chung, không phải `DoctorResponse` riêng |
| Tạo tài khoản bác sĩ trong admin dùng `POST /doctors` với `CreateDoctorRequest` | Theo OpenAPI 08/07/2026, payload chỉ gửi `fullName`, `email`, `phone`; không gửi các field cũ `doctorCode`, `hospitalName`, `licenseNumber`, `specialization`. |
| `DoctorAccountModel` parse được cả `DoctorResponse` lẫn `UserResponse` | Field `role` có thể là String hoặc Object `{id, name, permissions[]}` |
| `PatientDetailPage` dùng `Navigator.push` không phải GoRouter | Trang con trong cùng Doctor role, không cần URL-based routing |
| Patient list page tự tải trang đầu khi màn danh sách bệnh nhân được render lần đầu | Tránh trạng thái chip "Tất cả" hiển thị rỗng dù backend có bệnh nhân; chỉ gọi khi màn danh sách thật sự mở để không load sẵn không cần thiết |
