import '../interface_repositories/permission_repository.dart';

class DeletePermissionUseCase {
  final PermissionRepository repository;

  DeletePermissionUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.deletePermission(id);
  }
}
