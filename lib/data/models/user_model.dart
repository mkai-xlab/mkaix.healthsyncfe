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
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['username'] ?? '', // Spring Boot thường trả về 'username'
      token: json['accessToken'] ?? '', // Token JWT từ Spring Boot
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
    );
  }
}
