import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource(this.client);

  /// Hàm giả lập Đăng nhập bằng cách GET toàn bộ danh sách từ MockAPI
  /// sau đó lọc ra User có email hoặc username trùng khớp.
  Future<UserModel> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Gọi API bằng phương thức GET để lấy danh sách tài khoản từ MockAPI
      final response = await client
          .get(
            Uri.parse(ApiConstants.loginEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Tự động hủy sau 10 giây nếu mạng quá yếu

      // 2. Kiểm tra nếu MockAPI trả về trạng thái thành công (200 OK)
      if (response.statusCode == 200) {
        // MockAPI trả về một Mảng (List) các Object JSON
        final List<dynamic> usersList = jsonDecode(response.body);

        // 3. Tìm kiếm User trong danh sách trùng khớp với dữ liệu người dùng nhập
        // Vì MockAPI không có logic check password, ở đây ta chấp nhận mọi mật khẩu, miễn là đúng Email/Username
        final matchedUser = usersList.firstWhere(
          (user) =>
              user['email'] == email.trim() || user['username'] == email.trim(),
          orElse: () => null,
        );

        // 4. Trả về kết quả hoặc báo lỗi dựa trên kết quả tìm kiếm
        if (matchedUser != null) {
          // Ép kiểu Map thành Object UserModel để đẩy lên tầng Repository
          return UserModel.fromJson(matchedUser);
        } else {
          // Không tìm thấy email/username này trong danh sách của MockAPI
          throw Exception('Tài khoản không tồn tại trên hệ thống MockAPI!');
        }
      } else {
        // Trường hợp MockAPI trả về các mã lỗi khác (Ví dụ: 404, 500)
        throw Exception(
          'Lỗi kết nối từ MockAPI (Mã lỗi: ${response.statusCode})',
        );
      }
    } catch (e) {
      // Nếu là lỗi do chính chúng ta chủ động throw ở trên thì giữ nguyên để UI hiển thị
      if (e is Exception) rethrow;

      // Các lỗi ngoại vi như: mất mạng, sai URL, timeout...
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới MockAPI.');
    }
  }

  // Future<UserModel> loginWithEmailAndPassword(
  //   String email,
  //   String password,
  // ) async {
  //   try {
  //     final response = await client
  //         .post(
  //           Uri.parse(ApiConstants.loginEndpoint),
  //           headers: {
  //             'Content-Type': 'application/json; charset=UTF-8',
  //             'Accept': 'application/json',
  //           },
  //           body: jsonEncode({'email': email, 'password': password}),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       return UserModel.fromJson(data);
  //     } else if (response.statusCode == 401 || response.statusCode == 403) {
  //       throw Exception('Tài khoản hoặc mật khẩu không chính xác!');
  //     } else {
  //       // Parse message lỗi tùy biến từ Spring Boot Custom Error Handler (nếu có)
  //       final Map<String, dynamic> errorData = jsonDecode(response.body);
  //       throw Exception(
  //         errorData['message'] ?? 'Đã có lỗi xảy ra từ hệ thống.',
  //       );
  //     }
  //   } catch (e) {
  //     if (e is Exception) rethrow;
  //     throw Exception(
  //       'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại!',
  //     );
  //   }
  // }
}
