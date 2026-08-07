import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/usecases/get_all_patients_usecase.dart';
import '../../core/utils/error_message_utils.dart';

class DoctorViewModel extends ChangeNotifier {
  final GetAllPatientsUseCase getAllPatientsUseCase;
  DoctorViewModel({required this.getAllPatientsUseCase});

  List<PatientEntity> _patients = [];
  List<PatientEntity> get patients => _patients;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  bool _isLastPage = true;
  bool get isLastPage => _isLastPage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _pageSize = 10;
  int get pageSize => _pageSize;

  // Filter state
  String _filterFullName = '';
  String _filterPatientCode = '';
  String _filterGender = '';

  // Debounce
  Timer? _debounce;

  /// Load trang đầu (hoặc refresh)
  Future<void> fetchFirstPage({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
  }) async {
    _currentPage = 0;
    _patients.clear();
    _isLastPage = false;
    _errorMessage = null;

    if (fullName != null) _filterFullName = fullName;
    if (patientCode != null) _filterPatientCode = patientCode;
    if (gender != null) _filterGender = gender;

    _isLoading = true;
    notifyListeners();
    await _load(token);
  }

  /// Load thêm trang tiếp theo
  Future<void> fetchNextPage(String token) async {
    if (_isLoading || _isLastPage) return;
    _currentPage++;
    _isLoading = true;
    notifyListeners();
    await _load(token);
  }

  Future<void> goToPage(String token, int page) async {
    if (_isLoading) return;
    final safePage = page
        .clamp(0, (_totalPages <= 0 ? 1 : _totalPages) - 1)
        .toInt();
    if (safePage == _currentPage && _patients.isNotEmpty) return;
    _currentPage = safePage;
    _patients.clear();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _load(token);
  }

  Future<void> changePageSize(String token, int size) async {
    if (_pageSize == size) return;
    _pageSize = size;
    await fetchFirstPage(token: token);
  }

  /// Tìm kiếm debounce 500ms theo tên
  void searchByNameDebounced(String name, String token) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchFirstPage(token: token, fullName: name);
    });
  }

  Future<void> _load(String token) async {
    try {
      final result = await getAllPatientsUseCase.execute(
        token: token,
        fullName: _filterFullName.isEmpty ? null : _filterFullName,
        patientCode: _filterPatientCode.isEmpty ? null : _filterPatientCode,
        gender: _filterGender.isEmpty ? null : _filterGender,
        isPersonal: true,
        page: _currentPage,
        size: _pageSize,
      );
      if (_currentPage == 0) {
        _patients = result.content;
      } else {
        _patients = result.content;
      }
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _isLastPage = result.isLast;
      _currentPage = result.pageNumber;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFilters(String token) {
    _filterFullName = '';
    _filterPatientCode = '';
    _filterGender = '';
    fetchFirstPage(token: token);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
