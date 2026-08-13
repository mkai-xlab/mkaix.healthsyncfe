import '../entities/admin_dashboard_stats_entity.dart';
import '../interface_repositories/admin_dashboard_repository.dart';

class GetAdminDashboardStatsUseCase {
  final AdminDashboardRepository repository;

  GetAdminDashboardStatsUseCase(this.repository);

  Future<AdminDashboardStatsEntity> execute({required String token}) {
    return repository.getStats(token: token);
  }
}
