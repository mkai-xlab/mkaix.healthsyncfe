import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/services/toast_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/domain/entities/doctor_account_entity.dart';
import 'package:fe/data/datasources/permission_remote_datasource.dart';
import 'package:fe/presentation/viewmodels/permission_viewmodel.dart';
import 'package:fe/presentation/pages/admin/permission_page.dart';
import 'package:fe/presentation/pages/admin/feature_permission_catalog_page.dart';
import 'package:fe/presentation/widgets/pagination_bar.dart';
import 'package:http/http.dart' as http;

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  int _selectedNavIndex = 0;
  DoctorAccountEntity? _selectedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<AdminAccountViewModel>().fetchFirstPage(token);
    });
  }

  // @override
  // void dispose() {
  //   _debounce?.cancel(); // Hủy bỏ timer khi widget bị dispose
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
                _buildNavItem(
                  4,
                  'Thông báo hệ thống',
                  Icons.notifications_outlined,
                ),
                _buildNavItem(5, 'Cấu hình hệ thống', Icons.settings_outlined),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.white70,
                size: 20,
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              onTap: () {
                context.read<AuthViewModel>().logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedNavIndex == index;
    return ListTile(
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
        });
      },
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      shape: isSelected
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    4,
                    'Thông báo hệ thống',
                    Icons.notifications_outlined,
                  ),
                  _buildNavItem(
                    5,
                    'Cấu hình hệ thống',
                    Icons.settings_outlined,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  context.read<AuthViewModel>().logout();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_selectedNavIndex == 1) {
      return _buildUserManagementPage(context);
    }
    if (_selectedNavIndex == 2) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      return Container(
        color: const Color(0xFFF0F4F3),
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

    // Mặc định hiển thị Dashboard (index 0)
    return Container(
      color: const Color(0xFFF5F5F5),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KL Grade Distribution
                      Expanded(flex: 1, child: _buildKLGradeDistribution()),
                      const SizedBox(width: 20),
                      // System Status Section
                      Expanded(flex: 1, child: _buildSystemStatus()),
                    ],
                  ),
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

  Widget _buildUserManagementPage(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F3),
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Consumer<AdminAccountViewModel>(
              builder: (context, viewModel, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── LEFT: main list ──
                    Expanded(
                      flex: 7,
                      child: _buildUserListPanel(context, viewModel),
                    ),
                    // ── RIGHT: detail panel ──
                    Container(
                      width: 260,
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

  // ─── LEFT PANEL ───────────────────────────────────────────
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
                      'Danh sách bác sĩ, kỹ thuật viên và nhân viên hệ thống.',
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
                label: const Text('Thêm bác sĩ'),
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

          // Stat cards
          _buildUserStatCards(viewModel),
          const SizedBox(height: 20),

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
          label: 'TỔNG SỐ',
          value: total.toString(),
          sub: '↑ +3 mới',
          subColor: const Color(0xFF2D7E6E),
          borderColor: const Color(0xFF2D7E6E),
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'BÁC SĨ',
          value: doctors.toString(),
          sub: 'Đang công tác',
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'KỸ THUẬT VIÊN',
          value: ktv.toString(),
          sub: 'Hỗ trợ CDHA',
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'ĐÃ KHÓA',
          value: locked.toString().padLeft(2, '0'),
          sub: 'Vi phạm CS',
          subColor: const Color(0xFFE53E3E),
          valueColor: const Color(0xFFE53E3E),
          borderColor: const Color(0xFFE53E3E),
        ),
        const SizedBox(width: 10),
        _buildUMStatCard(
          label: 'TRỰC TUYẾN',
          value: online.toString(),
          sub: '● ● ○',
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
          flex: 3,
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: (v) {
                viewModel.searchByNameDebounced(v, token);
              },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFADB5BD),
                ),
                prefixIcon: const Icon(
                  Icons.tune,
                  size: 18,
                  color: Color(0xFF718096),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
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
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildFilterChip('Tất cả vai trò'),
        const SizedBox(width: 8),
        _buildFilterChip('Trạng thái'),
        const SizedBox(width: 8),
        _buildFilterChip('Khoa phòng'),
      ],
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
          Expanded(flex: 5, child: Text('NGƯỜI DÙNG', style: style)),
          Expanded(flex: 3, child: Text('TÀI KHOẢN', style: style)),
          Expanded(flex: 2, child: Text('VAI TRÒ', style: style)),
          Expanded(flex: 2, child: Text('KHOA', style: style)),
          Expanded(flex: 3, child: Text('TRẠNG THÁI', style: style)),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    DoctorAccountEntity account,
    AdminAccountViewModel viewModel,
  ) {
    final isActive = account.status == 'ACTIVE';
    final isSelected = _selectedUser?.id == account.id;

    Color roleColor;
    Color roleBg;
    String roleLabel;
    switch (account.role) {
      case 'DOCTOR':
        roleLabel = 'Bác sĩ';
        roleColor = const Color(0xFF2D7E6E);
        roleBg = const Color(0xFFE6F4F1);
        break;
      case 'ADMIN':
        roleLabel = 'Admin';
        roleColor = const Color(0xFFD97706);
        roleBg = const Color(0xFFFEF3C7);
        break;
      default:
        roleLabel = 'KTV';
        roleColor = const Color(0xFF3B82F6);
        roleBg = const Color(0xFFEFF6FF);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedUser = account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4F1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D7E6E)
                : const Color(0xFFEDF2F7),
          ),
        ),
        child: Row(
          children: [
            // Avatar + name
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(
                          0xFF2D7E6E,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          account.fullName.isNotEmpty
                              ? account.fullName[0]
                              : 'U',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D7E6E),
                          ),
                        ),
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
                            border: Border.all(color: Colors.white, width: 1.5),
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
                          account.fullName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B3C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          account.specialization ?? roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF718096),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Username
            Expanded(
              flex: 3,
              child: Text(
                account.username,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
              ),
            ),
            // Role badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Department
            Expanded(
              flex: 2,
              child: Text(
                account.hospitalName?.split(' ').last ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            Expanded(
              flex: 3,
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
                    isActive ? 'Online' : 'Tạm khóa',
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
                } else if (v == 'permission') {
                  _showRolePermissionDialog(context);
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
                const PopupMenuItem(
                  value: 'permission',
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 16,
                        color: Color(0xFF2D7E6E),
                      ),
                      SizedBox(width: 8),
                      Text('Phan quyen'),
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

  // ─── RIGHT DETAIL SIDEBAR ─────────────────────────────────
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
          // ── User card ──
          if (user != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(
                      0xFF2D7E6E,
                    ).withValues(alpha: 0.15),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D7E6E),
                      ),
                    ),
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
            Row(
              children: [
                Expanded(
                  child: _buildSidebarInfoBox(
                    'CA TRỰC',
                    user.position == 'DEPARTMENT_HEAD' ? 'Sáng' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSidebarInfoBox(
                    'THÂM NIÊN',
                    '${user.yearsOfExperience} Năm',
                  ),
                ),
              ],
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

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEDF2F7)),
          const SizedBox(height: 16),

          // ── Cơ cấu nhân sự ──
          const Text(
            'Cơ cấu nhân sự',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 16),
          _buildStaffStructure(viewModel),
          const SizedBox(height: 24),

          // ── Hoạt động gần đây ──
          const Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentActivity(
            Icons.login,
            'BS. An vừa đăng nhập',
            '2 phút trước',
            color: const Color(0xFF2D7E6E),
          ),
          _buildRecentActivity(
            Icons.lock_reset,
            'Đổi pass: maile_rad',
            '45 phút trước',
            color: const Color(0xFFD97706),
          ),
          _buildRecentActivity(
            Icons.person_add_outlined,
            'Thêm mới: BS. Hùng',
            '2 giờ trước',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2D7E6E),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Toàn bộ nhật ký',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarInfoBox(String label, String value) {
    return Container(
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

  Widget _buildStaffStructure(AdminAccountViewModel viewModel) {
    final total = viewModel.accounts.isEmpty ? 128 : viewModel.accounts.length;
    final doctors = viewModel.accounts.isEmpty
        ? 84
        : viewModel.accounts.where((a) => a.role == 'DOCTOR').length;
    final ktv = viewModel.accounts.isEmpty
        ? 32
        : viewModel.accounts.where((a) => a.role == 'KTV').length;
    final admin = viewModel.accounts.isEmpty
        ? 12
        : viewModel.accounts.where((a) => a.role == 'ADMIN').length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // mini donut
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(56, 56),
                painter: _MiniDonutPainter(
                  total: total,
                  doctors: doctors,
                  ktv: ktv,
                  admin: admin,
                ),
              ),
              Text(
                '${total > 0 ? ((doctors / total) * 100).round() : 65}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _buildStructureRow('Bác sĩ', doctors, const Color(0xFF2D7E6E)),
              const SizedBox(height: 4),
              _buildStructureRow('KTV', ktv, const Color(0xFFD97706)),
              const SizedBox(height: 4),
              _buildStructureRow('Admin', admin, const Color(0xFF3B82F6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructureRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568)),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2B3C),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    IconData icon,
    String text,
    String time, {
    Color color = const Color(0xFF718096),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
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

    showDialog(
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                          'Thêm bác sĩ mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2B3C),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tạo hồ sơ bác sĩ theo API mới',
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FBFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD8E7E3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2D7E6E),
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'API mới tạo bác sĩ qua /doctors với họ tên, email và số điện thoại.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Color(0xFF4F6F68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      _buildFieldLabel('Số điện thoại *'),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
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
                          setDialogState(() {
                            isSubmitting = true;
                            submitError = null;
                          });
                          final success = await viewModel.createDoctorSilently(
                            doctorData: {
                              'fullName': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'phone': phoneController.text.trim(),
                            },
                            token: token,
                          );
                          if (!mounted ||
                              !context.mounted ||
                              !dialogContext.mounted) {
                            return;
                          }
                          if (success) {
                            Navigator.pop(dialogContext);
                            await viewModel.fetchFirstPage(token);
                            AppToast.showSuccess('Tạo bác sĩ thành công');
                          }
                          if (!success && context.mounted) {
                            setDialogState(() {
                              isSubmitting = false;
                              submitError =
                                  viewModel.errorMessage ??
                                  'Không thể tạo bác sĩ';
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
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  void _showCreateAccountDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    bool showLegacyDescription = false;
    // roleId mặc định — có thể mở rộng thành dropdown khi có API lấy danh sách role
    int selectedRoleId = 1;

    // Danh sách role tạm thời — khi có API roles thì thay bằng dữ liệu thực
    final roles = [
      {'id': 1, 'name': 'Bác sĩ'},
      {'id': 2, 'name': 'Kỹ thuật viên'},
      {'id': 3, 'name': 'Quản trị viên'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer<AdminAccountViewModel>(
          builder: (context, viewModel, child) {
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
              titleTextStyle: const TextStyle(
                color: Color(0xFF1A2B3C),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_outlined, color: Color(0xFF2D7E6E)),
                  SizedBox(width: 10),
                  Text('Thêm tài khoản mới'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD8E7E3)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF2D7E6E),
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Dien thong tin de tao user. He thong se gan tai khoan theo vai tro da chon.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Color(0xFF4F6F68),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (showLegacyDescription)
                          const Text(
                            'Điền thông tin để tạo tài khoản. Hệ thống sẽ tự động gửi mật khẩu tạm thời qua email.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 20),

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

                        _buildFieldLabel('Số điện thoại'),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                            'Số điện thoại',
                            Icons.phone_outlined,
                          ),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                !RegExp(r'^\d+$').hasMatch(v)) {
                              return 'Số điện thoại chỉ chứa chữ số';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildFieldLabel('Vai trò *'),
                        DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: _buildInputDecoration(
                            'Chọn vai trò',
                            Icons.admin_panel_settings_outlined,
                          ),
                          items: roles
                              .map(
                                (r) => DropdownMenuItem<int>(
                                  value: r['id'] as int,
                                  child: Text(r['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedRoleId = v);
                            }
                          },
                        ),

                        if (viewModel.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                viewModel.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => Navigator.pop(context),
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
                  onPressed: viewModel.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final token =
                                context
                                    .read<AuthViewModel>()
                                    .currentUser
                                    ?.token ??
                                '';
                            final success = await viewModel.createUser(
                              fullName: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              roleId: selectedRoleId,
                              token: token,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              AppToast.showSuccess('Tạo tài khoản thành công');
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
                  child: viewModel.isLoading
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
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
    final String actionText = isActive ? 'Khóa' : 'Kích hoạt';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText tài khoản'),
        content: Text(
          'Bạn có chắc chắn muốn $actionText tài khoản của bác sĩ ${account.fullName} không?',
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
                  AppToast.showSuccess('${actionText} tài khoản thành công!');
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

  void _showAccountDetailDialog(
    BuildContext context,
    DoctorAccountEntity account,
  ) {
    final isActive = account.status == 'ACTIVE';
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
                // Phần bên trái: Tóm tắt danh tính
                Container(
                  width: 260,
                  color: const Color(0xFFF8FAF9),
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(
                          0xFF2D7E6E,
                        ).withOpacity(0.1),
                        child: Text(
                          account.fullName.isNotEmpty
                              ? account.fullName[0]
                              : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Color(0xFF2D7E6E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          account.status,
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
                // Phần bên phải: Chi tiết đầy đủ
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
                hintText: 'Tìm kiếm nhân viên, người dùng...',
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

  Widget _buildStatisticsSection() {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
            'Phân bố KL Grade',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Donut Chart
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: DonutChartPainter(),
                  ),
                  // Center text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '2.8k',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Tổng số',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          _buildLegendItem('KL0-KL1', '62%', const Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          _buildLegendItem('KL2-KL3', '28%', const Color(0xFFFFC107)),
          const SizedBox(height: 12),
          _buildLegendItem('KL4', '10%', const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      children: [
        _buildStatusBox(
          'Trạng thái PACS',
          '4/4 Online',
          'DICOM Nodes',
          Colors.green,
          Icons.cloud_done,
        ),
        const SizedBox(height: 16),
        _buildStorageBox(),
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
                    '4.2 TB',
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
                  'TỔNG CÔNG SUẤT: 85%',
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
                  'CẢN BÁO',
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
    final activities = [
      {
        'time': '14:25:31, 24/05/2024',
        'user': 'Bác sĩ Mai Tiến',
        'avatar': 'M',
        'action': 'Chạy phân tích AI - Case #92110',
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
        'action': 'Backup dữ liệu tự động hàng ngày',
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
}

// Mini Donut for sidebar staff structure
class _MiniDonutPainter extends CustomPainter {
  final int total, doctors, ktv, admin;
  const _MiniDonutPainter({
    required this.total,
    required this.doctors,
    required this.ktv,
    required this.admin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;

    final t = total == 0 ? 1 : total;
    final docAngle = (doctors / t) * 2 * 3.14159;
    final ktvAngle = (ktv / t) * 2 * 3.14159;
    final adminAngle = (admin / t) * 2 * 3.14159;

    final rect = Rect.fromCircle(center: center, radius: radius);

    paint.color = const Color(0xFF2D7E6E);
    canvas.drawArc(rect, -3.14159 / 2, docAngle, false, paint);

    paint.color = const Color(0xFFD97706);
    canvas.drawArc(rect, -3.14159 / 2 + docAngle, ktvAngle, false, paint);

    paint.color = const Color(0xFF3B82F6);
    canvas.drawArc(
      rect,
      -3.14159 / 2 + docAngle + ktvAngle,
      adminAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_MiniDonutPainter old) => false;
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw segments
    _drawSegment(
      canvas,
      center,
      radius,
      0,
      220,
      const Color(0xFF4CAF50),
    ); // 62%
    _drawSegment(
      canvas,
      center,
      radius,
      220,
      100,
      const Color(0xFFFFC107),
    ); // 28%
    _drawSegment(
      canvas,
      center,
      radius,
      320,
      40,
      const Color(0xFFF44336),
    ); // 10%
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2,
    );

    canvas.drawArc(
      rect,
      startAngle * 3.14159 / 180,
      sweepAngle * 3.14159 / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => false;
}
