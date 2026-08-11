String userFriendlyErrorMessage(Object error) {
  final raw = error.toString().replaceAll('Exception: ', '').trim();
  final normalized = raw.toLowerCase();

  final isNetworkError =
      normalized.contains('clientexception') ||
      normalized.contains('socketexception') ||
      normalized.contains('xmlhttprequest error') ||
      normalized.contains('failed to fetch') ||
      normalized.contains('connection refused') ||
      normalized.contains('connection closed') ||
      normalized.contains('connection reset') ||
      normalized.contains('connection timed out') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('networkerror') ||
      normalized.contains('localhost:') ||
      normalized.contains('127.0.0.1:');

  if (isNetworkError) {
    return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra server hoặc thử lại sau.';
  }

  if (raw.isEmpty) {
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }

  return _translateKnownApiError(raw, normalized) ?? raw;
}

String? _translateKnownApiError(String raw, String normalized) {
  final duplicateValue = RegExp(
    r"^(phone|email|username)\s+'([^']+)'\s+is already registered$",
    caseSensitive: false,
  ).firstMatch(raw);
  if (duplicateValue != null) {
    final field = _fieldLabel(duplicateValue.group(1)!);
    final value = duplicateValue.group(2)!;
    return '$field "$value" đã được đăng ký.';
  }

  final duplicateField = RegExp(
    r"^(phone|email|username)\s+is already registered$",
    caseSensitive: false,
  ).firstMatch(raw);
  if (duplicateField != null) {
    final field = _fieldLabel(duplicateField.group(1)!);
    return '$field đã được đăng ký.';
  }

  if (normalized.contains('already registered') ||
      normalized.contains('already exists') ||
      normalized.contains('duplicate')) {
    if (normalized.contains('phone')) {
      return 'Số điện thoại đã được đăng ký.';
    }
    if (normalized.contains('email')) {
      return 'Email đã được đăng ký.';
    }
    if (normalized.contains('username')) {
      return 'Tên đăng nhập đã được đăng ký.';
    }
    return 'Thông tin này đã tồn tại trong hệ thống.';
  }

  if (normalized.contains('unauthorized') || normalized.contains('forbidden')) {
    return 'Bạn không có quyền thực hiện thao tác này.';
  }

  if (normalized.contains('bad credentials')) {
    return 'Tên đăng nhập hoặc mật khẩu không chính xác.';
  }

  return null;
}

String _fieldLabel(String field) {
  switch (field.toLowerCase()) {
    case 'phone':
      return 'Số điện thoại';
    case 'email':
      return 'Email';
    case 'username':
      return 'Tên đăng nhập';
    default:
      return 'Thông tin';
  }
}
