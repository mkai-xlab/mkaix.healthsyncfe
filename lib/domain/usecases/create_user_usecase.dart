import '../interface_repositories/admin_repository.dart';

class CreateUserUseCase {
  final AdminRepository repository;

  CreateUserUseCase(this.repository);

  Future<void> execute({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  }) {
    return repository.createUser(
      fullName: fullName,
      email: email,
      phone: phone,
      roleId: roleId,
      token: token,
    );
  }
}
