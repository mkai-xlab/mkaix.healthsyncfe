class UserEntity {
  final String id;
  final String username;
  final String fullName;
  final String token;
  final String refreshToken;
  final List<String> roles;
  final List<String> permissions;
  final List<UserPermissionEntity> permissionItems;

  UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.token,
    this.refreshToken = '',
    required this.roles,
    this.permissions = const [],
    this.permissionItems = const [],
  });

  // Hàm tiện ích kiểm tra quyền nhanh ở tầng UI
  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  bool get isAdmin => roles.contains('ADMIN');
  bool get isDoctor => roles.contains('DOCTOR');
}

class UserPermissionEntity {
  final String id;
  final String name;
  final String code;
  final String? presentation;
  final String? description;
  final String? parentId;
  final int priority;

  const UserPermissionEntity({
    required this.id,
    required this.name,
    this.code = '',
    this.presentation,
    this.description,
    this.parentId,
    this.priority = 0,
  });

  bool get isParent => parentId == null || parentId!.isEmpty;
}
