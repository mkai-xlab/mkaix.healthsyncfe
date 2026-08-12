import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/role_model.dart';
import '../../domain/entities/doctor_account_entity.dart';
import '../../core/utils/error_message_utils.dart';

class AdminAccountViewModel extends ChangeNotifier {
  final AdminRemoteDataSource dataSource;
  AdminAccountViewModel(this.dataSource);

  final List<DoctorAccountEntity> _accounts = [];
  List<DoctorAccountEntity> get accounts => List.unmodifiable(_accounts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _pageSize = 10;
  int get pageSize => _pageSize;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;

  Timer? _searchDebounce;
  String _currentSearchName = '';
  String? _currentStatus;
  String? get currentStatus => _currentStatus;

  Future<void> fetchFirstPage(String token) async {
    _currentPage = 0;
    _isLastPage = false;
    _isLoading = true;
    _errorMessage = null;
    _accounts.clear();
    notifyListeners();

    await _loadMoreData(token);
  }

  Future<void> fetchNextPage(String token) async {
    if (_isLoading || _isLastPage) return;
    _isLoading = true;
    notifyListeners();

    _currentPage++;
    await _loadMoreData(token);
  }

  Future<void> goToPage(String token, int page) async {
    if (_isLoading) return;
    final safePage = page
        .clamp(0, (_totalPages <= 0 ? 1 : _totalPages) - 1)
        .toInt();
    if (safePage == _currentPage && _accounts.isNotEmpty) return;
    _currentPage = safePage;
    _accounts.clear();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _loadMoreData(token);
  }

  Future<void> changePageSize(String token, int size) async {
    if (_pageSize == size) return;
    _pageSize = size;
    await fetchFirstPage(token);
  }

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

  Future<void> filterByStatus(String? status, String token) async {
    final normalized = status?.trim();
    _currentStatus = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    _currentPage = 0;
    _isLastPage = false;
    _isLoading = true;
    _errorMessage = null;
    _accounts.clear();
    notifyListeners();
    await _loadMoreData(token);
  }

  Future<bool> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.createDoctor(doctorData: doctorData, token: token);
      return true;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDoctorSilently({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    _errorMessage = null;

    try {
      await dataSource.createDoctor(doctorData: doctorData, token: token);
      return true;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      return false;
    }
  }

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
      _errorMessage = userFriendlyErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<RoleModel>> getRoles(String token) {
    return dataSource.getRoles(token: token);
  }

  Future<bool> toggleDoctorStatus(
    int id,
    bool activate,
    String token, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.toggleDoctorStatus(
        id: id,
        activate: activate,
        token: token,
        reason: reason,
      );
      await fetchFirstPage(token);
      return true;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
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
        size: _pageSize,
        token: token,
        name: _currentSearchName.isEmpty ? null : _currentSearchName,
        status: _currentStatus,
      );

      _accounts
        ..clear()
        ..addAll(result.content);
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _isLastPage = result.isLast;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
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
