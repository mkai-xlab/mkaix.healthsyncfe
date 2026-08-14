import '../../data/models/permission_model.dart';
import '../interface_repositories/permission_repository.dart';

class CreatePermissionUseCase {
  final PermissionRepository repository;

  CreatePermissionUseCase(this.repository);

  Future<PermissionModel> execute({
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) {
    return repository.createPermission(
      code: code,
      name: name,
      featureId: featureId,
      priority: priority,
      requiresPermissionId: requiresPermissionId,
    );
  }
}
