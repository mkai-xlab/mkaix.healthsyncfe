import 'package:flutter/material.dart';

import '../../domain/entities/examination_entity.dart';
import '../../domain/usecases/get_patient_examinations_usecase.dart';

class ExaminationViewModel extends ChangeNotifier {
  final GetPatientExaminationsUseCase getPatientExaminationsUseCase;

  ExaminationViewModel({required this.getPatientExaminationsUseCase});

  List<ExaminationEntity> _examinations = [];
  List<ExaminationEntity> get examinations => List.unmodifiable(_examinations);

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

  int? _dashboardSevereTotal;
  int? get dashboardSevereTotal => _dashboardSevereTotal;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  Future<void> loadExaminations({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    notifyListeners();

    try {
      final result = await getPatientExaminationsUseCase.executeAllPage(
        token: token,
        page: _currentPage,
        size: _pageSize,
      );
      _examinations = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _currentPage = result.pageNumber;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardExaminations({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _dashboardSevereTotal = null;
    notifyListeners();

    try {
      final pageResult = await getPatientExaminationsUseCase.executeAllPage(
        token: token,
        page: 0,
        size: 5,
      );
      final severeTotal = await getPatientExaminationsUseCase
          .executeMyTotalSevere(token: token);
      _examinations = pageResult.content;
      _totalElements = pageResult.totalElements;
      _totalPages = pageResult.totalPages;
      _currentPage = pageResult.pageNumber;
      _pageSize = pageResult.pageSize;
      _dashboardSevereTotal = severeTotal;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage({required String token, required int page}) async {
    if (_isLoading) return;
    _currentPage = page
        .clamp(0, (_totalPages <= 0 ? 1 : _totalPages) - 1)
        .toInt();
    await loadExaminations(token: token);
  }

  Future<void> changePageSize({
    required String token,
    required int size,
  }) async {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 0;
    await loadExaminations(token: token);
  }

  Future<void> loadDoctorExaminations({
    required String doctorId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    notifyListeners();

    try {
      final parsedDoctorId = int.tryParse(doctorId);
      if (parsedDoctorId == null || parsedDoctorId <= 0) {
        throw Exception('Không tìm thấy doctorId hợp lệ để tải ca khám');
      }
      _examinations = await getPatientExaminationsUseCase.executeDoctor(
        doctorId: parsedDoctorId,
        token: token,
      );
      _totalElements = _examinations.length;
      _totalPages = 1;
      _currentPage = 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientExaminations({
    required String patientId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    notifyListeners();

    try {
      _examinations = await getPatientExaminationsUseCase.execute(
        patientId: patientId,
        token: token,
      );
      _totalElements = _examinations.length;
      _totalPages = 1;
      _currentPage = 0;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _examinations = [];
    _errorMessage = null;
    _totalElements = 0;
    _totalPages = 1;
    _currentPage = 0;
    notifyListeners();
  }
}
