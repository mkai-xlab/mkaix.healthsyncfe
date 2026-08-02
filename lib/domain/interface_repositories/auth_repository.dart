import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  });
}
