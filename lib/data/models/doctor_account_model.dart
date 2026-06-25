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
    String roleName = 'DOCTOR';
    int? roleIdParsed;
    final rawRole = json['role'];
    if (rawRole is String) {
      roleName = rawRole;
    } else if (rawRole is Map<String, dynamic>) {
      roleName = rawRole['name']?.toString() ?? 'UNKNOWN';
      roleIdParsed = rawRole['id'] is int
          ? rawRole['id'] as int
          : int.tryParse(rawRole['id']?.toString() ?? '');
    }

    return DoctorAccountModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: roleName,
      roleId: roleIdParsed,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'INACTIVE',
      userType: json['userType'] as String?,
      doctorCode: json['doctorCode'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      specialization: json['specialization'] as String?,
      hospitalName: json['hospitalName'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      academicTitle: json['academicTitle'] as String?,
      degree: json['degree'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
      bio: json['bio'] as String?,
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
}
