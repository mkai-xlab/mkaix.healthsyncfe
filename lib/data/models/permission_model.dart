class PermissionModel {
  final String id;
  final String name;
  final String resource;
  final String action;
  final String? parentId;

  const PermissionModel({
    required this.id,
    required this.name,
    required this.resource,
    required this.action,
    this.parentId,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      resource: json['resource']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      parentId:
          json['parent_id']?.toString() ??
          json['requiresPermissionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'resource': resource,
    'action': action,
    'parent_id': parentId,
  };
}
