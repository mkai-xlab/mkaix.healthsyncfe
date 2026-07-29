import 'audit_log_entity.dart';

class AuditLogPageEntity {
  final List<AuditLogEntity> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool isLast;

  const AuditLogPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
    required this.isLast,
  });
}
