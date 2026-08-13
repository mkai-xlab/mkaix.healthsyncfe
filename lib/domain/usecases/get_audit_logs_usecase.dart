import '../entities/audit_log_page_entity.dart';
import '../interface_repositories/audit_log_repository.dart';

class GetAuditLogsUseCase {
  final AuditLogRepository repository;

  GetAuditLogsUseCase(this.repository);

  Future<AuditLogPageEntity> execute({
    required String token,
    required int page,
    required int size,
  }) {
    return repository.getAuditLogs(token: token, page: page, size: size);
  }
}
