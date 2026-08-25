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
  severeGrades,
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
        warningMessage: 'Không thể tải dữ liệu dashboard',
      );

  final GetPatientExaminationsUseCase getPatientExaminationsUseCase;

  ExaminationViewModel({required this.getPatientExaminationsUseCase});

  List<ExaminationEntity> _examinations = [];
  List<ExaminationEntity> get examinations => List.unmodifiable(_examinations);

  List<ExaminationEntity> _dashboardSevereExaminations = [];
  List<ExaminationEntity> get dashboardSevereExaminations =>
      List.unmodifiable(_dashboardSevereExaminations);

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
  bool _isPersonal = true;
  final Set<String> _selectedStatuses = {};
  Set<String> get selectedStatuses => Set.unmodifiable(_selectedStatuses);

  final Set<int> _selectedGrades = {};
  Set<int> get selectedGrades => Set.unmodifiable(_selectedGrades);

  String? _selectedSort;
  String? get selectedSort => _selectedSort;

  DateTime? _filterDate;
  DateTime? get filterDate => _filterDate;

  Future<void> loadExaminations({
    required String token,
    bool isPersonal = true,
  }) async {
    _isPersonal = isPersonal;
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
        isPersonal: _isPersonal,
        statuses: _selectedStatuses.toList()..sort(),
        grades: _selectedGrades.toList()..sort(),
        sort: _selectedSort,
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

  Future<void> loadDashboardExaminations({
    required String token,
    bool isPersonal = true,
  }) async {
    _isPersonal = isPersonal;
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _dashboardSevereExaminations = [];
    _dashboardTotals = null;
    _patientGradeStats = [];
    _dailyLast7DaysStats = [];
    _selectedExamination = null;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final dashboardTotals = await getPatientExaminationsUseCase
          .executeMyDashboardTotals(token: token, isPersonal: _isPersonal);
      _totalElements = dashboardTotals.total;
      _totalPages = 1;
      _currentPage = 0;
      _dashboardTotals = dashboardTotals;
      final totalWarning = dashboardTotals.warningMessage;
      if (totalWarning != null && totalWarning.isNotEmpty) {
        _errorMessage = totalWarning;
      }

      try {
        final recentPage = await getPatientExaminationsUseCase.executeAllPage(
          token: token,
          page: 0,
          size: 5,
          mode: ExaminationListMode.all.name,
          direction: 'desc',
          isPersonal: _isPersonal,
        );
        _examinations = recentPage.content;
      } catch (e) {
        final recentError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, recentError);
        _examinations = [];
      }

      try {
        final severePage = await getPatientExaminationsUseCase.executeAllPage(
          token: token,
          page: 0,
          size: 3,
          mode: ExaminationListMode.all.name,
          direction: 'desc',
          isPersonal: _isPersonal,
          grades: const [3, 4],
        );
        _dashboardSevereExaminations = severePage.content;
      } catch (e) {
        final severeError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, severeError);
        _dashboardSevereExaminations = [];
      }

      try {
        _patientGradeStats = await getPatientExaminationsUseCase
            .executePatientGradeStatistics(
              token: token,
              isPersonal: _isPersonal,
            );
      } catch (e) {
        final gradeError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, gradeError);
        _patientGradeStats = [];
      }

      try {
        _dailyLast7DaysStats = await getPatientExaminationsUseCase
            .executeDailyLast7DaysStatistics(
              token: token,
              isPersonal: _isPersonal,
            );
      } catch (e) {
        final dailyError = userFriendlyErrorMessage(e);
        _errorMessage = _appendDashboardError(_errorMessage, dailyError);
        _dailyLast7DaysStats = [];
      }
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      _examinations = [];
      _dashboardSevereExaminations = [];
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
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> changePageSize({
    required String token,
    required int size,
  }) async {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> applyListMode({
    required String token,
    required ExaminationListMode mode,
    DateTime? date,
    bool? isPersonal,
  }) async {
    _listMode = mode;
    _filterDate = date;
    if (_isSortMode(mode)) {
      _selectedStatuses.clear();
      _selectedGrades.clear();
      _selectedSort = _sortValueForMode(mode);
    } else if (mode.name.startsWith('status')) {
      _selectedGrades.clear();
      _selectedStatuses
        ..clear()
        ..add(_statusValueForMode(mode));
    } else if (mode == ExaminationListMode.severeGrades) {
      _selectedStatuses.clear();
      _selectedGrades
        ..clear()
        ..addAll(const [3, 4]);
    } else if (mode.name.startsWith('grade')) {
      _selectedStatuses.clear();
      final grade = int.tryParse(mode.name.replaceFirst('grade', ''));
      _selectedGrades
        ..clear()
        ..addAll([?grade]);
    }
    _currentPage = 0;
    if (isPersonal != null) _isPersonal = isPersonal;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> clearListMode({required String token, bool? isPersonal}) async {
    _listMode = ExaminationListMode.all;
    _filterDate = null;
    _selectedStatuses.clear();
    _selectedGrades.clear();
    _selectedSort = null;
    _currentPage = 0;
    if (isPersonal != null) _isPersonal = isPersonal;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> applySort({
    required String token,
    required ExaminationListMode mode,
  }) async {
    if (!_isSortMode(mode)) return;
    _listMode = mode;
    _selectedSort = _sortValueForMode(mode);
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> clearSort({required String token}) async {
    _listMode = ExaminationListMode.all;
    _selectedSort = null;
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> clearFilters({required String token}) async {
    _listMode = ExaminationListMode.all;
    _selectedStatuses.clear();
    _selectedGrades.clear();
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> toggleStatusFilter({
    required String token,
    required String status,
  }) async {
    if (_selectedStatuses.contains(status)) {
      _selectedStatuses.remove(status);
    } else {
      _selectedStatuses.add(status);
    }
    _listMode = ExaminationListMode.all;
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  Future<void> toggleGradeFilter({
    required String token,
    required int grade,
  }) async {
    if (_selectedGrades.contains(grade)) {
      _selectedGrades.remove(grade);
    } else {
      _selectedGrades.add(grade);
    }
    _listMode = ExaminationListMode.all;
    _currentPage = 0;
    await loadExaminations(token: token, isPersonal: _isPersonal);
  }

  bool _isSortMode(ExaminationListMode mode) {
    return mode == ExaminationListMode.studyDateAsc ||
        mode == ExaminationListMode.studyDateDesc ||
        mode == ExaminationListMode.uploadDateAsc ||
        mode == ExaminationListMode.uploadDateDesc;
  }

  String? _sortValueForMode(ExaminationListMode mode) {
    switch (mode) {
      case ExaminationListMode.studyDateAsc:
        return 'studyDate,asc';
      case ExaminationListMode.studyDateDesc:
        return 'studyDate,desc';
      case ExaminationListMode.uploadDateAsc:
        return 'createdAt,asc';
      case ExaminationListMode.uploadDateDesc:
        return 'createdAt,desc';
      default:
        return null;
    }
  }

  String _statusValueForMode(ExaminationListMode mode) {
    switch (mode) {
      case ExaminationListMode.statusAiProcessing:
        return 'AI_PROCESSING';
      case ExaminationListMode.statusAiFailed:
        return 'AI_FAILED';
      case ExaminationListMode.statusNeedVerify:
        return 'NEED_VERIFY';
      case ExaminationListMode.statusVerified:
        return 'VERIFIED';
      case ExaminationListMode.statusReportGenerated:
        return 'REPORT_GENERATED';
      default:
        return '';
    }
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
      _detailErrorMessage = 'Không tìm thấy examinationId hợp lệ';
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
        } catch (_) {}
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
    _dashboardSevereExaminations = _dashboardSevereExaminations.map((item) {
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
    _dashboardSevereExaminations = [];
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
    _selectedStatuses.clear();
    _selectedGrades.clear();
    _selectedSort = null;
    notifyListeners();
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
