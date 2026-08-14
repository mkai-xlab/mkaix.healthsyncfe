import '../entities/admin_dashboard_stats_entity.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardStatsEntity> getStats({required String token});
}
