import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/doctor_account_model.dart';
import '../models/user_account_model.dart';
import '../../domain/entities/user_account_page_entity.dart';

abstract class AdminRemoteDataSource {
  Future<UserAccountPageEntity> getUserAccounts({
    required int page,
    required int size,
  });
  Future<Map<String, dynamic>> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
  });
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  });
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final http.Client client;
  AdminRemoteDataSourceImpl(this.client);

  @override
  Future<UserAccountPageEntity> getUserAccounts({
    required int page,
    required int size,
  }) async {
    final uri = Uri.parse(ApiConstants.userAccountsEndpoint).replace(
      queryParameters: {'page': page.toString(), 'size': size.toString()},
    );

    try {
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final dynamic responseData = jsonDecode(decodedBody);

        // KỊCH BẢN MOCK: Dữ liệu bị bọc mảng ngoài cùng [ { content: [...] } ]
        if (responseData is List &&
            responseData.isNotEmpty &&
            responseData[0] is Map &&
            responseData[0].containsKey('content')) {
          final Map<String, dynamic> pageData = responseData[0];
          return _parsePage(pageData);
        }
        // KỊCH BẢN SPRING BOOT THẬT: Trả về Object trực tiếp { content: [...] }
        else if (responseData is Map) {
          return _parsePage(responseData as Map<String, dynamic>);
        }

        throw Exception('Định dạng dữ liệu không hợp lệ');
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi mạng: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (name != null && name.isNotEmpty) 'name': name,
    };

    final uri = Uri.parse(
      ApiConstants.doctorsEndpoint,
    ).replace(queryParameters: queryParams);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // Sử dụng token
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final dynamic responseData = jsonDecode(decodedBody);

        // Xử lý linh hoạt cho cả MockAPI (List) và Spring Boot (Map)
        Map<String, dynamic> pageData;
        if (responseData is List && responseData.isNotEmpty) {
          pageData = responseData[0] as Map<String, dynamic>;
        } else {
          pageData = responseData as Map<String, dynamic>;
        }

        final List<dynamic> contentList = pageData['content'] ?? [];
        final List<DoctorAccountModel> accounts = contentList
            .map(
              (item) =>
                  DoctorAccountModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return {
          'content': accounts,
          'isLast':
              pageData['last'] ??
              pageData['isLast'] ??
              true, // Kiểm tra cả 'last' (chuẩn Spring) và 'isLast'
        };
      } else {
        throw Exception('Lỗi hệ thống: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    final uri = Uri.parse(ApiConstants.createDoctorsEndpoint);

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(doctorData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> errorData = jsonDecode(decodedBody);
        throw Exception(errorData['message'] ?? 'Lỗi khi tạo tài khoản bác sĩ');
      }
    } catch (e) {
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
  }) async {
    final action = activate ? 'activate' : 'deactivate';
    final uri = Uri.parse('${ApiConstants.doctorsEndpoint}/$id/$action');

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> errorData = jsonDecode(decodedBody);
        throw Exception(
          errorData['message'] ?? 'Không thể thay đổi trạng thái tài khoản',
        );
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  UserAccountPageEntity _parsePage(Map<String, dynamic> json) {
    final List<dynamic> content = json['content'] ?? [];
    return UserAccountPageEntity(
      content: content
          .map(
            (item) => UserAccountModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
