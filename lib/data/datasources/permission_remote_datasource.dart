import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/permission_catalog_model.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';

abstract class PermissionRemoteDataSource {
  Future<PermissionCatalogModel> getPermissionCatalog();
  Future<List<RoleModel>> getRoles();
  Future<RoleModel> updateRolePermissions(
    String roleId,
    List<String> permissions,
  );
  Future<PermissionFeatureModel> createFeature({
    required String name,
    String? description,
  });
  Future<PermissionFeatureModel> updateFeature({
    required String id,
    required String name,
    String? description,
  });
  Future<void> deleteFeature(String id);
  Future<PermissionModel> createPermission({
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  });
  Future<PermissionModel> updatePermission({
    required String id,
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  });
  Future<void> deletePermission(String id);
}

class PermissionRemoteDataSourceImpl implements PermissionRemoteDataSource {
  final http.Client client;
  final String? token;

  PermissionRemoteDataSourceImpl(this.client, {this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  @override
  Future<PermissionCatalogModel> getPermissionCatalog() async {
    final uri = Uri.parse(ApiConstants.permissionsTreeEndpoint);
    try {
      final response = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return PermissionCatalogModel.fromJson(data);
      }

      throw Exception('Loi tai danh sach quyen (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Loi ket noi: $e');
    }
  }

  @override
  Future<PermissionFeatureModel> createFeature({
    required String name,
    String? description,
  }) async {
    final uri = Uri.parse(ApiConstants.featuresEndpoint);
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (description?.trim().isNotEmpty ?? false)
        'description': description?.trim(),
    };

    final response = await client
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFeatureResponse(response.bodyBytes, fallback: payload);
    }
    throw Exception('Loi tao feature (${response.statusCode})');
  }

  @override
  Future<PermissionFeatureModel> updateFeature({
    required String id,
    required String name,
    String? description,
  }) async {
    final uri = Uri.parse(ApiConstants.featureByIdEndpoint(id));
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (description?.trim().isNotEmpty ?? false)
        'description': description?.trim(),
    };

    final response = await client
        .put(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseFeatureResponse(
        response.bodyBytes,
        fallback: {...payload, 'id': id},
      );
    }
    throw Exception('Loi cap nhat feature (${response.statusCode})');
  }

  @override
  Future<void> deleteFeature(String id) async {
    final uri = Uri.parse(ApiConstants.featureByIdEndpoint(id));
    final response = await client
        .delete(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception('Lỗi xóa feature (${response.statusCode})');
  }

  @override
  Future<PermissionModel> createPermission({
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) async {
    final uri = Uri.parse(ApiConstants.permissionsEndpoint);
    final parsedFeatureId = int.tryParse(featureId) ?? featureId;
    final payload = <String, dynamic>{
      'code': code.trim(),
      'name': name.trim(),
      'featureId': parsedFeatureId,
      'feature_id': parsedFeatureId,
    };
    if (priority != null) {
      payload['priority'] = priority;
    }
    final trimmedRequiresPermissionId = requiresPermissionId?.trim();
    if (trimmedRequiresPermissionId?.isNotEmpty ?? false) {
      final parsedRequiresPermissionId =
          int.tryParse(trimmedRequiresPermissionId!) ??
          trimmedRequiresPermissionId;
      payload['requiresPermissionId'] = parsedRequiresPermissionId;
      payload['parent_id'] = parsedRequiresPermissionId;
    }

    final response = await client
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parsePermissionResponse(response.bodyBytes, fallback: payload);
    }
    throw Exception('Loi tao permission (${response.statusCode})');
  }

  @override
  Future<PermissionModel> updatePermission({
    required String id,
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) async {
    final uri = Uri.parse(ApiConstants.permissionByIdEndpoint(id));
    final parsedFeatureId = int.tryParse(featureId) ?? featureId;
    final payload = <String, dynamic>{
      'id': int.tryParse(id) ?? id,
      'code': code.trim(),
      'name': name.trim(),
      'featureId': parsedFeatureId,
      'feature_id': parsedFeatureId,
    };
    if (priority != null) {
      payload['priority'] = priority;
    }
    final trimmedRequiresPermissionId = requiresPermissionId?.trim();
    if (trimmedRequiresPermissionId?.isNotEmpty ?? false) {
      payload['requiresPermissionId'] =
          int.tryParse(trimmedRequiresPermissionId!) ??
          trimmedRequiresPermissionId;
    }

    final response = await client
        .put(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parsePermissionResponse(
        response.bodyBytes,
        fallback: {...payload, 'id': id},
      );
    }
    throw Exception('Loi cap nhat permission (${response.statusCode})');
  }

  @override
  Future<void> deletePermission(String id) async {
    final uri = Uri.parse(ApiConstants.permissionByIdEndpoint(id));
    final response = await client
        .delete(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception('Lỗi xóa permission (${response.statusCode})');
  }

  @override
  Future<List<RoleModel>> getRoles() async {
    try {
      final rolesResponse = await client
          .get(Uri.parse(ApiConstants.rolesEndpoint), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (rolesResponse.statusCode != 200) {
        throw Exception(
          'Loi tai danh sach vai tro (${rolesResponse.statusCode})',
        );
      }

      final rolesData = jsonDecode(utf8.decode(rolesResponse.bodyBytes));
      final roleItems = _extractRoleItems(rolesData);
      final roles = roleItems
          .whereType<Map>()
          .map((item) => RoleModel.fromJson(Map<String, dynamic>.from(item)))
          .where((role) => !_isAdminRole(role))
          .toList();

      final hydratedRoles = <RoleModel>[];

      for (final role in roles) {
        final roleName = _rolePathKey(role);
        if (roleName.isEmpty) continue;
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
        hydratedRoles.add(
          RoleModel(
            id: roleName,
            name: role.name.isEmpty ? roleName : role.name,
            code: role.code.isEmpty ? roleName : role.code,
            permissions: data.map((e) => e.toString()).toList(),
          ),
        );
      }

      return hydratedRoles;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Loi ket noi: $e');
    }
  }

  PermissionFeatureModel _parseFeatureResponse(
    List<int> bodyBytes, {
    required Map<String, dynamic> fallback,
  }) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return PermissionFeatureModel.fromJson(decoded);
      }
    } catch (_) {}
    return PermissionFeatureModel.fromJson(fallback);
  }

  List<dynamic> _extractRoleItems(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['content'] is List) return data['content'] as List;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['roles'] is List) return data['roles'] as List;
    throw Exception('Dinh dang danh sach vai tro khong hop le');
  }

  String _rolePathKey(RoleModel role) {
    final code = role.code.trim();
    if (code.isNotEmpty) return code;
    final name = role.name.trim();
    if (name.isNotEmpty) return name;
    return role.id.trim();
  }

  bool _isAdminRole(RoleModel role) {
    final code = role.code.trim().toUpperCase();
    final name = role.name.trim().toUpperCase();
    return code == 'ADMIN' ||
        code == 'ROLE_ADMIN' ||
        name == 'ADMIN' ||
        name == 'ROLE_ADMIN';
  }

  PermissionModel _parsePermissionResponse(
    List<int> bodyBytes, {
    required Map<String, dynamic> fallback,
  }) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return PermissionModel.fromJson(data);
        }
        return PermissionModel.fromJson(decoded);
      }
    } catch (_) {}
    return PermissionModel.fromJson(fallback);
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
