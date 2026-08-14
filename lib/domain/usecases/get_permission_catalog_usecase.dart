import '../../data/models/permission_catalog_model.dart';
import '../interface_repositories/permission_repository.dart';

class GetPermissionCatalogUseCase {
  final PermissionRepository repository;

  GetPermissionCatalogUseCase(this.repository);

  Future<PermissionCatalogModel> execute() {
    return repository.getPermissionCatalog();
  }
}
