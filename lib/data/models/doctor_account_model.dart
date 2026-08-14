import '../../domain/entities/doctor_account_entity.dart';

class DoctorAccountModel extends DoctorAccountEntity {
  const DoctorAccountModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.role,
    super.roleId,
    required super.email,
    required super.phone,
    super.avatarUrl,
    required super.status,
    super.userType,
    super.doctorCode,
    super.licenseNumber,
    super.specialization,
    super.hospitalName,
    super.yearsOfExperience = 0,
    super.academicTitle,
    super.degree,
    super.signatureUrl,
    super.bio,
    super.position,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DoctorAccountModel.fromJson(Map<String, dynamic> json) {
    final roleInfo = _parseRole(json);

    return DoctorAccountModel(
      id: _parseId(json),
      username: _readString(json, const ['username', 'email']),
      fullName: _readString(json, const ['fullName', 'name', 'displayName']),
      role: roleInfo.name,
      roleId: roleInfo.id,
      email: _readString(json, const ['email']),
      phone: _readString(json, const ['phone', 'phoneNumber']),
      avatarUrl: json['avatarUrl'] as String?,
      status: _parseStatus(json),
      userType: json['userType'] as String?,
      doctorCode: json['doctorCode'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      specialization: json['specialization'] as String?,
      hospitalName: json['hospitalName'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      academicTitle: json['academicTitle'] as String?,
      degree: json['degree'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      bio: (json['biography'] ?? json['bio']) as String?,
      position: json['position'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _parseId(Map<String, dynamic> json) {
    for (final key in const ['doctorId', 'userId', 'id']) {
      final value = json[key];
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static _RoleInfo _parseRole(Map<String, dynamic> json) {
    final rawRole = json['role'] ?? json['roleName'] ?? json['roleCode'];
    if (rawRole is String) {
      return _RoleInfo(name: rawRole.replaceAll('ROLE_', ''));
    }
    if (rawRole is Map<String, dynamic>) {
      return _RoleInfo.fromMap(rawRole);
    }

    final rawRoles = json['roles'];
    if (rawRoles is List && rawRoles.isNotEmpty) {
      final first = rawRoles.first;
      if (first is String) {
        return _RoleInfo(name: first.replaceAll('ROLE_', ''));
      }
      if (first is Map<String, dynamic>) {
        return _RoleInfo.fromMap(first);
      }
    }

    return const _RoleInfo(name: 'UNKNOWN');
  }

  static String _parseStatus(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    if (rawStatus != null && rawStatus.trim().isNotEmpty) {
      return rawStatus;
    }
    final active = json['active'] ?? json['enabled'];
    if (active is bool) return active ? 'ACTIVE' : 'INACTIVE';
    return 'INACTIVE';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
}

class _RoleInfo {
  final String name;
  final int? id;

  const _RoleInfo({required this.name, this.id});

  factory _RoleInfo.fromMap(Map<String, dynamic> json) {
    final name =
        (json['name'] ?? json['code'] ?? json['authority'] ?? 'UNKNOWN')
            .toString()
            .replaceAll('ROLE_', '');
    final rawId = json['id'] ?? json['roleId'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    return _RoleInfo(name: name, id: id);
  }
}
