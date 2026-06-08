import '../../domain/entities/user_account_entity.dart';

class UserAccountModel extends UserAccountEntity {
  UserAccountModel({
    required super.id,
    required super.username,
    required super.email,
    required super.roles,
    required super.isActive,
  });

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    // Xử lý bóc tách roles linh hoạt giống như UserModel
    List<String> parsedRoles = [];
    if (json['roles'] != null) {
      final rawRoles = json['roles'] as List;
      parsedRoles = rawRoles.map((item) {
        final String role = item is Map
            ? (item['authority'] ?? '').toString()
            : item.toString();
        return role.replaceAll('ROLE_', '');
      }).toList();
    }

    return UserAccountModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      roles: parsedRoles,
      isActive:
          json['isActive'] ??
          json['enabled'] ??
          true, // Dự phòng trường 'enabled' từ Spring Security
    );
  }
}
