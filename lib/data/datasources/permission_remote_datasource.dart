import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';

abstract class PermissionRemoteDataSource {
  Future<List<PermissionModel>> getPermissions();
  Future<List<RoleModel>> getRoles();
  Future<RoleModel> updateRolePermissions(
    String roleId,
    List<String> permissions,
  );
}

class PermissionRemoteDataSourceImpl implements PermissionRemoteDataSource {
  final http.Client client;
  PermissionRemoteDataSourceImpl(this.client);

  @override
  Future<List<PermissionModel>> getPermissions() async {
    final uri = Uri.parse(ApiConstants.permissionsEndpoint);
    try {
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Lỗi tải danh sách quyền (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: $e');
    }
  }

  @override
  Future<List<RoleModel>> getRoles() async {
    final uri = Uri.parse(ApiConstants.rolesEndpoint);
    try {
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Lỗi tải danh sách vai trò (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: $e');
    }
  }

  @override
  Future<RoleModel> updateRolePermissions(
    String roleId,
    List<String> permissions,
  ) async {
    final uri = Uri.parse('${ApiConstants.rolesEndpoint}/$roleId');
    try {
      final response = await client
          .put(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'permissions': permissions}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return RoleModel.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Lỗi cập nhật quyền (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
