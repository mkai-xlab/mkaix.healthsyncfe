import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/services/toast_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/rbac/permission_code.dart';
import '../../../core/utils/media_url_resolver.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/dicom_upload_viewmodel.dart';
import '../../viewmodels/doctor_viewmodel.dart';
import '../../viewmodels/doctor_profile_viewmodel.dart';
import '../../viewmodels/examination_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/authenticated_avatar_image.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import '../admin/knowledge_documents_page.dart';
import '../auth/account_change_password_page.dart';
import 'ai_clinical_chat_page.dart';
import 'doctor_dashboard_page.dart';
import 'doctor_profile_page.dart';
import 'examination_detail_page.dart';
import 'examination_list_page.dart';
import 'file_upload_page.dart';
import 'patient_detail_page.dart';
import 'patient_list_page.dart';

class DoctorHomepage extends StatefulWidget {
  const DoctorHomepage({super.key});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  int _selectedNavIndex = 0;
  final _searchController = TextEditingController();
  bool _showUploadExaminationList = false;
  bool _showDoctorProfile = false;
  bool _showChangePassword = false;
  bool _isUploadMiniProgressCollapsed = false;
  final List<ExaminationEntity> _newUploadExaminations = const [];
  ExaminationListMode? _pendingExaminationListMode;
  int _examinationListRefreshVersion = 0;
  int _handledAiChatPageRequestVersion = 0;
  PatientEntity? _selectedPatientDetail;
  ExaminationEntity? _selectedExaminationDetail;
  ChatViewModel? _chatViewModel;

  static const Color _primaryGreen = AppColors.primary;
  static const Color _darkGreen = AppColors.primary;
  static const Map<PermissionCode, _DoctorNavConfig> _doctorNavRegistry = {
    PermissionCode.viewDoctorDashboard: _DoctorNavConfig(
      routeKey: 'doctor_dashboard_page',
      label: 'Trang tổng quan',
      icon: Icons.home_outlined,
    ),
    PermissionCode.readPatientList: _DoctorNavConfig(
      routeKey: 'patient_list_page',
      label: 'Danh sách bệnh nhân',
      icon: Icons.people_outline,
    ),
    PermissionCode.createPatientExam: _DoctorNavConfig(
      routeKey: 'examination_list_page',
      label: 'Danh sách ca khám',
      icon: Icons.assignment_outlined,
    ),
    PermissionCode.viewExaminationList: _DoctorNavConfig(
      routeKey: 'examination_list_page',
      label: 'Danh sách ca khám',
      icon: Icons.assignment_outlined,
    ),
    PermissionCode.uploadDicomImage: _DoctorNavConfig(
      routeKey: 'file_upload_page',
      label: 'Upload DICOM',
      icon: Icons.medical_information_outlined,
    ),
    PermissionCode.useAiChat: _DoctorNavConfig(
      routeKey: 'ai_clinical_chat_page',
      label: 'Trợ lý AI',
      icon: Icons.smart_toy_outlined,
    ),
    PermissionCode.manageMedicalKnowledge: _DoctorNavConfig(
      routeKey: 'knowledge_documents_page',
      label: 'Kho tri thức',
      icon: Icons.library_books_outlined,
    ),
  };

