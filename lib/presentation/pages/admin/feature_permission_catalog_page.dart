import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../viewmodels/permission_viewmodel.dart';
import '../../../data/models/permission_catalog_model.dart';
import '../../../data/models/permission_model.dart';

class FeaturePermissionCatalogPage extends StatefulWidget {
  const FeaturePermissionCatalogPage({super.key});

  @override
  State<FeaturePermissionCatalogPage> createState() =>
      _FeaturePermissionCatalogPageState();
}

class _FeaturePermissionCatalogPageState
    extends State<FeaturePermissionCatalogPage> {
  static const Color _primaryGreen = AppColors.primary;
  int _selectedTab = 0;

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
        if (vm.isLoading && vm.features.isEmpty && vm.permissions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null &&
            vm.features.isEmpty &&
            vm.permissions.isEmpty) {
          return _buildError(vm);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildHeader(vm),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTabs(vm),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildSelectedTab(vm),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(PermissionViewModel vm) {
    final actionLabel = switch (_selectedTab) {
      0 => 'Thêm feature',
      1 => 'Thêm permission',
      _ => 'Tải lại',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh mục quyền hệ thống',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quản lý feature, permission và role theo schema backend mới.',
                style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: vm.loadAll,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Tải lại'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryGreen,
            side: const BorderSide(color: _primaryGreen),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: vm.isSaving
              ? null
              : () {
                  if (_selectedTab == 0) {
                    _showFeatureDialog(context, vm);
                  } else if (_selectedTab == 1) {
                    _showPermissionDialog(context, vm);
                  }
                },
          icon: const Icon(Icons.add, size: 16),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(PermissionViewModel vm) {
    final tabs = [
      ('Features', vm.features.length),
      ('Permissions', vm.permissions.length),
      ('Roles', vm.roles.length),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = _selectedTab == index;
          return InkWell(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? _primaryGreen : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.$1,
                    style: TextStyle(
                      color: selected ? _primaryGreen : const Color(0xFF718096),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE6F4F1)
                          : const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tab.$2.toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTab(PermissionViewModel vm) {
    switch (_selectedTab) {
      case 1:
        return _buildPermissionTab(vm);
      case 2:
        return _buildRoleTab(vm);
      default:
        return _buildFeatureTab(vm);
    }
  }

  Widget _buildFeatureTab(PermissionViewModel vm) {
    if (vm.features.isEmpty) {
      return _emptyState('Chưa có feature nào');
    }

    return Column(
      children: vm.features.map((feature) {
        final permissions = vm.permissionsForFeature(feature.id);
        return _panel(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.view_module_outlined,
                        color: _primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.name.isEmpty
                                ? 'Feature không tên'
                                : feature.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2B3C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description.isEmpty
                                ? 'Không có mô tả'
                                : feature.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${permissions.length} permission',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A5568),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showFeatureDialog(
                                context,
                                vm,
                                feature: feature,
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: _primaryGreen,
                              tooltip: 'Sửa feature',
                            ),
                            IconButton(
                              onPressed: () => _showPermissionDialog(
                                context,
                                vm,
                                featureId: feature.id,
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              color: _primaryGreen,
                              tooltip: 'Thêm permission vào feature',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (permissions.isEmpty)
                  const Text(
                    'Chưa có permission con.',
                    style: TextStyle(color: Color(0xFF718096), fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: permissions
                        .map(
                          (permission) => _permissionChip(
                            permission,
                            onTap: () => _showPermissionDialog(
                              context,
                              vm,
                              permission: permission,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionTab(PermissionViewModel vm) {
    if (vm.permissions.isEmpty) {
      return _emptyState('Chưa có permission nào');
    }

    return Column(
      children: vm.permissions.map((permission) {
        final feature = vm.featureById(permission.featureId ?? '');
        return _panel(
          child: ListTile(
            leading: const Icon(Icons.key_outlined, color: _primaryGreen),
            title: Text(
              permission.name.isEmpty ? permission.code : permission.name,
            ),
            subtitle: Text(
              [
                'ID: ${permission.id.isEmpty ? 'N/A' : permission.id}',
                'Code: ${permission.code.isEmpty ? 'N/A' : permission.code}',
                'Feature: ${feature?.name ?? permission.resource}',
                'Priority: ${permission.priority}',
                'Presentation: ${permission.presentation.isEmpty ? 'N/A' : permission.presentation}',
                if (permission.parentId != null)
                  'Parent: ${permission.parentId}',
              ].join('  |  '),
            ),
            trailing: IconButton(
              onPressed: () =>
                  _showPermissionDialog(context, vm, permission: permission),
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: _primaryGreen,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleTab(PermissionViewModel vm) {
    if (vm.roles.isEmpty) {
      return _emptyState('Chưa có role nào');
    }

    return Column(
      children: vm.roles.map((role) {
        return _panel(
          child: ListTile(
            leading: const Icon(Icons.group_outlined, color: _primaryGreen),
            title: Text(role.name),
            subtitle: Text('${role.permissions.length} permissions enabled'),
          ),
        );
      }).toList(),
    );
  }

  Widget _permissionChip(
    PermissionModel permission, {
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(
        permission.name.isEmpty
            ? permission.code
            : '${permission.name} (#${permission.id})',
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: const Color(0xFFF7FAFC),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      onPressed: onTap,
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF718096)),
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

  Future<void> _showFeatureDialog(
    BuildContext context,
    PermissionViewModel vm, {
    PermissionFeatureModel? feature,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: feature?.name ?? '');
    final descriptionController = TextEditingController(
      text: feature?.description ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(feature == null ? 'Thêm feature' : 'Sửa feature'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên feature *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Bắt buộc nhập tên'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                if (vm.errorMessage != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Color(0xFFE53E3E)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: vm.isSaving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: vm.isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final success = feature == null
                        ? await vm.createFeature(
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                          )
                        : await vm.updateFeature(
                            id: feature.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                          );
                    if (!dialogContext.mounted) return;
                    if (success) {
                      Navigator.pop(dialogContext);
                      await vm.loadAll();
                    }
                  },
            child: Text(vm.isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showPermissionDialog(
    BuildContext context,
    PermissionViewModel vm, {
    PermissionModel? permission,
    String? featureId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: permission?.code ?? '');
    final nameController = TextEditingController(text: permission?.name ?? '');
    final presentationController = TextEditingController(
      text: permission?.presentation ?? '',
    );
    final priorityController = TextEditingController(
      text: permission == null ? '' : permission.priority.toString(),
    );
    final requiresPermissionController = TextEditingController(
      text: permission?.parentId ?? '',
    );

    String selectedFeatureId = featureId ?? permission?.featureId ?? '';
    if (selectedFeatureId.isEmpty && vm.features.isNotEmpty) {
      selectedFeatureId = vm.features.first.id;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              permission == null ? 'Thêm permission' : 'Sửa permission',
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc nhập code'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc nhập tên'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFeatureId.isEmpty
                            ? null
                            : selectedFeatureId,
                        decoration: const InputDecoration(
                          labelText: 'Feature *',
                        ),
                        items: vm.features
                            .map(
                              (featureItem) => DropdownMenuItem<String>(
                                value: featureItem.id,
                                child: Text(featureItem.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedFeatureId = value);
                          }
                        },
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Chọn feature' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: presentationController,
                        decoration: const InputDecoration(
                          labelText: 'Presentation',
                          helperText:
                              'VD: patient_list_page, patient_detail_page',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priorityController,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          final parsed = int.tryParse(value);
                          if (parsed == null) return 'Priority phải là số';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: requiresPermissionController,
                        decoration: const InputDecoration(
                          labelText: 'Parent permission ID',
                        ),
                      ),
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(color: Color(0xFFE53E3E)),
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
                onPressed: vm.isSaving
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final priorityText = priorityController.text.trim();
                        final success = permission == null
                            ? await vm.createPermission(
                                code: codeController.text.trim(),
                                name: nameController.text.trim(),
                                featureId: selectedFeatureId,
                                presentation:
                                    presentationController.text.trim().isEmpty
                                    ? null
                                    : presentationController.text.trim(),
                                priority: priorityText.isEmpty
                                    ? null
                                    : int.tryParse(priorityText),
                                requiresPermissionId:
                                    requiresPermissionController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : requiresPermissionController.text.trim(),
                              )
                            : await vm.updatePermission(
                                id: permission.id,
                                code: codeController.text.trim(),
                                name: nameController.text.trim(),
                                featureId: selectedFeatureId,
                                presentation:
                                    presentationController.text.trim().isEmpty
                                    ? null
                                    : presentationController.text.trim(),
                                priority: priorityText.isEmpty
                                    ? null
                                    : int.tryParse(priorityText),
                                requiresPermissionId:
                                    requiresPermissionController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : requiresPermissionController.text.trim(),
                              );
                        if (!dialogContext.mounted) return;
                        if (success) {
                          Navigator.pop(dialogContext);
                          await vm.loadAll();
                        }
                      },
                child: Text(vm.isSaving ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );

    codeController.dispose();
    nameController.dispose();
    presentationController.dispose();
    priorityController.dispose();
    requiresPermissionController.dispose();
  }
}
