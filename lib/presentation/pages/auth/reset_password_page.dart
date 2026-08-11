import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/password_validation_utils.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ResetPasswordPage extends StatefulWidget {
  /// Email truyền từ ForgotPasswordPage qua GoRouter extra
  final String? email;

  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Lưu local ngay initState — tránh mất khi GoRouter rebuild
  String _email = '';

  static const Color _primaryGreen = AppColors.primary;
  static const Color _darkGreen = Color(0xFF1A5C4E);

  @override
  void initState() {
    super.initState();
    // Lấy email TRƯỚC khi clearPasswordResetState có thể trigger rebuild
    _email = widget.email ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().clearPasswordResetState();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(body: isMobile ? _buildMobile() : _buildDesktop());
  }

  // ─────────────────────────────────────────────
  // DESKTOP
  // ─────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_darkGreen, _primaryGreen, Color(0xFF3A9E8A)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogoHeader(),
                      const Spacer(),
                      _buildLeftContent(),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF4F6F8),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 40,
                ),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MOBILE
  // ─────────────────────────────────────────────
  Widget _buildMobile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_darkGreen, _primaryGreen],
          stops: [0.0, 0.3],
        ),
        color: Color(0xFFF4F6F8),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: _buildLogoHeader(),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: _buildFormContent(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LEFT PANEL
  // ─────────────────────────────────────────────
  Widget _buildLogoHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'lib/presentation/images/logo1.jpg',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_hospital,
              color: _primaryGreen,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'lib/presentation/images/logo2.jpg',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.healing, color: _primaryGreen, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'VIỆN Y HỌC CỔ TRUYỀN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'QUÂN ĐỘI',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Đặt lại\nmật khẩu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nhập mã xác thực đã được gửi\nqua email và tạo mật khẩu mới\ncho tài khoản của bạn.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 32),
        _buildStep('1', 'Nhập email đăng ký', true, done: true),
        const SizedBox(height: 12),
        _buildStep('2', 'Nhận mã xác thực qua email', true, done: true),
        const SizedBox(height: 12),
        _buildStep('3', 'Đặt mật khẩu mới', true),
      ],
    );
  }

  Widget _buildStep(
    String num,
    String text,
    bool isActive, {
    bool done = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? Colors.white
                : isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: _primaryGreen,
                  )
                : Text(
                    num,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? _primaryGreen : Colors.white70,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white54,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CARD
  // ─────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(36),
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final vm = context.watch<AuthViewModel>();

    if (vm.resetSuccess) {
      return _buildSuccessContent();
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back
          GestureDetector(
            onTap: () => context.go('/forgot-password'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 14,
                  color: Color(0xFF718096),
                ),
                SizedBox(width: 4),
                Text(
                  'Quay lại',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: _primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Đặt lại mật khẩu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 6),

          // Email hint — dùng _email đã lưu local
          if (_email.isNotEmpty)
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
                children: [
                  const TextSpan(text: 'Mã xác thực đã gửi đến '),
                  TextSpan(
                    text: _email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Nhập mã xác thực và mật khẩu mới.',
              style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),

          const SizedBox(height: 28),

          // Token field
          _buildLabel('Mã xác thực'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _tokenController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Color(0xFF1A2B3C),
            ),
            keyboardType: TextInputType.text,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập mã xác thực';
              }
              return null;
            },
            decoration: _buildInputDecoration(
              hint: 'Nhập mã từ email',
              icon: Icons.vpn_key_outlined,
            ),
          ),
          const SizedBox(height: 18),

          // New password
          _buildLabel('Mật khẩu mới'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              return PasswordValidationUtils.validateNewPassword(v);
            },
            decoration: _buildInputDecoration(
              hint: '8-32 ký tự, Aa, 0-9, @#!',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _showNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF718096),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Confirm password
          _buildLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (v != _newPasswordController.text) {
                return 'Mật khẩu không khớp';
              }
              return null;
            },
            decoration: _buildInputDecoration(
              hint: 'Nhập lại mật khẩu mới',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF718096),
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Real-time match indicator
          if (_newPasswordController.text.isNotEmpty &&
              _confirmPasswordController.text.isNotEmpty)
            _buildMatchIndicator(),

          const SizedBox(height: 20),

          // Error
          if (vm.resetError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFE53E3E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.resetError!,
                      style: const TextStyle(
                        color: Color(0xFFE53E3E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit
          SizedBox(
            width: double.infinity,
            height: 48,
            child: vm.isResetLoading
                ? Container(
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_rounded, size: 18),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4F1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: _primaryGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đổi mật khẩu thành công!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2B3C),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Mật khẩu của bạn đã được cập nhật.\nVui lòng đăng nhập lại bằng mật khẩu mới.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.6),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _buildLabel(String label) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
        children: [
          TextSpan(text: label),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFE53E3E)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchIndicator() {
    final match =
        _newPasswordController.text == _confirmPasswordController.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: match ? const Color(0xFFE6F4F1) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 15,
            color: match ? _primaryGreen : const Color(0xFFE53E3E),
          ),
          const SizedBox(width: 8),
          Text(
            match ? 'Mật khẩu khớp' : 'Mật khẩu chưa khớp',
            style: TextStyle(
              fontSize: 12,
              color: match ? _primaryGreen : const Color(0xFFE53E3E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF718096), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryGreen, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.8),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthViewModel>().resetPassword(
      email: _email,
      token: _tokenController.text.trim(),
      newPassword: _newPasswordController.text,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
