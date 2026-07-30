import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    super.username,
    super.title,
    super.description,
    super.ipAddress,
    super.userAgent,
    super.timeStamp,
    super.rawData,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: _parseInt(json['id']),
      username: _string(json['username']),
      title: _string(json['title']),
      description: _string(json['description']),
      ipAddress: _string(json['ipAddress']),
      userAgent: _string(json['userAgent']),
      timeStamp: _parseDate(json['timeStamp']),
      rawData: Map<String, dynamic>.unmodifiable(json),
    );
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
