import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/constants/app_colors.dart';
import 'package:fe/core/services/toast_service.dart';
import 'package:fe/core/utils/media_url_resolver.dart';
import 'package:fe/data/datasources/permission_remote_datasource.dart';
import 'package:fe/data/models/role_model.dart';
import 'package:fe/data/repositories/permission_repository_impl.dart';
import 'package:fe/domain/entities/doctor_account_entity.dart';
import 'package:fe/domain/usecases/create_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/create_permission_usecase.dart';
import 'package:fe/domain/usecases/delete_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/delete_permission_usecase.dart';
import 'package:fe/domain/usecases/get_permission_catalog_usecase.dart';
import 'package:fe/domain/usecases/get_permission_roles_usecase.dart';
import 'package:fe/domain/usecases/update_permission_feature_usecase.dart';
import 'package:fe/domain/usecases/update_permission_usecase.dart';
import 'package:fe/domain/usecases/update_role_permissions_usecase.dart';
import 'package:fe/presentation/pages/admin/permission_page.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/permission_viewmodel.dart';
import 'package:fe/presentation/widgets/authenticated_avatar_image.dart';
import 'package:fe/presentation/widgets/pagination_bar.dart';
import 'package:http/http.dart' as http;

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  DoctorAccountEntity? _selectedUser;
  int? _hoveredUserId;

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAccountViewModel>(
      builder: (context, viewModel, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 7, child: _buildUserListPanel(context, viewModel)),
            Container(
              width: 320,
              color: Colors.white,
              child: _buildUserDetailSidebar(context, viewModel),
            ),
          ],
        );
      },
    );
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
                  } else if (v == 'role') {
                    _showChangeRoleDialog(context, account);
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
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_accounts_outlined,
                          size: 16,
                          color: Color(0xFF2D7E6E),
                        ),
                        SizedBox(width: 8),
                        Text('Đổi vai trò'),
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

  // RIGHT DETAIL SIDEBAR
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
            create: (_) => _createPermissionViewModel(token),
            child: PermissionPage(showTopBar: false),
          ),
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    DoctorAccountEntity account,
  ) {
    final pageContext = context;
    final token = pageContext.read<AuthViewModel>().currentUser?.token ?? '';
    final viewModel = pageContext.read<AdminAccountViewModel>();
    late final Future<List<RoleModel>> rolesFuture = viewModel.getRoles(token);
    RoleModel? selectedRole;
    bool isSubmitting = false;
    String? submitError;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Đổi vai trò',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 440,
              child: FutureBuilder<List<RoleModel>>(
                future: rolesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                        fontSize: 13,
                        color: Color(0xFFE53E3E),
                      ),
                    );
                  }

                  final roles = snapshot.data ?? const <RoleModel>[];
                  if (roles.isEmpty) {
                    return const Text(
                      'Chưa có vai trò hợp lệ để chọn.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE53E3E)),
                    );
                  }

                  selectedRole ??= _initialSelectedRole(roles, account);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Vai trò mới *'),
                      DropdownButtonFormField<RoleModel>(
                        initialValue: selectedRole,
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
                        onChanged: isSubmitting
                            ? null
                            : (value) =>
                                  setDialogState(() => selectedRole = value),
                      ),
                      if (submitError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            submitError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final role = selectedRole;
                        final roleId = int.tryParse(role?.id ?? '');
                        if (role == null || roleId == null) {
                          setDialogState(() {
                            submitError = 'Vai trò không hợp lệ';
                          });
                          return;
                        }
                        if (account.roleId == roleId) {
                          Navigator.pop(dialogContext, false);
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          submitError = null;
                        });

                        final success = await viewModel.updateUserRole(
                          userId: account.id,
                          roleId: roleId,
                          token: token,
                        );

                        if (!dialogContext.mounted) return;
                        if (success) {
                          Navigator.pop(dialogContext, true);
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            submitError =
                                viewModel.errorMessage ??
                                'Không thể đổi vai trò';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7E6E),
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận'),
              ),
            ],
          );
        },
      ),
    ).then((changed) {
      if (changed == true && mounted && pageContext.mounted) {
        DoctorAccountEntity? refreshedAccount;
        for (final item in viewModel.accounts) {
          if (item.id == account.id) {
            refreshedAccount = item;
            break;
          }
        }
        if (refreshedAccount != null) {
          setState(() => _selectedUser = refreshedAccount);
        }
        AppToast.showSuccess('Đổi vai trò thành công');
      }
    });
  }

  RoleModel _initialSelectedRole(
    List<RoleModel> roles,
    DoctorAccountEntity account,
  ) {
    final roleId = account.roleId;
    if (roleId != null) {
      for (final role in roles) {
        if (int.tryParse(role.id) == roleId) return role;
      }
    }

    final currentRole = account.role.trim().toUpperCase();
    for (final role in roles) {
      if (role.code.trim().toUpperCase() == currentRole ||
          role.name.trim().toUpperCase() == currentRole) {
        return role;
      }
    }
    return roles.first;
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
          // User card
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
                                initialValue: selectedRole,
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
                                FocusScope.of(dialogContext).unfocus();
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
            await viewModel.fetchFirstPage(token);
            if (!mounted || !pageContext.mounted) return;
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
                                  'Chuyên khoa:',
                                  account.specialization ?? 'N/A',
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Chức vụ:',
                                  account.role.trim().isEmpty
                                      ? 'N/A'
                                      : account.role.trim(),
                                ),
                              ),
                              const Spacer(),
                            ],
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
}
