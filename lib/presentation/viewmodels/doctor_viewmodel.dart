import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/usecases/get_all_patients_usecase.dart';

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
        page: _currentPage,
        size: 15,
      );
      if (_currentPage == 0) {
        _patients = result.content;
      } else {
        _patients.addAll(result.content);
      }
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _isLastPage = result.isLast;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
