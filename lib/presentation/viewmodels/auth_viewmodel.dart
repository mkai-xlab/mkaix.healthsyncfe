import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/interface_repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  AuthViewModel({required this.loginUseCase, required this.authRepository});

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // First-time login state
  bool _isFirstTimeLogin = false;
  String? _pendingUsername;
  String? _pendingOldPassword;

  // Forgot / Reset password state
  bool _isForgotLoading = false;
  String? _forgotError;
  bool _forgotSuccess = false;

  bool _isResetLoading = false;
  String? _resetError;
  bool _resetSuccess = false;

  // Change password state
  bool _isChangeLoading = false;
  String? _changeError;
  bool _changeSuccess = false;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isFirstTimeLogin => _isFirstTimeLogin;
  String? get pendingUsername => _pendingUsername;
  String? get pendingOldPassword => _pendingOldPassword;

  bool get isForgotLoading => _isForgotLoading;
  String? get forgotError => _forgotError;
  bool get forgotSuccess => _forgotSuccess;

  bool get isResetLoading => _isResetLoading;
  String? get resetError => _resetError;
  bool get resetSuccess => _resetSuccess;

  bool get isChangeLoading => _isChangeLoading;
  String? get changeError => _changeError;
  bool get changeSuccess => _changeSuccess;

  /// Đăng nhập — trả về true nếu thành công, false nếu lỗi thường,
  /// và set isFirstTimeLogin = true nếu cần đổi mật khẩu lần đầu
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isFirstTimeLogin = false;
    notifyListeners();

    try {
      _currentUser = await loginUseCase.execute(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirstTimeLoginException catch (e) {
      // Backend yêu cầu đổi mật khẩu lần đầu
      _isLoading = false;
      _isFirstTimeLogin = true;
      _pendingUsername = e.username;
      _pendingOldPassword = e.oldPassword;
      notifyListeners();
      return false;
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
    _isFirstTimeLogin = false;
    _pendingUsername = null;
    _pendingOldPassword = null;
    notifyListeners();
  }

  /// Đổi mật khẩu lần đầu đăng nhập
  Future<bool> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    _isChangeLoading = true;
    _changeError = null;
    _changeSuccess = false;
    notifyListeners();

    try {
      await authRepository.changePassword(
        username: username,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _isChangeLoading = false;
      _changeSuccess = true;
      _isFirstTimeLogin = false;
      _pendingUsername = null;
      _pendingOldPassword = null;
      notifyListeners();
      return true;
    } catch (e) {
      _changeError = e.toString().replaceAll('Exception: ', '');
      _isChangeLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearChangePasswordState() {
    _isChangeLoading = false;
    _changeError = null;
    _changeSuccess = false;
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
