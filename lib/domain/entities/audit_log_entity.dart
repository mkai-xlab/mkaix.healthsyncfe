class AuditLogEntity {
  final int id;
  final String username;
  final String title;
  final String description;
  final String ipAddress;
  final String userAgent;
  final DateTime? timeStamp;
  final Map<String, dynamic> rawData;

  const AuditLogEntity({
    required this.id,
    this.username = '',
    this.title = '',
    this.description = '',
    this.ipAddress = '',
    this.userAgent = '',
    this.timeStamp,
    this.rawData = const {},
  });

  String get userDisplay {
    final value = username.trim();
    return value.isEmpty ? 'Hệ thống' : value;
  }

  String get titleDisplay {
    final value = title.trim();
    return value.isEmpty ? '---' : value;
  }

  String get descriptionDisplay {
    final value = description.trim();
    return value.isEmpty ? '---' : value;
  }

  String get userAgentDisplay {
    final value = userAgent.trim();
    return value.isEmpty ? '---' : value;
  }

  String get ipAddressDisplay {
    final value = ipAddress.trim();
    return value.isEmpty ? '---' : value;
  }
}
