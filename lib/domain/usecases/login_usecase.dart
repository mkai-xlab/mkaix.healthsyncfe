import '../entities/user_entity.dart';
import '../interface_repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> execute(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email và mật khẩu không được để trống!');
    }
    return repository.login(email.trim(), password.trim());
  }
}
