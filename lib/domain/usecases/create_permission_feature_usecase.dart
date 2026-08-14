import '../../data/models/permission_catalog_model.dart';
import '../interface_repositories/permission_repository.dart';

class CreatePermissionFeatureUseCase {
  final PermissionRepository repository;

  CreatePermissionFeatureUseCase(this.repository);

  Future<PermissionFeatureModel> execute({
    required String name,
    String? description,
  }) {
    return repository.createFeature(name: name, description: description);
  }
}
