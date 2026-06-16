class RoleModel {
  final String id;
  final String name;
  final String code;
  final List<String> permissions; // list of permission id

  const RoleModel({
    required this.id,
    required this.name,
    required this.code,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final List<String> perms = rawPerms is List
        ? rawPerms.map((e) => e.toString()).toList()
        : [];

    return RoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'permissions': permissions,
  };

  RoleModel copyWith({List<String>? permissions}) {
    return RoleModel(
      id: id,
      name: name,
      code: code,
      permissions: permissions ?? this.permissions,
    );
  }
}
