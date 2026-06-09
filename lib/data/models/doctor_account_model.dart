class DoctorAccountModel {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final String email;
  final String status; // "ACTIVE" hoặc "INACTIVE"
  final DateTime updatedAt;

  DoctorAccountModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.email,
    required this.status,
    required this.updatedAt,
  });

  factory DoctorAccountModel.fromJson(Map<String, dynamic> json) {
    return DoctorAccountModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'DOCTOR',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'INACTIVE',
      // Parse chuỗi thời gian từ Spring Boot sang DateTime của Flutter
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
