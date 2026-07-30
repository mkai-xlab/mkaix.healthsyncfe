import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/audit_log_entity.dart';
import '../../viewmodels/audit_log_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/pagination_bar.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuditLogViewModel>().fetchFirstPage(_token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditLogViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: AppColors.surface1,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(vm),
              const SizedBox(height: 16),
              Expanded(child: _content(vm)),
            ],
          ),
        );
      },
    );
  }

  Widget _header(AuditLogViewModel vm) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhật ký hoạt động',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Theo dõi các thao tác được ghi nhận từ hệ thống.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: vm.isLoading ? null : () => vm.loadAuditLogs(_token),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tải lại'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(AuditLogViewModel vm) {
    if (vm.isLoading && vm.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.logs.isEmpty) {
      return _messageState(Icons.error_outline, vm.errorMessage!);
    }
    if (vm.logs.isEmpty) {
      return _messageState(
        Icons.history_toggle_off_outlined,
        'Chưa có nhật ký hoạt động.',
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _tablePanel(vm)),
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: _detailPanel(vm.selectedLog ?? vm.logs.first),
        ),
      ],
    );
  }

  Widget _tablePanel(AuditLogViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _tableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: vm.logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = vm.logs[index];
                final selected =
                    identical(vm.selectedLog, log) ||
                    ((vm.selectedLog?.id ?? -1) > 0 &&
                        vm.selectedLog?.id == log.id);
                return _logRow(log, selected, () => vm.selectLog(log));
              },
            ),
          ),
          PaginationBar(
            currentPage: vm.currentPage,
            totalPages: vm.totalPages,
            totalElements: vm.totalElements,
            pageSize: vm.pageSize,
            isLoading: vm.isLoading,
            itemLabel: 'bản ghi',
            onPageChanged: (page) => vm.goToPage(_token, page),
            onPageSizeChanged: (size) => vm.changePageSize(_token, size),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Thời gian')),
          Expanded(flex: 2, child: _HeaderText('Người dùng')),
          Expanded(flex: 2, child: _HeaderText('Tiêu đề')),
          Expanded(flex: 3, child: _HeaderText('Mô tả')),
          Expanded(flex: 2, child: _HeaderText('IP')),
          Expanded(flex: 3, child: _HeaderText('Thiết bị')),
          SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _logRow(AuditLogEntity log, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? AppColors.primaryXLight.withValues(alpha: 0.16)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Expanded(flex: 2, child: _cell(_formatDateTime(log.timeStamp))),
            Expanded(flex: 2, child: _cell(log.userDisplay, strong: true)),
            Expanded(flex: 2, child: _cell(log.titleDisplay)),
            Expanded(flex: 3, child: _cell(log.descriptionDisplay)),
            Expanded(flex: 2, child: _cell(log.ipAddressDisplay)),
            Expanded(flex: 3, child: _cell(_shortText(log.userAgentDisplay))),
            const SizedBox(
              width: 42,
              child: Icon(Icons.visibility_outlined, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _detailPanel(AuditLogEntity log) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 14),
            child: Text(
              'Chi tiết hoạt động',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _detailSection('Tiêu đề', log.titleDisplay),
                _detailSection('Mô tả hoạt động', log.descriptionDisplay),
                _detailSection(
                  'Thời gian chi tiết',
                  _formatDateTime(log.timeStamp).replaceAll('\n', ' - '),
                ),
                _detailSection('Người dùng', log.userDisplay),
                _detailSection('Địa chỉ IP', log.ipAddressDisplay),
                _detailSection('Thiết bị / User Agent', log.userAgentDisplay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('dd/MM/yyyy\nHH:mm:ss').format(date);
  }

  String _shortText(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 42) return compact;
    return '${compact.substring(0, 39)}...';
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
