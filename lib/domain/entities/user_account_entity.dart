class UserAccountEntity {
  final String id;
  final String username;
  final String email;
  final List<String> roles;
  final bool isActive;

  UserAccountEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    required this.isActive,
  });
}
