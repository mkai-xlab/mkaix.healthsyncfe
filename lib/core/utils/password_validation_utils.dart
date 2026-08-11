class PasswordValidationUtils {
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[^A-Za-z0-9\s]');

  static const String requirementMessage =
      'Mật khẩu phải có 8-32 ký tự, gồm chữ hoa, chữ thường, chữ số và ký tự đặc biệt';

  static String? validateNewPassword(
    String? value, {
    String emptyMessage = 'Vui lòng nhập mật khẩu mới',
  }) {
    if (value == null || value.isEmpty) return emptyMessage;
    if (!isValid(value)) return requirementMessage;
    return null;
  }

  static bool isValid(String value) {
    return value.length >= 8 &&
        value.length <= 32 &&
        _hasUppercase.hasMatch(value) &&
        _hasLowercase.hasMatch(value) &&
        _hasDigit.hasMatch(value) &&
        _hasSpecial.hasMatch(value);
  }
}
