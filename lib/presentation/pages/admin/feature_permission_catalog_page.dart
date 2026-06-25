import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/permission_viewmodel.dart';

class FeaturePermissionCatalogPage extends StatefulWidget {
  const FeaturePermissionCatalogPage({super.key});

  @override
  State<FeaturePermissionCatalogPage> createState() =>
      _FeaturePermissionCatalogPageState();
}

class _FeaturePermissionCatalogPageState
    extends State<FeaturePermissionCatalogPage> {
  static const Color _primaryGreen = Color(0xFF2D7E6E);
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
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null && vm.permissions.isEmpty) {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh muc he thong',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quan ly rieng feature, permission va role de tranh nham voi phan quyen role.',
                style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: vm.loadAll,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Tai lai'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryGreen,
            side: const BorderSide(color: _primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(PermissionViewModel vm) {
    final tabs = [
      ('Features', vm.permissionsByResource.length),
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
                      color: selected
                          ? _primaryGreen
                          : const Color(0xFF718096),
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
    final features = vm.permissionsByResource.entries.toList();
    if (features.isEmpty) {
      return _emptyState('Chua co feature nao');
    }

    return Column(
      children: features.map((entry) {
        return _panel(
          child: ListTile(
            leading: const Icon(Icons.view_module_outlined, color: _primaryGreen),
            title: Text(entry.key.isEmpty ? 'Feature khong ten' : entry.key),
            subtitle: Text('${entry.value.length} permissions'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionTab(PermissionViewModel vm) {
    if (vm.permissions.isEmpty) {
      return _emptyState('Chua co permission nao');
    }

    return Column(
      children: vm.permissions.map((permission) {
        return _panel(
          child: ListTile(
            leading: const Icon(Icons.key_outlined, color: _primaryGreen),
            title: Text(permission.name),
            subtitle: Text(
              [
                'Feature: ${permission.resource.isEmpty ? 'N/A' : permission.resource}',
                'ID: ${permission.id}',
                if (permission.parentId != null)
                  'Requires: ${permission.parentId}',
              ].join('  |  '),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleTab(PermissionViewModel vm) {
    if (vm.roles.isEmpty) {
      return _emptyState('Chua co role nao');
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
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFF718096))),
      ),
    );
  }

  Widget _buildError(PermissionViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(vm.errorMessage ?? 'Khong the tai du lieu'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: vm.loadAll, child: const Text('Thu lai')),
        ],
      ),
    );
  }
}
