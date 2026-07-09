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

const Map<String, String> _permissionRouteKeyFallbackByCode = {
  'read_patient_list': 'patient_list_page',
  'read_patient_detail': 'patient_detail_page',
  'view_patient_detail': 'patient_detail_page',
  'create_patient_exam': 'examination_list_page',
  'upload_dicom_image': 'dicom_upload_page',
};

const Map<String, String> _permissionLabelFallbackByCode = {
  'read_patient_list': 'Danh sách bệnh nhân',
  'read_patient_detail': 'Chi tiết bệnh nhân',
  'view_patient_detail': 'Chi tiết bệnh nhân',
  'create_patient_exam': 'Danh sách ca khám',
  'upload_dicom_image': 'Tải ảnh DICOM',
  'patient_list_page': 'Danh sách bệnh nhân',
  'patient_detail_page': 'Chi tiết bệnh nhân',
  'examination_list_page': 'Danh sách ca khám',
  'dicom_upload_page': 'Tải ảnh DICOM',
};

bool _looksLikePermissionCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;
  return RegExp(r'^[A-Z0-9_]+$').hasMatch(normalized);
}

String _firstNonEmptyNormalized(Iterable<String?> values) {
  for (final value in values) {
    final normalized = normalizePermissionKey(value ?? '');
    if (normalized.isNotEmpty) return normalized;
  }
  return '';
}

String permissionKeyFor(UserPermissionEntity permission) {
  final presentationKey = normalizePermissionKey(permission.presentation ?? '');
  if (presentationKey.isNotEmpty) {
    return presentationKey;
  }

  final codeKey = normalizePermissionKey(permission.code);
  final mappedCodeKey = _permissionRouteKeyFallbackByCode[codeKey];
  if (mappedCodeKey != null) return mappedCodeKey;

  final nameKey = normalizePermissionKey(permission.name);
  final mappedNameKey = _permissionRouteKeyFallbackByCode[nameKey];
  if (mappedNameKey != null) return mappedNameKey;

  return _firstNonEmptyNormalized([permission.name, permission.id, permission.code]);
}

String permissionLabelFor(UserPermissionEntity permission) {
  final name = permission.name.trim();
  if (name.isNotEmpty && !_looksLikePermissionCode(name)) {
    return name;
  }

  final presentation = permission.presentation?.trim() ?? '';
  if (presentation.isNotEmpty && !_looksLikePermissionCode(presentation)) {
    return presentation;
  }

  final codeKey = normalizePermissionKey(permission.code);
  final mappedLabel = _permissionLabelFallbackByCode[codeKey];
  if (mappedLabel != null) return mappedLabel;

  final routeKey = permissionKeyFor(permission);
  final routeMappedLabel = _permissionLabelFallbackByCode[routeKey];
  if (routeMappedLabel != null) return routeMappedLabel;

  if (name.isNotEmpty) return name;
  return 'Chưa đặt tên';
}

bool permissionMatchesKey(UserPermissionEntity permission, String key) {
  final normalizedKey = normalizePermissionKey(key);
  if (normalizedKey.isEmpty) return false;

  final candidates = <String>{
    normalizePermissionKey(permission.presentation ?? ''),
    normalizePermissionKey(permission.code),
    normalizePermissionKey(permission.name),
    normalizePermissionKey(permission.id),
  };

  final mappedPresentation =
      _permissionRouteKeyFallbackByCode[normalizePermissionKey(permission.code)];
  if (mappedPresentation != null) {
    candidates.add(mappedPresentation);
  }

  final mappedFromName =
      _permissionRouteKeyFallbackByCode[normalizePermissionKey(permission.name)];
  if (mappedFromName != null) {
    candidates.add(mappedFromName);
  }

  return candidates.contains(normalizedKey);
}
