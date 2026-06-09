class DoctorAccountModel {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String status; // "ACTIVE" hoặc "INACTIVE"
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

  DoctorAccountModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.status,
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

  factory DoctorAccountModel.fromJson(Map<String, dynamic> json) {
    return DoctorAccountModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'DOCTOR',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'INACTIVE',
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
      // Parse chuỗi thời gian từ Spring Boot sang DateTime của Flutter
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
