import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../domain/entities/doctor_account_page_entity.dart';
import '../models/doctor_account_model.dart';
import '../models/role_model.dart';

abstract class AdminRemoteDataSource {
  Future<DoctorAccountPageEntity> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
    String? status,
  });

  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  });

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  });

  Future<List<RoleModel>> getRoles({required String token});

  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
    String? reason,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final http.Client client;
  AdminRemoteDataSourceImpl(this.client);

  @override
  Future<DoctorAccountPageEntity> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
    String? status,
  }) async {
    final keyword = name?.trim() ?? '';
    final statusFilter = status?.trim() ?? '';
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (keyword.isNotEmpty) 'keyword': keyword,
      if (statusFilter.isNotEmpty) 'status': statusFilter,
    };

    final endpoint = keyword.isEmpty && statusFilter.isEmpty
        ? ApiConstants.staffUsersEndpoint
        : ApiConstants.staffUsersSearchEndpoint;
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);

        if (responseData is List) {
          return _parseUserPage(
            {'content': responseData},
            fallbackPage: page,
            fallbackSize: size,
          );
        }
        if (responseData is Map<String, dynamic>) {
          return _parseUserPage(
            responseData,
            fallbackPage: page,
            fallbackSize: size,
          );
        }

        throw Exception('Định dạng danh sách người dùng không hợp lệ');
      }

      throw Exception('Lỗi hệ thống: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    final uri = Uri.parse(ApiConstants.createDoctorsEndpoint);
    final requestBody = <String, dynamic>{
      'fullName': doctorData['fullName']?.toString().trim() ?? '',
      'email': doctorData['email']?.toString().trim() ?? '',
      'phone': doctorData['phone']?.toString().trim() ?? '',
    };

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      String message = 'Lỗi khi tạo tài khoản bác sĩ';
      try {
        final errorData = jsonDecode(decodedBody);
        if (errorData is Map && errorData['message'] != null) {
          message = errorData['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  }) async {
    final uri = Uri.parse(ApiConstants.userAccountsEndpoint);

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'roleId': roleId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      String message = 'Lỗi khi tạo tài khoản';
      try {
        final errorData = jsonDecode(decodedBody);
        if (errorData is Map && errorData['message'] != null) {
          message = errorData['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<List<RoleModel>> getRoles({required String token}) async {
    final uri = Uri.parse(ApiConstants.rolesEndpoint);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rolesJson;
        if (data is List) {
          rolesJson = data;
        } else if (data is Map && data['content'] is List) {
          rolesJson = data['content'] as List;
        } else if (data is Map && data['data'] is List) {
          rolesJson = data['data'] as List;
        } else if (data is Map && data['roles'] is List) {
          rolesJson = data['roles'] as List;
        } else {
          throw Exception('Định dạng danh sách vai trò không hợp lệ');
        }

        return rolesJson
            .map((item) => RoleModel.fromJson(item as Map<String, dynamic>))
            .where((role) => !_isAdminRole(role))
            .toList();
      }

      throw Exception('Lỗi tải danh sách vai trò (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Kết nối thất bại: $e');
    }
  }

  @override
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
    String? reason,
  }) async {
    final uri = Uri.parse(
      activate
          ? ApiConstants.activateDoctorEndpoint(id)
          : ApiConstants.deactivateDoctorEndpoint(id),
    );

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: activate ? null : jsonEncode({'reason': reason?.trim() ?? ''}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final decodedBody = utf8.decode(response.bodyBytes);
        String message = 'Không thể thay đổi trạng thái bác sĩ';
        try {
          final errorData = jsonDecode(decodedBody);
          if (errorData is Map && errorData['message'] != null) {
            message = errorData['message'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: $e');
    }
  }

  DoctorAccountPageEntity _parseUserPage(
    Map<String, dynamic> json, {
    required int fallbackPage,
    required int fallbackSize,
  }) {
    final pageJson = _extractPageMap(json);
    final content = _extractUserList(pageJson);
    final users = content
        .map(
          (item) => DoctorAccountModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final totalElements = _parseInt(
      pageJson['totalElements'] ?? pageJson['total'] ?? pageJson['totalItems'],
      users.length,
    );
    final pageSize = _parseInt(
      pageJson['pageSize'] ?? pageJson['size'],
      fallbackSize,
    );
    final totalPages = _parseTotalPages(
      pageJson['totalPages'] ?? pageJson['pages'],
      totalElements: totalElements,
      pageSize: pageSize,
    );
    final pageNumber = _parseInt(
      pageJson['pageNumber'] ?? pageJson['number'] ?? pageJson['page'],
      fallbackPage,
    );

    return DoctorAccountPageEntity(
      content: users,
      totalElements: totalElements,
      totalPages: totalPages,
      pageNumber: pageNumber,
      pageSize: pageSize,
      isLast:
          pageJson['isLast'] as bool? ??
          pageJson['last'] as bool? ??
          pageNumber >= totalPages - 1,
    );
  }

  List<dynamic> _extractUserList(Map<String, dynamic> json) {
    for (final key in const ['content', 'data', 'items', 'users']) {
      final value = json[key];
      if (value is List) return value;
    }
    return const [];
  }

  Map<String, dynamic> _extractPageMap(Map<String, dynamic> json) {
    for (final key in const ['data', 'result', 'payload']) {
      final value = json[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return json;
  }

  int _parseInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _parseTotalPages(
    Object? value, {
    required int totalElements,
    required int pageSize,
  }) {
    final parsed = _parseInt(value, 0);
    if (parsed > 0) return parsed;
    if (totalElements <= 0 || pageSize <= 0) return 1;
    return (totalElements / pageSize).ceil();
  }

  bool _isAdminRole(RoleModel role) {
    final code = role.code.trim().toUpperCase();
    final name = role.name.trim().toUpperCase();
    return code == 'ADMIN' ||
        code == 'ROLE_ADMIN' ||
        name == 'ADMIN' ||
        name == 'ROLE_ADMIN';
  }
}
