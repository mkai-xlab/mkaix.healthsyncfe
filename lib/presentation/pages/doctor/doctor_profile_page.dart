import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/media_url_resolver.dart';
import '../../../domain/entities/doctor_account_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/doctor_profile_viewmodel.dart';
import '../../widgets/authenticated_avatar_image.dart';

class DoctorProfilePage extends StatefulWidget {
  final bool embedded;

  const DoctorProfilePage({super.key, this.embedded = false});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<DoctorProfileViewModel>().loadProfile(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: const Color(0xFFF6F8F7),
      child: Consumer<DoctorProfileViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.errorMessage != null && vm.profile == null) {
            return _ProfileErrorState(
              message: vm.errorMessage!,
              onRetry: () {
                final token =
                    context.read<AuthViewModel>().currentUser?.token ?? '';
                vm.loadProfile(token: token, forceRefresh: true);
              },
            );
          }

          final profile = vm.profile;
          if (profile == null) {
            return const Center(
              child: Text(
                'Chưa có dữ liệu hồ sơ bác sĩ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return _ProfileContent(
            profile: profile,
            warning: vm.errorMessage,
            onRefresh: () {
              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              vm.loadProfile(token: token, forceRefresh: true);
            },
          );
        },
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(body: content);
  }
}

class _ProfileContent extends StatelessWidget {
  final DoctorAccountEntity profile;
  final String? warning;
  final VoidCallback onRefresh;

  const _ProfileContent({
    required this.profile,
    required this.warning,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          if (warning != null && warning!.trim().isNotEmpty) ...[
            _InlineWarning(message: warning!, onRefresh: onRefresh),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final detailPanel = _EditableProfileCard(profile: profile);
              final summaryPanel = _SummaryPanel(
                profile: profile,
                onRefresh: onRefresh,
              );
              if (!isWide) {
                return Column(
                  children: [
                    _HeroCard(
                      profile: profile,
                      onAvatarTap: () => _showAvatarUploadDialog(context),
                    ),
                    const SizedBox(height: 20),
                    detailPanel,
                    const SizedBox(height: 20),
                    summaryPanel,
                  ],
                );
              }

              return Column(
                children: [
                  _HeroCard(
                    profile: profile,
                    onAvatarTap: () => _showAvatarUploadDialog(context),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: detailPanel),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: summaryPanel),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarUploadDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AvatarUploadDialog(),
    );
  }
}

class _EditableProfileCard extends StatefulWidget {
  final DoctorAccountEntity profile;

  const _EditableProfileCard({required this.profile});

  @override
  State<_EditableProfileCard> createState() => _EditableProfileCardState();
}

class _EditableProfileCardState extends State<_EditableProfileCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _biographyController;

  String _initialSnapshot = '';

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _biographyController = TextEditingController();
    _syncFromProfile(widget.profile);
  }

  @override
  void didUpdateWidget(covariant _EditableProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _syncFromProfile(widget.profile);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorProfileViewModel>();
    final isUpdating = vm.isUpdating;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                final fields = <Widget>[
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Họ và tên',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email công vụ',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return null;
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                  ),
                ];
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final field in fields)
                      SizedBox(width: fieldWidth, child: field),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _biographyController,
              label: 'Giới thiệu cá nhân',
              minLines: 4,
              maxLines: 6,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isUpdating ? null : _resetForm,
                  child: const Text('Đặt lại'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isUpdating ? null : () => _submit(context),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isUpdating ? 'Đang cập nhật...' : 'Cập nhật'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isMultiLine = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF9AA6B2)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isMultiLine ? 12 : 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _syncFromProfile(DoctorAccountEntity profile) {
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _biographyController.text = profile.bio ?? '';
    _initialSnapshot = _snapshot();
    if (mounted) {
      setState(() {});
    }
  }

  void _resetForm() {
    _syncFromProfile(widget.profile);
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) return;
    if (_snapshot() == _initialSnapshot) {
      AppToast.showInfo('Bạn chưa thay đổi thông tin nào');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận cập nhật'),
          content: const Text(
            'Bạn có chắc muốn cập nhật thông tin cá nhân không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final payload = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'biography': _biographyController.text.trim(),
    };

    final vm = context.read<DoctorProfileViewModel>();
    final success = await vm.updateProfile(token: token, payload: payload);
    if (!context.mounted) return;

    if (success) {
      _syncFromProfile(vm.profile ?? widget.profile);
      AppToast.showSuccess('Cập nhật thông tin cá nhân thành công');
    } else {
      AppToast.showError(
        vm.errorMessage ?? 'Không thể cập nhật thông tin cá nhân',
      );
    }
  }

  String _snapshot() {
    return [
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _biographyController.text.trim(),
    ].join('|');
  }
}

