import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Exception đặc biệt khi backend trả về 403 + first_time_login_required
class FirstTimeLoginException implements Exception {
  final String username;
  final String oldPassword;
  const FirstTimeLoginException({
    required this.username,
    required this.oldPassword,
  });
}

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource(this.client);

  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) return;

    final response = await client
        .post(
          Uri.parse(ApiConstants.logoutEndpoint),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể đăng xuất (${response.statusCode})');
    }
  }

  /// Đăng nhập
  Future<UserModel> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.loginEndpoint);
      final Map<String, dynamic> requestBody = {
        'username': email.trim(),
        'password': password.trim(),
      };

      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        return UserModel.fromJson(responseData);
      } else if (response.statusCode == 403) {
        // Kiểm tra trường hợp đăng nhập lần đầu yêu cầu đổi mật khẩu
        try {
          final String body = utf8.decode(response.bodyBytes);
          final data = jsonDecode(body);
          final String? error = data['error']?.toString().toLowerCase();
          if (error != null && error.contains('first_time_login')) {
            throw FirstTimeLoginException(
              username: email.trim(),
              oldPassword: password.trim(),
            );
          }
        } catch (e) {
          if (e is FirstTimeLoginException) rethrow;
        }
        throw Exception('Tên đăng nhập hoặc mật khẩu không chính xác!');
      } else if (response.statusCode == 401) {
        throw Exception('Tên đăng nhập hoặc mật khẩu không chính xác!');
      } else if (response.statusCode == 423) {
        throw Exception(
          'Tài khoản đã bị khóa 15 phút do nhập sai mật khẩu 5 lần. Vui lòng thử lại sau.',
        );
      } else if (response.statusCode == 400) {
        throw Exception('Mật khẩu phải có ít nhất 8 ký tự.');
      } else {
        throw Exception('Hệ thống gặp sự cố (Mã lỗi: ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception(
        'Kết nối tới máy chủ quá thời gian. Vui lòng kiểm tra mạng hoặc thử lại sau.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới máy chủ.');
    }
  }

  /// Gửi yêu cầu quên mật khẩu — backend gửi token về email
  Future<void> forgotPassword(String email) async {
    try {
      final uri = Uri.parse(ApiConstants.forgotPasswordEndpoint);
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final String body = utf8.decode(response.bodyBytes);
        String message = 'Có lỗi xảy ra (${response.statusCode})';
        try {
          final data = jsonDecode(body);
          if (data is Map && data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception(
        'Kết nối tới máy chủ quá thời gian. Vui lòng kiểm tra mạng hoặc thử lại sau.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới máy chủ.');
    }
  }

  /// Đặt lại mật khẩu bằng token nhận từ email
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.resetPasswordEndpoint);
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'token': token.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final String body = utf8.decode(response.bodyBytes);
        String message = 'Token không hợp lệ hoặc đã hết hạn';
        try {
          final data = jsonDecode(body);
          if (data is Map && data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception(
        'Kết nối tới máy chủ quá thời gian. Vui lòng kiểm tra mạng hoặc thử lại sau.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới máy chủ.');
    }
  }

  /// Đổi mật khẩu lần đầu đăng nhập (chưa có token, dùng username + oldPassword)
  Future<void> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.changePasswordEndpoint);
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'oldPassword': oldPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final String body = utf8.decode(response.bodyBytes);
        String message = 'Không thể đổi mật khẩu, vui lòng thử lại';
        try {
          final data = jsonDecode(body);
          if (data is Map && data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}
        throw Exception(message);
      }
    } on TimeoutException {
      throw Exception(
        'Kết nối tới máy chủ quá thời gian. Vui lòng kiểm tra mạng hoặc thử lại sau.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: Không thể kết nối tới máy chủ.');
    }
  }
}
