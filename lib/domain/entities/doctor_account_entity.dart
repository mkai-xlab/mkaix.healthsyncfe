class DoctorAccountEntity {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final int? roleId;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String status;
  final String? userType;
  final String? doctorCode;
  final String? licenseNumber;
  final String? specialization;
  final String? hospitalName;
  final int yearsOfExperience;
  final String? academicTitle;
  final String? degree;
  final String? signatureUrl;
  final String? bio;
  final String? position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorAccountEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.roleId,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.status,
    this.userType,
    this.doctorCode,
    this.licenseNumber,
    this.specialization,
    this.hospitalName,
    this.yearsOfExperience = 0,
    this.academicTitle,
    this.degree,
    this.signatureUrl,
    this.bio,
    this.position,
    required this.createdAt,
    required this.updatedAt,
  });
}
