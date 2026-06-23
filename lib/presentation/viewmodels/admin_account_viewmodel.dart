import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/doctor_account_model.dart';

class AdminAccountViewModel extends ChangeNotifier {
  final AdminRemoteDataSource dataSource;
  AdminAccountViewModel(this.dataSource);

  List<DoctorAccountModel> _accounts = [];
  List<DoctorAccountModel> get accounts => _accounts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;

  // Debounce search
  Timer? _searchDebounce;
  String _currentSearchName = '';

  /// Tải trang đầu tiên (hoặc khi Pull-to-Refresh)
  Future<void> fetchFirstPage(String token) async {
    _currentPage = 0;
    _isLastPage = false;
    _isLoading = true;
    _errorMessage = null;
    _accounts.clear();
    notifyListeners();

    await _loadMoreData(token);
  }

  /// Tải các trang tiếp theo khi Admin cuộn xuống đáy
  Future<void> fetchNextPage(String token) async {
    if (_isLoading || _isLastPage) return;
    _isLoading = true;
    notifyListeners();

    _currentPage++;
    await _loadMoreData(token);
  }

  /// Tìm kiếm theo tên với debounce — gọi từ UI
  void searchByNameDebounced(String name, String token) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _currentSearchName = name.trim();
      _currentPage = 0;
      _isLastPage = false;
      _isLoading = true;
      _errorMessage = null;
      _accounts.clear();
      notifyListeners();
      _loadMoreData(token);
    });
  }

  /// Tạo tài khoản người dùng mới (POST /users)
  Future<bool> createUser({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.createUser(
        fullName: fullName,
        email: email,
        phone: phone,
        roleId: roleId,
        token: token,
      );
      _currentSearchName = '';
      await fetchFirstPage(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thay đổi trạng thái hoạt động của bác sĩ
  Future<bool> toggleDoctorStatus(int id, bool activate, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.toggleDoctorStatus(
        id: id,
        activate: activate,
        token: token,
      );
      await fetchFirstPage(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadMoreData(String token) async {
    try {
      final result = await dataSource.getDoctorAccounts(
        page: _currentPage,
        size: 15,
        token: token,
        name: _currentSearchName.isEmpty ? null : _currentSearchName,
      );
      final List<DoctorAccountModel> newAccounts =
          (result['content'] as List<DoctorAccountModel>?) ?? [];

      _accounts.addAll(newAccounts);
      _isLastPage = (result['isLast'] as bool?) ?? true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
