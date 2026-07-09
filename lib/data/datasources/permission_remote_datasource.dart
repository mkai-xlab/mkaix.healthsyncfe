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
  Future<PermissionModel> createPermission({
    required String code,
    required String name,
    required String featureId,
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  });
  Future<PermissionModel> updatePermission({
    required String id,
    required String code,
    required String name,
    required String featureId,
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  });
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
  Future<PermissionModel> createPermission({
    required String code,
    required String name,
    required String featureId,
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  }) async {
    final uri = Uri.parse(ApiConstants.permissionsEndpoint);
    final payload = <String, dynamic>{
      'code': code.trim(),
      'name': name.trim(),
      'featureId': int.tryParse(featureId) ?? featureId,
    };
    final trimmedPresentation = presentation?.trim();
    if (trimmedPresentation?.isNotEmpty ?? false) {
      payload['presentation'] = trimmedPresentation;
    }
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
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  }) async {
    final uri = Uri.parse(ApiConstants.permissionByIdEndpoint(id));
    final payload = <String, dynamic>{
      'code': code.trim(),
      'name': name.trim(),
      'featureId': int.tryParse(featureId) ?? featureId,
    };
    final trimmedPresentation = presentation?.trim();
    if (trimmedPresentation?.isNotEmpty ?? false) {
      payload['presentation'] = trimmedPresentation;
    }
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

  PermissionModel _parsePermissionResponse(
    List<int> bodyBytes, {
    required Map<String, dynamic> fallback,
  }) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) {
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
