import '../../data/models/role_model.dart';
import '../interface_repositories/admin_repository.dart';

class GetAdminRolesUseCase {
  final AdminRepository repository;

  GetAdminRolesUseCase(this.repository);

  Future<List<RoleModel>> execute({required String token}) {
    return repository.getRoles(token: token);
  }
}
