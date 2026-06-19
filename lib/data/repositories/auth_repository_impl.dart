import '../../domain/entities/user_entity.dart';
import '../../domain/interface_repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> login(String email, String password) async {
    return await remoteDataSource.loginWithEmailAndPassword(email, password);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> forgotPassword(String email) async {
    await remoteDataSource.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await remoteDataSource.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    await remoteDataSource.changePassword(
      username: username,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
