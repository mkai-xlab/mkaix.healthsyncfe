import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isMobile = MediaQuery.of(context).size.width < 900;

    // GoRouter sẽ tự động redirect sau khi login thành công
    return Scaffold(
      body: isMobile
          ? _buildMobileLoginUI(context, authViewModel)
          : _buildDesktopLoginUI(context, authViewModel),
    );
  }

  Widget _buildDesktopLoginUI(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    return Row(
      children: [
        // Left Panel - Green
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF2D7E6E),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.healing,
                              color: Color(0xFF2D7E6E),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VIỆN Y HỌC CÓ TRUYỀN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Text(
                                'QUÂN ĐỘI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'HỖ TRỢ CHẨN ĐOÁN X-QUANG KHỚP GỐI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  // Middle Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Hệ thống hỗ trợ chẩn đoán\nX-quang khớp gối',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Giải pháp ứng dụng trí tuệ nhân tạo\ngiúp bác sĩ phát hiện và phân tích chính xác\ncác tổn thương khớp gối trên hình ảnh\nX-quang kỹ thuật số.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  // Badges
                  Row(
                    children: [
                      _buildBadge('✓ Clinical Validated'),
                      const SizedBox(width: 12),
                      _buildBadge('🔒 Military Grade Encryption'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right Panel - White
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Center(child: _buildLoginForm(context, authViewModel)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLoginUI(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2D7E6E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.healing, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            _buildLoginForm(context, authViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthViewModel authViewModel) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Đăng nhập hệ thống',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng chọn vai trò để đăng nhập',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // Username Field
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Tên đăng nhập',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF2D7E6E),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2D7E6E),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF2D7E6E),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2D7E6E),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Remember Me & Forgot Password
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2D7E6E),
              ),
              const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Handle forgot password
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2D7E6E),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Error Message
          if (authViewModel.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                authViewModel.errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          if (authViewModel.errorMessage != null) const SizedBox(height: 16),
          // Login Button
          SizedBox(
            width: double.infinity,
            child: authViewModel.isLoading
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2D7E6E),
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      await authViewModel.login(
                        _emailController.text,
                        _passwordController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7E6E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Hệ thống bảo mật dữ liệu ở tiêu chuẩn\ny tế quốc gia và quốc tế.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2026 - Đơn vị quản lý ở Viện Y học cổ Truyền Quân đội',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  'VERSION V2.5.0-MILITARY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
