import 'package:flutter/material.dart';

import '../../domain/entities/examination_dashboard_totals_entity.dart';
import '../../domain/entities/daily_examination_stat_entity.dart';
import '../../domain/entities/examination_entity.dart';
import '../../domain/entities/patient_grade_stats_entity.dart';
import '../../domain/usecases/get_patient_examinations_usecase.dart';
import '../../core/utils/error_message_utils.dart';

enum ExaminationListMode {
  all,
  studyDateDesc,
  studyDateAsc,
  uploadDateDesc,
  uploadDateAsc,
  studyDateFilter,
  uploadDateFilter,
  grade0,
  grade1,
  grade2,
  grade3,
  grade4,
  statusAiProcessing,
  statusAiFailed,
  statusNeedVerify,
  statusVerified,
  statusReportGenerated,
}

class ExaminationViewModel extends ChangeNotifier {
  static const ExaminationDashboardTotalsEntity _emptyDashboardTotals =
      ExaminationDashboardTotalsEntity(
        total: 0,
        verified: 0,
        unverified: 0,
        severe: 0,
        warningMessage: 'Khong the tai so lieu dashboard',
      );

  final GetPatientExaminationsUseCase getPatientExaminationsUseCase;

  ExaminationViewModel({required this.getPatientExaminationsUseCase});

