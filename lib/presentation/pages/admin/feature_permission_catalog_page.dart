import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../viewmodels/permission_viewmodel.dart';
import '../../../data/models/permission_catalog_model.dart';
import '../../../data/models/permission_model.dart';
import '../../widgets/required_field_label.dart';

enum _PermissionTabMode { list, hierarchy, sort }

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
  _PermissionTabMode _permissionTabMode = _PermissionTabMode.list;

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
      0 => 'Thêm tính năng',
      1 => 'Thêm quyền',
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
                'Quản lý tính năng, quyền và vai trò theo schema backend mới.',
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
      ('Tính năng', vm.features.length),
      ('Quyền', vm.permissions.length),
      ('Vai trò', vm.roles.length),
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
        return _buildFeatureTreeTab(vm);
    }
  }

  Widget _buildFeatureTreeTab(PermissionViewModel vm) {
    if (vm.features.isEmpty) {
      return _emptyState('Chưa có tính năng nào');
    }

    return Column(
      children: vm.features.map((feature) {
        final permissions = vm.permissionsForFeature(feature.id);
        return DragTarget<PermissionModel>(
          onWillAcceptWithDetails: (details) {
            return details.data.featureId != feature.id;
          },
          onAcceptWithDetails: (details) =>
              _confirmMovePermission(context, vm, details.data, feature),
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return _HoverSurface(
              isHighlighted: isDropTarget,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDropTarget
                        ? const Color(0xFFDDF4EF)
                        : const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.view_module_outlined,
                    color: _primaryGreen,
                  ),
                ),
                title: Text(
                  feature.name.isEmpty
                      ? 'Tính năng chưa đặt tên'
                      : feature.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isDropTarget
                        ? 'Thả vào đây để chuyển quyền sang tính năng này'
                        : feature.description.isEmpty
                        ? 'Không có mô tả'
                        : feature.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                ),
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${permissions.length} quyền',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            _showFeatureDialog(context, vm, feature: feature),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: _primaryGreen,
                        tooltip: 'Sửa tính năng',
                      ),
                      IconButton(
                        onPressed: () => _showPermissionDialog(
                          context,
                          vm,
                          featureId: feature.id,
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        color: _primaryGreen,
                        tooltip: 'Thêm quyền vào tính năng',
                      ),
                    ],
                  ),
                ),
                children: [
                  if (permissions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Chưa có quyền con.',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: permissions
                          .map(
                            (permission) => _permissionRow(
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
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _confirmMovePermission(
    BuildContext context,
    PermissionViewModel vm,
    PermissionModel permission,
    PermissionFeatureModel targetFeature,
  ) async {
    if (permission.featureId == targetFeature.id || vm.isSaving) return;

    final permissionName = permission.name.isEmpty
        ? permission.code
        : permission.name;
    final targetName = targetFeature.name.isEmpty
        ? 'tính năng chưa đặt tên'
        : targetFeature.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chuyển quyền'),
        content: Text(
          'Chuyển quyền "$permissionName" sang tính năng "$targetName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await vm.movePermissionToFeature(
      permission: permission,
      targetFeatureId: targetFeature.id,
    );
  }

  Future<void> _confirmMovePermissionToParent(
    PermissionViewModel vm,
    PermissionModel permission,
    PermissionModel targetParent,
  ) async {
    if (permission.id == targetParent.id ||
        permission.parentId == targetParent.id ||
        vm.isSaving) {
      return;
    }

    final permissionName = permission.name.isEmpty
        ? permission.code
        : permission.name;
    final parentName = targetParent.name.isEmpty
        ? targetParent.code
        : targetParent.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chuyển quyền cha'),
        content: Text('Đặt "$parentName" làm quyền cha của "$permissionName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await vm.movePermissionToParent(
      permission: permission,
      targetParent: targetParent,
    );
  }

  Widget _permissionRow(
    PermissionModel permission, {
    required VoidCallback onTap,
  }) {
    final title = permission.name.isEmpty ? permission.code : permission.name;
    final row = _HoverSurface(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 8,
      color: const Color(0xFFF7FAFC),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: _primaryGreen, size: 18),
          const SizedBox(width: 8),
          const Icon(Icons.key_outlined, color: _primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  permission.code.isEmpty
                      ? 'Code: N/A'
                      : 'Code: ${permission.code}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              'Thứ tự: ${permission.priority}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              permission.parentId == null || permission.parentId!.isEmpty
                  ? 'Quyền cha: N/A'
                  : 'Quyền cha: ${permission.parentId}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: _primaryGreen,
            tooltip: 'Sửa quyền',
          ),
        ],
      ),
    );

    return Draggable<PermissionModel>(
      data: permission,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _HoverSurface(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            borderRadius: 8,
            isHighlighted: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key_outlined, color: _primaryGreen, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: row),
      child: row,
    );
  }

  // ignore: unused_element
  Widget _buildFeatureTab(PermissionViewModel vm) {
    if (vm.features.isEmpty) {
      return _emptyState('Chưa có tính năng nào');
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
                                ? 'Tính năng chưa đặt tên'
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
                          '${permissions.length} quyền',
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
                              tooltip: 'Sửa tính năng',
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
                              tooltip: 'Thêm quyền vào tính năng',
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
                    'Chưa có quyền con.',
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
      return _emptyState('Chưa có quyền nào');
    }

    final treeData = _buildPermissionTreeData(vm.permissions);
    final rootPermissions = treeData.$1;
    final childrenByParent = treeData.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPermissionModeSelector(),
        const SizedBox(height: 12),
        if (_permissionTabMode == _PermissionTabMode.sort)
          _buildPermissionSortMode(vm, rootPermissions)
        else
          _buildPermissionTreeMode(
            vm,
            rootPermissions,
            childrenByParent,
            enableParentDragDrop:
                _permissionTabMode == _PermissionTabMode.hierarchy,
          ),
      ],
    );
  }

  (List<PermissionModel>, Map<String, List<PermissionModel>>)
  _buildPermissionTreeData(List<PermissionModel> permissions) {
    final permissionById = {
      for (final permission in permissions) permission.id: permission,
    };
    final childrenByParent = <String, List<PermissionModel>>{};
    for (final permission in permissions) {
      final parentId = permission.parentId?.trim() ?? '';
      if (parentId.isEmpty) continue;
      childrenByParent.putIfAbsent(parentId, () => []).add(permission);
    }

    int comparePermission(PermissionModel a, PermissionModel b) {
      final priorityCmp = a.priority.compareTo(b.priority);
      if (priorityCmp != 0) return priorityCmp;
      final nameCmp = (a.name.isEmpty ? a.code : a.name).compareTo(
        b.name.isEmpty ? b.code : b.name,
      );
      if (nameCmp != 0) return nameCmp;
      return a.id.compareTo(b.id);
    }

    for (final children in childrenByParent.values) {
      children.sort(comparePermission);
    }

    final rootPermissions = permissions.where((permission) {
      final parentId = permission.parentId?.trim() ?? '';
      return parentId.isEmpty || !permissionById.containsKey(parentId);
    }).toList()..sort(comparePermission);

    return (rootPermissions, childrenByParent);
  }

  Widget _buildPermissionModeSelector() {
    Widget item(_PermissionTabMode mode, String label, IconData icon) {
      final selected = _permissionTabMode == mode;
      return ChoiceChip(
        selected: selected,
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : _primaryGreen,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A2B3C),
          fontWeight: FontWeight.w600,
        ),
        selectedColor: _primaryGreen,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primaryGreen : const Color(0xFFE2E8F0),
        ),
        onSelected: (_) => setState(() => _permissionTabMode = mode),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        item(_PermissionTabMode.list, 'Danh sách', Icons.list_alt_outlined),
        item(
          _PermissionTabMode.hierarchy,
          'Phân quyền',
          Icons.account_tree_outlined,
        ),
        item(_PermissionTabMode.sort, 'Sắp xếp', Icons.sort_outlined),
      ],
    );
  }

  Widget _buildPermissionTreeMode(
    PermissionViewModel vm,
    List<PermissionModel> rootPermissions,
    Map<String, List<PermissionModel>> childrenByParent, {
    required bool enableParentDragDrop,
  }) {
    return Column(
      children: rootPermissions.map((permission) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _permissionTreeNode(
            vm,
            permission,
            childrenByParent: childrenByParent,
            level: 0,
            visited: const {},
            onMoveToParent: _confirmMovePermissionToParent,
            enableParentDragDrop: enableParentDragDrop,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionSortMode(
    PermissionViewModel vm,
    List<PermissionModel> rootPermissions,
  ) {
    if (rootPermissions.isEmpty) {
      return _emptyState('Chưa có quyền cha nào để sắp xếp');
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: rootPermissions.length,
      onReorderItem: (oldIndex, newIndex) async {
        final reordered = List<PermissionModel>.from(rootPermissions);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        await vm.updateParentPermissionPriorities(reordered);
      },
      itemBuilder: (context, index) {
        final permission = rootPermissions[index];
        final featureName = vm.featureById(permission.featureId ?? '')?.name;
        return _HoverSurface(
          key: ValueKey('sort-permission-${permission.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: _primaryGreen),
            ),
            title: Text(
              permission.name.isEmpty ? permission.code : permission.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
            subtitle: Text(
              _permissionSummary(permission, featureName),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
            trailing: Text(
              'Thứ tự mới: ${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  String _permissionSummary(PermissionModel permission, String? featureName) {
    return [
      'ID: ${permission.id.isEmpty ? 'N/A' : permission.id}',
      'Code: ${permission.code.isEmpty ? 'N/A' : permission.code}',
      'Tính năng: ${featureName ?? permission.resource}',
      'Thứ tự: ${permission.priority}',
      if (permission.parentId != null && permission.parentId!.isNotEmpty)
        'Quyền cha: ${permission.parentId}',
    ].join('  |  ');
  }

  Widget _permissionTreeNode(
    PermissionViewModel vm,
    PermissionModel permission, {
    required Map<String, List<PermissionModel>> childrenByParent,
    required int level,
    required Set<String> visited,
    required bool enableParentDragDrop,
    required Future<void> Function(
      PermissionViewModel vm,
      PermissionModel permission,
      PermissionModel targetParent,
    )
    onMoveToParent,
  }) {
    return _PermissionDropTarget(
      vm: vm,
      permission: permission,
      childrenByParent: childrenByParent,
      level: level,
      visited: visited,
      enableParentDragDrop: enableParentDragDrop,
      onMoveToParent: onMoveToParent,
      buildNode: _buildPermissionTreeNodeContent,
    );
  }

  Widget _buildPermissionTreeNodeContent(
    PermissionViewModel vm,
    PermissionModel permission, {
    required Map<String, List<PermissionModel>> childrenByParent,
    required int level,
    required Set<String> visited,
    required bool isDropTarget,
    required bool enableParentDragDrop,
    required ExpansibleController controller,
    required Future<void> Function(
      PermissionViewModel vm,
      PermissionModel permission,
      PermissionModel targetParent,
    )
    onMoveToParent,
  }) {
    final children =
        childrenByParent[permission.id] ?? const <PermissionModel>[];
    final featureName = vm.featureById(permission.featureId ?? '')?.name;
    final nextVisited = {...visited, permission.id};
    final safeChildren = children
        .where((child) => !nextVisited.contains(child.id))
        .toList();
    final hasChildren = safeChildren.isNotEmpty;
    final isRoot = level == 0;
    final indent = (level * 18.0).clamp(0.0, 72.0);
    final title = permission.name.isEmpty ? permission.code : permission.name;
    final leadingIcon = isRoot
        ? Icons.key_outlined
        : hasChildren
        ? Icons.account_tree_outlined
        : Icons.subdirectory_arrow_right;

    Widget trailing() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${safeChildren.length} quyền con',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            onPressed: () =>
                _showPermissionDialog(context, vm, permission: permission),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: _primaryGreen,
            tooltip: isRoot ? 'Sửa quyền cha' : 'Sửa quyền',
          ),
        ],
      );
    }

    final tilePadding = EdgeInsets.only(
      left: 18 + indent,
      right: 12,
      top: 8,
      bottom: 8,
    );

    Widget draggableNode(Widget child) {
      return Draggable<PermissionModel>(
        data: permission,
        maxSimultaneousDrags: enableParentDragDrop ? null : 0,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _HoverSurface(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 8,
              isHighlighted: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.key_outlined,
                    color: _primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.45, child: child),
        child: child,
      );
    }

    final tileBody = _HoverSurface(
      margin: EdgeInsets.only(top: isRoot ? 0 : 8),
      borderRadius: 8,
      color: isRoot ? Colors.white : const Color(0xFFF7FAFC),
      isHighlighted: isDropTarget,
      child: hasChildren
          ? ExpansionTile(
              controller: controller,
              tilePadding: tilePadding,
              childrenPadding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
              leading: Icon(
                leadingIcon,
                color: _primaryGreen,
                size: isRoot ? 20 : 18,
              ),
              title: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isRoot ? 14 : 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
              subtitle: Text(
                _permissionSummary(permission, featureName),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              trailing: trailing(),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              children: safeChildren
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: _permissionTreeNode(
                        vm,
                        child,
                        childrenByParent: childrenByParent,
                        level: level + 1,
                        visited: nextVisited,
                        onMoveToParent: onMoveToParent,
                        enableParentDragDrop: enableParentDragDrop,
                      ),
                    ),
                  )
                  .toList(),
            )
          : ListTile(
              contentPadding: tilePadding,
              leading: Icon(
                leadingIcon,
                color: _primaryGreen,
                size: isRoot ? 20 : 18,
              ),
              title: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isRoot ? 14 : 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
              subtitle: Text(
                _permissionSummary(permission, featureName),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              trailing: trailing(),
            ),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: draggableNode(tileBody),
    );
  }

  Widget _buildRoleTab(PermissionViewModel vm) {
    if (vm.roles.isEmpty) {
      return _emptyState('Chưa có vai trò nào');
    }

    return Column(
      children: vm.roles.map((role) {
        return _panel(
          child: ListTile(
            leading: const Icon(Icons.group_outlined, color: _primaryGreen),
            title: Text(role.name),
            subtitle: Text('${role.permissions.length} quyền đang bật'),
          ),
        );
      }).toList(),
    );
  }

  // ignore: unused_element
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
    return _HoverSurface(
      margin: const EdgeInsets.only(bottom: 10),
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
        title: Text(feature == null ? 'Thêm tính năng' : 'Sửa tính năng'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    label: RequiredFieldLabel('Tên tính năng'),
                  ),
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
            title: Text(permission == null ? 'Thêm quyền' : 'Sửa quyền'),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          label: RequiredFieldLabel('Code'),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc nhập code'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          label: RequiredFieldLabel('Tên'),
                        ),
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
                          label: RequiredFieldLabel('Tính năng'),
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
                            (v == null || v.isEmpty) ? 'Chọn tính năng' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priorityController,
                        decoration: const InputDecoration(labelText: 'Thứ tự'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          final parsed = int.tryParse(value);
                          if (parsed == null) return 'Thứ tự phải là số';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: requiresPermissionController,
                        decoration: const InputDecoration(
                          labelText: 'ID quyền cha',
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
    priorityController.dispose();
    requiresPermissionController.dispose();
  }
}

class _PermissionDropTarget extends StatefulWidget {
  const _PermissionDropTarget({
    required this.vm,
    required this.permission,
    required this.childrenByParent,
    required this.level,
    required this.visited,
    required this.enableParentDragDrop,
    required this.onMoveToParent,
    required this.buildNode,
  });

  final PermissionViewModel vm;
  final PermissionModel permission;
  final Map<String, List<PermissionModel>> childrenByParent;
  final int level;
  final Set<String> visited;
  final bool enableParentDragDrop;
  final Future<void> Function(
    PermissionViewModel vm,
    PermissionModel permission,
    PermissionModel targetParent,
  )
  onMoveToParent;
  final Widget Function(
    PermissionViewModel vm,
    PermissionModel permission, {
    required Map<String, List<PermissionModel>> childrenByParent,
    required int level,
    required Set<String> visited,
    required bool isDropTarget,
    required bool enableParentDragDrop,
    required ExpansibleController controller,
    required Future<void> Function(
      PermissionViewModel vm,
      PermissionModel permission,
      PermissionModel targetParent,
    )
    onMoveToParent,
  })
  buildNode;

  @override
  State<_PermissionDropTarget> createState() => _PermissionDropTargetState();
}

class _PermissionDropTargetState extends State<_PermissionDropTarget> {
  final ExpansibleController _controller = ExpansibleController();

  bool _isDescendantOfDraggedPermission(PermissionModel dragged) {
    final stack = List<PermissionModel>.from(
      widget.childrenByParent[dragged.id] ?? const <PermissionModel>[],
    );
    final visited = <String>{dragged.id};

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (!visited.add(current.id)) continue;
      if (current.id == widget.permission.id) return true;
      stack.addAll(widget.childrenByParent[current.id] ?? const []);
    }

    return false;
  }

  bool _canAccept(PermissionModel dragged) {
    if (dragged.id == widget.permission.id) return false;
    if (dragged.parentId == widget.permission.id) return false;
    return !_isDescendantOfDraggedPermission(dragged);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<PermissionModel>(
      onWillAcceptWithDetails: (details) {
        if (!widget.enableParentDragDrop) return false;
        final canAccept = _canAccept(details.data);
        if (canAccept) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.expand();
          });
        }
        return canAccept;
      },
      onAcceptWithDetails: (details) async {
        if (!widget.enableParentDragDrop) return;
        await widget.onMoveToParent(widget.vm, details.data, widget.permission);
      },
      builder: (context, candidateData, rejectedData) {
        return widget.buildNode(
          widget.vm,
          widget.permission,
          childrenByParent: widget.childrenByParent,
          level: widget.level,
          visited: widget.visited,
          isDropTarget: candidateData.isNotEmpty,
          enableParentDragDrop: widget.enableParentDragDrop,
          controller: _controller,
          onMoveToParent: widget.onMoveToParent,
        );
      },
    );
  }
}

class _HoverSurface extends StatefulWidget {
  const _HoverSurface({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.padding = EdgeInsets.zero,
    this.borderRadius = 10,
    this.color = Colors.white,
    this.isHighlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final bool isHighlighted;

  @override
  State<_HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<_HoverSurface> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || widget.isHighlighted;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0F9F7) : widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: active ? const Color(0xFFB7DDD6) : const Color(0xFFE2E8F0),
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}
