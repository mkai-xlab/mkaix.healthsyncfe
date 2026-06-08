import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_account_model.dart';
import '../../domain/entities/user_account_page_entity.dart';

abstract class AdminRemoteDataSource {
  Future<UserAccountPageEntity> getUserAccounts({
    required int page,
    required int size,
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
    // TODO: Di chuyển endpoint này vào ApiConstants để quản lý tập trung
    final String adminUserEndpoint = 'http://10.0.2.2:4010/api/v1/users';

    final uri = Uri.parse(adminUserEndpoint).replace(
      queryParameters: {'page': page.toString(), 'size': size.toString()},
    );

    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
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
