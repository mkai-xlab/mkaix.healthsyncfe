import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource(this.client);

  /// Hàm Đăng nhập: GET toàn bộ danh sách từ MockAPI, tìm kiếm và xác thực mật khẩu
  /// Nếu thông tin chính xác, trả về UserModel với thông tin role để routing có thể điều hướng
  Future<UserModel> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Gọi API để lấy danh sách tài khoản từ MockAPI
      final response = await client
          .get(
            Uri.parse(ApiConstants.loginEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      // 2. Kiểm tra nếu MockAPI trả về trạng thái thành công (200 OK)
      if (response.statusCode == 200) {
        // MockAPI trả về một Mảng (List) các Object JSON
        final List<dynamic> usersList = jsonDecode(response.body);

        // 3. Tìm kiếm User trong danh sách trùng khớp với email/username và mật khẩu
        final matchedUser = usersList.firstWhere(
          (user) =>
              (user['email'] == email.trim() ||
                  user['username'] == email.trim()) &&
              user['password'] == password.trim(),
          orElse: () => null,
        );

        // 4. Trả về kết quả hoặc báo lỗi dựa trên kết quả tìm kiếm
        if (matchedUser != null) {
          // Ép kiểu Map thành Object UserModel (bao gồm role)
          // Nếu là DOCTOR -> return UserModel với roles=['DOCTOR']
          // Nếu là ADMIN -> return UserModel với roles=['ADMIN']
          return UserModel.fromJson(matchedUser);
        } else {
          // Không tìm thấy hoặc mật khẩu sai
          throw Exception('Tài khoản hoặc mật khẩu không chính xác!');
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
}
