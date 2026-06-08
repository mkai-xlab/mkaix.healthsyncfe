import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource(this.client);

  /// Hàm Đăng nhập kết nối Spring Boot Backend
  /// Gửi POST request kèm credentials, nhận về thông tin User và Token phân quyền
  Future<UserModel> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Cấu hình endpoint POST của Spring Boot (Ví dụ: /api/v1/auth/login)
      final uri = Uri.parse(ApiConstants.loginEndpoint);

      // 2. Đóng gói dữ liệu gửi lên (Request Body) đúng chuẩn DTO của Backend
      final Map<String, dynamic> requestBody = {
        'username': email
            .trim(), // Thường Spring Boot dùng trường 'username' đại diện cho Email/Login ID
        'password': password.trim(),
      };

      // 3. Tiến hành gọi API bằng phương thức POST
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      // 4. Xử lý kết quả trả về từ Spring Boot
      if (response.statusCode == 200) {
        // Tránh lỗi font tiếng Việt khi giải mã thông tin User
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        // Trả về UserModel. Toàn bộ logic bóc tách 'roles' hoặc 'accessToken'
        // nên được xử lý gọn gã bên trong hàm UserModel.fromJson()
        return UserModel.fromJson(responseData);
      }
      // 5. Xử lý các lỗi nghiệp vụ từ Spring Boot Security (Ví dụ: 401 Unauthorized, 403 Forbidden)
      else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Tài khoản hoặc mật khẩu không chính xác!');
      } else {
        throw Exception('Hệ thống gặp sự cố (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới máy chủ.');
    }
  }
}
