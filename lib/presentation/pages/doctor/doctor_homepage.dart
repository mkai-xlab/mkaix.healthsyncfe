import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/doctor_viewmodel.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import 'dicom_upload_page.dart';
import 'examination_list_page.dart';

class DoctorHomepage extends StatefulWidget {
  const DoctorHomepage({super.key});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  int _selectedNavIndex = 0;
  final _searchController = TextEditingController();
  String _filterGender = '';
  bool _hasRequestedPatientList = false;

  static const Color _primaryGreen = Color(0xFF2D7E6E);
  static const Color _darkGreen = Color(0xFF1B5A4E);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (scaffoldContext) => _buildTopBar(scaffoldContext),
                ),
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
    );
  }

  List<_DoctorNavItemData> _visibleNavItems(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final permissionItems = user?.permissionItems ?? const [];
    final parentPermissions = permissionItems
        .where((permission) => permission.isParent)
        .toList();

    final source = parentPermissions.isNotEmpty
        ? parentPermissions
        : permissionItems;
    final navSource = List<UserPermissionEntity>.from(source);
    _appendChildPermissionNavItem(
      navSource,
      permissionItems,
      permissionKey: 'read_patient_list',
      duplicateLabel: 'Quản lý bệnh nhân',
    );
    _appendChildPermissionNavItem(
      navSource,
      permissionItems,
      permissionKey: 'create_patient_exam',
      duplicateLabel: 'Danh sách ca khám',
    );
    _appendChildPermissionNavItem(
      navSource,
      permissionItems,
      permissionKey: 'upload_dicom_image',
      duplicateLabel: 'Hỗ trợ chẩn đoán',
    );

    return List.generate(navSource.length, (index) {
      final permission = navSource[index];
      return _DoctorNavItemData(
        index: index,
        permissionName: permission.name,
        label: _permissionTitle(permission),
        icon: _permissionIcon(permission.name),
      );
    });
  }

  void _appendChildPermissionNavItem(
    List<UserPermissionEntity> navSource,
    List<UserPermissionEntity> permissionItems, {
    required String permissionKey,
    required String duplicateLabel,
  }) {
    UserPermissionEntity? uploadDicomPermission;
    for (final permission in permissionItems) {
      if (_normalizePermissionKey(permission.name) == permissionKey) {
        uploadDicomPermission = permission;
        break;
      }
    }

    if (uploadDicomPermission != null &&
        !navSource.any(
          (permission) =>
              _normalizePermissionKey(permission.name) == permissionKey ||
              _permissionTitle(permission) == duplicateLabel,
        )) {
      navSource.add(uploadDicomPermission);
    }
  }

  String _normalizePermissionKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _permissionTitle(UserPermissionEntity permission) {
    final normalized = _normalizePermissionKey(permission.name);
    const labels = {
      'patient': 'Quản lý bệnh nhân',
      'patients': 'Quản lý bệnh nhân',
      'benh_nhan': 'Quản lý bệnh nhân',
      'read_patient_list': 'Quản lý bệnh nhân',
      'create_patient_exam': 'Danh sách ca khám',
      'dicom': 'Hỗ trợ chẩn đoán',
      'dicom_image': 'Hỗ trợ chẩn đoán',
      'upload_dicom_image': 'Hỗ trợ chẩn đoán',
      'xray': 'Hỗ trợ chẩn đoán',
      'x_quang': 'Hỗ trợ chẩn đoán',
      'diagnosis': 'Hỗ trợ chẩn đoán',
      'report': 'Báo cáo & hồ sơ',
      'reports': 'Báo cáo & hồ sơ',
      'notification': 'Thông báo',
      'notifications': 'Thông báo',
    };

    if (labels.containsKey(normalized)) return labels[normalized]!;
    return _capitalize(permission.name.replaceAll('_', ' '));
  }

  IconData _permissionIcon(String permissionName) {
    final normalized = _normalizePermissionKey(permissionName);
    if (normalized == 'create_patient_exam') {
      return Icons.assignment_outlined;
    }
    if (normalized.contains('patient') || normalized.contains('benh_nhan')) {
      return Icons.people_outline;
    }
    if (normalized.contains('dicom') ||
        normalized.contains('upload_dicom_image') ||
        normalized.contains('xray') ||
        normalized.contains('x_quang') ||
        normalized.contains('diagnosis')) {
      return Icons.medical_information_outlined;
    }
    if (normalized.contains('report')) {
      return Icons.description_outlined;
    }
    if (normalized.contains('notification') ||
        normalized.contains('thong_bao')) {
      return Icons.notifications_outlined;
    }
    return Icons.lock_outline;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  // ─────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    final navItems = _visibleNavItems(context);
    return Container(
      width: 250,
      color: _darkGreen,
      child: Column(
        children: [
          _buildSidebarHeader(),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: navItems.isEmpty
                  ? [_buildEmptyPermissionNote()]
                  : navItems.map((item) => _buildNavItem(item)).toList(),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _logoBox('lib/presentation/images/logo1.jpg'),
              const SizedBox(width: 8),
              _logoBox('lib/presentation/images/logo2.jpg'),
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
            'HỖ TRỢ CHẨN ĐOÁN X-QUANG',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoBox(String asset) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.local_hospital, color: _primaryGreen, size: 22),
      ),
    );
  }

  Widget _buildNavItem(_DoctorNavItemData item, {bool closeDrawer = false}) {
    final index = item.index;
    final isSelected = _selectedNavIndex == index;
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 20,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (closeDrawer) {
          Navigator.pop(context);
        }
      },
      tileColor: isSelected ? Colors.white.withValues(alpha: 0.1) : null,
      shape: isSelected
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildEmptyPermissionNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Text(
        'Chưa có quyền hiển thị',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        onTap: () => context.read<AuthViewModel>().logout(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final navItems = _visibleNavItems(context);
    return Drawer(
      child: Container(
        color: _darkGreen,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: _primaryGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _logoBox('lib/presentation/images/logo1.jpg'),
                      const SizedBox(width: 8),
                      _logoBox('lib/presentation/images/logo2.jpg'),
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
                children: navItems.isEmpty
                    ? [_buildEmptyPermissionNote()]
                    : navItems
                          .map((item) => _buildNavItem(item, closeDrawer: true))
                          .toList(),
              ),
            ),
            _buildLogoutTile(context),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN CONTENT ROUTER
  // ─────────────────────────────────────────────
  Widget _buildMainContent(BuildContext context) {
    final navItems = _visibleNavItems(context);
    final selectedItem =
        _selectedNavIndex >= 0 && _selectedNavIndex < navItems.length
        ? navItems[_selectedNavIndex]
        : null;

    final selectedLabel = selectedItem?.label ?? '';
    final selectedPermission = _normalizePermissionKey(
      selectedItem?.permissionName ?? '',
    );
    final hasUploadDicomPermission =
        context.read<AuthViewModel>().currentUser?.permissions.any(
          (name) => _normalizePermissionKey(name) == 'upload_dicom_image',
        ) ??
        false;

    if (selectedPermission == 'create_patient_exam' ||
        selectedLabel == 'Danh sách ca khám') {
      return const ExaminationListPage(embedded: true);
    }
    if (selectedPermission == 'read_patient_list' ||
        selectedLabel == 'Quản lý bệnh nhân') {
      return _buildPatientListPage(context);
    }
    if (selectedLabel == 'Trang chủ') {
      return _buildDashboard(context);
    }
    if (selectedPermission == 'upload_dicom_image' ||
        (selectedLabel == 'Hỗ trợ chẩn đoán' && hasUploadDicomPermission)) {
      return const DicomUploadPage();
    }

    return _buildFeaturePlaceholderPage(
      title: selectedItem?.label ?? 'Đang cập nhật',
      subtitle: selectedItem == null
          ? 'Tài khoản hiện chưa có permission cha để hiển thị trong sidebar.'
          : 'Tính năng này đang được cập nhật.',
      icon: selectedItem?.icon ?? Icons.construction_outlined,
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Mobile menu
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.menu, color: _primaryGreen, size: 22),
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => context
                    .read<DoctorViewModel>()
                    .searchByNameDebounced(v, _token),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bệnh nhân, hồ sơ, mã số...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFADB5BD),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF718096),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
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
                      color: _primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF718096),
            size: 20,
          ),
          const SizedBox(width: 12),
          // Doctor info — đồng bộ với patient_detail_page
          Consumer<AuthViewModel>(
            builder: (context, vm, child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE6F4F1),
                  child: Text(
                    vm.currentUser?.name.isNotEmpty == true
                        ? vm.currentUser!.name[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BS. ${vm.currentUser?.name ?? 'Bác sĩ'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    const Text(
                      'Chẩn đoán hình ảnh',
                      style: TextStyle(fontSize: 10, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePlaceholderPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      color: const Color(0xFFF0F4F3),
      width: double.infinity,
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryGreen, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DASHBOARD
  // ─────────────────────────────────────────────
  Widget _buildDashboard(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trang chủ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tổng quan hoạt động chẩn đoán hôm nay',
              style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),
            const SizedBox(height: 24),
            _buildDashboardStats(),
            const SizedBox(height: 24),
            _buildCriticalCasesAlert(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Row(
      children: [
        _buildStatCard(
          'Tổng ca hôm nay',
          '148',
          '+12%',
          _primaryGreen,
          Icons.trending_up_rounded,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Ca nguy cơ cao',
          '32',
          '+5%',
          const Color(0xFFE53E3E),
          Icons.warning_amber_rounded,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Đã hoàn thành',
          '112',
          '',
          const Color(0xFF3B82F6),
          Icons.check_circle_outline_rounded,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Chờ xác nhận',
          '04',
          '',
          const Color(0xFFD97706),
          Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String? change,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
                    fontSize: 11,
                    color: Color(0xFF718096),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B3C),
              ),
            ),
            if (change != null && change.isNotEmpty)
              Text(
                change,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalCasesAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE53E3E),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Cảnh báo ca nghiêm trọng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _criticalItem('BN: Lê Văn A', 'GRADE 4', 'Thoái hóa khớp nặng'),
          const SizedBox(height: 10),
          _criticalItem('BN: Trần Thị B', 'GRADE 4', 'Hẹp khe khớp nặng'),
          const SizedBox(height: 10),
          _criticalItem('BN: Phạm Minh C', 'GRADE 3', 'Gai xương đùi chày'),
        ],
      ),
    );
  }

  Widget _criticalItem(String name, String grade, String desc) {
    final isGrade4 = grade == 'GRADE 4';
    final color = isGrade4 ? const Color(0xFFE53E3E) : const Color(0xFFD97706);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            grade,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PATIENT LIST PAGE
  // ─────────────────────────────────────────────
  Widget _buildPatientListPage(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F3),
      child: Consumer<DoctorViewModel>(
        builder: (context, vm, _) {
          if (!_hasRequestedPatientList &&
              !vm.isLoading &&
              vm.patients.isEmpty &&
              vm.errorMessage == null) {
            _hasRequestedPatientList = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<DoctorViewModel>().fetchFirstPage(token: _token);
            });
          }

          return Column(
            children: [
              _buildPatientListHeader(context, vm),
              Expanded(
                child: vm.isLoading && vm.patients.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryGreen),
                      )
                    : vm.errorMessage != null && vm.patients.isEmpty
                    ? _buildErrorState(vm)
                    : vm.patients.isEmpty
                    ? _buildEmptyState()
                    : _buildPatientTable(context, vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPatientListHeader(BuildContext context, DoctorViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh sách bệnh nhân',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng ${vm.totalElements} bệnh nhân',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showFilterDialog(context, vm),
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Bộ lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showCreatePatientDialog(context, vm),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm bệnh nhân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gender filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', '', vm),
                const SizedBox(width: 8),
                _filterChip('Nam', 'MALE', vm),
                const SizedBox(width: 8),
                _filterChip('Nữ', 'FEMALE', vm),
                const SizedBox(width: 8),
                _filterChip('Khác', 'OTHER', vm),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, DoctorViewModel vm) {
    final isSelected = _filterGender == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterGender = value);
        vm.fetchFirstPage(token: _token, gender: value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryGreen : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientTable(BuildContext context, DoctorViewModel vm) {
    return Column(
      children: [
        // Table header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: const [
              Expanded(flex: 2, child: _TableHeader('MÃ BỆNH NHÂN')),
              Expanded(flex: 4, child: _TableHeader('HỌ VÀ TÊN')),
              Expanded(flex: 2, child: _TableHeader('NGÀY SINH')),
              Expanded(flex: 1, child: _TableHeader('GIỚI TÍNH')),
              Expanded(flex: 3, child: _TableHeader('ĐIỆN THOẠI')),
              Expanded(flex: 3, child: _TableHeader('EMAIL')),
              SizedBox(width: 48),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEDF2F7)),
        // Rows
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 200) {
                vm.fetchNextPage(_token);
              }
              return false;
            },
            child: RefreshIndicator(
              color: _primaryGreen,
              onRefresh: () => vm.fetchFirstPage(token: _token),
              child: ListView.separated(
                itemCount: vm.patients.length + (vm.isLastPage ? 0 : 1),
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFEDF2F7)),
                itemBuilder: (context, i) {
                  if (i >= vm.patients.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primaryGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return _buildPatientRow(context, vm.patients[i]);
                },
              ),
            ),
          ),
        ),
        // Footer bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                'Hiển thị ${vm.patients.length} / ${vm.totalElements} bệnh nhân',
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              const Spacer(),
              if (!vm.isLastPage)
                TextButton.icon(
                  onPressed: () => vm.fetchNextPage(_token),
                  icon: const Icon(Icons.expand_more, size: 16),
                  label: const Text('Tải thêm'),
                  style: TextButton.styleFrom(foregroundColor: _primaryGreen),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientRow(BuildContext context, PatientEntity p) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExaminationListPage(patient: p)),
      ),
      hoverColor: const Color(0xFFF0F4F3),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                p.patientCode,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE6F4F1),
                    child: Text(
                      p.fullName.isNotEmpty ? p.fullName[0] : 'P',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2B3C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                p.dobDisplay,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
              ),
            ),
            Expanded(flex: 1, child: _genderBadge(p.gender)),
            Expanded(
              flex: 3,
              child: Text(
                p.phone ?? '—',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                p.email ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Color(0xFF718096),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExaminationListPage(patient: p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderBadge(String gender) {
    final isMale = gender.toUpperCase() == 'MALE';
    final isFemale = gender.toUpperCase() == 'FEMALE';
    Color color = const Color(0xFF718096);
    Color bg = const Color(0xFFF7FAFC);
    String label = 'Khác';
    if (isMale) {
      color = const Color(0xFF3B82F6);
      bg = const Color(0xFFEFF6FF);
      label = 'Nam';
    }
    if (isFemale) {
      color = const Color(0xFFEC4899);
      bg = const Color(0xFFFDF2F8);
      label = 'Nữ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(DoctorViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 48),
          const SizedBox(height: 12),
          Text(
            vm.errorMessage ?? 'Có lỗi xảy ra',
            style: const TextStyle(color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => vm.fetchFirstPage(token: _token),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy bệnh nhân nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────
  void _showFilterDialog(BuildContext context, DoctorViewModel vm) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Bộ lọc bệnh nhân'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mã bệnh nhân',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              vm.clearFilters(_token);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Xóa bộ lọc',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              vm.fetchFirstPage(
                token: _token,
                patientCode: codeCtrl.text.trim().isEmpty
                    ? null
                    : codeCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _showCreatePatientDialog(BuildContext context, DoctorViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreatePatientDialog(),
    ).then((_) => vm.fetchFirstPage(token: _token));
  }
}

// ─────────────────────────────────────────────
// TABLE HEADER WIDGET
// ─────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF718096),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DoctorNavItemData {
  final int index;
  final String permissionName;
  final String label;
  final IconData icon;

  const _DoctorNavItemData({
    required this.index,
    required this.permissionName,
    required this.label,
    required this.icon,
  });
}

// ─────────────────────────────────────────────
// CREATE PATIENT DIALOG
// ─────────────────────────────────────────────
class _CreatePatientDialog extends StatefulWidget {
  const _CreatePatientDialog();

  @override
  State<_CreatePatientDialog> createState() => _CreatePatientDialogState();
}

class _CreatePatientDialogState extends State<_CreatePatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecPhoneCtrl = TextEditingController();
  String _gender = 'MALE';
  bool _isLoading = false;
  String? _error;

  static const Color _primaryGreen = Color(0xFF2D7E6E);

  @override
  void dispose() {
    for (final c in [
      _codeCtrl,
      _nameCtrl,
      _dobCtrl,
      _phoneCtrl,
      _emailCtrl,
      _addressCtrl,
      _ecNameCtrl,
      _ecPhoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.person_add_outlined, color: _primaryGreen),
          SizedBox(width: 10),
          Text('Thêm bệnh nhân mới'),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Mã bệnh nhân *',
                        _codeCtrl,
                        Icons.badge_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        'Họ và tên *',
                        _nameCtrl,
                        Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _dobField(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _genderField()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Số điện thoại',
                        _phoneCtrl,
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              !RegExp(r'^\d+$').hasMatch(v)) {
                            return 'Chỉ nhập số';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        'Email',
                        _emailCtrl,
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Địa chỉ', _addressCtrl, Icons.location_on_outlined),
                const SizedBox(height: 14),
                const Text(
                  'LIÊN HỆ KHẨN CẤP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Tên người liên hệ',
                        _ecNameCtrl,
                        Icons.contact_phone_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        'SĐT khẩn cấp',
                        _ecPhoneCtrl,
                        Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Color(0xFF718096))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Lưu bệnh nhân'),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF718096)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _dobField(BuildContext context) {
    return TextFormField(
      controller: _dobCtrl,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: _primaryGreen),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _dobCtrl.text =
                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Ngày sinh',
        prefixIcon: const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Color(0xFF718096),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _genderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        prefixIcon: const Icon(
          Icons.wc_outlined,
          size: 18,
          color: Color(0xFF718096),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'MALE', child: Text('Nam')),
        DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
        DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
      ],
      onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // TODO: implement create patient — POST /patients
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chức năng tạo bệnh nhân đang hoàn thiện'),
          backgroundColor: Color(0xFF2D7E6E),
        ),
      );
    }
  }
}
