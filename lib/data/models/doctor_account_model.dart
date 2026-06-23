class DoctorAccountModel {
  final int id;
  final String username;
  final String fullName;
  final String role; // tên role (string) để hiển thị
  final int? roleId; // id role để tạo user
  final String email;
  final String phone;
  final String? avatarUrl;
  final String status; // "ACTIVE" hoặc "INACTIVE"
  final String? userType;
  // Doctor-specific fields (nullable vì UserResponse chung không có)
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

  /// Parse từ cả DoctorResponse lẫn UserResponse
  factory DoctorAccountModel.fromJson(Map<String, dynamic> json) {
    // role có thể là String (DoctorResponse) hoặc Object (UserResponse)
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