class _HeroCard extends StatelessWidget {
  final DoctorAccountEntity profile;
  final VoidCallback onAvatarTap;

  const _HeroCard({required this.profile, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final title = profile.fullName.trim().isEmpty
        ? profile.username
        : profile.fullName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final image = _ProfileAvatar(
            profile: profile,
            size: compact ? 112 : 148,
            onTap: onAvatarTap,
          );
          final info = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BS. $title',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _BadgeChip(
                      icon: Icons.verified_user_outlined,
                      label: profile.role.trim().isEmpty
                          ? 'Bác sĩ'
                          : profile.role,
                    ),
                    _BadgeChip(
                      icon: Icons.circle_notifications_outlined,
                      label: _doctorStatusLabel(profile.status),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [image, const SizedBox(height: 20), info],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [image, const SizedBox(width: 24), info],
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final DoctorAccountEntity profile;
  final double size;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.profile,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim() ?? '';
    final imageUrl = resolveMediaUrl(avatarUrl);
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final initialsSource = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : profile.username.trim();
    final initial = initialsSource.isEmpty
        ? 'B'
        : initialsSource[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );

    return Tooltip(
      message: 'Đổi ảnh đại diện',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFE7F5F1),
                border: Border.all(color: const Color(0xFFD8E2E8)),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? fallback
                  : AuthenticatedAvatarImage(
                      imageUrl: imageUrl,
                      token: token,
                      fallback: fallback,
                    ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarUploadDialog extends StatefulWidget {
  const _AvatarUploadDialog();

  @override
  State<_AvatarUploadDialog> createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<_AvatarUploadDialog> {
  static const int _maxFileSize = 5 * 1024 * 1024;

  final _cropKey = GlobalKey();
  Uint8List? _imageBytes;
  Uint8List? _previewBytes;
  String _filename = 'avatar.png';
  String? _error;
  bool _isDragging = false;
  bool _isPreparing = false;
  double _zoom = 1;
  double _cropSize = 320;
  Offset _imageOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<DoctorProfileViewModel>().isUpdating;
    final screenSize = MediaQuery.sizeOf(context);
    final maxDialogHeight = screenSize.height * 0.94;
    final maxCropSize = (screenSize.height - 250).clamp(340.0, 520.0);
    final maxDialogWidth = screenSize.width < 1180
        ? screenSize.width - 40
        : 920.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final preview = _buildSidePanel();
              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 13),
                            child: LayoutBuilder(
                              builder: (context, leftConstraints) {
                                final cropSize = leftConstraints.maxWidth.clamp(
                                  260.0,
                                  maxCropSize,
                                );
                                _cropSize = cropSize;
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: SizedBox.square(
                                    dimension: cropSize,
                                    child: _buildCropper(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 13),
                            child: preview,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) {
                            final cropSize = constraints.maxWidth.clamp(
                              260.0,
                              maxCropSize,
                            );
                            _cropSize = cropSize;
                            return SizedBox.square(
                              dimension: cropSize,
                              child: _buildCropper(),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        preview,
                      ],
                    );

              final dialogBody = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cập nhật ảnh đại diện',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  content,
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed:
                            _imageBytes == null || isUploading || _isPreparing
                            ? null
                            : _uploadAvatar,
                        icon: isUploading || _isPreparing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          isUploading || _isPreparing
                              ? 'Đang lưu...'
                              : 'Lưu ảnh',
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (isWide) {
                return dialogBody;
              }

              return SingleChildScrollView(child: dialogBody);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCropper() {
    return AspectRatio(
      aspectRatio: 1,
      child: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (detail) async {
          setState(() => _isDragging = false);
          if (detail.files.isNotEmpty) {
            await _loadXFile(detail.files.first);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDragging ? AppColors.primary : const Color(0xFFE2E8F0),
              width: _isDragging ? 1.6 : 1,
            ),
          ),
          child: SizedBox.expand(
            child: _imageBytes == null
                ? _buildDropPlaceholder()
                : _buildCropArea(),
          ),
        ),
      ),
    );
  }

  Widget _buildDropPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 42,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kéo thả ảnh PNG hoặc JPEG vào đây',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tối đa 5MB',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RepaintBoundary(
        key: _cropKey,
        child: ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                _imageOffset = _boundedOffset(
                  _imageOffset + details.delta,
                  _zoom,
                );
              });
            },
            onPanEnd: (_) => _refreshPreview(),
            child: Transform.translate(
              offset: _imageOffset,
              child: Transform.scale(
                scale: _zoom,
                child: SizedBox.expand(
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F5F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD8E2E8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _previewBytes == null
              ? (_imageBytes == null
                    ? const Icon(Icons.person_outline, size: 38)
                    : Image.memory(_imageBytes!, fit: BoxFit.cover))
              : Image.memory(_previewBytes!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kéo ảnh để căn khung, dùng thanh trượt để thu phóng.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Chọn ảnh'),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Thu phóng',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Slider(
          value: _zoom,
          min: 1,
          max: 4,
          divisions: 30,
          onChanged: _imageBytes == null ? null : _setZoom,
          onChangeEnd: _imageBytes == null ? null : (_) => _refreshPreview(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    await _loadBytes(bytes: file.bytes, filename: file.name, size: file.size);
  }

  Future<void> _loadXFile(XFile file) async {
    await _loadBytes(
      bytes: await file.readAsBytes(),
      filename: file.name,
      size: await file.length(),
    );
  }

  Future<void> _loadBytes({
    required Uint8List? bytes,
    required String filename,
    required int size,
  }) async {
    final lowerName = filename.toLowerCase();
    if (!lowerName.endsWith('.png') &&
        !lowerName.endsWith('.jpg') &&
        !lowerName.endsWith('.jpeg')) {
      setState(() => _error = 'Chỉ hỗ trợ ảnh PNG hoặc JPEG');
      return;
    }
    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Không thể đọc file ảnh');
      return;
    }
    if (size > _maxFileSize) {
      setState(() => _error = 'Ảnh vượt quá dung lượng 5MB');
      return;
    }

    setState(() {
      _imageBytes = bytes;
      _previewBytes = bytes;
      _filename = filename;
      _zoom = 1;
      _imageOffset = Offset.zero;
      _error = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      await _refreshPreview();
    }
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value;
      _imageOffset = _boundedOffset(_imageOffset, value);
    });
  }

  Offset _boundedOffset(Offset offset, double scale) {
    final maxOffset = ((_cropSize * scale) - _cropSize) / 2;
    if (maxOffset <= 0) return Offset.zero;
    return Offset(
      offset.dx.clamp(-maxOffset, maxOffset),
      offset.dy.clamp(-maxOffset, maxOffset),
    );
  }

  Future<Uint8List?> _captureCrop() async {
    final boundary =
        _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _refreshPreview() async {
    final bytes = await _captureCrop();
    if (!mounted || bytes == null) return;
    setState(() => _previewBytes = bytes);
  }

  Future<void> _uploadAvatar() async {
    setState(() => _isPreparing = true);
    final bytes = await _captureCrop();
    if (!mounted) return;
    if (bytes == null) {
      setState(() {
        _isPreparing = false;
        _error = 'Không thể xử lý ảnh đã cắt';
      });
      return;
    }

    setState(() {
      _previewBytes = bytes;
      _isPreparing = false;
    });

    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final success = await context.read<DoctorProfileViewModel>().uploadAvatar(
      token: token,
      bytes: bytes,
      filename: _normalizedUploadName(),
    );
    if (!mounted) return;
    if (success) {
      AppToast.showSuccess('Cập nhật ảnh đại diện thành công');
      Navigator.of(context).pop();
    } else {
      final vm = context.read<DoctorProfileViewModel>();
      setState(() {
        _error = vm.errorMessage ?? 'Không thể cập nhật ảnh đại diện';
      });
    }
  }

  String _normalizedUploadName() {
    final baseName = _filename
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'\.(png|jpe?g)$', caseSensitive: false), '');
    final safeBaseName = baseName.trim().isEmpty ? 'avatar' : baseName.trim();
    return '$safeBaseName-cropped.png';
  }
}

class _SummaryPanel extends StatelessWidget {
  final DoctorAccountEntity profile;
  final VoidCallback onRefresh;

  const _SummaryPanel({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medical_information_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                profile.fullName.trim().isEmpty
                    ? profile.username
                    : profile.fullName.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.email.trim().isEmpty ? profile.username : profile.email,
                style: const TextStyle(color: Color(0xFFD8F3EB), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thao tác',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại hồ sơ'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 34,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải hồ sơ bác sĩ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _InlineWarning({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFD4A017)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B4E00)),
            ),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Làm mới')),
        ],
      ),
    );
  }
}

String _doctorStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ACTIVE':
      return 'Đang hoạt động';
    case 'INACTIVE':
      return 'Ngừng hoạt động';
    default:
      return status;
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BadgeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
