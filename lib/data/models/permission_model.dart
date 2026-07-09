class PermissionModel {
  final String id;
  final String code;
  final String name;
  final String resource;
  final String action;
  final String? featureId;
  final String? parentId;
  final String presentation;
  final int priority;

  const PermissionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.resource,
    required this.action,
    this.featureId,
    this.parentId,
    this.presentation = '',
    this.priority = 0,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      resource: json['resource']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      featureId: json['featureId']?.toString(),
      parentId:
          json['parent_id']?.toString() ??
          json['requiresPermissionId']?.toString(),
      presentation: json['presentation']?.toString() ?? '',
      priority: json['priority'] is int
          ? json['priority'] as int
          : int.tryParse(json['priority']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'resource': resource,
    'action': action,
    'featureId': featureId,
    'parent_id': parentId,
    'presentation': presentation,
    'priority': priority,
  };
}
