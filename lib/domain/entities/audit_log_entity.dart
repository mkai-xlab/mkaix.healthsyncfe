class AuditLogEntity {
  final int id;
  final String action;
  final String actorUsername;
  final String actorFullName;
  final String actorRole;
  final String targetType;
  final String targetId;
  final String description;
  final String status;
  final String ipAddress;
  final String device;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  const AuditLogEntity({
    required this.id,
    required this.action,
    this.actorUsername = '',
    this.actorFullName = '',
    this.actorRole = '',
    this.targetType = '',
    this.targetId = '',
    this.description = '',
    this.status = '',
    this.ipAddress = '',
    this.device = '',
    this.createdAt,
    this.rawData = const {},
  });

  String get actorDisplay {
    if (actorFullName.trim().isNotEmpty) return actorFullName.trim();
    if (actorUsername.trim().isNotEmpty) return actorUsername.trim();
    return 'Hệ thống';
  }

  String get targetDisplay {
    final type = targetType.trim();
    final idValue = targetId.trim();
    if (type.isEmpty && idValue.isEmpty) return '---';
    if (type.isEmpty) return idValue;
    if (idValue.isEmpty) return type;
    return '$type #$idValue';
  }

  bool get isSuccess {
    final normalized = status.trim().toUpperCase();
    return normalized == 'SUCCESS' ||
        normalized == 'SUCCEEDED' ||
        normalized == 'THÀNH CÔNG' ||
        normalized == 'THANH_CONG' ||
        normalized == 'OK' ||
        normalized == 'true'.toUpperCase();
  }
}
