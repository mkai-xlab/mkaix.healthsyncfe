import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/interface_repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardRemoteDataSource remoteDataSource;

  AdminDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminDashboardStatsEntity> getStats({required String token}) {
    return remoteDataSource.getStats(token: token);
  }
}
