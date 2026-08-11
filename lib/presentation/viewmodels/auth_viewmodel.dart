import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/services/toast_service.dart';
import '../../core/services/session_storage_service.dart';
import '../../core/utils/permission_utils.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/interface_repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../core/utils/error_message_utils.dart';

class AuthViewModel extends ChangeNotifier {
  static const Duration _sessionDuration = Duration(minutes: 14);
  static const Duration _firstWarningBeforeExpiry = Duration(seconds: 60);
  static const Duration _secondWarningBeforeExpiry = Duration(seconds: 30);
  static const String _sessionStartedAtKey = 'sessionStartedAt';

  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;
  final SessionStorageService sessionStorage;

  AuthViewModel({
    required this.loginUseCase,
    required this.authRepository,
    SessionStorageService? sessionStorage,
  }) : sessionStorage = sessionStorage ?? SessionStorageService();

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPersonalView = true;
  DateTime? _sessionStartedAt;
  Timer? _sessionExpiryTimer;
  Timer? _sessionFirstWarningTimer;
  Timer? _sessionSecondWarningTimer;

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
  bool get isPersonalView =>
      _currentUser?.isDepartmentHead == true ? _isPersonalView : true;

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

  bool hasPermissionKey(String key) {
    final user = _currentUser;
    if (user == null) return false;
    return user.permissionItems.any((permission) {
      return permissionMatchesKey(permission, key);
    });
  }

  bool hasPermissionPresentation(String presentation) {
    return hasPermissionKey(presentation);
  }

  void setPersonalView(bool value) {
    if (_currentUser?.isDepartmentHead != true) return;
    if (_isPersonalView == value) return;
    _isPersonalView = value;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    try {
      final raw = await sessionStorage.readUserJson();
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await sessionStorage.clearUser();
        return;
      }

      final user = UserModel.fromJson(decoded);
      if (user.token.trim().isEmpty) {
        await sessionStorage.clearUser();
        return;
      }

      final storedSessionStartedAt = DateTime.tryParse(
        decoded[_sessionStartedAtKey]?.toString() ?? '',
      );
      final sessionStartedAt = storedSessionStartedAt ?? DateTime.now();
      if (_isSessionExpired(sessionStartedAt)) {
        await sessionStorage.clearUser();
        return;
      }

      _currentUser = user;
      if (_currentUser?.isDepartmentHead != true) {
        _isPersonalView = true;
      }
      _sessionStartedAt = sessionStartedAt;
      _scheduleSessionTimers(sessionStartedAt);
      notifyListeners();
    } catch (_) {
      await sessionStorage.clearUser();
    }
  }

  /// Đăng nhập — trả về true nếu thành công, false nếu lỗi thường,
  /// và set isFirstTimeLogin = true nếu cần đổi mật khẩu lần đầu
  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _isFirstTimeLogin = false;
    notifyListeners();

    try {
      _currentUser = await loginUseCase.execute(email, password);
      _isPersonalView = true;
      _sessionStartedAt = DateTime.now();
      await sessionStorage.saveUserJson(jsonEncode(_userToJson(_currentUser!)));
      _scheduleSessionTimers(_sessionStartedAt!);
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
      _errorMessage = userFriendlyErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _cancelSessionTimers();
    final accessToken = _currentUser?.token ?? '';
    final refreshToken = _currentUser?.refreshToken ?? '';
    try {
      await authRepository.logout(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {}
    await sessionStorage.clearAll();
    _currentUser = null;
    _isPersonalView = true;
    _sessionStartedAt = null;
    _errorMessage = null;
    _isFirstTimeLogin = false;
    _pendingUsername = null;
    _pendingOldPassword = null;
    notifyListeners();
  }

  Map<String, dynamic> _userToJson(UserEntity user) {
    return {
      'id': user.id,
      'username': user.username,
      'fullName': user.fullName,
      'token': user.token,
      'refreshToken': user.refreshToken,
      'avatarUrl': user.avatarUrl,
      'roles': user.roles,
      'permissions': user.permissionItems.isNotEmpty
          ? user.permissionItems
                .map(
                  (permission) => {
                    'id': permission.id,
                    'name': permission.name,
                    'code': permission.code,
                    'presentation': permission.presentation,
                    'description': permission.description,
                    'parentId': permission.parentId,
                    'priority': permission.priority,
                  },
                )
                .toList()
          : user.permissions,
      _sessionStartedAtKey: (_sessionStartedAt ?? DateTime.now())
          .toIso8601String(),
    };
  }

  bool _isSessionExpired(DateTime startedAt) {
    return DateTime.now().difference(startedAt) >= _sessionDuration;
  }

  void _scheduleSessionTimers(DateTime startedAt) {
    _cancelSessionTimers();
    final expiresAt = startedAt.add(_sessionDuration);
    _sessionFirstWarningTimer = _scheduleTimerAt(
      expiresAt.subtract(_firstWarningBeforeExpiry),
      () => AppToast.showWarning(
        'Phiên đăng nhập sẽ hết hạn sau 60 giây. Vui lòng đăng nhập lại sau khi hệ thống tự thoát.',
      ),
    );
    _sessionSecondWarningTimer = _scheduleTimerAt(
      expiresAt.subtract(_secondWarningBeforeExpiry),
      () => AppToast.showWarning(
        'Phiên đăng nhập sẽ hết hạn sau 30 giây. Vui lòng đăng nhập lại sau khi hệ thống tự thoát.',
      ),
    );
    _sessionExpiryTimer = _scheduleTimerAt(expiresAt, _logoutExpiredSession);
  }

  Timer? _scheduleTimerAt(DateTime target, VoidCallback callback) {
    final delay = target.difference(DateTime.now());
    if (delay <= Duration.zero) {
      callback();
      return null;
    }
    return Timer(delay, callback);
  }

  void _cancelSessionTimers() {
    _sessionExpiryTimer?.cancel();
    _sessionFirstWarningTimer?.cancel();
    _sessionSecondWarningTimer?.cancel();
    _sessionExpiryTimer = null;
    _sessionFirstWarningTimer = null;
    _sessionSecondWarningTimer = null;
  }

  Future<void> _logoutExpiredSession() async {
    await logout();
    AppToast.showWarning(
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để tiếp tục.',
    );
  }

  /// Đổi mật khẩu lần đầu đăng nhập
  @override
  void dispose() {
    _cancelSessionTimers();
    super.dispose();
  }

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
      _changeError = userFriendlyErrorMessage(e);
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
      _forgotError = userFriendlyErrorMessage(e);
      _isForgotLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại mật khẩu bằng token từ email
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _isResetLoading = true;
    _resetError = null;
    _resetSuccess = false;
    notifyListeners();

    try {
      await authRepository.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      _resetSuccess = true;
      _isResetLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _resetError = userFriendlyErrorMessage(e);
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
