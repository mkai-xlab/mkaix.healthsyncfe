import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    required super.action,
    super.actorUsername,
    super.actorFullName,
    super.actorRole,
    super.targetType,
    super.targetId,
    super.description,
    super.status,
    super.ipAddress,
    super.device,
    super.createdAt,
    super.rawData,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    final actor = _mapValue(json['actor']) ?? _mapValue(json['user']);
    final target = _mapValue(json['target']) ?? _mapValue(json['resource']);
    final rawStatus =
        json['status'] ??
        json['result'] ??
        json['success'] ??
        json['isSuccess'];

    return AuditLogModel(
      id: _parseInt(json['id'] ?? json['auditLogId'] ?? json['audit_log_id']),
      action: _string(
        json['action'] ??
            json['eventType'] ??
            json['event_type'] ??
            json['operation'] ??
            json['type'],
      ),
      actorUsername: _string(
        json['actorUsername'] ??
            json['actor_username'] ??
            json['username'] ??
            actor?['username'],
      ),
      actorFullName: _string(
        json['actorFullName'] ??
            json['actor_full_name'] ??
            json['fullName'] ??
            json['full_name'] ??
            actor?['fullName'] ??
            actor?['full_name'],
      ),
      actorRole: _string(
        json['actorRole'] ??
            json['actor_role'] ??
            json['role'] ??
            actor?['role'],
      ),
      targetType: _string(
        json['targetType'] ??
            json['target_type'] ??
            json['entityType'] ??
            json['entity_type'] ??
            json['resourceType'] ??
            target?['type'],
      ),
      targetId: _string(
        json['targetId'] ??
            json['target_id'] ??
            json['entityId'] ??
            json['entity_id'] ??
            json['resourceId'] ??
            target?['id'],
      ),
      description: _string(
        json['description'] ??
            json['message'] ??
            json['details'] ??
            json['detail'],
      ),
      status: _string(rawStatus),
      ipAddress: _string(json['ipAddress'] ?? json['ip_address'] ?? json['ip']),
      device: _string(
        json['device'] ?? json['userAgent'] ?? json['user_agent'],
      ),
      createdAt: _parseDate(
        json['createdAt'] ??
            json['created_at'] ??
            json['timestamp'] ??
            json['time'],
      ),
      rawData: Map<String, dynamic>.unmodifiable(json),
    );
  }

  static Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _parseDate(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
