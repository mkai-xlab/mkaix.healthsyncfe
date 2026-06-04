class UserEntity {
  final String id;
  final String name;
  final String token;
  final List<String> roles;

  UserEntity({
    required this.id,
    required this.name,
    required this.token,
    required this.roles,
  });

  // Hàm tiện ích kiểm tra quyền nhanh ở tầng UI
  bool get isAdmin => roles.contains('ROLE_ADMIN');
  bool get isDoctor => roles.contains('ROLE_DOCTOR');
}
