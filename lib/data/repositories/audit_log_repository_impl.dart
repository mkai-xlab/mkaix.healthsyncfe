import '../../domain/entities/audit_log_page_entity.dart';
import '../../domain/interface_repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_datasource.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogRemoteDataSource remoteDataSource;

  AuditLogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuditLogPageEntity> getAuditLogs({
    required String token,
    required int page,
    required int size,
  }) {
    return remoteDataSource.getAuditLogs(token: token, page: page, size: size);
  }
}
