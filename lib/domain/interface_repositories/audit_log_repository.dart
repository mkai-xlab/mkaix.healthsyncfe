import '../entities/audit_log_page_entity.dart';

abstract class AuditLogRepository {
  Future<AuditLogPageEntity> getAuditLogs({
    required String token,
    required int page,
    required int size,
  });
}
