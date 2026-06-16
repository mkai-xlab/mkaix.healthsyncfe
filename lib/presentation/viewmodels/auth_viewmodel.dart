import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/interface_repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  AuthViewModel({required this.loginUseCase, required this.authRepository});

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Forgot / Reset password state
  bool _isForgotLoading = false;
  String? _forgotError;
  bool _forgotSuccess = false;

  bool _isResetLoading = false;
  String? _resetError;
  bool _resetSuccess = false;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isForgotLoading => _isForgotLoading;
  String? get forgotError => _forgotError;
  bool get forgotSuccess => _forgotSuccess;

  bool get isResetLoading => _isResetLoading;
  String? get resetError => _resetError;
  bool get resetSuccess => _resetSuccess;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await loginUseCase.execute(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Gửi email để nhận token đặt lại mật khẩu
  Future<bool> forgotPassword(String email) async {
    _isForgotLoading = true;
    _forgotError = null;
    _forgotSuccess = false;
    notifyListeners();

    try {
      await authRepository.forgotPassword(email);
      _forgotSuccess = true;
      _isForgotLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _forgotError = e.toString().replaceAll('Exception: ', '');
      _isForgotLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại mật khẩu bằng token từ email
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isResetLoading = true;
    _resetError = null;
    _resetSuccess = false;
    notifyListeners();

    try {
      await authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      _resetSuccess = true;
      _isResetLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _resetError = e.toString().replaceAll('Exception: ', '');
      _isResetLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset trạng thái forgot/reset để tái sử dụng
  void clearPasswordResetState() {
    _isForgotLoading = false;
    _forgotError = null;
    _forgotSuccess = false;
    _isResetLoading = false;
    _resetError = null;
    _resetSuccess = false;
    notifyListeners();
  }
}
