class PermissionModel {
  final String id;
  final String code;
  final String name;
  final String resource;
  final String action;
  final String? featureId;
  final String? parentId;
  final int priority;

  const PermissionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.resource,
    required this.action,
    this.featureId,
    this.parentId,
    this.priority = 0,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      resource: json['resource']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      featureId:
          json['featureId']?.toString() ?? json['feature_id']?.toString(),
      parentId:
          json['parent_id']?.toString() ??
          json['parentId']?.toString() ??
          json['requiresPermissionId']?.toString(),
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
    'priority': priority,
  };

  PermissionModel copyWith({
    String? id,
    String? code,
    String? name,
    String? resource,
    String? action,
    String? featureId,
    String? parentId,
    int? priority,
  }) {
    return PermissionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      resource: resource ?? this.resource,
      action: action ?? this.action,
      featureId: featureId ?? this.featureId,
      parentId: parentId ?? this.parentId,
      priority: priority ?? this.priority,
    );
  }
}
