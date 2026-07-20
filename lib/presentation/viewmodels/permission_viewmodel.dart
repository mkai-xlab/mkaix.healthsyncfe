import 'package:flutter/material.dart';

import '../../data/datasources/permission_remote_datasource.dart';
import '../../data/models/permission_catalog_model.dart';
import '../../data/models/permission_model.dart';
import '../../data/models/role_model.dart';

class PermissionViewModel extends ChangeNotifier {
  final PermissionRemoteDataSource dataSource;
  PermissionViewModel(this.dataSource);

  List<PermissionFeatureModel> _features = [];
  List<PermissionModel> _permissions = [];
  List<RoleModel> _roles = [];

  Map<String, Set<String>> _draft = {};
  Map<String, Set<String>> _saved = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<PermissionFeatureModel> get features => _features;
  List<PermissionModel> get permissions => _permissions;
  List<RoleModel> get roles => _roles;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get hasUnsavedChanges {
    for (final role in _roles) {
      if (roleHasUnsavedChanges(role.id)) return true;
    }
    return false;
  }

  bool roleHasUnsavedChanges(String roleId) {
    final draft = _draft[roleId] ?? {};
    final saved = _saved[roleId] ?? {};
    return !_setsEqual(draft, saved);
  }

  bool hasPermission(String roleId, String permissionId) {
    return _draft[roleId]?.contains(permissionId) ?? false;
  }

  Map<String, List<PermissionModel>> get permissionsByResource {
    final map = <String, List<PermissionModel>>{};
    for (final permission in _permissions) {
      map.putIfAbsent(permission.resource, () => []).add(permission);
    }
    final ordered = <String, List<PermissionModel>>{};
    for (final entry in map.entries) {
      ordered[entry.key] = _orderPermissionsByHierarchy(entry.value);
    }
    return ordered;
  }

  PermissionFeatureModel? featureById(String id) {
    for (final feature in _features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  List<PermissionModel> permissionsForFeature(String featureId) {
    final permissions = _permissions.where((p) => p.featureId == featureId).toList();
    return _orderPermissionsByHierarchy(permissions);
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        dataSource.getPermissionCatalog(),
        dataSource.getRoles(),
      ]);

      final catalog = results[0] as PermissionCatalogModel;
      _features = catalog.features;
      _permissions = catalog.permissions;
      _roles = results[1] as List<RoleModel>;

      _draft = {};
      _saved = {};
      for (final role in _roles) {
        final perms = Set<String>.from(role.permissions);
        _draft[role.id] = Set<String>.from(perms);
        _saved[role.id] = Set<String>.from(perms);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFeature({
    required String name,
    String? description,
  }) async {
    return _runMutation(() async {
      await dataSource.createFeature(name: name, description: description);
    });
  }

  Future<bool> updateFeature({
    required String id,
    required String name,
    String? description,
  }) async {
    return _runMutation(() async {
      await dataSource.updateFeature(
        id: id,
        name: name,
        description: description,
      );
    });
  }

  Future<bool> createPermission({
    required String code,
    required String name,
    required String featureId,
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  }) async {
    return _runMutation(() async {
      await dataSource.createPermission(
        code: code,
        name: name,
        featureId: featureId,
        presentation: presentation,
        priority: priority,
        requiresPermissionId: requiresPermissionId,
      );
    });
  }

  Future<bool> updatePermission({
    required String id,
    required String code,
    required String name,
    required String featureId,
    String? presentation,
    int? priority,
    String? requiresPermissionId,
  }) async {
    return _runMutation(() async {
      await dataSource.updatePermission(
        id: id,
        code: code,
        name: name,
        featureId: featureId,
        presentation: presentation,
        priority: priority,
        requiresPermissionId: requiresPermissionId,
      );
    });
  }

  void togglePermission(String roleId, String permissionId) {
    final current = _draft[roleId] ?? <String>{};
    final isEnabling = !current.contains(permissionId);

    if (isEnabling) {
      current.add(permissionId);
    } else {
      current.remove(permissionId);
      _removeChildren(current, permissionId);
    }

    _draft[roleId] = current;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> saveChanges() async {
    if (!hasUnsavedChanges) return;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final futures = <Future>[];
      for (final role in _roles) {
        final draft = _draft[role.id] ?? {};
        final saved = _saved[role.id] ?? {};
        if (!_setsEqual(draft, saved)) {
          futures.add(
            dataSource.updateRolePermissions(role.id, draft.toList()).then((
              updatedRole,
            ) {
              _saved[role.id] = Set<String>.from(draft);
            }),
          );
        }
      }
      await Future.wait(futures);
      _successMessage = 'Đã lưu thay đổi phân quyền thành công';
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void discardChanges() {
    for (final roleId in _saved.keys) {
      _draft[roleId] = Set<String>.from(_saved[roleId]!);
    }
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> _runMutation(Future<void> Function() operation) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await operation();
      _successMessage = 'Đã cập nhật dữ liệu thành công';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _removeChildren(Set<String> current, String parentId) {
    final children = _permissions
        .where((p) => p.parentId == parentId)
        .map((p) => p.id)
        .toList();
    for (final childId in children) {
      current.remove(childId);
      _removeChildren(current, childId);
    }
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  List<PermissionModel> _orderPermissionsByHierarchy(
    List<PermissionModel> permissions,
  ) {
    final byParent = <String, List<PermissionModel>>{};
    final allById = <String, PermissionModel>{};

    for (final permission in permissions) {
      allById[permission.id] = permission;
      final parentKey = permission.parentId?.trim() ?? '';
      byParent.putIfAbsent(parentKey, () => []).add(permission);
    }

    int comparePermission(PermissionModel a, PermissionModel b) {
      final cmp = a.priority.compareTo(b.priority);
      if (cmp != 0) return cmp;
      final nameCmp = a.name.compareTo(b.name);
      if (nameCmp != 0) return nameCmp;
      return a.id.compareTo(b.id);
    }

    for (final entry in byParent.entries) {
      entry.value.sort(comparePermission);
    }

    final ordered = <PermissionModel>[];
    final visited = <String>{};

    void visitChildren(String parentId) {
      final children = byParent[parentId] ?? const <PermissionModel>[];
      for (final child in children) {
        if (!visited.add(child.id)) continue;
        ordered.add(child);
        visitChildren(child.id);
      }
    }

    visitChildren('');

    final remainingRoots = permissions
        .where((permission) {
          final parentId = permission.parentId?.trim() ?? '';
          return parentId.isNotEmpty && !allById.containsKey(parentId);
        })
        .toList()
      ..sort(comparePermission);

    for (final root in remainingRoots) {
      if (!visited.add(root.id)) continue;
      ordered.add(root);
      visitChildren(root.id);
    }

    final leftovers = permissions
        .where((permission) => !visited.contains(permission.id))
        .toList()
      ..sort(comparePermission);

    for (final permission in leftovers) {
      visited.add(permission.id);
      ordered.add(permission);
      visitChildren(permission.id);
    }

    return ordered;
  }
}
