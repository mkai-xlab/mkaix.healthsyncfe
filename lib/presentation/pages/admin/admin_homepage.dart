import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/data/models/doctor_account_model.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  // Thêm Timer cho debounce
  // Timer? _debounce;

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
      color: const Color(0xFF1B5A4E),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7E6E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.healing,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'VIỆN Y HỌC CÓ TRUYỀN',
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
                _buildNavItem(2, 'Lịch sử hoạt động', Icons.history_outlined),
                _buildNavItem(
                  3,
                  'Thông báo hệ thống',
                  Icons.notifications_outlined,
                ),
                _buildNavItem(4, 'Cấu hình hệ thống', Icons.settings_outlined),
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
        color: const Color(0xFF1B5A4E),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D7E6E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.healing,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VIỆN Y HỌC CÓ TRUYỀN QUÂN ĐỘI',
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
                  _buildNavItem(2, 'Lịch sử hoạt động', Icons.history_outlined),
                  _buildNavItem(
                    3,
                    'Thông báo hệ thống',
                    Icons.notifications_outlined,
                  ),
                  _buildNavItem(
                    4,
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
    // Nếu đang ở menu Quản lý người dùng (index 1)
    if (_selectedNavIndex == 1) {
      return _buildUserManagementPage(context);
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
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Consumer<AdminAccountViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading && viewModel.accounts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.errorMessage != null &&
                    viewModel.accounts.isEmpty) {
                  return Center(child: Text(viewModel.errorMessage!));
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      final token =
                          context.read<AuthViewModel>().currentUser?.token ??
                          '';
                      viewModel.fetchNextPage(token);
                    }
                    return true;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final token =
                          context.read<AuthViewModel>().currentUser?.token ??
                          '';
                      await viewModel.fetchFirstPage(token);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quản lý người dùng',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Danh sách tài khoản nhân viên và bác sĩ trong hệ thống',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          _buildUserTable(viewModel),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable(AdminAccountViewModel viewModel) {
    final accounts = viewModel.accounts;

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
          // Header Table Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách tài khoản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateAccountDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo tài khoản'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7E6E),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 32,
              columns: const [
                DataColumn(label: Text('Thông tin người dùng')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Vai trò')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Cập nhật')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: accounts.map((account) {
                final isActive = account.status == 'ACTIVE';
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(
                              0xFF2D7E6E,
                            ).withOpacity(0.1),
                            child: Text(
                              account.fullName.isNotEmpty
                                  ? account.fullName[0]
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2D7E6E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            account.fullName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(account.email, style: const TextStyle(fontSize: 13)),
                    ),
                    DataCell(
                      Text(account.role, style: const TextStyle(fontSize: 13)),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          account.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('dd/MM/yyyy').format(account.updatedAt),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                _showAccountDetailDialog(context, account),
                            tooltip: 'Xem chi tiết',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF2D7E6E),
                            ),
                            onPressed: () {},
                            tooltip: 'Chỉnh sửa',
                          ),
                          IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.block
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                            onPressed: () =>
                                _showToggleStatusDialog(context, account),
                            tooltip: isActive ? 'Khóa tài khoản' : 'Kích hoạt',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!viewModel.isLastPage && !viewModel.isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  final token =
                      context.read<AuthViewModel>().currentUser?.token ?? '';
                  viewModel.fetchNextPage(token);
                },
                child: const Text('Xem thêm tài khoản...'),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showCreateAccountDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    final licenseController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<AdminAccountViewModel>(
        builder: (context, viewModel, child) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.person_add_outlined, color: Color(0xFF2D7E6E)),
                SizedBox(width: 10),
                Text('Tạo tài khoản bác sĩ mới'),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điền thông tin để khởi tạo tài khoản bác sĩ. Các trường đánh dấu (*) là bắt buộc nhập.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('Họ và tên *'),
                      TextFormField(
                        controller: nameController,
                        decoration: _buildInputDecoration(
                          'Nhập họ và tên bác sĩ',
                          Icons.person_outline,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Email *'),
                      TextFormField(
                        controller: emailController,
                        decoration: _buildInputDecoration(
                          'example@email.com',
                          Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Vui lòng nhập email';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v))
                            return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Số điện thoại *'),
                                TextFormField(
                                  controller: phoneController,
                                  decoration: _buildInputDecoration(
                                    'Số điện thoại',
                                    Icons.phone_outlined,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? 'Vui lòng nhập số điện thoại'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Mã bác sĩ *'),
                                TextFormField(
                                  controller: codeController,
                                  decoration: _buildInputDecoration(
                                    'Mã định danh',
                                    Icons.badge_outlined,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? 'Vui lòng nhập mã bác sĩ'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Số giấy phép hành nghề *'),
                      TextFormField(
                        controller: licenseController,
                        decoration: _buildInputDecoration(
                          'Nhập số giấy phép (License Number)',
                          Icons.assignment_ind_outlined,
                        ),
                        validator: (v) => v!.isEmpty
                            ? 'Vui lòng nhập số giấy phép hành nghề'
                            : null,
                      ),
                      if (viewModel.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
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
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final doctorData = {
                            "fullName": nameController.text.trim(),
                            "email": emailController.text.trim(),
                            "phone": phoneController.text.trim(),
                            "doctorCode": codeController.text.trim(),
                            "licenseNumber": licenseController.text.trim(),
                            "avatarUrl": "",
                            "specialization": "Đang cập nhật",
                            "hospitalName": "Viện Y học Cổ truyền Quân đội",
                            "yearsOfExperience": 0,
                            "academicTitle": "",
                            "degree": "",
                            "signatureUrl": "",
                            "bio": "",
                            "position": "DEPARTMENT_HEAD",
                          };

                          final token =
                              context
                                  .read<AuthViewModel>()
                                  .currentUser
                                  ?.token ??
                              '';
                          final success = await viewModel.createDoctor(
                            doctorData,
                            token,
                          );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tạo tài khoản thành công'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7E6E),
                  foregroundColor: Colors.white,
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
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2D7E6E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2D7E6E), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _showToggleStatusDialog(
    BuildContext context,
    DoctorAccountModel account,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${actionText} tài khoản thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Có lỗi xảy ra, vui lòng thử lại.'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    DoctorAccountModel account,
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
