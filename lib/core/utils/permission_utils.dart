import '../../domain/entities/user_entity.dart';

String normalizePermissionKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('đ', 'd')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

bool _looksLikePermissionCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;
  return RegExp(r'^[A-Z0-9_]+$').hasMatch(normalized);
}

String permissionKeyFor(UserPermissionEntity permission) {
  return normalizePermissionKey(permission.presentation ?? '');
}

String permissionLabelFor(UserPermissionEntity permission) {
  final name = permission.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final presentation = permission.presentation?.trim() ?? '';
  if (presentation.isNotEmpty && !_looksLikePermissionCode(presentation)) {
    return presentation;
  }

  if (name.isNotEmpty) return name;
  return presentation.isNotEmpty ? presentation : 'Chưa đặt tên';
}

bool permissionMatchesKey(UserPermissionEntity permission, String key) {
  final normalizedKey = normalizePermissionKey(key);
  if (normalizedKey.isEmpty) return false;

  return permissionKeyFor(permission) == normalizedKey;
}
