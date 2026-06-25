import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/permission_viewmodel.dart';
import '../../../data/models/permission_model.dart';
import '../../../data/models/role_model.dart';

class PermissionPage extends StatefulWidget {
  final bool showTopBar;
  final String? initialRoleId;

  const PermissionPage({super.key, this.showTopBar = true, this.initialRoleId});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  // Dùng int thay vì TabController để tránh vấn đề rebuild với length động
  int _selectedRoleIndex = 0;
  bool _didApplyInitialRole = false;

  static const Color _primaryGreen = Color(0xFF2D7E6E);
  static const Color _darkGreen = Color(0xFF1B5A4E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PermissionViewModel>().loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: const Color(0xFFF0F4F3),
          child: Column(
            children: [
              if (widget.showTopBar) _buildTopBar(context),
              Expanded(
                child: vm.isLoading
                    ? _buildLoading()
                    : vm.errorMessage != null && vm.roles.isEmpty
                    ? _buildError(vm)
                    : _buildBody(vm),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.menu, color: _primaryGreen),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu, quyền...',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF718096),
                  size: 20,
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
          const SizedBox(width: 16),
          const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF718096),
            size: 22,
          ),
          const SizedBox(width: 12),
          const Icon(Icons.help_outline, color: Color(0xFF718096), size: 22),
          const SizedBox(width: 16),
          const Text(
            'Quản trị viên Hệ thống',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────
  Widget _buildBody(PermissionViewModel vm) {
    if (vm.roles.isEmpty) {
      return const Center(
        child: Text(
          'Không có vai trò nào',
          style: TextStyle(color: Color(0xFF718096)),
        ),
      );
    }

    // Đảm bảo index hợp lệ sau khi load
    if (!_didApplyInitialRole && widget.initialRoleId != null) {
      final roleIndex = vm.roles.indexWhere(
        (role) =>
            role.id == widget.initialRoleId ||
            role.name == widget.initialRoleId ||
            role.code == widget.initialRoleId,
      );
      if (roleIndex >= 0 && _selectedRoleIndex != roleIndex) {
        _selectedRoleIndex = roleIndex;
      }
      _didApplyInitialRole = true;
    }
    final safeIndex = _selectedRoleIndex.clamp(0, vm.roles.length - 1);
    final currentRole = vm.roles[safeIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + action buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Phân quyền người dùng',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thiết lập quyền truy cập cho từng vai trò trong hệ thống.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: vm.hasUnsavedChanges
                    ? () => _confirmDiscard(context, vm)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A5568),
                  side: const BorderSide(color: Color(0xFFCBD5E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: vm.hasUnsavedChanges && !vm.isSaving
                    ? () => vm.saveChanges()
                    : null,
                icon: vm.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(vm.isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Banners ──
          if (vm.successMessage != null)
            _buildBanner(
              vm.successMessage!,
              const Color(0xFFE6F4F1),
              _primaryGreen,
              Icons.check_circle_outline,
              onClose: vm.clearMessages,
            ),
          if (vm.errorMessage != null)
            _buildBanner(
              vm.errorMessage!,
              const Color(0xFFFFF0F0),
              const Color(0xFFE53E3E),
              Icons.error_outline,
              onClose: vm.clearMessages,
            ),

          // ── Role tabs ──
          _buildRoleTabs(vm, safeIndex),
          const SizedBox(height: 24),

          // ── Permission grid cho role hiện tại ──
          _buildRolePermissions(vm, currentRole),
          const SizedBox(height: 24),

          // ── Footer ──
          _buildFooterNote(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ROLE TABS — dùng custom tab để tránh TabController
  // ─────────────────────────────────────────────
  Widget _buildRoleTabs(PermissionViewModel vm, int safeIndex) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(vm.roles.length, (i) {
            final role = vm.roles[i];
            final isSelected = i == safeIndex;
            // Kiểm tra role này có thay đổi chưa lưu không
            final hasDraft = vm.roleHasUnsavedChanges(role.id);

            return GestureDetector(
              onTap: () => setState(() => _selectedRoleIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? _primaryGreen : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? _primaryGreen
                            : const Color(0xFF718096),
                      ),
                    ),
                    if (hasDraft) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PERMISSIONS GRID
  // ─────────────────────────────────────────────
  Widget _buildRolePermissions(PermissionViewModel vm, RoleModel role) {
    final grouped = vm.permissionsByResource;
    final entries = grouped.entries.toList();

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Không có quyền nào',
          style: TextStyle(color: Color(0xFF718096)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: entries.map((entry) {
            return SizedBox(
              width: isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2,
              child: _buildResourceCard(vm, role, entry.key, entry.value),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResourceCard(
    PermissionViewModel vm,
    RoleModel role,
    String resource,
    List<PermissionModel> perms,
  ) {
    final info = _resourceInfo(resource);
    final enabledCount = perms
        .where((p) => vm.hasPermission(role.id, p.id))
        .length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7)),
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
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: info.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(info.icon, color: info.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                      Text(
                        '$enabledCount/${perms.length} quyền được bật',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F3)),

          // Permission rows — truyền toàn bộ danh sách để check parent
          ...perms.map((perm) => _buildPermissionRow(vm, role, perm, perms)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Render một dòng permission với logic parent_id
  Widget _buildPermissionRow(
    PermissionViewModel vm,
    RoleModel role,
    PermissionModel perm,
    List<PermissionModel> allPermsInGroup,
  ) {
    final enabled = vm.hasPermission(role.id, perm.id);

    // Kiểm tra parent: nếu perm này có parent_id, parent đó có được bật không?
    bool parentEnabled = true;
    bool hasParent = false;
    PermissionModel? parentPerm;

    if (perm.parentId != null) {
      hasParent = true;
      // Tìm parent trong toàn bộ permissions (không chỉ trong group)
      parentPerm = vm.permissions
          .where((p) => p.id == perm.parentId)
          .firstOrNull;
      if (parentPerm != null) {
        parentEnabled = vm.hasPermission(role.id, parentPerm.id);
      }
    }

    // isDisabled = có parent nhưng parent chưa được bật
    final isDisabled = hasParent && !parentEnabled;

    return Padding(
      padding: EdgeInsets.only(
        left: hasParent ? 36 : 20, // indent permission con
        right: 20,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        children: [
          // Connector line cho permission con
          if (hasParent)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: 14,
                color: isDisabled
                    ? const Color(0xFFCBD5E0)
                    : const Color(0xFF718096),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _permissionLabel(perm),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDisabled
                        ? const Color(0xFFCBD5E0)
                        : enabled
                        ? const Color(0xFF1A2B3C)
                        : const Color(0xFF718096),
                  ),
                ),
                // Tooltip khi bị disable do parent
                if (isDisabled && parentPerm != null)
                  Text(
                    'Yêu cầu: ${_permissionLabel(parentPerm)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD97706),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isDisabled ? false : enabled,
            onChanged: isDisabled
                ? null // null = disabled, Flutter tự render màu xám
                : (_) => vm.togglePermission(role.id, perm.id),
            activeThumbColor: Colors.white,
            activeTrackColor: _primaryGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E0),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: _primaryGreen),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lưu ý: Mọi thay đổi quyền truy cập sẽ được ghi lại trong nhật ký hệ thống (Audit Log).',
              style: TextStyle(fontSize: 12, color: Color(0xFF2D7E6E)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Trạng thái hiện tại:',
                style: TextStyle(fontSize: 10, color: Color(0xFF718096)),
              ),
              SizedBox(height: 2),
              Text(
                'ĐANG HOẠT ĐỘNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOADING / ERROR
  // ─────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _primaryGreen),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu phân quyền...',
            style: TextStyle(color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PermissionViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 48),
          const SizedBox(height: 12),
          Text(
            vm.errorMessage ?? 'Có lỗi xảy ra',
            style: const TextStyle(color: Color(0xFF718096), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => vm.loadAll(),
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

  Widget _buildBanner(
    String message,
    Color bg,
    Color color,
    IconData icon, {
    VoidCallback? onClose,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 13, color: color)),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: color),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  void _confirmDiscard(BuildContext context, PermissionViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hủy thay đổi?'),
        content: const Text(
          'Các thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn tiếp tục không?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Không',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.discardChanges();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hủy thay đổi'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  _ResourceInfo _resourceInfo(String resource) {
    switch (resource.toLowerCase()) {
      case 'patient':
      case 'patients':
        return _ResourceInfo(
          label: 'Quản lý bệnh nhân',
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
        );
      case 'dicom_image':
      case 'dicom':
      case 'xray':
        return _ResourceInfo(
          label: 'Phân tích AI',
          icon: Icons.psychology_outlined,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
        );
      case 'report':
      case 'reports':
        return _ResourceInfo(
          label: 'Báo cáo & Hồ sơ',
          icon: Icons.description_outlined,
          iconColor: const Color(0xFF10B981),
          bgColor: const Color(0xFFD1FAE5),
        );
      case 'user':
      case 'users':
      case 'admin':
        return _ResourceInfo(
          label: 'Hệ thống & Quản trị',
          icon: Icons.admin_panel_settings_outlined,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFEDE9FE),
        );
      default:
        return _ResourceInfo(
          label: _capitalize(resource.replaceAll('_', ' ')),
          icon: Icons.lock_outline_rounded,
          iconColor: _darkGreen,
          bgColor: const Color(0xFFE6F4F1),
        );
    }
  }

  String _permissionLabel(PermissionModel perm) {
    final actionMap = {
      'view': 'Xem',
      'create': 'Tạo mới',
      'update': 'Chỉnh sửa',
      'delete': 'Xóa',
      'analyze': 'Chạy phân tích',
      'export': 'Xuất dữ liệu',
      'approve': 'Phê duyệt',
    };
    final resourceMap = {
      'dicom_image': 'ảnh X-quang',
      'patient': 'bệnh nhân',
      'report': 'báo cáo',
      'user': 'người dùng',
    };
    final action = actionMap[perm.action.toLowerCase()] ?? perm.action;
    final resource = resourceMap[perm.resource.toLowerCase()] ?? perm.resource;
    if (perm.name.contains(':')) return '$action $resource';
    return perm.name;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ResourceInfo {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _ResourceInfo({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
