import '../../data/models/permission_catalog_model.dart';
import '../interface_repositories/permission_repository.dart';

class UpdatePermissionFeatureUseCase {
  final PermissionRepository repository;

  UpdatePermissionFeatureUseCase(this.repository);

  Future<PermissionFeatureModel> execute({
    required String id,
    required String name,
    String? description,
  }) {
    return repository.updateFeature(
      id: id,
      name: name,
      description: description,
    );
  }
}
