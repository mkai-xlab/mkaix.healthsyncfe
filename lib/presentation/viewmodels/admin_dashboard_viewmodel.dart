import 'package:flutter/material.dart';

import '../../data/datasources/admin_dashboard_remote_datasource.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final AdminDashboardRemoteDataSource remoteDataSource;

  AdminDashboardViewModel(this.remoteDataSource);

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
      _stats = await remoteDataSource.getStats(token: token);
      _errorMessage = _stats.warningMessage;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _stats = AdminDashboardStatsEntity.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
