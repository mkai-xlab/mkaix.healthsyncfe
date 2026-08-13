import '../../data/models/permission_model.dart';
import '../interface_repositories/permission_repository.dart';

class UpdatePermissionUseCase {
  final PermissionRepository repository;

  UpdatePermissionUseCase(this.repository);

  Future<PermissionModel> execute({
    required String id,
    required String code,
    required String name,
    required String featureId,
    int? priority,
    String? requiresPermissionId,
  }) {
    return repository.updatePermission(
      id: id,
      code: code,
      name: name,
      featureId: featureId,
      priority: priority,
      requiresPermissionId: requiresPermissionId,
    );
  }
}
