import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.token,
    required super.roles,
    super.permissions,
    super.permissionItems,
  });

  // Map chính xác các Key từ JSON của Spring Boot trả về
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];

    // 1. Ưu tiên xử lý trường 'role' (dạng String) từ response thực tế của bạn
    if (json['role'] != null && json['role'] is String) {
      parsedRoles.add(json['role'].toString().replaceAll('ROLE_', ''));
    }
    // 2. Dự phòng xử lý trường 'roles' (dạng List) nếu backend thay đổi cấu trúc sau này
    if (json['roles'] != null) {
      final rawRoles = json['roles'] as List;

      parsedRoles = rawRoles.map((roleItem) {
        if (roleItem is Map) {
          // Xử lý Dạng 2: Spring Boot trả về dạng đối tượng GrantedAuthority [{"authority": "ROLE_DOCTOR"}]
          // Mẹo: .replaceAll('ROLE_', '') để loại bỏ tiền tố mặc định của Spring Security nếu cần
          return (roleItem['authority'] ?? '').toString().replaceAll(
            'ROLE_',
            '',
          );
        }
        // Xử lý Dạng 1: Spring Boot trả về dạng mảng String ["DOCTOR"]
        return roleItem.toString().replaceAll('ROLE_', '');
      }).toList();
    }

    final parsedPermissionItems = <UserPermissionEntity>[];
    final parsedPermissions = <String>[];

    if (json['permissions'] is List) {
      for (final permission in json['permissions'] as List) {
        if (permission is Map) {
          final id =
              (permission['id'] ??
                      permission['permissionId'] ??
                      permission['code'] ??
                      permission['name'] ??
                      permission['authority'] ??
                      '')
                  .toString();
          final name =
              (permission['name'] ??
                      permission['code'] ??
                      permission['authority'] ??
                      permission['id'] ??
                      '')
                  .toString();
          final code = (permission['code'] ?? '').toString();
          final presentation = permission['presentation']?.toString();
          final parentId =
              permission['parent_id'] ??
              permission['parentId'] ??
              permission['requiresPermissionId'];
          final priority = permission['priority'] is int
              ? permission['priority'] as int
              : int.tryParse(permission['priority']?.toString() ?? '') ?? 0;

          if (name.isNotEmpty) {
            parsedPermissions.add(name);
            parsedPermissionItems.add(
              UserPermissionEntity(
                id: id.isNotEmpty ? id : name,
                name: name,
                code: code,
                presentation: presentation,
                description: permission['description']?.toString(),
                parentId: parentId?.toString(),
                priority: priority,
              ),
            );
          }
          continue;
        }

        final name = permission.toString();
        if (name.isNotEmpty) {
          parsedPermissions.add(name);
          parsedPermissionItems.add(UserPermissionEntity(id: name, name: name));
        }
      }
    }

    final doctorJson = json['doctor'] is Map
        ? Map<String, dynamic>.from(json['doctor'] as Map)
        : null;
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final resolvedId =
        json['doctorId'] ??
        json['doctor_id'] ??
        doctorJson?['id'] ??
        json['userId'] ??
        json['user_id'] ??
        userJson?['id'] ??
        json['id'] ??
        json['username'] ??
        '';

    return UserModel(
      id: resolvedId.toString(),
      name:
          json['username'] ??
          json['fullName'] ??
          '', // Dự phòng nếu backend trả về username hoặc fullName
      token:
          json['accessToken'] ??
          json['token'] ??
          '', // Dự phòng cả accessToken và token
      roles: parsedRoles,
      permissions: parsedPermissions,
      permissionItems: parsedPermissionItems,
    );
  }

  // --- 💡 TIỆN ÍCH PHÂN QUYỀN (Hỗ trợ Routing điều hướng màn hình ở tầng UI) ---

  /// Kiểm tra xem User này có phải là Bác sĩ không
  @override
  bool get isDoctor => roles.contains('DOCTOR');

  /// Kiểm tra xem User này có phải là Admin không
  @override
  bool get isAdmin => roles.contains('ADMIN');
}
