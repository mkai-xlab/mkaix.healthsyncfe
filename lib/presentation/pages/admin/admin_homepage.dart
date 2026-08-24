import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/media_url_resolver.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:fe/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:fe/presentation/viewmodels/notification_viewmodel.dart';
import 'package:fe/domain/entities/notification_entity.dart';
import 'package:fe/data/datasources/permission_remote_datasource.dart';
import 'package:fe/data/repositories/permission_repository_impl.dart';
import 'package:fe/domain/usecases/create_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/create_permission_usecase.dart';
import 'package:fe/domain/usecases/delete_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/delete_permission_usecase.dart';
import 'package:fe/domain/usecases/get_permission_catalog_usecase.dart';
import 'package:fe/domain/usecases/get_permission_roles_usecase.dart';
import 'package:fe/domain/usecases/update_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/update_permission_usecase.dart';
import 'package:fe/domain/usecases/update_role_permissions_usecase.dart';
import 'package:fe/presentation/viewmodels/permission_viewmodel.dart';
import 'package:fe/presentation/pages/admin/feature_permission_catalog_page.dart';
import 'package:fe/presentation/pages/admin/audit_log_page.dart';
import 'package:fe/presentation/pages/admin/admin_user_list_page.dart';
import 'package:fe/presentation/pages/admin/knowledge_documents_page.dart';
import 'package:fe/presentation/pages/auth/account_change_password_page.dart';
import 'package:fe/presentation/widgets/authenticated_avatar_image.dart';
import 'package:http/http.dart' as http;

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  static const Color _pageBackground = Color(0xFFF0F4F3);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 0;
  bool _showChangePassword = false;
  bool _isSystemSettingsExpanded = false;

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

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
  //   _debounce?.cancel(); // H?y b? timer khi widget b? dispose
  //   _scrollController.dispose();
  //   super.dispose();
  // }
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
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
                        errorBuilder: (_, _, _) => const Icon(
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
                        errorBuilder: (_, _, _) => const Icon(
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
              'Cấu hình hệ thống',
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
            label: 'Quản lý tài liệu',
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
                          errorBuilder: (_, _, _) => const Icon(
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
                          errorBuilder: (_, _, _) => const Icon(
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
      return Container(
        color: _pageBackground,
        child: Column(
          children: [
            _buildTopBar(context),
            const Expanded(child: AdminUserListPage()),
          ],
        ),
      );
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
                create: (_) => _createPermissionViewModel(token),
                child: const FeaturePermissionCatalogPage(),
              ),
            ),
          ],
        ),
      );
    }

    // M?c ??nh hi?n th? Dashboard (index 0)
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

  PermissionViewModel _createPermissionViewModel(String token) {
    final repository = PermissionRepositoryImpl(
      remoteDataSource: PermissionRemoteDataSourceImpl(
        http.Client(),
        token: token,
      ),
    );
    return PermissionViewModel(
      getPermissionCatalogUseCase: GetPermissionCatalogUseCase(repository),
      getRolesUseCase: GetPermissionRolesUseCase(repository),
      updateRolePermissionsUseCase: UpdateRolePermissionsUseCase(repository),
      createFeatureUseCase: CreatePermissionFeatureUseCase(repository),
      updateFeatureUseCase: UpdatePermissionFeatureUseCase(repository),
      createPermissionUseCase: CreatePermissionUseCase(repository),
      updatePermissionUseCase: UpdatePermissionUseCase(repository),
      deleteFeatureUseCase: DeletePermissionFeatureUseCase(repository),
      deletePermissionUseCase: DeletePermissionUseCase(repository),
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
                onPressed: _openDrawer,
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
                onPressed: _openDrawer,
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: Colors.orange.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            separatorBuilder: (_, _) => const Divider(height: 1),
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
                separatorBuilder: (_, _) => const Divider(height: 1),
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
