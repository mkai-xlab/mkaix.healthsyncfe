import '../../data/models/role_model.dart';
import '../interface_repositories/permission_repository.dart';

class GetPermissionRolesUseCase {
  final PermissionRepository repository;

  GetPermissionRolesUseCase(this.repository);

  Future<List<RoleModel>> execute() {
    return repository.getRoles();
  }
}
