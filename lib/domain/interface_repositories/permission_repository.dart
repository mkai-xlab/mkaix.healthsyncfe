import '../../data/models/permission_catalog_model.dart';
import '../../data/models/permission_model.dart';
import '../../data/models/role_model.dart';

abstract class PermissionRepository {
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
}
