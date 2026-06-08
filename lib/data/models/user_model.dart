import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.token,
    required super.roles,
  });

  // Map chính xác các Key từ JSON của Spring Boot trả về
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];

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

    return UserModel(
      id: json['id']?.toString() ?? '',
      name:
          json['username'] ??
          json['fullName'] ??
          '', // Dự phòng nếu backend trả về username hoặc fullName
      token:
          json['accessToken'] ??
          json['token'] ??
          '', // Dự phòng cả accessToken và token
      roles: parsedRoles,
    );
  }

  // --- 💡 TIỆN ÍCH PHÂN QUYỀN (Hỗ trợ Routing điều hướng màn hình ở tầng UI) ---

  /// Kiểm tra xem User này có phải là Bác sĩ không
  bool get isDoctor => roles.contains('DOCTOR');

  /// Kiểm tra xem User này có phải là Admin không
  bool get isAdmin => roles.contains('ADMIN');
}
