import '../interface_repositories/admin_repository.dart';

class UpdateUserRoleUseCase {
  final AdminRepository repository;

  UpdateUserRoleUseCase(this.repository);

  Future<void> execute({
    required int userId,
    required int roleId,
    required String token,
  }) {
    return repository.updateUserRole(
      userId: userId,
      roleId: roleId,
      token: token,
    );
  }
}
