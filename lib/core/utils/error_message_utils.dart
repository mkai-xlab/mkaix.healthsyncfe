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

  return raw.isEmpty ? 'Đã có lỗi xảy ra. Vui lòng thử lại.' : raw;
}
