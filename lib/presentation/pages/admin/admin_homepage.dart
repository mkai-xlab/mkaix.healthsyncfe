import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/services/toast_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/media_url_resolver.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:fe/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:fe/presentation/viewmodels/notification_viewmodel.dart';
import 'package:fe/data/models/role_model.dart';
import 'package:fe/domain/entities/doctor_account_entity.dart';
import 'package:fe/domain/entities/notification_entity.dart';
import 'package:fe/data/datasources/permission_remote_datasource.dart';
import 'package:fe/presentation/viewmodels/permission_viewmodel.dart';
import 'package:fe/presentation/pages/admin/permission_page.dart';
import 'package:fe/presentation/pages/admin/feature_permission_catalog_page.dart';
import 'package:fe/presentation/pages/admin/audit_log_page.dart';
import 'package:fe/presentation/pages/admin/knowledge_documents_page.dart';
import 'package:fe/presentation/pages/auth/account_change_password_page.dart';
import 'package:fe/presentation/widgets/pagination_bar.dart';
import 'package:fe/presentation/widgets/authenticated_avatar_image.dart';
import 'package:http/http.dart' as http;

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  static const Color _pageBackground = Color(0xFFF0F4F3);

  int _selectedNavIndex = 0;
  DoctorAccountEntity? _selectedUser;
  int? _hoveredUserId;
  bool _showChangePassword = false;
  bool _isSystemSettingsExpanded = false;

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  Widget _buildAccountAvatar({
    required String name,
    required String? avatarUrl,
    required double radius,
    Color color = AppColors.primary,
  }) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    final imageUrl = resolveMediaUrl(avatarUrl ?? '');
    final fallback = Text(
      initial,
      style: TextStyle(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: imageUrl.isEmpty
          ? fallback
          : ClipOval(
              child: SizedBox.expand(
                child: AuthenticatedAvatarImage(
                  imageUrl: imageUrl,
                  token: _token,
                  fallback: fallback,
                ),
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<AdminAccountViewModel>().fetchFirstPage(token);
      context.read<AdminDashboardViewModel>().loadStats(token);
      context.read<AuditLogViewModel>().fetchFirstPage(token);
    });
  }

  // @override
  // void dispose() {
  //   _debounce?.cancel(); // HĂ¡Â»Â§y bĂ¡Â»Â timer khi widget bĂ¡Â»â€¹ dispose
  //   _scrollController.dispose();
  //   super.dispose();
  // }
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (!isMobile) _buildSidebar(context),
          // Main Content
          Expanded(child: _buildMainContent(context)),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.primary,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'lib/presentation/images/logo1.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'lib/presentation/images/logo2.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.healing,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'VIỆN Y HỌC CỔ TRUYỀN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'QUÂN ĐỘI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'QUẢN TRỊ HỆ THỐNG',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(0, 'Trang chủ', Icons.home_outlined),
                _buildNavItem(1, 'Quản lý người dùng', Icons.people_outline),
                _buildNavItem(
                  2,
                  'Quản lý phân quyền',
                  Icons.admin_panel_settings_outlined,
                ),
                _buildNavItem(3, 'Lịch sử hoạt động', Icons.history_outlined),
                _buildNavItem(5, 'Cấu hình hệ thống', Icons.settings_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected =
        _selectedNavIndex == index || (index == 5 && _selectedNavIndex == 6);
    final borderRadius = BorderRadius.circular(8);
    return Material(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: borderRadius,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedNavIndex = index;
            _showChangePassword = false;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSystemSettingsNavGroup() {
    final isSelected = _selectedNavIndex == 5 || _selectedNavIndex == 6;
    final borderRadius = BorderRadius.circular(8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: borderRadius,
          child: ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            title: Text(
              'CĂ¡ÂºÂ¥u hÄ‚Â¬nh hĂ¡Â»â€¡ thĂ¡Â»â€˜ng',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: Icon(
              _isSystemSettingsExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: Colors.white70,
              size: 18,
            ),
            onTap: () {
              setState(() {
                _isSystemSettingsExpanded = !_isSystemSettingsExpanded;
                _selectedNavIndex = 5;
                _showChangePassword = false;
              });
            },
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ),
        if (_isSystemSettingsExpanded || _selectedNavIndex == 6)
          _buildSystemSettingsChildNavItem(
            index: 6,
            label: 'QuĂ¡ÂºÂ£n lÄ‚Â½ tÄ‚Â i liĂ¡Â»â€¡u',
            icon: Icons.description_outlined,
          ),
      ],
    );
  }

  Widget _buildSystemSettingsChildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedNavIndex == index;
    final borderRadius = BorderRadius.circular(8);

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Material(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: borderRadius,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 18,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedNavIndex = index;
              _isSystemSettingsExpanded = true;
              _showChangePassword = false;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'lib/presentation/images/logo1.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_hospital,
                            color: Color(0xFF2D7E6E),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'lib/presentation/images/logo2.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.healing,
                            color: Color(0xFF2D7E6E),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VIỆN Y HỌC CỔ TRUYỀN QUÂN ĐỘI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildNavItem(0, 'Trang chủ', Icons.home_outlined),
                  _buildNavItem(1, 'Quản lý người dùng', Icons.people_outline),
                  _buildNavItem(
                    2,
                    'Quản lý phân quyền',
                    Icons.admin_panel_settings_outlined,
                  ),
                  _buildNavItem(3, 'Lịch sử hoạt động', Icons.history_outlined),
                  _buildNavItem(
                    5,
                    'Cấu hình hệ thống',
                    Icons.settings_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_showChangePassword) {
      return Container(
        color: _pageBackground,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: AccountChangePasswordPage(
                onCancel: () => setState(() {
                  _showChangePassword = false;
                }),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedNavIndex == 1) {
      return _buildUserManagementPage(context);
    }
    if (_selectedNavIndex == 2) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      return Container(
        color: _pageBackground,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ChangeNotifierProvider(
                create: (_) => PermissionViewModel(
                  PermissionRemoteDataSourceImpl(http.Client(), token: token),
                ),
                child: const FeaturePermissionCatalogPage(),
              ),
            ),
          ],
        ),
      );
    }

    // MĂ¡ÂºÂ·c Ă„â€˜Ă¡Â»â€¹nh hiĂ¡Â»Æ’n thĂ¡Â»â€¹ Dashboard (index 0)
    if (_selectedNavIndex == 3) {
      return Container(
        color: _pageBackground,
        child: Column(
          children: [
            _buildTopBar(context),
            const Expanded(child: AuditLogPage()),
          ],
        ),
      );
    }
    if (_selectedNavIndex == 5) {
      return _buildSystemSettingsPage(context);
    }
    if (_selectedNavIndex == 6) {
      return Container(
        color: _pageBackground,
        child: Column(
          children: [
            _buildTopBar(context),
            const Expanded(child: KnowledgeDocumentsPage()),
          ],
        ),
      );
    }

    return Container(
      color: _pageBackground,
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản trị hệ thống',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Giám sát hoạt động hệ thống AI hỗ trợ chẩn đoán X-quang khớp gối',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Statistics Cards
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),
                  // Charts Section
                  SizedBox(height: 410, child: _buildKLGradeDistribution()),
                  const SizedBox(height: 24),
                  // Activity Log
                  _buildActivityLog(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsPage(BuildContext context) {
    return Container(
      color: _pageBackground,
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cấu hình hệ thống',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quản lý các chức năng vận hành, dữ liệu nền và thiết lập hệ thống.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSettingsFeatureCard(
                        icon: Icons.description_outlined,
                        title: 'Quản lý tài liệu',
                        description:
                            'Quản lý tài liệu lâm sàng, tài liệu AI và bài báo khoa học.',
                        onTap: () => setState(() {
                          _selectedNavIndex = 6;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeDocumentsPage(BuildContext context) {
    return Container(
      color: _pageBackground,
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh sÄ‚Â¡ch tÄ‚Â i liĂ¡Â»â€¡u & bÄ‚Â i bÄ‚Â¡o khoa hĂ¡Â»Âc',
                              style: TextStyle(
                                fontSize: 34,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'QuĂ¡ÂºÂ£n lÄ‚Â½ vÄ‚Â  xem xÄ‚Â©t cÄ‚Â¡c tÄ‚Â i liĂ¡Â»â€¡u lÄ‚Â¢m sÄ‚Â ng, tÄ‚Â i liĂ¡Â»â€¡u vĂ¡Â»Â AI vÄ‚Â  tÄ‚Â i liĂ¡Â»â€¡u nghiÄ‚Âªn cĂ¡Â»Â©u.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            _showUploadKnowledgeDocumentDialog(context),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text(
                          'TĂ¡ÂºÂ£i lÄ‚Âªn tÄ‚Â i liĂ¡Â»â€¡u mĂ¡Â»â€ºi',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildDocumentFilterBar(),
                  const SizedBox(height: 18),
                  _buildEmptyDocumentTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'TÄ‚Â¬m kiĂ¡ÂºÂ¿m tÄ‚Â i liĂ¡Â»â€¡u...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildDocumentFilterChip('TĂ¡ÂºÂ¥t cĂ¡ÂºÂ£', selected: true),
          _buildDocumentFilterChip('BÄ‚Â i bÄ‚Â¡o khoa hĂ¡Â»Âc'),
          _buildDocumentFilterChip('HĂ¡Â»â€œ sĂ†Â¡ bĂ¡Â»â€¡nh Ä‚Â¡n'),
          _buildDocumentFilterChip('KĂ¡ÂºÂ¿t quĂ¡ÂºÂ£ xÄ‚Â©t nghiĂ¡Â»â€¡m'),
        ],
      ),
    );
  }

  Widget _buildDocumentFilterChip(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? AppColors.primaryLight : Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? AppColors.primaryLight : AppColors.borderStrong,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildEmptyDocumentTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFEFF4FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _DocumentHeaderCell('TÄ‚ÂN TÄ‚â‚¬I LIĂ¡Â»â€ U'),
                ),
                Expanded(child: _DocumentHeaderCell('LOĂ¡ÂºÂ I')),
                Expanded(
                  child: _DocumentHeaderCell(
                    'BĂ¡Â»â€ NH NHÄ‚â€N\nLIÄ‚ÂN QUAN',
                  ),
                ),
                Expanded(child: _DocumentHeaderCell('NGÄ‚â‚¬Y TĂ¡ÂºÂ¢I')),
                Expanded(child: _DocumentHeaderCell('TRĂ¡ÂºÂ NG THÄ‚ÂI\nAI')),
                SizedBox(width: 72, child: _DocumentHeaderCell('THAO\nTÄ‚ÂC')),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: const Column(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 56,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 14),
                Text(
                  'ChĂ†Â°a cÄ‚Â³ tÄ‚Â i liĂ¡Â»â€¡u nÄ‚Â o',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'TĂ¡ÂºÂ£i lÄ‚Âªn tÄ‚Â i liĂ¡Â»â€¡u Ă„â€˜Ă¡ÂºÂ§u tiÄ‚Âªn Ă„â€˜Ă¡Â»Æ’ bĂ¡ÂºÂ¯t Ă„â€˜Ă¡ÂºÂ§u quĂ¡ÂºÂ£n lÄ‚Â½ kho tri thĂ¡Â»Â©c.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Text(
                  'Showing 0 to 0 of 0 results',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                ),
                Spacer(),
                Icon(Icons.chevron_left_rounded, color: Color(0xFFCBD5E1)),
                SizedBox(width: 8),
                Text('1', style: TextStyle(color: Color(0xFF9CA3AF))),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadKnowledgeDocumentDialog(BuildContext context) async {
    const allowedExtensions = ['pdf', 'doc', 'docx', 'docs'];
    PlatformFile? selectedFile;
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: allowedExtensions,
                allowMultiple: false,
                withData: true,
              );
              if (result == null || result.files.isEmpty) return;

              final file = result.files.first;
              final extension = _fileExtension(file.name);
              if (!allowedExtensions.contains(extension)) {
                setDialogState(() {
                  selectedFile = null;
                  validationError =
                      'ChĂ¡Â»â€° hĂ¡Â»â€” trĂ¡Â»Â£ file PDF, DOC, DOCX hoĂ¡ÂºÂ·c DOCS. Vui lÄ‚Â²ng chĂ¡Â»Ân lĂ¡ÂºÂ¡i.';
                });
                return;
              }

              setDialogState(() {
                selectedFile = file;
                validationError = null;
              });
            }

            final file = selectedFile;

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                'TĂ¡ÂºÂ£i lÄ‚Âªn tÄ‚Â i liĂ¡Â»â€¡u',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ChĂ¡Â»Ân tÄ‚Â i liĂ¡Â»â€¡u Ă„â€˜Ă¡Â»Æ’ bĂ¡Â»â€¢ sung vÄ‚Â o kho tri thĂ¡Â»Â©c. HĂ¡Â»â€¡ thĂ¡Â»â€˜ng hiĂ¡Â»â€¡n hĂ¡Â»â€” trĂ¡Â»Â£ PDF, DOC, DOCX vÄ‚Â  DOCS.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: pickFile,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: validationError == null
                                ? AppColors.borderStrong
                                : AppColors.error,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 36,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              file == null
                                  ? 'NhĂ¡ÂºÂ¥n Ă„â€˜Ă¡Â»Æ’ chĂ¡Â»Ân file'
                                  : file.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              file == null
                                  ? 'Ă„ÂĂ¡Â»â€¹nh dĂ¡ÂºÂ¡ng: .pdf, .doc, .docx, .docs'
                                  : _formatFileSize(file.size),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        validationError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('HĂ¡Â»Â§y'),
                ),
                FilledButton.icon(
                  onPressed: file == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ă„ÂÄ‚Â£ chĂ¡Â»Ân ${file.name}. API upload sĂ¡ÂºÂ½ Ă„â€˜Ă†Â°Ă¡Â»Â£c tÄ‚Â­ch hĂ¡Â»Â£p Ă¡Â»Å¸ bĂ†Â°Ă¡Â»â€ºc tiĂ¡ÂºÂ¿p theo.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('TĂ¡ÂºÂ£i lÄ‚Âªn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().trim().split('.');
    if (parts.length < 2) return '';
    return parts.last;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'KhÄ‚Â´ng rÄ‚Âµ dung lĂ†Â°Ă¡Â»Â£ng';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  Widget _buildUserManagementPage(BuildContext context) {
    return Container(
      color: _pageBackground,
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Consumer<AdminAccountViewModel>(
              builder: (context, viewModel, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ă¢â€â‚¬Ă¢â€â‚¬ LEFT: main list Ă¢â€â‚¬Ă¢â€â‚¬
                    Expanded(
                      flex: 7,
                      child: _buildUserListPanel(context, viewModel),
                    ),
                    // Ă¢â€â‚¬Ă¢â€â‚¬ RIGHT: detail panel Ă¢â€â‚¬Ă¢â€â‚¬
                    Container(
                      width: 320,
                      color: Colors.white,
                      child: _buildUserDetailSidebar(context, viewModel),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬ LEFT PANEL Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬
  Widget _buildUserListPanel(
    BuildContext context,
    AdminAccountViewModel viewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Quản lý người dùng',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Danh sách người dùng, kỹ thuật viên và nhân viên hệ thống.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showRolePermissionDialog(context),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                label: const Text('Phân quyền'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D7E6E),
                  side: const BorderSide(color: Color(0xFF2D7E6E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Thêm tài khoản'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7E6E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stat cards are temporarily hidden.
          // _buildUserStatCards(viewModel),
          // const SizedBox(height: 20),

          // Filter bar
          _buildFilterBar(context, viewModel),
          const SizedBox(height: 16),

          // Table header
          _buildTableHeader(),
          const SizedBox(height: 4),

          // User rows
          if (viewModel.isLoading && viewModel.accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (viewModel.errorMessage != null && viewModel.accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text(viewModel.errorMessage!)),
            )
          else
            ...viewModel.accounts.map(
              (account) => _buildUserRow(context, account, viewModel),
            ),

          // Load more / pagination
          if (viewModel.isLoading && viewModel.accounts.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 12),
          _buildPaginationBar(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildUserStatCards(AdminAccountViewModel viewModel) {
    final total = viewModel.totalElements;
    final doctors = viewModel.accounts.where((a) => a.role == 'DOCTOR').length;
    final ktv = viewModel.accounts.where((a) => a.role == 'KTV').length;
    final locked = viewModel.accounts
        .where((a) => a.status == 'INACTIVE')
        .length;
    final online = viewModel.accounts.where((a) => a.status == 'ACTIVE').length;

    return Row(
      children: [
        _buildUMStatCard(
          label: 'TĂ¡Â»â€NG SĂ¡Â»Â',
          value: total.toString(),
          sub: 'Ă¢â€ â€˜ +3 mĂ¡Â»â€ºi',
          subColor: const Color(0xFF2D7E6E),
          borderColor: const Color(0xFF2D7E6E),
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'BÄ‚ÂC SĂ„Â¨',
          value: doctors.toString(),
          sub: 'Ă„Âang cÄ‚Â´ng tÄ‚Â¡c',
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'KĂ¡Â»Â¸ THUĂ¡ÂºÂ¬T VIÄ‚ÂN',
          value: ktv.toString(),
          sub: 'HĂ¡Â»â€” trĂ¡Â»Â£ CDHA',
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'Ă„ÂÄ‚Æ’ KHÄ‚â€œA',
          value: locked.toString().padLeft(2, '0'),
          sub: 'Vi phĂ¡ÂºÂ¡m CS',
          subColor: const Color(0xFFE53E3E),
          valueColor: const Color(0xFFE53E3E),
          borderColor: const Color(0xFFE53E3E),
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'TRĂ¡Â»Â°C TUYĂ¡ÂºÂ¾N',
          value: online.toString(),
          sub: 'Ă¢â€”Â Ă¢â€”Â Ă¢â€”â€¹',
        ),
      ],
    );
  }

  Widget _buildUMStatCard({
    required String label,
    required String value,
    String? sub,
    Color subColor = const Color(0xFF718096),
    Color valueColor = const Color(0xFF1A2B3C),
    Color borderColor = Colors.transparent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: borderColor, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF718096),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor,
                height: 1,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 10, color: subColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    AdminAccountViewModel viewModel,
  ) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              onChanged: (value) =>
                  viewModel.searchByNameDebounced(value, token),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF718096),
                ),
                hintText: 'Tìm kiếm người dùng...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A9A96),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D7E6E),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusFilterDropdown(context, viewModel),
      ],
    );
  }

  Widget _buildStatusFilterDropdown(
    BuildContext context,
    AdminAccountViewModel viewModel,
  ) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final currentStatus = viewModel.currentStatus;
    final label = switch (currentStatus) {
      'ACTIVE' => 'Active',
      'INACTIVE' => 'Inactive',
      _ => 'Trạng thái',
    };

    return PopupMenuButton<String>(
      tooltip: 'Lọc trạng thái',
      onSelected: (value) =>
          viewModel.filterByStatus(value.isEmpty ? null : value, token),
      itemBuilder: (context) => const [
        PopupMenuItem<String>(value: '', child: Text('Tất cả trạng thái')),
        PopupMenuItem<String>(value: 'ACTIVE', child: Text('Active')),
        PopupMenuItem<String>(value: 'INACTIVE', child: Text('Inactive')),
      ],
      child: _buildFilterChip(label),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF718096),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF718096),
      letterSpacing: 0.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('TÊN', style: style)),
          Expanded(flex: 2, child: Text('CHỨC VỤ', style: style)),
          Expanded(flex: 3, child: Text('EMAIL', style: style)),
          Expanded(flex: 2, child: Text('TRẠNG THÁI', style: style)),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  String _userStatusLabel(String status) {
    return status == 'ACTIVE' ? 'active' : 'deactive';
  }

  Widget _buildUserRow(
    BuildContext context,
    DoctorAccountEntity account,
    AdminAccountViewModel viewModel,
  ) {
    final isActive = account.status == 'ACTIVE';
    final statusLabel = _userStatusLabel(account.status);
    final isSelected = _selectedUser?.id == account.id;
    final isHovered = _hoveredUserId == account.id;
    final roleLabel = account.role.trim().isEmpty ? '-' : account.role.trim();
    final displayName = account.fullName.trim().isEmpty
        ? '-'
        : account.fullName.trim();
    final email = account.email.trim().isEmpty ? '-' : account.email.trim();

    return GestureDetector(
      onTap: () => setState(() => _selectedUser = account),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredUserId = account.id),
        onExit: (_) => setState(() => _hoveredUserId = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isHovered ? -1 : 0, 0),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE6F4F1)
                : isHovered
                ? const Color(0xFFF8FCFA)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2D7E6E)
                  : isHovered
                  ? const Color(0xFFCFE3DC)
                  : const Color(0xFFEDF2F7),
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              // Avatar + name
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        _buildAccountAvatar(
                          name: displayName,
                          avatarUrl: account.avatarUrl,
                          radius: 20,
                          color: const Color(0xFF2D7E6E),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF48BB78)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2B3C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  roleLabel,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  email,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5568),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF48BB78)
                            : Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive
                            ? const Color(0xFF2D7E6E)
                            : Colors.red.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // More menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF718096),
                ),
                onSelected: (v) {
                  if (v == 'detail') {
                    _showAccountDetailDialog(context, account);
                  } else if (v == 'toggle') {
                    _showToggleStatusDialog(context, account);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text('Xem chi tiết'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          size: 16,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Khóa tài khoản' : 'Kích hoạt'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    AdminAccountViewModel viewModel,
  ) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    return PaginationBar(
      currentPage: viewModel.currentPage,
      totalPages: viewModel.totalPages,
      totalElements: viewModel.totalElements,
      pageSize: viewModel.pageSize,
      isLoading: viewModel.isLoading,
      itemLabel: 'người dùng',
      onPageChanged: (page) => viewModel.goToPage(token, page),
      onPageSizeChanged: (size) => viewModel.changePageSize(token, size),
    );
  }

  // Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬ RIGHT DETAIL SIDEBAR Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬Ă¢â€â‚¬
  void _showRolePermissionDialog(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 1100,
          height: 760,
          child: ChangeNotifierProvider(
            create: (_) => PermissionViewModel(
              PermissionRemoteDataSourceImpl(http.Client(), token: token),
            ),
            child: PermissionPage(showTopBar: false),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailSidebar(
    BuildContext context,
    AdminAccountViewModel viewModel,
  ) {
    final user = _selectedUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ă¢â€â‚¬Ă¢â€â‚¬ User card Ă¢â€â‚¬Ă¢â€â‚¬
          if (user != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAccountAvatar(
                    name: user.fullName,
                    avatarUrl: user.avatarUrl,
                    radius: 36,
                    color: const Color(0xFF2D7E6E),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user.status == 'ACTIVE'
                          ? const Color(0xFF48BB78)
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user.specialization ?? user.role,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2D7E6E)),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'ID: ${user.doctorCode ?? user.id}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
              ),
            ),
            const SizedBox(height: 16),
            _buildSidebarInfoBox(
              'EMAIL',
              user.email.isEmpty ? '-' : user.email,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAccountDetailDialog(context, user),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D7E6E),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Chi tiết hồ sơ',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chọn người dùng\nđể xem chi tiết',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF718096),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final token = pageContext.read<AuthViewModel>().currentUser?.token ?? '';
    final viewModel = pageContext.read<AdminAccountViewModel>();
    bool isSubmitting = false;
    String? submitError;
    RoleModel? selectedRole;
    late final Future<List<RoleModel>> rolesFuture = viewModel.getRoles(token);

    showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_add_outlined,
                          color: Color(0xFF2D7E6E),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm tài khoản mới',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2B3C),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tạo người dùng theo vai trò',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4F6F68),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                content: SizedBox(
                  width: 500,
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Họ và tên *'),
                          TextFormField(
                            controller: nameController,
                            decoration: _buildInputDecoration(
                              'Nhập họ và tên',
                              Icons.person_outline,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập họ tên'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Email *'),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              'example@email.com',
                              Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!RegExp(
                                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                              ).hasMatch(v.trim())) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Vai trò *'),
                          FutureBuilder<List<RoleModel>>(
                            future: rolesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Đang tải danh sách vai trò...'),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Text(
                                  'Không thể tải danh sách vai trò: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE53E3E),
                                  ),
                                );
                              }

                              final roles =
                                  snapshot.data ?? const <RoleModel>[];
                              if (roles.isEmpty) {
                                return const Text(
                                  'Chưa có vai trò hợp lệ để chọn.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE53E3E),
                                  ),
                                );
                              }

                              selectedRole ??= roles.first;
                              return DropdownButtonFormField<RoleModel>(
                                value: selectedRole,
                                decoration: _buildInputDecoration(
                                  'Chọn vai trò',
                                  Icons.badge_outlined,
                                ),
                                items: roles
                                    .map(
                                      (role) => DropdownMenuItem<RoleModel>(
                                        value: role,
                                        child: Text(role.name),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) => value == null
                                    ? 'Vui lòng chọn vai trò'
                                    : null,
                                onChanged: isSubmitting
                                    ? null
                                    : (value) => setDialogState(
                                        () => selectedRole = value,
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Số điện thoại *'),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: _buildInputDecoration(
                              'Số điện thoại',
                              Icons.phone_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                                return 'Số điện thoại chỉ chứa chữ số';
                              }
                              if (v.trim().length != 10) {
                                return 'Số điện thoại phải có đúng 10 chữ số';
                              }
                              return null;
                            },
                          ),
                          if (submitError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFCDD2),
                                  ),
                                ),
                                child: Text(
                                  submitError!,
                                  style: const TextStyle(
                                    color: Color(0xFFE53E3E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2D7E6E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final role = selectedRole;
                              final roleId = int.tryParse(role?.id ?? '');
                              if (role == null || roleId == null) {
                                setDialogState(() {
                                  submitError = 'Vui lòng chọn vai trò hợp lệ';
                                });
                                return;
                              }
                              setDialogState(() {
                                isSubmitting = true;
                                submitError = null;
                              });
                              final success = await viewModel.createUser(
                                fullName: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                roleId: roleId,
                                token: token,
                              );
                              if (!mounted ||
                                  !context.mounted ||
                                  !dialogContext.mounted) {
                                return;
                              }
                              if (success) {
                                Navigator.pop(dialogContext, true);
                                return;
                              }
                              if (!success && context.mounted) {
                                setDialogState(() {
                                  isSubmitting = false;
                                  submitError =
                                      viewModel.errorMessage ??
                                      'Không thể tạo tài khoản';
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7E6E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Xác nhận tạo'),
                  ),
                ],
              );
            },
          ),
        )
        .whenComplete(() {
          nameController.dispose();
          emailController.dispose();
          phoneController.dispose();
        })
        .then((created) async {
          if (created == true && mounted && pageContext.mounted) {
            if (mounted && pageContext.mounted) {
              AppToast.showSuccess('Tạo tài khoản thành công');
            }
          }
        });
  }

  Widget _buildFieldLabel(String label) {
    final isRequired = label.trimRight().endsWith('*');
    final cleanLabel = isRequired
        ? label
              .trimRight()
              .substring(0, label.trimRight().length - 1)
              .trimRight()
        : label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          children: [
            TextSpan(text: cleanLabel),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFE53E3E)),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A9A96), fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2D7E6E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD8E7E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD8E7E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2D7E6E), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF7FBFA),
    );
  }

  void _showToggleStatusDialog(
    BuildContext context,
    DoctorAccountEntity account,
  ) {
    final bool isActive = account.status == 'ACTIVE';
    if (isActive) {
      _showDeactivateDoctorDialog(context, account);
      return;
    }
    const actionText = 'Kích hoạt';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText tài khoản'),
        content: Text(
          'Bạn có chắc chắn muốn $actionText tài khoản của người dùng ${account.fullName} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              final success = await context
                  .read<AdminAccountViewModel>()
                  .toggleDoctorStatus(account.id, !isActive, token);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  AppToast.showSuccess('$actionText tài khoản thành công!');
                } else {
                  AppToast.showError('Có lỗi xảy ra, vui lòng thử lại.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Xác nhận $actionText'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDoctorDialog(
    BuildContext context,
    DoctorAccountEntity account,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Khóa tài khoản'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn khóa tài khoản của người dùng ${account.fullName} không?',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: _buildInputDecoration(
                  'Nhập lý do vô hiệu hóa',
                  Icons.notes_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập lý do vô hiệu hóa';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              final success = await context
                  .read<AdminAccountViewModel>()
                  .toggleDoctorStatus(
                    account.id,
                    false,
                    token,
                    reason: reasonController.text.trim(),
                  );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess('Khóa tài khoản thành công!');
                } else {
                  AppToast.showError('Có lỗi xảy ra, vui lòng thử lại.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận khóa'),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  void _showAccountDetailDialog(
    BuildContext context,
    DoctorAccountEntity account,
  ) {
    final isActive = account.status == 'ACTIVE';
    final statusLabel = _userStatusLabel(account.status);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: SizedBox(
          width: 850,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PhĂ¡ÂºÂ§n bÄ‚Âªn trÄ‚Â¡i: TÄ‚Â³m tĂ¡ÂºÂ¯t danh tÄ‚Â­nh
                Container(
                  width: 260,
                  color: const Color(0xFFF8FAF9),
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      _buildAccountAvatar(
                        name: account.fullName,
                        avatarUrl: account.avatarUrl,
                        radius: 50,
                        color: const Color(0xFF2D7E6E),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        account.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        account.role,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // PhĂ¡ÂºÂ§n bÄ‚Âªn phĂ¡ÂºÂ£i: Chi tiĂ¡ÂºÂ¿t Ă„â€˜Ă¡ÂºÂ§y Ă„â€˜Ă¡Â»Â§
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Thông tin định danh'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Tên đăng nhập:',
                                  account.username,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  'Số điện thoại:',
                                  account.phone,
                                ),
                              ),
                            ],
                          ),
                          _buildDetailRow('Email liên hệ:', account.email),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Hồ sơ chuyên môn'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Mã bác sĩ:',
                                  account.doctorCode ?? 'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  'Số chứng chỉ:',
                                  account.licenseNumber ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Chuyên khoa:',
                                  account.specialization ?? 'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  'Đơn vị công tác:',
                                  account.hospitalName ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Chức vụ:',
                                  account.position ?? 'N/A',
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  'Kinh nghiệm:',
                                  '${account.yearsOfExperience} năm',
                                ),
                              ),
                            ],
                          ),
                          _buildDetailRow(
                            'Học hàm/Học vị:',
                            '${account.academicTitle ?? ""} ${account.degree ?? ""}'
                                    .trim()
                                    .isEmpty
                                ? 'N/A'
                                : '${account.academicTitle ?? ""} ${account.degree ?? ""}'
                                      .trim(),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('Dữ liệu hệ thống'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Ngày tham gia:',
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(account.createdAt),
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  'Lần cuối cập nhật:',
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(account.updatedAt),
                                ),
                              ),
                            ],
                          ),
                          if (account.bio != null &&
                              account.bio!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionTitle('Giới thiệu'),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                account.bio!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2D7E6E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D7E6E),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.primary,
                  size: 22,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          const Spacer(),
          _notificationButton(context),
          const SizedBox(width: 12),
          Consumer<AuthViewModel>(
            builder: (context, vm, _) => PopupMenuButton<_AdminUserMenuAction>(
              tooltip: 'Tài khoản',
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 10,
              offset: const Offset(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              onSelected: (action) => _handleAdminUserMenuAction(action),
              itemBuilder: (context) => const [
                PopupMenuItem<_AdminUserMenuAction>(
                  value: _AdminUserMenuAction.changePassword,
                  child: _AdminUserMenuItem(
                    icon: Icons.lock_reset_rounded,
                    label: 'Đổi mật khẩu',
                  ),
                ),
                PopupMenuItem<_AdminUserMenuAction>(
                  value: _AdminUserMenuAction.logout,
                  child: _AdminUserMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    isDestructive: true,
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAccountAvatar(
                      name: vm.currentUser?.displayName ?? 'Admin',
                      avatarUrl: vm.currentUser?.avatarUrl,
                      radius: 15,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vm.currentUser?.displayName ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B3C),
                          ),
                        ),
                        const Text(
                          'Quản trị hệ thống',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF718096),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLegacyTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Mobile Menu Button
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF2D7E6E)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          // Search Bar
          Expanded(
            child: TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D7E6E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Hệ thống: Hoạt động',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D7E6E)),
            onPressed: () {},
          ),
          // Profile Button
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF2D7E6E),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _handleAdminUserMenuAction(_AdminUserMenuAction action) {
    switch (action) {
      case _AdminUserMenuAction.changePassword:
        setState(() {
          _showChangePassword = true;
        });
        break;
      case _AdminUserMenuAction.logout:
        context.read<AuthViewModel>().logout();
        break;
    }
  }

  Widget _notificationButton(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, _) {
        return PopupMenuButton<void>(
          tooltip: 'Thông báo',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          constraints: const BoxConstraints.tightFor(width: 380),
          onOpened: () => vm.loadNotifications(_token),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: _AdminNotificationDropdown(token: _token),
            ),
          ],
          child: SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: vm.unreadCount > 0
                          ? const Color(0xFFEAF2FF)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF718096),
                      size: 20,
                    ),
                  ),
                ),
                if (vm.unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        vm.unreadCount > 99 ? '99+' : vm.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection() {
    return _buildDashboardStatsFromApi();

    // ignore: dead_code
    return Row(
      children: [
        _buildStatCard(
          'Tổng số ca phân tích',
          '2,840',
          '+18%',
          Colors.blue,
          Icons.assessment,
          showProgress: true,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Ca nguy cơ cao',
          '452',
          'Cần duyệt ngay',
          Colors.orange,
          Icons.warning_amber,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Bác sĩ hoạt động',
          '48',
          '8 bạn tuyến',
          Colors.purple,
          Icons.people,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'AI hôm nay',
          '124',
          '1.2 giây',
          Colors.teal,
          Icons.speed,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Thành công',
          '99.8%',
          '',
          Colors.green,
          Icons.check_circle,
          showProgress: true,
          progressValue: 0.998,
        ),
      ],
    );
  }

  Widget _buildDashboardStatsFromApi() {
    return Consumer<AdminDashboardViewModel>(
      builder: (context, vm, _) {
        final stats = vm.stats;
        final verifiedProgress = stats.totalExaminations <= 0
            ? 0.0
            : stats.verifiedExaminations / stats.totalExaminations;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            Row(
              children: [
                _buildStatCard(
                  'Tổng số ca phân tích',
                  _formatCount(stats.totalExaminations),
                  '${_formatCount(stats.totalDicomStudies)} DICOM studies',
                  Colors.blue,
                  Icons.assessment,
                  showProgress: true,
                  progressValue: verifiedProgress.clamp(0.0, 1.0),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Ca nguy cơ cao',
                  _formatCount(stats.severeExaminations),
                  'KL nặng cần theo dõi',
                  Colors.orange,
                  Icons.warning_amber,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Chờ xác nhận',
                  _formatCount(stats.unverifiedExaminations),
                  '${_formatCount(stats.verifiedExaminations)} đã xác nhận',
                  Colors.teal,
                  Icons.fact_check_outlined,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Bác sĩ hoạt động',
                  _formatCount(stats.activeDoctors),
                  '${_formatCount(stats.totalDoctors)} tổng bác sĩ',
                  Colors.purple,
                  Icons.people,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Bệnh nhân',
                  _formatCount(stats.totalPatients),
                  'Tổng hồ sơ bệnh nhân',
                  Colors.green,
                  Icons.personal_injury_outlined,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String? subtitle,
    Color color,
    IconData icon, {
    bool showProgress = false,
    double progressValue = 0.0,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            if (showProgress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKLGradeDistribution() {
    return Consumer<AdminDashboardViewModel>(
      builder: (context, vm, _) {
        final segments = _adminGradeSegments(vm.stats.gradeCounts);
        final total = segments.fold<int>(0, (sum, item) => sum + item.value);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân bổ bệnh nhân theo KL Grade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(220, 220),
                                painter: _DonutChartPainter(
                                  segments: segments,
                                  emptyColor: const Color(0xFFE7F5F1),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatCount(total),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Tổng số',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final segment in segments) ...[
                            _buildLegendItem(
                              segment.label,
                              segment.value,
                              total,
                              segment.color,
                            ),
                            if (segment != segments.last)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_AdminGradeSegment> _adminGradeSegments(Map<int, int> gradeCounts) {
    return [
      _AdminGradeSegment(
        label: 'KL 0',
        value: gradeCounts[0] ?? 0,
        color: const Color(0xFF2F855A),
      ),
      _AdminGradeSegment(
        label: 'KL 1',
        value: gradeCounts[1] ?? 0,
        color: const Color(0xFF38A169),
      ),
      _AdminGradeSegment(
        label: 'KL 2',
        value: gradeCounts[2] ?? 0,
        color: const Color(0xFFD4A017),
      ),
      _AdminGradeSegment(
        label: 'KL 3',
        value: gradeCounts[3] ?? 0,
        color: const Color(0xFFE67E22),
      ),
      _AdminGradeSegment(
        label: 'KL 4',
        value: gradeCounts[4] ?? 0,
        color: const Color(0xFFD71920),
      ),
    ];
  }

  int _percentOf(int value, int denominator) {
    if (denominator <= 0) return 0;
    return ((value / denominator) * 100).round();
  }

  Widget _buildLegendItem(String label, int value, int total, Color color) {
    final percent = _percentOf(value, total);
    final progress = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildSystemStatus() {
    return Column(
      children: [
        Expanded(
          child: _buildStatusBox(
            'Trạng thái PACS',
            '4/4 Online',
            'DICOM Nodes',
            Colors.green,
            Icons.cloud_done,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildStorageBox()),
      ],
    );
  }

  Widget _buildStatusBox(
    String title,
    String mainText,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Kết nối ổn định',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dung lượng lưu trữ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.storage,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '4.2 TB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ Tổng công suất',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ảnh x-quang',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'Kết nối ổn định',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.85,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFC107),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CẢNH BÁO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CẢNH BÁO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    return _buildAuditLogFromApi();

    // ignore: dead_code
    final activities = [
      {
        'time': '14:25:31, 24/05/2024',
        'user': 'Bác sĩ Mai Tiến',
        'avatar': 'M',
        'status': 'THÀNH CÔNG',
      },
      {
        'time': '14:18:05, 24/05/2024',
        'user': 'KTV Hoàng Thúy',
        'avatar': 'H',
        'action': 'Đồng bộ PACS - Khoa Chấn thương',
        'status': 'HOẠT ĐỘNG',
      },
      {
        'time': '13:55:12, 24/05/2024',
        'user': 'Hệ thống',
        'avatar': 'S',
        'status': 'CẢNH BÁO',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động hệ thống gần đây',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D7E6E),
                  ),
                  child: const Text(
                    'Xem tất cả lịch sử >',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Activity List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getAvatarColor(activity['avatar'] as String),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          activity['avatar'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['time'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['user'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['action'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(activity['status'] as String),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(
                            activity['status'] as String,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View Icon
                    Icon(
                      Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogFromApi() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động hệ thống gần đây',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedNavIndex = 3),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D7E6E),
                  ),
                  child: const Text(
                    'Xem tất cả lịch sử >',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Consumer<AuditLogViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (vm.errorMessage != null && vm.logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                );
              }
              if (vm.logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có nhật ký hoạt động.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }

              final logs = vm.logs.take(5).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final actor = log.userDisplay;
                  final initial = actor.characters.first.toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _getAvatarColor(initial),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatAuditLogTime(log.timeStamp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                actor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.descriptionDisplay,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatAuditLogTime(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('HH:mm:ss, dd/MM/yyyy').format(date);
  }

  Color _getAvatarColor(String initial) {
    switch (initial) {
      case 'M':
        return const Color(0xFF4CAF50);
      case 'H':
        return const Color(0xFFFF9800);
      case 'S':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'THÀNH CÔNG':
        return Colors.green.shade50;
      case 'HOẠT ĐỘNG':
        return Colors.blue.shade50;
      case 'CẢNH BÁO':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'THÀNH CÔNG':
        return Colors.green.shade700;
      case 'HOẠT ĐỘNG':
        return Colors.blue.shade700;
      case 'CẢNH BÁO':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }
}

enum _AdminUserMenuAction { changePassword, logout }

class _AdminUserMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _AdminUserMenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFD14343)
        : const Color(0xFF1A2B3C);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AdminNotificationDropdown extends StatelessWidget {
  final String token;

  const _AdminNotificationDropdown({required this.token});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.loadNotifications(token),
                      icon: const Icon(Icons.refresh_outlined),
                    ),
                    TextButton(
                      onPressed: vm.unreadCount == 0
                          ? null
                          : () => vm.markAllAsRead(token),
                      child: const Text('Đã đọc tất cả'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _AdminNotificationBody(vm: vm, token: token),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminNotificationBody extends StatelessWidget {
  final NotificationViewModel vm;
  final String token;

  const _AdminNotificationBody({required this.vm, required this.token});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading && vm.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (vm.errorMessage != null && vm.notifications.isEmpty) {
      return _AdminNotificationEmpty(
        icon: Icons.error_outline,
        message: 'Chưa có thông báo.',
      );
    }
    if (vm.notifications.isEmpty) {
      return const _AdminNotificationEmpty(
        icon: Icons.notifications_none_outlined,
        message: 'Chưa có thông báo.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.visibleNotifications.length + (vm.canShowMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= vm.visibleNotifications.length) {
          return TextButton(
            onPressed: vm.showMore,
            child: const Text('Xem thêm'),
          );
        }
        final notification = vm.visibleNotifications[index];
        return _AdminNotificationTile(
          notification: notification,
          onTap: notification.id <= 0 || notification.isRead
              ? null
              : () => vm.markAsRead(id: notification.id, token: token),
        );
      },
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const _AdminNotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? const Color(0xFFF0F7FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title.isEmpty
                        ? 'Thông báo'
                        : notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isUnread
                          ? AppColors.textSecondary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 8,
              child: isUnread
                  ? Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53E3E),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _AdminNotificationEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentHeaderCell extends StatelessWidget {
  final String label;

  const _DocumentHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4B5563),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _AdminGradeSegment {
  final String label;
  final int value;
  final Color color;

  const _AdminGradeSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

// Custom Painter for Donut Chart
class _DonutChartPainter extends CustomPainter {
  final List<_AdminGradeSegment> segments;
  final Color emptyColor;

  const _DonutChartPainter({required this.segments, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;
    final total = segments.fold<int>(0, (sum, item) => sum + item.value);

    if (total <= 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.emptyColor != emptyColor;
  }
}
