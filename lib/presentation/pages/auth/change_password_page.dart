import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Lưu local ngay khi initState — trước khi clear state
  String _username = '';
  String _oldPassword = '';

  static const Color _primaryGreen = Color(0xFF2D7E6E);
  static const Color _darkGreen = Color(0xFF1A5C4E);

  @override
  void initState() {
    super.initState();
    // Lấy credentials TRƯỚC khi clearChangePasswordState xóa chúng
    final vm = context.read<AuthViewModel>();
    _username = vm.pendingUsername ?? '';
    _oldPassword = vm.pendingOldPassword ?? '';

    // Clear chỉ trạng thái change (error/success), KHÔNG xóa pending credentials
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().clearChangePasswordState();
    });
  }

  @override
  void dispose() {
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
            errorBuilder: (context, error, stackTrace) => const Icon(
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
            errorBuilder: (context, error, stackTrace) =>
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security_rounded, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                'Yêu cầu bảo mật',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đổi mật khẩu\nlần đầu đăng nhập',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Xin chào, $_username!\n\nVì lý do bảo mật, bạn cần đặt mật khẩu mới trước khi sử dụng hệ thống.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'YÊU CẦU MẬT KHẨU',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildRequirement('Ít nhất 8 ký tự'),
        const SizedBox(height: 8),
        _buildRequirement('Khác với mật khẩu cũ'),
        const SizedBox(height: 8),
        _buildRequirement('Nhập lại khớp xác nhận'),
      ],
    );
  }

  Widget _buildRequirement(String text) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white70,
            size: 11,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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

    if (vm.changeSuccess) return _buildSuccessContent();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: _primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đặt mật khẩu mới',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bắt buộc khi đăng nhập lần đầu tiên.',
            style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 24),

          // Username — read-only, hiển thị từ _username đã lưu local
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1E7E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: _primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7E6E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tài khoản',
                    style: TextStyle(
                      fontSize: 10,
                      color: _primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // New password
          _buildLabel('Mật khẩu mới'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
              if (v == _oldPassword)
                return 'Mật khẩu mới phải khác mật khẩu cũ';
              return null;
            },
            decoration: _buildInputDecoration(
              hint: 'Ít nhất 8 ký tự',
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
          _buildLabel('Xác nhận mật khẩu mới'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
              if (v != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
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

          // Error từ API
          if (vm.changeError != null) ...[
            const SizedBox(height: 12),
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
                      vm.changeError!,
                      style: const TextStyle(
                        color: Color(0xFFE53E3E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: vm.isChangeLoading
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
                          'Xác nhận đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                context.read<AuthViewModel>().logout();
                context.go('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF718096),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Quay lại đăng nhập',
                style: TextStyle(fontSize: 13),
              ),
            ),
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
          'Mật khẩu đã được cập nhật.\nVui lòng đăng nhập lại bằng mật khẩu mới.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.6),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              context.go('/login');
            },
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
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
    // Dùng _username và _oldPassword đã lưu local từ initState
    context.read<AuthViewModel>().changePassword(
      username: _username,
      oldPassword: _oldPassword,
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
