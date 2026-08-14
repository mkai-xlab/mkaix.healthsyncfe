import 'package:flutter/material.dart';

import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/usecases/get_admin_dashboard_stats_usecase.dart';
import '../../core/utils/error_message_utils.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final GetAdminDashboardStatsUseCase getStatsUseCase;

  AdminDashboardViewModel(this.getStatsUseCase);

  AdminDashboardStatsEntity _stats = AdminDashboardStatsEntity.empty;
  AdminDashboardStatsEntity get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats(String token) async {
    if (token.trim().isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await getStatsUseCase.execute(token: token);
      _errorMessage = _stats.warningMessage;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      _stats = AdminDashboardStatsEntity.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _stats = AdminDashboardStatsEntity.empty;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
