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
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (name != null && name.isNotEmpty) 'keyword': name,
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
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);

        if (responseData is List && responseData.isNotEmpty) {
          return _parseDoctorPage(responseData.first as Map<String, dynamic>);
        }
        if (responseData is Map<String, dynamic>) {
          return _parseDoctorPage(responseData);
        }

        throw Exception('Dinh dang danh sach bac si khong hop le');
      }

      throw Exception('Loi he thong: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ket noi that bai: $e');
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
      String message = 'Loi khi tao tai khoan bac si';
      try {
        final errorData = jsonDecode(decodedBody);
        if (errorData is Map && errorData['message'] != null) {
          message = errorData['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ket noi that bai: $e');
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
      String message = 'Loi khi tao tai khoan';
      try {
        final errorData = jsonDecode(decodedBody);
        if (errorData is Map && errorData['message'] != null) {
          message = errorData['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ket noi that bai: $e');
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
        String message = 'Khong the thay doi trang thai bac si';
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
      throw Exception('Loi ket noi: $e');
    }
  }

  DoctorAccountPageEntity _parseDoctorPage(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? [];
    final doctors = content
        .map(
          (item) => DoctorAccountModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return DoctorAccountPageEntity(
      content: doctors,
      totalElements: json['totalElements'] as int? ?? doctors.length,
      totalPages: json['totalPages'] as int? ?? 1,
      isLast: json['isLast'] as bool? ?? json['last'] as bool? ?? true,
    );
  }
}