  List<ExaminationEntity> _examinations = [];
  List<ExaminationEntity> get examinations => List.unmodifiable(_examinations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ExaminationEntity? _selectedExamination;
  ExaminationEntity? get selectedExamination => _selectedExamination;

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _pageSize = 10;
  int get pageSize => _pageSize;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  ExaminationDashboardTotalsEntity? _dashboardTotals;
  ExaminationDashboardTotalsEntity? get dashboardTotals => _dashboardTotals;

  List<PatientGradeStatsEntity> _patientGradeStats = [];
  List<PatientGradeStatsEntity> get patientGradeStats =>
      List.unmodifiable(_patientGradeStats);

  List<DailyExaminationStatEntity> _dailyLast7DaysStats = [];
  List<DailyExaminationStatEntity> get dailyLast7DaysStats =>
      List.unmodifiable(_dailyLast7DaysStats);

  int _totalPages = 1;
  int get totalPages => _totalPages;

  ExaminationListMode _listMode = ExaminationListMode.all;
  ExaminationListMode get listMode => _listMode;

  DateTime? _filterDate;
  DateTime? get filterDate => _filterDate;

  Future<void> loadExaminations({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _selectedExamination = null;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final result = await getPatientExaminationsUseCase.executeAllPage(
        token: token,
        page: _currentPage,
        size: _pageSize,
        mode: _listMode.name,
        direction: _listMode.name.endsWith('Asc') ? 'asc' : 'desc',
        date: _filterDate == null ? null : _formatApiDate(_filterDate!),
        isPersonal: true,
      );
      _examinations = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _currentPage = result.pageNumber;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardExaminations({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _dashboardTotals = null;
    _patientGradeStats = [];
    _dailyLast7DaysStats = [];
    _selectedExamination = null;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final dashboardTotals = await getPatientExaminationsUseCase
          .executeMyDashboardTotals(token: token);
      _totalElements = dashboardTotals.total;
      _totalPages = 1;
      _currentPage = 0;
      _dashboardTotals = dashboardTotals;
      final totalWarning = dashboardTotals.warningMessage;
      if (totalWarning != null && totalWarning.isNotEmpty) {
        _errorMessage = totalWarning;
      }

      try {
        final recentPage = await getPatientExaminationsUseCase
            .executeMyRecentPage(token: token, page: 0, size: 5);
        _examinations = recentPage.content;
      } catch (e) {
        final recentError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, recentError);
        _examinations = [];
      }

      try {
        _patientGradeStats = await getPatientExaminationsUseCase
            .executePatientGradeStatistics(token: token, isPersonal: true);
      } catch (e) {
        final gradeError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, gradeError);
        _patientGradeStats = [];
      }

      try {
        _dailyLast7DaysStats = await getPatientExaminationsUseCase
            .executeDailyLast7DaysStatistics(token: token, isPersonal: true);
      } catch (e) {
        final dailyError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, dailyError);
        _dailyLast7DaysStats = [];
      }
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      _examinations = [];
      _patientGradeStats = [];
      _dailyLast7DaysStats = [];
      _totalElements = 0;
      _totalPages = 1;
      _currentPage = 0;
      _dashboardTotals = _emptyDashboardTotals;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _appendDashboardError(String? current, String next) {
    if (current == null || current.isEmpty) return next;
    if (next.isEmpty || current.contains(next)) return current;
    return '$current\n$next';
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

  Future<void> applyListMode({
    required String token,
    required ExaminationListMode mode,
    DateTime? date,
  }) async {
    _listMode = mode;
    _filterDate = date;
    _currentPage = 0;
    await loadExaminations(token: token);
  }

  Future<void> clearListMode({required String token}) async {
    _listMode = ExaminationListMode.all;
    _filterDate = null;
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
    _selectedExamination = null;
    _detailErrorMessage = null;
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
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientExaminations({
    required String patientId,
    required String token,
    int? page,
    int? size,
  }) async {
    if (page != null) _currentPage = page;
    if (size != null) _pageSize = size;
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _selectedExamination = null;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final result = await getPatientExaminationsUseCase.executePatientPage(
        patientId: patientId,
        token: token,
        page: _currentPage,
        size: _pageSize,
      );
      _examinations = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
      _currentPage = result.pageNumber;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPatientPage({
    required String patientId,
    required String token,
    required int page,
  }) async {
    if (_isLoading) return;
    final safePage = page
        .clamp(0, (_totalPages <= 0 ? 1 : _totalPages) - 1)
        .toInt();
    await loadPatientExaminations(
      patientId: patientId,
      token: token,
      page: safePage,
    );
  }

  Future<void> changePatientPageSize({
    required String patientId,
    required String token,
    required int size,
  }) async {
    if (_pageSize == size) return;
    await loadPatientExaminations(
      patientId: patientId,
      token: token,
      page: 0,
      size: size,
    );
  }

  Future<bool> openExaminationDetail({
    required ExaminationEntity examination,
    required String token,
  }) async {
    final examinationId = examination.examinationId;
    _selectedExamination = examination;
    _detailErrorMessage = null;

    if (examinationId <= 0) {
      _detailErrorMessage = 'Khong tim thay examinationId hop le';
      notifyListeners();
      return true;
    }

    _isLoadingDetail = true;
    notifyListeners();

    try {
      if (!examination.isViewed) {
        try {
          await getPatientExaminationsUseCase.executeMarkViewed(
            examinationId: examinationId,
            token: token,
          );
          _markExaminationViewedLocally(examinationId);
        } catch (e) {
          debugPrint('[Examination mark viewed] ignored error: $e');
        }
      }

      final detail = await getPatientExaminationsUseCase.executeDetail(
        examinationId: examinationId,
        token: token,
      );
      _selectedExamination = detail.copyWith(isViewed: true);
      _markExaminationViewedLocally(examinationId);
      return true;
    } catch (e) {
      _detailErrorMessage = userFriendlyErrorMessage(e);
      return true;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void _markExaminationViewedLocally(int examinationId) {
    _examinations = _examinations.map((item) {
      if (item.examinationId != examinationId || item.isViewed) return item;
      return item.copyWith(isViewed: true);
    }).toList();
    final selected = _selectedExamination;
    if (selected != null &&
        selected.examinationId == examinationId &&
        !selected.isViewed) {
      _selectedExamination = selected.copyWith(isViewed: true);
    }
  }

  void closeExaminationDetail() {
    _selectedExamination = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clear() {
    _examinations = [];
    _errorMessage = null;
    _selectedExamination = null;
    _detailErrorMessage = null;
    _totalElements = 0;
    _totalPages = 1;
    _currentPage = 0;
    _dashboardTotals = null;
    _patientGradeStats = [];
    _dailyLast7DaysStats = [];
    _listMode = ExaminationListMode.all;
    _filterDate = null;
    notifyListeners();
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
