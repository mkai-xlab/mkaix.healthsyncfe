import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../domain/entities/doctor_account_entity.dart';

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
  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;

  Timer? _searchDebounce;
  String _currentSearchName = '';

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

  Future<bool> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.createDoctor(doctorData: doctorData, token: token);
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

      _accounts.addAll(result.content);
      _isLastPage = result.isLast;
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
