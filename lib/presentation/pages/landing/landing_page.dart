import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _gold = Color(0xFFC5A059);
  static const _paper = Color(0xFFF7F6F2);
  static const _text = Color(0xFF151C27);
  static const _muted = Color(0xFF3E4945);
  static const _maxWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 80,
            backgroundColor: Colors.white.withValues(alpha: 0.96),
            surfaceTintColor: Colors.white,
            elevation: 1,
            titleSpacing: 0,
            title: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _LogoBlock(
                        compact: MediaQuery.sizeOf(context).width < 720,
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                      FilledButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Đăng nhập'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HeroSection(onLogin: () => context.go('/login')),
          ),
          const SliverToBoxAdapter(child: _GoldDivider()),
          const SliverToBoxAdapter(child: _MissionSection()),
          const SliverToBoxAdapter(child: _FeatureSection()),
          const SliverToBoxAdapter(child: _IdentitySection()),
          const SliverToBoxAdapter(child: _LandingFooter()),
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  final bool compact;

  const _LogoBlock({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoImage(path: 'lib/presentation/images/logo1.jpg'),
        const SizedBox(width: 10),
        _LogoImage(path: 'lib/presentation/images/logo2.jpg'),
        if (!compact) ...[
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VIỆN Y HỌC CỔ TRUYỀN',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              Text(
                'QUÂN ĐỘI',
                style: TextStyle(
                  color: LandingPage._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoImage extends StatelessWidget {
  final String path;

  const _LogoImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onLogin;

  const _HeroSection({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return _PatternBackground(
      child: _SectionPadding(
        child: Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: isWide ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Pill(),
                  const SizedBox(height: 24),
                  Text(
                    'Kỹ thuật hiện đại - Y học cổ truyền: Tương lai của chẩn đoán khớp gối',
                    style: TextStyle(
                      color: LandingPage._text,
                      fontSize: isWide ? 48 : 34,
                      height: 1.14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hệ thống AI tiên tiến giúp chẩn đoán chính xác, nhanh chóng và tin cậy. Kết hợp tinh hoa y học dân tộc với sức mạnh trí tuệ nhân tạo.',
                    style: TextStyle(
                      color: LandingPage._muted,
                      fontSize: 18,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isWide ? 56 : 0, height: isWide ? 0 : 36),
            Expanded(
              flex: isWide ? 1 : 0,
              child: AspectRatio(
                aspectRatio: 1.48,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE2F3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'lib/presentation/images/banner1.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF0A1628),
                          child: const Icon(
                            Icons.image_search_rounded,
                            color: Colors.white54,
                            size: 72,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.34),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 18,
                        bottom: 18,
                        child: _ImageBadge(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDEA5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF261900)),
          SizedBox(width: 8),
          Text(
            'TIÊN PHONG Y HỌC SỐ',
            style: TextStyle(
              color: Color(0xFF261900),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_rounded, color: AppColors.primaryLight),
          SizedBox(width: 8),
          Text(
            'AI phân tích X-quang khớp gối',
            style: TextStyle(
              color: LandingPage._text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;
    return Container(
      color: LandingPage._paper,
      child: _SectionPadding(
        child: Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionHeading('Sứ mệnh của chúng tôi'),
                  SizedBox(height: 18),
                  Text(
                    'Viện Y Học Cổ Truyền Quân Đội không ngừng kết hợp hài hòa giữa tri thức y học cổ truyền với các đột phá công nghệ hiện đại, kiến tạo hệ sinh thái chăm sóc sức khỏe nơi sự chính xác của AI hỗ trợ hiệu quả y dược học dân tộc.',
                    style: TextStyle(
                      color: LandingPage._muted,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isWide ? 48 : 0, height: isWide ? 0 : 28),
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _MetricCard(value: '45+', label: 'Năm kinh nghiệm'),
                  _MetricCard(value: '99%', label: 'Độ chính xác AI'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _SectionPadding(
        child: Column(
          children: [
            const Text(
              'Ưu điểm vượt trội của hệ thống AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingPage._text,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Text(
                'Công nghệ phân tích hình ảnh chuyên sâu giúp phát hiện sớm các dấu hiệu thoái hóa và tổn thương khớp gối với hiệu suất vượt trội.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingPage._muted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 44),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = width >= 920 ? (width - 48) / 3 : width;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: const [
                    _FeatureCard(
                      icon: Icons.biotech_rounded,
                      title: 'Độ chính xác cao',
                      body:
                          'Thuật toán được huấn luyện trên dữ liệu lâm sàng, giảm thiểu sai sót trong chẩn đoán hình ảnh.',
                    ),
                    _FeatureCard(
                      icon: Icons.bolt_rounded,
                      title: 'Phân tích tức thì',
                      body:
                          'Kết quả được xử lý nhanh chóng, giúp bác sĩ đưa ra phác đồ điều trị kịp thời và tối ưu.',
                    ),
                    _FeatureCard(
                      icon: Icons.assignment_rounded,
                      title: 'Hỗ trợ lâm sàng',
                      body:
                          'Cung cấp báo cáo phân tích chi tiết, hỗ trợ bác sĩ trong các ca khám và điều trị phức tạp.',
                    ),
                  ].map((card) => SizedBox(width: cardWidth, child: card)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE2F3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: LandingPage._text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: LandingPage._muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: _SectionPadding(
        child: Column(
          children: const [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 36,
              runSpacing: 24,
              children: [
                _IdentityMark(
                  icon: Icons.account_balance_rounded,
                  label: 'VIỆN Y HỌC CỔ TRUYỀN QUÂN ĐỘI',
                ),
                _IdentityMark(
                  icon: Icons.psychology_rounded,
                  label: 'MITM AI WORDMARK',
                ),
              ],
            ),
            SizedBox(height: 36),
            Text(
              'Trải nghiệm dịch vụ y tế đẳng cấp quốc phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityMark extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IdentityMark({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.primaryLight, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F3FF),
      child: _SectionPadding(
        vertical: 54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Viện Y Học Cổ Truyền Quân Đội',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Số 442 Kim Giang, Đại Kim, Hoàng Mai, Hà Nội.\nĐiện thoại: (024) 3858 3135\nEmail: info@yhoccotruyenquandoi.vn',
              style: TextStyle(
                color: LandingPage._muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            SizedBox(height: 28),
            _GoldDivider(),
            SizedBox(height: 24),
            Text(
              '© 2026 Viện Y Học Cổ Truyền Quân Đội. Bảo lưu mọi quyền.',
              style: TextStyle(color: LandingPage._muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;

  const _MetricCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandingPage._gold.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 44,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF775A19),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 48, height: 2, color: const Color(0xFF775A19)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, LandingPage._gold, Colors.transparent],
        ),
      ),
    );
  }
}

class _SectionPadding extends StatelessWidget {
  final Widget child;
  final double vertical;

  const _SectionPadding({required this.child, this.vertical = 80});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LandingPage._maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: vertical),
          child: child,
        ),
      ),
    );
  }
}

class _PatternBackground extends StatelessWidget {
  final Widget child;

  const _PatternBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(),
      child: Container(
        color: Colors.white.withValues(alpha: 0.96),
        child: child,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LandingPage._gold.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const step = 100.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        canvas.drawLine(Offset(x + 50, y), Offset(x + 50, y + 100), paint);
        canvas.drawLine(Offset(x, y + 50), Offset(x + 100, y + 50), paint);
        canvas.drawCircle(Offset(x + 50, y + 50), 10, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
