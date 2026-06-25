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
  final String? token;

  PermissionRemoteDataSourceImpl(this.client, {this.token});

  static const List<String> _knownRoleNames = ['ADMIN', 'DOCTOR'];

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  @override
  Future<List<PermissionModel>> getPermissions() async {
    final uri = Uri.parse(ApiConstants.permissionsTreeEndpoint);
    try {
      final response = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final permissions = <PermissionModel>[];

        for (final feature in data) {
          if (feature is! Map<String, dynamic>) continue;

          final resource = feature['name']?.toString() ?? '';
          final rawPermissions = feature['permissions'];
          if (rawPermissions is! List) continue;

          for (final item in rawPermissions) {
            if (item is! Map<String, dynamic>) continue;

            permissions.add(
              PermissionModel.fromJson({
                ...item,
                'resource': resource,
                'action': item['name'],
              }),
            );
          }
        }

        return permissions;
      }

      throw Exception('Loi tai danh sach quyen (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Loi ket noi: $e');
    }
  }

  @override
  Future<List<RoleModel>> getRoles() async {
    try {
      final roles = <RoleModel>[];

      for (final roleName in _knownRoleNames) {
        final uri = Uri.parse(
          '${ApiConstants.rolePermissionsEndpoint}/$roleName',
        );
        final response = await client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception(
            'Loi tai quyen vai tro $roleName (${response.statusCode})',
          );
        }

        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        roles.add(
          RoleModel(
            id: roleName,
            name: roleName,
            code: roleName,
            permissions: data.map((e) => e.toString()).toList(),
          ),
        );
      }

      return roles;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Loi ket noi: $e');
    }
  }

  @override
  Future<RoleModel> updateRolePermissions(
    String roleId,
    List<String> permissions,
  ) async {
    final uri = Uri.parse('${ApiConstants.rolePermissionsEndpoint}/$roleId');
    try {
      final response = await client
          .put(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'permissionIds': permissions
                  .map(int.tryParse)
                  .whereType<int>()
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return RoleModel(
          id: roleId,
          name: roleId,
          code: roleId,
          permissions: permissions,
        );
      }

      throw Exception('Loi cap nhat quyen (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Loi ket noi: $e');
    }
  }
}