  @override
  void initState() {
    super.initState();
    _chatViewModel = context.read<ChatViewModel>();
    _handledAiChatPageRequestVersion =
        _chatViewModel?.fullPageRequestVersion ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationViewModel>().loadNotifications(_token);
      context.read<DoctorProfileViewModel>().loadProfile(token: _token);
    });
  }

  @override
  void dispose() {
    _chatViewModel?.setFullPageVisible(false);
    _searchController.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    _handleAiChatPageRequest();
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
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildMainContent(context)),
                      _buildUploadMiniProgress(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
    );
  }

  List<_DoctorNavItemData> _visibleNavItems(
    BuildContext context, {
    bool listen = true,
  }) {
    final auth = listen
        ? context.watch<AuthViewModel>()
        : context.read<AuthViewModel>();
    final user = auth.currentUser;
    final permissionItems =
        List<UserPermissionEntity>.from(user?.permissionItems ?? const [])
          ..sort((a, b) {
            final cmp = a.priority.compareTo(b.priority);
            if (cmp != 0) return cmp;
            return a.code.compareTo(b.code);
          });
    final navSource = permissionItems.where((permission) {
      if (!permission.isParent) return false;
      final code = PermissionCode.fromValue(permission.code);
      return code != null && _doctorNavRegistry.containsKey(code);
    }).toList();

    final seenRoutes = <String>{};
    final navItems = <_DoctorNavItemData>[];
    for (final permission in navSource) {
      final code = PermissionCode.fromValue(permission.code);
      final config = code == null ? null : _doctorNavRegistry[code];
      if (code == null || config == null) continue;
      if (!seenRoutes.add(config.routeKey)) continue;
      final index = navItems.length;
      final label = permission.name.trim().isNotEmpty
          ? permission.name
          : config.label;
      navItems.add(
        _DoctorNavItemData(
          index: index,
          routeKey: config.routeKey,
          permissionName: permission.name,
          label: label,
          icon: config.icon,
          permissionCode: code,
        ),
      );
    }

    return navItems;
  }

  // ─────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    final navItems = _visibleNavItems(context);
    return Material(
      color: _darkGreen,
      child: SizedBox(
        width: 250,
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
          ],
        ),
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
    final borderRadius = BorderRadius.circular(8);
    return Material(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: borderRadius,
      child: ListTile(
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
          _setAiChatFloatingHidden(item.routeKey == 'ai_clinical_chat_page');
          setState(() {
            _selectedNavIndex = index;
            if (item.routeKey == 'examination_list_page') {
              _examinationListRefreshVersion++;
            }
            _showDoctorProfile = false;
            _showChangePassword = false;
            _showUploadExaminationList = false;
            _selectedPatientDetail = null;
            _selectedExaminationDetail = null;
          });
          if (closeDrawer) {
            Navigator.pop(context);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
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

  Widget _buildDrawer(BuildContext context) {
    final navItems = _visibleNavItems(context);
    return Drawer(
      child: Material(
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
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN CONTENT ROUTER
  // ─────────────────────────────────────────────
  Widget _buildMainContent(BuildContext context) {
    if (_showChangePassword) {
      return AccountChangePasswordPage(
        onCancel: () {
          setState(() {
            _showChangePassword = false;
            _showDoctorProfile = true;
            _showUploadExaminationList = false;
            _selectedPatientDetail = null;
            _selectedExaminationDetail = null;
          });
        },
      );
    }

    if (_showDoctorProfile) {
      return const DoctorProfilePage(embedded: true);
    }

    final selectedExaminationDetail = _selectedExaminationDetail;
    if (selectedExaminationDetail != null) {
      if (!_canOpenExaminationDetail(context)) {
        return _forbiddenPage(
          title: 'Không có quyền xem chi tiết ca khám',
          subtitle:
              'Tài khoản hiện tại chưa được cấp quyền xem chi tiết ca khám.',
          icon: Icons.lock_outline,
        );
      }
      return ExaminationDetailPage(
        examination: selectedExaminationDetail,
        onBack: () => setState(() => _selectedExaminationDetail = null),
        onOpenPatientDetail: (patient) => setState(() {
          _selectedExaminationDetail = null;
          _selectedPatientDetail = patient;
        }),
      );
    }

    final selectedPatientDetail = _selectedPatientDetail;
    if (selectedPatientDetail != null) {
      if (!_hasPermission(context, PermissionCode.viewPatientDetail)) {
        return _forbiddenPage(
          title: 'Không có quyền xem chi tiết bệnh nhân',
          subtitle: 'Tài khoản hiện tại chưa được cấp permission cho màn này.',
          icon: Icons.lock_outline,
        );
      }
      return PatientDetailPage(
        patient: selectedPatientDetail,
        embedded: true,
        onOpenExaminationDetail: (examination) =>
            setState(() => _selectedExaminationDetail = examination),
      );
    }

    if (_showUploadExaminationList) {
      return ExaminationListPage(
        key: ValueKey(
          'upload-examination-list-$_examinationListRefreshVersion',
        ),
        embedded: true,
        newExaminations: _newUploadExaminations,
      );
    }

    final navItems = _visibleNavItems(context);
    final selectedItem =
        _selectedNavIndex >= 0 && _selectedNavIndex < navItems.length
        ? navItems[_selectedNavIndex]
        : null;

    final selectedPermission = selectedItem?.routeKey ?? '';
    _syncAiChatFloatingVisibility(selectedPermission);

    if (selectedPermission == 'ai_clinical_chat_page') {
      return const AiClinicalChatPage();
    }
    if (selectedPermission == 'knowledge_documents_page') {
      return const KnowledgeDocumentsPage();
    }
    if (selectedPermission == 'doctor_dashboard_page') {
      return DoctorDashboardPage(
        embedded: true,
        canOpenExaminationList: _canOpenExaminationList(context),
        onOpenExaminationList: _openExaminationListTab,
      );
    }
    if (selectedPermission == 'examination_list_page') {
      if (!_canOpenExaminationList(context)) {
        return _forbiddenPage(
          title: 'Không có quyền xem ca khám',
          subtitle: 'Màn danh sách ca khám chưa được cấp cho tài khoản này.',
          icon: Icons.lock_outline,
        );
      }
      return ExaminationListPage(
        key: ValueKey(
          'examination-list-${_pendingExaminationListMode?.name ?? 'all'}-$_examinationListRefreshVersion',
        ),
        embedded: true,
        newExaminations: _newUploadExaminations,
        initialMode: _pendingExaminationListMode,
        onOpenPatientDetail: (patient) =>
            setState(() => _selectedPatientDetail = patient),
      );
    }
    if (selectedPermission == 'patient_list_page') {
      if (!_hasPermission(context, PermissionCode.readPatientList)) {
        return _forbiddenPage(
          title: 'Không có quyền xem bệnh nhân',
          subtitle: 'Danh sách bệnh nhân không khả dụng với tài khoản này.',
          icon: Icons.lock_outline,
        );
      }
      return PatientListPage(
        embedded: true,
        onClearSearch: () => _searchController.clear(),
        onOpenPatientDetail: (patient) =>
            setState(() => _selectedPatientDetail = patient),
      );
    }
    if (selectedPermission == 'file_upload_page') {
      if (!_hasUploadPermission(context)) {
        return _forbiddenPage(
          title: 'Không có quyền upload DICOM',
          subtitle: 'Tài khoản này chưa được cấp quyền hỗ trợ chẩn đoán.',
          icon: Icons.lock_outline,
        );
      }
      return FileUploadPage(onGoToExaminationList: _openExaminationListTab);
    }

    return _buildFeaturePlaceholderPage(
      title: selectedItem?.label ?? 'Đang cập nhật',
      subtitle: 'Tính năng này đang được cập nhật.',
      icon: selectedItem?.icon ?? Icons.construction_outlined,
    );
  }

  void _syncAiChatFloatingVisibility(String selectedPermission) {
    final shouldHideFloatingChat =
        selectedPermission == 'ai_clinical_chat_page';
    final chatVm = context.read<ChatViewModel>();
    if (chatVm.isFullPageVisible == shouldHideFloatingChat) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setAiChatFloatingHidden(shouldHideFloatingChat);
    });
  }

  void _setAiChatFloatingHidden(bool hidden) {
    final chatVm = context.read<ChatViewModel>();
    if (chatVm.isFullPageVisible == hidden) return;
    chatVm.setFullPageVisible(hidden);
  }

  void _handleAiChatPageRequest() {
    final requestVersion = context.select<ChatViewModel, int>(
      (chat) => chat.fullPageRequestVersion,
    );
    if (requestVersion == _handledAiChatPageRequestVersion) return;
    _handledAiChatPageRequestVersion = requestVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navItems = _visibleNavItems(context, listen: false);
      final aiChatIndex = navItems.indexWhere((item) {
        return item.permissionCode == PermissionCode.useAiChat;
      });
      if (aiChatIndex < 0) {
        final chatVm = context.read<ChatViewModel>();
        chatVm.setFullPageVisible(false);
        chatVm.open();
        AppToast.showError('Tài khoản chưa có quyền mở trang AI chat.');
        return;
      }

      _setAiChatFloatingHidden(true);
      setState(() {
        _selectedNavIndex = aiChatIndex;
        _showDoctorProfile = false;
        _showChangePassword = false;
        _showUploadExaminationList = false;
        _selectedPatientDetail = null;
        _selectedExaminationDetail = null;
      });
    });
  }

  void _openExaminationListTab([ExaminationListMode? mode]) {
    final navItems = _visibleNavItems(context, listen: false);
    final examIndex = navItems.indexWhere((item) {
      return item.permissionCode == PermissionCode.createPatientExam ||
          item.permissionCode == PermissionCode.viewExaminationList;
    });
    if (examIndex < 0) return;
    setState(() {
      _selectedNavIndex = examIndex;
      _examinationListRefreshVersion++;
      _showDoctorProfile = false;
      _showChangePassword = false;
      _showUploadExaminationList = false;
      _pendingExaminationListMode = mode;
      _selectedPatientDetail = null;
      _selectedExaminationDetail = null;
    });
  }

  Widget _buildUploadMiniProgress() {
    return Positioned(
      right: 18,
      bottom: 18,
      child: Consumer<DicomUploadViewModel>(
        builder: (context, vm, _) {
          if (!vm.isProcessActive || _isUploadPageSelected(context)) {
            return const SizedBox.shrink();
          }
          if (_isUploadMiniProgressCollapsed) {
            return _buildCollapsedUploadMiniProgress(vm);
          }
          return Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openUploadTabFromMiniProgress,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openUploadTabFromMiniProgress,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_sync_outlined,
                            color: _primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Xử lý DICOM',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2B3C),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Thu gọn',
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            onPressed: () => setState(
                              () => _isUploadMiniProgressCollapsed = true,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatUploadDuration(vm.uploadElapsed),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: vm.progress?.clamp(0, 1).toDouble(),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: _primaryGreen,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.uploadStatusMessage ?? 'Đang xử lý...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedUploadMiniProgress(DicomUploadViewModel vm) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openUploadTabFromMiniProgress,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _openUploadTabFromMiniProgress,
          child: Container(
            width: 176,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.cloud_sync_outlined,
                    color: _primaryGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatUploadDuration(vm.uploadElapsed),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mở trang upload',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: _openUploadTabFromMiniProgress,
                  icon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isUploadPageSelected(BuildContext context) {
    if (_showUploadExaminationList || _selectedPatientDetail != null) {
      return false;
    }
    final navItems = _visibleNavItems(context);
    if (_selectedNavIndex < 0 || _selectedNavIndex >= navItems.length) {
      return false;
    }
    final routeKey = navItems[_selectedNavIndex].routeKey;
    return routeKey == 'file_upload_page';
  }

  void _openUploadTabFromMiniProgress() {
    final navItems = _visibleNavItems(context, listen: false);
    final uploadIndex = navItems.indexWhere((item) {
      return item.permissionCode == PermissionCode.uploadDicomImage;
    });
    if (uploadIndex < 0) return;
    setState(() {
      _selectedNavIndex = uploadIndex;
      _showDoctorProfile = false;
      _showChangePassword = false;
      _showUploadExaminationList = false;
      _selectedPatientDetail = null;
      _selectedExaminationDetail = null;
      _isUploadMiniProgressCollapsed = false;
    });
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final canSearchPatients =
        _hasPermission(context, PermissionCode.readPatientList) ||
        _hasPermission(context, PermissionCode.viewPatientDetail);
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
                readOnly: !canSearchPatients,
                onChanged: canSearchPatients
                    ? _handleTopBarPatientSearchChanged
                    : null,
                onSubmitted: canSearchPatients
                    ? _handleTopBarPatientSearchSubmitted
                    : null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: canSearchPatients
                      ? 'Tìm kiếm bệnh nhân, hồ sơ, mã số...'
                      : 'Không có quyền tìm kiếm bệnh nhân',
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
          _notificationButton(context),
          const SizedBox(width: 12),
          // Doctor info menu
          Consumer<AuthViewModel>(
            builder: (context, vm, child) => PopupMenuButton<_DoctorUserMenuAction>(
              tooltip: 'Tai khoan',
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 10,
              offset: const Offset(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              onSelected: (action) => _handleUserMenuAction(context, action),
              itemBuilder: (context) => [
                if (vm.currentUser?.isDepartmentHead == true) ...[
                  PopupMenuItem<_DoctorUserMenuAction>(
                    value: _DoctorUserMenuAction.toggleScope,
                    child: _ScopeToggleMenuItem(isPersonal: vm.isPersonalView),
                  ),
                  const PopupMenuDivider(),
                ],
                const PopupMenuItem<_DoctorUserMenuAction>(
                  value: _DoctorUserMenuAction.profile,
                  child: _UserMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Thông tin cá nhân',
                  ),
                ),
                PopupMenuItem<_DoctorUserMenuAction>(
                  value: _DoctorUserMenuAction.changePassword,
                  child: _UserMenuItem(
                    icon: Icons.lock_reset_rounded,
                    label: 'Đổi mật khẩu',
                  ),
                ),
                PopupMenuItem<_DoctorUserMenuAction>(
                  value: _DoctorUserMenuAction.logout,
                  child: _UserMenuItem(
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
                    Consumer<DoctorProfileViewModel>(
                      builder: (context, profileVm, _) {
                        final avatarUrl = resolveMediaUrl(
                          profileVm.profile?.avatarUrl ?? '',
                        );
                        final token = vm.currentUser?.token ?? '';
                        final initial =
                            vm.currentUser?.displayName.isNotEmpty == true
                            ? vm.currentUser!.displayName[0].toUpperCase()
                            : 'B';
                        final fallback = Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryGreen,
                          ),
                        );
                        return CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFE6F4F1),
                          child: avatarUrl.isEmpty
                              ? fallback
                              : ClipOval(
                                  child: SizedBox.expand(
                                    child: AuthenticatedAvatarImage(
                                      imageUrl: avatarUrl,
                                      token: token,
                                      fallback: fallback,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BS. ${vm.currentUser?.displayName ?? 'Bac si'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B3C),
                          ),
                        ),
                        Text(
                          vm.currentUser?.isDepartmentHead == true
                              ? 'Chế độ: ${vm.isPersonalView ? 'Cá nhân' : 'Toàn khoa'}'
                              : 'Chẩn đoán hình ảnh',
                          style: const TextStyle(
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

  Future<void> _handleUserMenuAction(
    BuildContext context,
    _DoctorUserMenuAction action,
  ) async {
    if (action == _DoctorUserMenuAction.toggleScope) {
      final isPersonal = !context.read<AuthViewModel>().isPersonalView;
      context.read<AuthViewModel>().setPersonalView(isPersonal);
      _reloadScopedData(isPersonal: isPersonal);
      return;
    }

    switch (action) {
      case _DoctorUserMenuAction.toggleScope:
        return;
      case _DoctorUserMenuAction.profile:
        setState(() {
          _showDoctorProfile = true;
          _showChangePassword = false;
          _showUploadExaminationList = false;
          _selectedPatientDetail = null;
          _selectedExaminationDetail = null;
        });
        break;
      case _DoctorUserMenuAction.changePassword:
        setState(() {
          _showChangePassword = true;
          _showDoctorProfile = false;
          _showUploadExaminationList = false;
          _selectedPatientDetail = null;
          _selectedExaminationDetail = null;
        });
        break;
      case _DoctorUserMenuAction.logout:
        await context.read<AuthViewModel>().logout();
        break;
    }
  }

  void _reloadScopedData({required bool isPersonal}) {
    final token = _token;
    final navItems = _visibleNavItems(context, listen: false);
    final selectedPermission =
        _selectedNavIndex >= 0 && _selectedNavIndex < navItems.length
        ? navItems[_selectedNavIndex].routeKey
        : '';

    if (selectedPermission == 'patient_list_page') {
      context.read<DoctorViewModel>().fetchFirstPage(
        token: token,
        isPersonal: isPersonal,
      );
      return;
    }

    if (selectedPermission == 'examination_list_page') {
      context.read<ExaminationViewModel>().loadExaminations(
        token: token,
        isPersonal: isPersonal,
      );
      return;
    }

    if (selectedPermission == 'doctor_dashboard_page') {
      context.read<ExaminationViewModel>().loadDashboardExaminations(
        token: token,
        isPersonal: isPersonal,
      );
    }
  }

  void _handleTopBarPatientSearchChanged(String value) {
    _openPatientListForSearch();
    context.read<DoctorViewModel>().searchByNameDebounced(
      value,
      _token,
      isPersonal: context.read<AuthViewModel>().isPersonalView,
    );
  }

  void _handleTopBarPatientSearchSubmitted(String value) {
    _openPatientListForSearch();
    context.read<DoctorViewModel>().searchByNameNow(
      value,
      _token,
      isPersonal: context.read<AuthViewModel>().isPersonalView,
    );
  }

  void _openPatientListForSearch() {
    final navItems = _visibleNavItems(context, listen: false);
    final patientListIndex = navItems.indexWhere(
      (item) => item.routeKey == 'patient_list_page',
    );
    if (patientListIndex < 0 || _selectedNavIndex == patientListIndex) return;
    setState(() {
      _selectedNavIndex = patientListIndex;
      _showDoctorProfile = false;
      _showChangePassword = false;
      _showUploadExaminationList = false;
      _selectedPatientDetail = null;
      _selectedExaminationDetail = null;
    });
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

  /*
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
              context.read<DoctorViewModel>().fetchFirstPage(
                token: _token,
                isPersonal: context.read<AuthViewModel>().isPersonalView,
              );
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
        vm.fetchFirstPage(
          token: _token,
          gender: value,
          isPersonal: context.read<AuthViewModel>().isPersonalView,
        );
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
              onRefresh: () => vm.fetchFirstPage(
                token: _token,
                isPersonal: context.read<AuthViewModel>().isPersonalView,
              ),
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
    final canOpenDetail = _hasPermission(
      context,
      PermissionCode.viewPatientDetail,
    );
    var isHovered = false;
    return StatefulBuilder(
      builder: (context, setHoverState) {
        return InkWell(
          onTap: () {
            if (!canOpenDetail) {
              _showPermissionDeniedToast('Không có quyền xem chi tiết bệnh nhân');
              return;
            }
            setState(() {
              _showChangePassword = false;
              _showDoctorProfile = false;
              _selectedPatientDetail = p;
            });
          },
          onHover: (hovering) => setHoverState(() => isHovered = hovering),
          hoverColor: Colors.transparent,
          splashColor: _primaryGreen.withValues(alpha: 0.08),
          highlightColor: _primaryGreen.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, isHovered ? -1 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFFF8FCFA) : Colors.white,
              border: Border.all(
                color: isHovered
                    ? const Color(0xFFCFE3DC)
                    : Colors.transparent,
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
              onPressed: () {
                if (!canOpenDetail) {
                  _showPermissionDeniedToast(
                    'Không có quyền xem chi tiết bệnh nhân',
                  );
                  return;
                }
                setState(() {
                  _showChangePassword = false;
                  _showDoctorProfile = false;
                  _selectedPatientDetail = p;
                });
              },
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
            onPressed: () => vm.fetchFirstPage(
              token: _token,
              isPersonal: context.read<AuthViewModel>().isPersonalView,
            ),
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
                isPersonal: context.read<AuthViewModel>().isPersonalView,
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
    ).then(
      (_) => vm.fetchFirstPage(
        token: _token,
        isPersonal: context.read<AuthViewModel>().isPersonalView,
      ),
    );
  }

  */
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
              child: _NotificationDropdown(token: _token),
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

  String _formatUploadDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  bool _hasPermission(BuildContext context, PermissionCode code) {
    return context.read<AuthViewModel>().hasPermissionCode(code);
  }

  bool _hasUploadPermission(BuildContext context) {
    return _hasPermission(context, PermissionCode.uploadDicomImage);
  }

  bool _canOpenExaminationList(BuildContext context) {
    return _hasPermission(context, PermissionCode.createPatientExam) ||
        _hasPermission(context, PermissionCode.viewExaminationList);
  }

  bool _canOpenExaminationDetail(BuildContext context) {
    return _hasPermission(context, PermissionCode.viewExaminationDetail) ||
        _canOpenExaminationList(context);
  }

  void _showPermissionDeniedToast(String message) {
    AppToast.showWarning(message);
  }

  Widget _forbiddenPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      color: const Color(0xFFF0F4F3),
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
                textAlign: TextAlign.center,
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
}

/*
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
*/

enum _DoctorUserMenuAction { toggleScope, profile, changePassword, logout }

class _ScopeToggleMenuItem extends StatelessWidget {
  final bool isPersonal;

  const _ScopeToggleMenuItem({required this.isPersonal});

  @override
  Widget build(BuildContext context) {
    final color = isPersonal
        ? const Color(0xFF2D7E6E)
        : const Color(0xFF2563EB);
    final bg = isPersonal ? const Color(0xFFDDF5EC) : const Color(0xFFDCEBFF);
    final borderColor = isPersonal
        ? const Color(0xFF9FD8C7)
        : const Color(0xFF9DBDFF);
    final knobAlignment = isPersonal
        ? Alignment.centerLeft
        : Alignment.centerRight;

    return Container(
      width: 176,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            alignment: knobAlignment,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Container(
              width: 84,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cá nhân',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPersonal
                        ? Colors.white
                        : color.withValues(alpha: 0.82),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Toàn khoa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPersonal
                        ? color.withValues(alpha: 0.82)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _UserMenuItem({
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

class _DoctorNavConfig {
  final String routeKey;
  final String label;
  final IconData icon;

  const _DoctorNavConfig({
    required this.routeKey,
    required this.label,
    required this.icon,
  });
}

class _DoctorNavItemData {
  final int index;
  final String routeKey;
  final String permissionName;
  final String label;
  final IconData icon;
  final PermissionCode permissionCode;

  const _DoctorNavItemData({
    required this.index,
    required this.routeKey,
    required this.permissionName,
    required this.label,
    required this.icon,
    required this.permissionCode,
  });
}

class _NotificationDropdown extends StatelessWidget {
  const _NotificationDropdown({required this.token});

  final String token;

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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.loadNotifications(token),
                      icon: const Icon(Icons.refresh, size: 18),
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
              if (vm.isLoading && vm.notifications.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (vm.errorMessage != null && vm.notifications.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF718096)),
                      ),
                    ),
                  ),
                )
              else if (vm.notifications.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Không có thông báo',
                      style: TextStyle(color: Color(0xFF718096)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount:
                        vm.visibleNotifications.length +
                        (vm.canShowMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= vm.visibleNotifications.length) {
                        return TextButton(
                          onPressed: vm.showMore,
                          child: const Text('Xem thêm'),
                        );
                      }
                      final notification = vm.visibleNotifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: notification.isRead
                            ? null
                            : () => vm.markAsRead(
                                id: notification.id,
                                token: token,
                              ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification.type);
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0F7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_notificationIcon(notification.type), color: color),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isUnread
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF718096),
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

  static IconData _notificationIcon(String type) {
    switch (type) {
      case 'AI_RESULT':
      case 'DICOM_BATCH_RESULT':
        return Icons.check_circle_outline;
      case 'ERROR':
        return Icons.error_outline;
      case 'SYSTEM':
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _notificationColor(String type) {
    switch (type) {
      case 'AI_RESULT':
      case 'DICOM_BATCH_RESULT':
        return const Color(0xFF2F855A);
      case 'ERROR':
        return const Color(0xFFE53E3E);
      case 'SYSTEM':
      default:
        return AppColors.primary;
    }
  }
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              !RegExp(r'^\d+$').hasMatch(v)) {
                            return 'Chỉ nhập số';
                          }
                          if (v != null &&
                              v.trim().isNotEmpty &&
                              v.trim().length != 10) {
                            return 'Số điện thoại phải có đúng 10 chữ số';
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v != null &&
                              v.trim().isNotEmpty &&
                              v.trim().length != 10) {
                            return 'Số điện thoại phải có đúng 10 chữ số';
                          }
                          return null;
                        },
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isRequired = label.trimRight().endsWith('*');
    final cleanLabel = isRequired
        ? label
              .trimRight()
              .substring(0, label.trimRight().length - 1)
              .trimRight()
        : label;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: cleanLabel,
                  style: const TextStyle(color: Color(0xFF4A5568)),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFE53E3E)),
                    ),
                  ],
                ),
              )
            : Text(cleanLabel),
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
      AppToast.showWarning('Chức năng tạo bệnh nhân đang hoàn thiện');
    }
  }
}
