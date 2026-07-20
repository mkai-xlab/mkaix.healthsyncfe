import 'permission_model.dart';

class PermissionFeatureModel {
  final String id;
  final String name;
  final String description;
  final List<PermissionModel> permissions;

  const PermissionFeatureModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
  });

  factory PermissionFeatureModel.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    final permissions = <PermissionModel>[];

    if (rawPermissions is List) {
      for (final item in rawPermissions) {
        if (item is Map<String, dynamic>) {
          permissions.add(
            PermissionModel.fromJson({
              ...item,
              'featureId': json['id'],
              'resource': json['name'],
            }),
          );
        }
      }
    }

    return PermissionFeatureModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      permissions: permissions,
    );
  }
}

class PermissionCatalogModel {
  final List<PermissionFeatureModel> features;
  final List<PermissionModel> permissions;

  const PermissionCatalogModel({
    required this.features,
    required this.permissions,
  });

  factory PermissionCatalogModel.fromJson(dynamic json) {
    final features = <PermissionFeatureModel>[];
    final permissions = <PermissionModel>[];

    if (json is List) {
      for (final item in json) {
        if (item is! Map<String, dynamic>) continue;
        final feature = PermissionFeatureModel.fromJson(item);
        features.add(feature);
        permissions.addAll(feature.permissions);
      }
    } else if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is List) {
        return PermissionCatalogModel.fromJson(data);
      }
      final feature = PermissionFeatureModel.fromJson(json);
      features.add(feature);
      permissions.addAll(feature.permissions);
    }

    permissions.sort((a, b) {
      final cmp = a.priority.compareTo(b.priority);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return PermissionCatalogModel(features: features, permissions: permissions);
  }
}
