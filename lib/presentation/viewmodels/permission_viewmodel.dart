import 'package:flutter/material.dart';
import '../../data/datasources/permission_remote_datasource.dart';
import '../../data/models/permission_model.dart';
import '../../data/models/role_model.dart';

class PermissionViewModel extends ChangeNotifier {
  final PermissionRemoteDataSource dataSource;
  PermissionViewModel(this.dataSource);

  // ── State ──────────────────────────────────────
  List<PermissionModel> _permissions = [];
  List<RoleModel> _roles = [];

  // Bản làm việc — tách riêng để track thay đổi chưa lưu
  Map<String, Set<String>> _draft = {}; // roleId → Set<permissionId>
  Map<String, Set<String>> _saved = {}; // roleId → Set<permissionId> (đã lưu)

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Getters ────────────────────────────────────
  List<PermissionModel> get permissions => _permissions;
  List<RoleModel> get roles => _roles;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// True nếu có bất kỳ thay đổi chưa lưu
  bool get hasUnsavedChanges {
    for (final role in _roles) {
      if (roleHasUnsavedChanges(role.id)) return true;
    }
    return false;
  }

  /// True nếu role cụ thể có thay đổi chưa lưu (dùng để hiển thị dot trên tab)
  bool roleHasUnsavedChanges(String roleId) {
    final draft = _draft[roleId] ?? {};
    final saved = _saved[roleId] ?? {};
    return !_setsEqual(draft, saved);
  }

  /// Kiểm tra permission có được bật cho role không
  bool hasPermission(String roleId, String permissionId) {
    return _draft[roleId]?.contains(permissionId) ?? false;
  }

  /// Group permissions theo resource (để render card)
  Map<String, List<PermissionModel>> get permissionsByResource {
    final map = <String, List<PermissionModel>>{};
    for (final p in _permissions) {
      map.putIfAbsent(p.resource, () => []).add(p);
    }
    return map;
  }

  // ── Load ───────────────────────────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        dataSource.getPermissions(),
        dataSource.getRoles(),
      ]);

      _permissions = results[0] as List<PermissionModel>;
      _roles = results[1] as List<RoleModel>;

      // Khởi tạo draft và saved từ dữ liệu gốc
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

  // ── Toggle ─────────────────────────────────────
  void togglePermission(String roleId, String permissionId) {
    final current = _draft[roleId] ?? <String>{};
    final isEnabling = !current.contains(permissionId);

    if (isEnabling) {
      current.add(permissionId);
    } else {
      // Khi tắt một permission, tắt luôn tất cả permission con của nó
      current.remove(permissionId);
      _removeChildren(current, permissionId);
    }

    _draft[roleId] = current;
    _successMessage = null;
    notifyListeners();
  }

  /// Đệ quy tắt tất cả permission có parent_id = permissionId
  void _removeChildren(Set<String> current, String parentId) {
    final children = _permissions
        .where((p) => p.parentId == parentId)
        .map((p) => p.id)
        .toList();
    for (final childId in children) {
      current.remove(childId);
      _removeChildren(current, childId); // đệ quy cho multi-level
    }
  }

  // ── Save ───────────────────────────────────────
  Future<void> saveChanges() async {
    if (!hasUnsavedChanges) return;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Chỉ PUT những role có thay đổi
      final futures = <Future>[];
      for (final role in _roles) {
        final draft = _draft[role.id] ?? {};
        final saved = _saved[role.id] ?? {};
        if (!_setsEqual(draft, saved)) {
          futures.add(
            dataSource.updateRolePermissions(role.id, draft.toList()).then((
              updatedRole,
            ) {
              // Cập nhật saved sau khi PUT thành công
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

  // ── Discard ────────────────────────────────────
  void discardChanges() {
    for (final roleId in _saved.keys) {
      _draft[roleId] = Set<String>.from(_saved[roleId]!);
    }
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────
  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
