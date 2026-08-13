import '../interface_repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> execute({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return repository.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }
}
