import 'package:flutter/material.dart';

import '../../data/datasources/audit_log_remote_datasource.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../core/utils/error_message_utils.dart';

class AuditLogViewModel extends ChangeNotifier {
  final AuditLogRemoteDataSource remoteDataSource;

  AuditLogViewModel(this.remoteDataSource);

  List<AuditLogEntity> _logs = [];
  List<AuditLogEntity> get logs => List.unmodifiable(_logs);

  AuditLogEntity? _selectedLog;
  AuditLogEntity? get selectedLog => _selectedLog;

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

  Future<void> fetchFirstPage(String token) async {
    _currentPage = 0;
    await loadAuditLogs(token);
  }

  Future<void> loadAuditLogs(String token) async {
    if (token.trim().isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await remoteDataSource.getAuditLogs(
        token: token,
        page: _currentPage,
        size: _pageSize,
      );
      _logs = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages <= 0 ? 1 : result.totalPages;
      _currentPage = result.pageNumber;
      if (_selectedLog != null &&
          !_logs.any((log) => _logKey(log) == _logKey(_selectedLog!))) {
        _selectedLog = _logs.isEmpty ? null : _logs.first;
      }
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      _logs = [];
      _selectedLog = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(String token, int page) async {
    if (_isLoading) return;
    _currentPage = page
        .clamp(0, (_totalPages <= 0 ? 1 : _totalPages) - 1)
        .toInt();
    await loadAuditLogs(token);
  }

  Future<void> changePageSize(String token, int size) async {
    if (_pageSize == size) return;
    _pageSize = size;
    _currentPage = 0;
    await loadAuditLogs(token);
  }

  void selectLog(AuditLogEntity log) {
    _selectedLog = log;
    notifyListeners();
  }

  String _logKey(AuditLogEntity log) {
    if (log.id > 0) return 'id:${log.id}';
    return '${log.timeStamp?.toIso8601String()}|${log.username}|${log.title}';
  }
}
