import '../interface_repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> execute({
    required String accessToken,
    required String refreshToken,
  }) {
    return repository.logout(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
