import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/toast_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DoctorChangePasswordPage extends StatefulWidget {
  final VoidCallback onCancel;

  const DoctorChangePasswordPage({super.key, required this.onCancel});

  @override
  State<DoctorChangePasswordPage> createState() =>
      _DoctorChangePasswordPageState();
}

class _DoctorChangePasswordPageState extends State<DoctorChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  static const _primary = AppColors.primary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().clearChangePasswordState();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 56, 32, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 576),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _breadcrumb(),
                    const SizedBox(height: 24),
                    _passwordCard(),
                    const SizedBox(height: 48),
                    _footer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _breadcrumb() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tài khoản',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _passwordCard() {
    final vm = context.watch<AuthViewModel>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: _primary, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(26, 26, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cập nhật mật khẩu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để bảo mật tài khoản của bạn.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            _passwordField(
              label: 'Mật khẩu hiện tại',
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              onToggleVisibility: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            _passwordField(
              label: 'Mật khẩu mới',
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              onChanged: (_) => setState(() {}),
              onToggleVisibility: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }
                if (value.length < 8) {
                  return 'Mật khẩu mới phải có tối thiểu 8 ký tự';
                }
                if (value.length > 32) {
                  return 'Mật khẩu mới không được quá 32 ký tự';
                }
                if (!_hasLetterAndNumber(value)) {
                  return 'Mật khẩu mới phải bao gồm chữ cái và số';
                }
                if (value == _currentPasswordController.text) {
                  return 'Mật khẩu mới không được trùng mật khẩu hiện tại';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            _passwordField(
              label: 'Xác nhận mật khẩu mới',
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              onChanged: (_) => setState(() {}),
              onToggleVisibility: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng xác nhận mật khẩu mới';
                }
                if (value != _newPasswordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _securityRequirements(),
            if (vm.changeError != null) ...[
              const SizedBox(height: 16),
              _errorBox(vm.changeError!),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: vm.isChangeLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.borderStrong,
                        elevation: 8,
                        shadowColor: _primary.withValues(alpha: 0.22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: vm.isChangeLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cập nhật mật khẩu',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: vm.isChangeLoading ? null : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 21,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface1,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _inputBorder(AppColors.borderStrong),
            enabledBorder: _inputBorder(AppColors.borderStrong),
            focusedBorder: _inputBorder(_primary, width: 1.5),
            errorBorder: _inputBorder(AppColors.error, width: 1.4),
            focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _securityRequirements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: _primary),
              SizedBox(width: 8),
              Text(
                'Yêu cầu bảo mật:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _RequirementText('Tối thiểu 8 ký tự'),
          _RequirementText('Bao gồm chữ cái và số'),
          _RequirementText('Không trùng với mật khẩu gần nhất'),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return const Center(
      child: Text(
        '© 2024 Viện Y học Cổ truyền Quân đội. Hệ thống chẩn đoán Knee AI.\nMã hóa đầu cuối 256-bit AES.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  bool _hasLetterAndNumber(String value) {
    return RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthViewModel>();
    final username = auth.currentUser?.username.trim() ?? '';
    if (username.isEmpty) {
      AppToast.showError('Không tìm thấy thông tin tài khoản.');
      return;
    }

    final success = await auth.changePassword(
      username: username,
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted || !success) return;
    AppToast.showSuccess('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.');
    await auth.logout();
  }
}

class _RequirementText extends StatelessWidget {
  final String text;

  const _RequirementText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
