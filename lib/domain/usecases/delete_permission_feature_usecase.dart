import '../interface_repositories/permission_repository.dart';

class DeletePermissionFeatureUseCase {
  final PermissionRepository repository;

  DeletePermissionFeatureUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.deleteFeature(id);
  }
}
