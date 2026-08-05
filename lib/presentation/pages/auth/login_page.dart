import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _primaryGreen = AppColors.primary;
  static const Color _darkGreen = Color(0xFF1A5C4E);
  static const Color _lightGreen = Color(0xFF3A9E8A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      body: isMobile
          ? _buildMobile(context, authViewModel)
          : _buildDesktop(context, authViewModel),
    );
  }

  // ─────────────────────────────────────────────
  // DESKTOP LAYOUT
  // ─────────────────────────────────────────────
  Widget _buildDesktop(BuildContext context, AuthViewModel vm) {
    return Row(
      children: [
        // ── LEFT PANEL ──
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_darkGreen, _primaryGreen, _lightGreen],
              ),
            ),
            child: Stack(
              children: [
                // subtle grid overlay
                Positioned.fill(child: _buildGridOverlay()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftHeader(),
                      const Spacer(),
                      _buildXrayCard(),
                      const SizedBox(height: 40),
                      _buildLeftDescription(),
                      const Spacer(),
                      _buildBadgesRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── RIGHT PANEL ──
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
                child: _buildLoginCard(context, vm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────────
  Widget _buildMobile(BuildContext context, AuthViewModel vm) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_darkGreen, _primaryGreen],
          stops: [0.0, 0.35],
        ),
        color: Color(0xFFF4F6F8),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // mobile header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: _buildLeftHeader(),
              ),
              // white card
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
                child: _buildLoginForm(context, vm),
              ),
              const SizedBox(height: 24),
              _buildFooterText(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LEFT PANEL WIDGETS
  // ─────────────────────────────────────────────
  Widget _buildGridOverlay() {
    return CustomPaint(painter: _GridPainter());
  }

  Widget _buildLeftHeader() {
    return Row(
      children: [
        // Logo 1
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
        // Logo 2
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
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXrayCard() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // X-ray image background
          Positioned.fill(
            child: Image.asset(
              'lib/presentation/images/banner1.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF0A1628),
                child: const Center(
                  child: Icon(
                    Icons.image_search,
                    color: Colors.white24,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          // dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // AI badge top-right
          Positioned(
            top: 12,
            right: 12,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'AI ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // X-ray label top-left
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'X-quang khớp gối',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Analysis results bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _buildAnalysisBadge('CARTILAGE', 'HIGH', Colors.cyan),
                const SizedBox(width: 8),
                _buildAnalysisBadge('MINISCUS', 'OPTIMAL', Colors.green),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Text(
                    '98.4%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Hỗ trợ chẩn đoán X-quang',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Giải pháp ứng dụng trí tuệ nhân tạo tiên tiến,\nphát hiện và phân tích chính xác tổn thương\nkhớp gối trên hình ảnh kỹ thuật số.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildBadgesRow() {
    return Row(
      children: [
        _buildBadge(Icons.verified, 'Clinical'),
        const SizedBox(width: 12),
        _buildBadge(Icons.security, 'Military'),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RIGHT PANEL — LOGIN CARD
  // ─────────────────────────────────────────────
  Widget _buildLoginCard(BuildContext context, AuthViewModel vm) {
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
      child: _buildLoginForm(context, vm),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryGreen,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text(
            'Về trang giới thiệu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 18),
        // Title
        const Text(
          'Đăng nhập hệ thống',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2B3C),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vui lòng điền tài khoản để làm việc',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A8B9A)),
        ),
        const SizedBox(height: 28),

        // Username
        _buildInputLabel('Tên đăng nhập'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _usernameController,
          hint: 'Nhập tên đăng nhập',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),

        // Password
        _buildInputLabel('Mật khẩu'),
        const SizedBox(height: 6),
        _buildPasswordField(),
        const SizedBox(height: 14),

        // Remember me + forgot
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: _primaryGreen,
                side: const BorderSide(color: Color(0xFFCBD5E0), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ghi nhớ',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/forgot-password'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryGreen,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Error message
        if (vm.errorMessage != null) ...[
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
                    vm.errorMessage!,
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

        // Login button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: vm.isLoading
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
                  onPressed: () async {
                    await vm.login(
                      _usernameController.text.trim(),
                      _passwordController.text,
                    );
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
                        'Đăng nhập hệ thống',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Security note
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Color(0xFF718096),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hệ thống bảo mật dữ liệu bệnh nhân theo tiêu chuẩn quốc gia.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildFooterText(),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF718096), size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
      decoration: InputDecoration(
        hintText: 'Nhập mật khẩu',
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF718096),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF718096),
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
      ),
    );
  }

  Widget _buildFooterText() {
    return Column(
      children: [
        const Text(
          '© 2026 . Bản quyền thuộc Viện Y học Cổ truyền Quân sự.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFFADB5BD)),
        ),
        const SizedBox(height: 4),
        const Text(
          'VERSION V2.5.0-MILITARY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFFCBD5E0),
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// GRID OVERLAY PAINTER
// ─────────────────────────────────────────────
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
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
