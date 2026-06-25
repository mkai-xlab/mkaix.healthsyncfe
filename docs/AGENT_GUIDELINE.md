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
| `/doctors` | POST | Tạo doctor bằng `CreateDoctorRequest` |
| `/doctors/active` | GET | Danh sách doctor active |
| `/doctors/{id}/activate` | POST | Kích hoạt doctor |
| `/doctors/{id}/deactivate` | POST | Khóa doctor |
| `/doctors/{id}` | DELETE | OperationId cũng là deactivateDoctor |

**Patients**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/patients` | GET | Query object: `filter` (`PatientFilterRequest`) + `pageable` |
| `/patients` | POST | Tạo bệnh nhân bằng `CreatePatientRequest`; required: `patientCode`, `fullName` |
| `/patients/{id}` | PUT | Cập nhật bệnh nhân bằng `EditPatientRequest` |
| `/patients/{id}` | DELETE | Xóa bệnh nhân |

**Permissions / Features**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/permissions/tree` | GET | Trả `FeatureResponse[]`, mỗi feature có `permissions[]` |
| `/permissions` | POST | Tạo permission `{name, description, featureId, requiresPermissionId}` |
| `/permissions/{id}` | PUT | Cập nhật permission `{name, description, requiresPermissionId}` |
| `/permissions/role/{roleName}` | GET | Trả danh sách permission id (`int64[]`) |
| `/permissions/role/{roleName}` | PUT | Cập nhật quyền role bằng `{permissionIds: [...]}` |
| `/features` | POST | Tạo feature `{name, description}` |
| `/features/{id}` | PUT | Cập nhật feature `{name, description}` |
| `/roles` | GET | Backend hiện chưa có/chưa ổn định endpoint này. Tạm thời popup tạo user dùng role cố định: `1 = Admin`, `2 = Doctor` theo yêu cầu 25/06/2026. |

**Notifications / Upload**
| Endpoint | Method | Ghi chú |
|---|---|---|
| `/notifications/unread` | GET | Trả `NotificationDto[]` |
| `/notifications/{id}/read` | PUT | Mark as read |
| `/notifications/send` | POST | Test notification `{userId, title, message, type}` |
| `/dicom/upload` | POST | Multipart `file` → `DicomTagResponse[]` |
| `/s3/test-upload` | POST | Multipart `file`, query `folderName`, `fileName` → string |

**Schema lưu ý**
- Password mới trong login/reset/change-password: `minLength: 8`, `maxLength: 32`.
- `ResetPasswordRequest` bắt buộc đủ `email`, `token`, `newPassword`; `token` đúng 6 ký tự.
- `CreateUserRequest` bắt buộc `fullName`, `email`, `roleId`; `phone` chỉ gồm chữ số nếu có.
- `CreateDoctorRequest` bắt buộc `doctorCode`, `email`, `fullName`, `hospitalName`, `licenseNumber`, `phone`, `specialization`.
- Gender dùng enum `MALE`, `FEMALE`, `OTHER`.
- Doctor status dùng enum `ACTIVE`, `INACTIVE`.
- Doctor position dùng enum `DEPARTMENT_HEAD`, `NORMAL`.

**MockAPI:** `https://6a21b474b1d0aaf32b4fe12a.mockapi.io`
- `/permission` — danh sách quyền
- `/role` — danh sách vai trò, PUT `{permissions: [...]}` để cập nhật

### 4.2 Mock data fallback
Khi backend chưa có dữ liệu, datasource tự fallback sang mock:
```dart
// Trong PatientRemoteDataSourceImpl
try {
  // Gọi API...
  if (result.content.isEmpty) return _mockPage(...); // fallback
} catch (_) {
  return _mockPage(...); // fallback khi lỗi
}
```
Mock data đặt trong `lib/data/mock/`.

### 4.3 First-time login (403 + first_time_login)
- Backend trả `403` với body `{ "error": "first_time_login..." }` khi lần đầu đăng nhập.
- Datasource throw `FirstTimeLoginException(username, oldPassword)`.
- ViewModel catch và set `isFirstTimeLogin = true`, lưu `pendingUsername/pendingOldPassword`.
- GoRouter redirect bắt buộc sang `/change-password`.

---

## 5. UI Patterns

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

## 7. Dữ liệu mock bệnh nhân

### 7.1 Bệnh nhân mẫu từ DICOM thực
- **Nguyễn Bá Sinh** — patientCode: `2600056713`, sinh 1963, nam
  - DICOM tags: BodyPart=KNEE, KVP=54, Device=GE Healthcare Optima XR646, Protocol=GOI THANG
  - Ảnh X-quang: `BaSinh_GoiThang1.png`, `BaSinh_GoiThang2.png`

### 7.2 Cấu trúc mock exam
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
| Tạo user dùng `POST /users` với `{fullName, email, phone, roleId}` | `CreateUserRequest` schema mới, bỏ các field doctor-specific |
| `DoctorAccountModel` parse được cả `DoctorResponse` lẫn `UserResponse` | Field `role` có thể là String hoặc Object `{id, name, permissions[]}` |
| `PatientDetailPage` dùng `Navigator.push` không phải GoRouter | Trang con trong cùng Doctor role, không cần URL-based routing |
| Patient list page tải data khi switch sang tab index 1 | Không load sẵn khi vào homepage để tránh gọi API không cần thiết |
