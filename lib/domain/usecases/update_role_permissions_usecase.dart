import '../../data/models/role_model.dart';
import '../interface_repositories/permission_repository.dart';

class UpdateRolePermissionsUseCase {
  final PermissionRepository repository;

  UpdateRolePermissionsUseCase(this.repository);

  Future<RoleModel> execute(String roleId, List<String> permissions) {
    return repository.updateRolePermissions(roleId, permissions);
  }
}
