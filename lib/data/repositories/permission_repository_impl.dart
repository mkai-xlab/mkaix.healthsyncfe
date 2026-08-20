import '../../domain/interface_repositories/permission_repository.dart';
import '../datasources/permission_remote_datasource.dart';
import '../models/permission_catalog_model.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionRemoteDataSource remoteDataSource;

  PermissionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PermissionCatalogModel> getPermissionCatalog() {
    return remoteDataSource.getPermissionCatalog();
  }

  @override
  Future<List<RoleModel>> getRoles() {
    return remoteDataSource.getRoles();
  }

  @override
  Future<RoleModel> updateRolePermissions(
    String roleId,
    List<String> permissions,
  ) {
    return remoteDataSource.updateRolePermissions(roleId, permissions);
  }

  @override
  Future<PermissionFeatureModel> createFeature({
    required String name,
    String? description,
  }) {
    return remoteDataSource.createFeature(name: name, description: description);
  }

  @override
  Future<PermissionFeatureModel> updateFeature({
    required String id,
    required String name,
    String? description,
  }) {
    return remoteDataSource.updateFeature(
      id: id,
      name: name,
      description: description,
    );
  }

  @override
  Future<void> deleteFeature(String id) {
    return remoteDataSource.deleteFeature(id);
  }

  @override
  Future<PermissionModel> createPermission({
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) {
    return remoteDataSource.createPermission(
      code: code,
      name: name,
      featureId: featureId,
      priority: priority,
      requiresPermissionId: requiresPermissionId,
    );
  }

  @override
  Future<PermissionModel> updatePermission({
    required String id,
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) {
    return remoteDataSource.updatePermission(
      id: id,
      code: code,
      name: name,
      featureId: featureId,
      priority: priority,
      requiresPermissionId: requiresPermissionId,
    );
  }

  @override
  Future<void> deletePermission(String id) {
    return remoteDataSource.deletePermission(id);
  }
}
