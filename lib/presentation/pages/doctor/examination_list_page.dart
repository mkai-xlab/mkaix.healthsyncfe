import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/examination_status_utils.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/examination_viewmodel.dart';
import '../../widgets/pagination_bar.dart';
import 'examination_detail_page.dart';

class ExaminationListPage extends StatefulWidget {
  final PatientEntity? patient;
  final bool embedded;
  final List<ExaminationEntity> newExaminations;
  final ValueChanged<PatientEntity>? onOpenPatientDetail;

  const ExaminationListPage({
    super.key,
    this.patient,
    this.embedded = false,
    this.newExaminations = const [],
    this.onOpenPatientDetail,
  });

  @override
  State<ExaminationListPage> createState() => _ExaminationListPageState();
}

class _SortOption {
  final String label;
  final ExaminationListMode mode;
  final IconData icon;

  const _SortOption({
    required this.label,
    required this.mode,
    required this.icon,
  });
}

class _StatusOption {
  final String label;
  final String status;
  final ExaminationListMode mode;

  const _StatusOption({
    required this.label,
    required this.status,
    required this.mode,
  });
}

class _ExaminationListPageState extends State<ExaminationListPage> {
  static const Color _primaryGreen = AppColors.primary;
  static const Color _pageBg = AppColors.surface1;
  static const List<_StatusOption> _statusOptions = [
    _StatusOption(
      label: 'Đang phân tích',
      status: 'AI_PROCESSING',
      mode: ExaminationListMode.statusAiProcessing,
    ),
    _StatusOption(
      label: 'Cần xác nhận',
      status: 'NEED_VERIFY',
      mode: ExaminationListMode.statusNeedVerify,
    ),
    _StatusOption(
      label: 'Đã xác nhận',
      status: 'VERIFIED',
      mode: ExaminationListMode.statusVerified,
    ),
    _StatusOption(
      label: 'Đã tạo báo cáo',
      status: 'REPORT_GENERATED',
      mode: ExaminationListMode.statusReportGenerated,
    ),
  ];

  bool _didLoad = false;

  String get _patientDetailId {
    final patient = widget.patient;
    if (patient == null) return '';
    return patient.id.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      final vm = context.read<ExaminationViewModel>();
      if (widget.patient == null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        vm.applyListMode(
          token: token,
          mode: ExaminationListMode.uploadDateFilter,
          date: today,
        );
      } else {
        vm.loadPatientExaminations(patientId: _patientDetailId, token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedExamination = context
        .watch<ExaminationViewModel>()
        .selectedExamination;
    if (selectedExamination != null) {
      final detail = ExaminationDetailPage(
        examination: selectedExamination,
        onBack: () =>
            context.read<ExaminationViewModel>().closeExaminationDetail(),
        onOpenPatientDetail: widget.onOpenPatientDetail,
      );
      if (widget.embedded) return detail;
      return Scaffold(backgroundColor: _pageBg, body: detail);
    }

    final content = Container(
      color: _pageBg,
      child: Column(
        children: [
          if (!widget.embedded) _buildTopBar(context),
          Expanded(
            child: Consumer<ExaminationViewModel>(
              builder: (context, vm, _) {
                return Column(
                  children: [
                    _buildHeader(vm),
                    Expanded(child: _buildBody(context, vm)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(backgroundColor: _pageBg, body: content);
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: _primaryGreen,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.patient?.fullName ?? 'Danh sách ca khám',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.patient?.patientCode ?? '',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ExaminationViewModel vm) {
    final visibleExaminations = _visibleExaminations(vm);
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách ca khám',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
              ),
              Text(
                widget.patient == null
                    ? '${vm.totalElements} ca'
                    : '${visibleExaminations.length} ca',
                style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
              ),
            ],
          ),
          if (widget.patient != null) ...[
            const SizedBox(height: 6),
            Text(
              '${widget.patient!.displayAgeGender} - ${widget.patient!.dobDisplay}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),
          ],
          if (widget.patient == null) ...[
            const SizedBox(height: 14),
            _sortDropdowns(vm),
          ],
        ],
      ),
    );
  }

  Widget _sortDropdowns(ExaminationViewModel vm) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _sortDropdown(
          vm,
          label: 'Sắp xếp',
          value: _isSortMode(vm.listMode) ? vm.listMode : null,
          items: const [
            _SortOption(
              label: 'Ngày khám tăng dần',
              mode: ExaminationListMode.studyDateAsc,
              icon: Icons.arrow_upward_rounded,
            ),
            _SortOption(
              label: 'Ngày khám giảm dần',
              mode: ExaminationListMode.studyDateDesc,
              icon: Icons.arrow_downward_rounded,
            ),
            _SortOption(
              label: 'Ngày upload tăng dần',
              mode: ExaminationListMode.uploadDateAsc,
              icon: Icons.arrow_upward_rounded,
            ),
            _SortOption(
              label: 'Ngày upload giảm dần',
              mode: ExaminationListMode.uploadDateDesc,
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
        _statusDropdown(vm),
        _allChip(vm),
        for (var grade = 4; grade >= 0; grade--) _gradeChip(vm, grade),
        if (vm.listMode != ExaminationListMode.all)
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Bỏ sắp xếp'),
            onPressed: () {
              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              vm.clearListMode(token: token);
            },
            backgroundColor: Colors.white,
            labelStyle: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }

  bool _isSortMode(ExaminationListMode mode) {
    return mode == ExaminationListMode.studyDateAsc ||
        mode == ExaminationListMode.studyDateDesc ||
        mode == ExaminationListMode.uploadDateAsc ||
        mode == ExaminationListMode.uploadDateDesc;
  }

  Widget _statusDropdown(ExaminationViewModel vm) {
    final selected = _statusOptionForMode(vm.listMode);
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<ExaminationListMode>(
        initialValue: selected?.mode,
        hint: const Text('Trạng thái'),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryGreen, width: 1.4),
          ),
        ),
        items: [
          for (final item in _statusOptions)
            DropdownMenuItem<ExaminationListMode>(
              value: item.mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle_rounded,
                    size: 10,
                    color: _statusColor(item.status),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
        selectedItemBuilder: (context) {
          return [
            for (final item in _statusOptions)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle_rounded,
                    size: 10,
                    color: _statusColor(item.status),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
          ];
        },
        onChanged: (mode) {
          if (mode == null) return;
          final token = context.read<AuthViewModel>().currentUser?.token ?? '';
          vm.applyListMode(token: token, mode: mode);
        },
        style: const TextStyle(
          color: Color(0xFF1A2B3C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

  _StatusOption? _statusOptionForMode(ExaminationListMode mode) {
    for (final item in _statusOptions) {
      if (item.mode == mode) return item;
    }
    return null;
  }

  Widget _allChip(ExaminationViewModel vm) {
    final selected = vm.listMode == ExaminationListMode.all;
    return ChoiceChip(
      label: const Text('Tất cả'),
      selected: selected,
      onSelected: (_) {
        final token = context.read<AuthViewModel>().currentUser?.token ?? '';
        vm.clearListMode(token: token);
      },
      selectedColor: _primaryGreen.withValues(alpha: 0.14),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? _primaryGreen : const Color(0xFF4A5568),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected
            ? _primaryGreen.withValues(alpha: 0.45)
            : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _gradeChip(ExaminationViewModel vm, int grade) {
    final mode = _gradeMode(grade);
    final selected = vm.listMode == mode;
    final chipColor = _gradeChipColor(grade);
    return ChoiceChip(
      label: Text('KL $grade'),
      selected: selected,
      onSelected: (_) {
        final token = context.read<AuthViewModel>().currentUser?.token ?? '';
        vm.applyListMode(token: token, mode: mode);
      },
      selectedColor: chipColor.withValues(alpha: 0.35),
      backgroundColor: selected
          ? chipColor.withValues(alpha: 0.35)
          : chipColor.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? _gradeChipSelectedLabelColor(grade) : chipColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected
            ? chipColor.withValues(alpha: 0.6)
            : chipColor.withValues(alpha: 0.35),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Color _gradeChipColor(int grade) {
    switch (grade) {
      case 4:
        return const Color(0xFFF44336); // đỏ
      case 3:
        return const Color(0xFFFF9800); // cam
      case 2:
        return const Color(0xFFFFC107); // vàng
      case 1:
        return const Color(0xFF2196F3); // xanh dương
      default:
        return const Color(0xFF4CAF50); // xanh lá
    }
  }

  Color _gradeChipSelectedLabelColor(int grade) {
    switch (grade) {
      case 4:
      case 3:
      case 2:
        return const Color(0xFF1F2937); // xám đậm cho nền đỏ/cam/vàng
      case 1:
      case 0:
      default:
        return Colors.white;
    }
  }

  ExaminationListMode _gradeMode(int grade) {
    switch (grade) {
      case 4:
        return ExaminationListMode.grade4;
      case 3:
        return ExaminationListMode.grade3;
      case 2:
        return ExaminationListMode.grade2;
      case 1:
        return ExaminationListMode.grade1;
      default:
        return ExaminationListMode.grade0;
    }
  }

  Widget _sortDropdown(
    ExaminationViewModel vm, {
    required String label,
    required ExaminationListMode? value,
    required List<_SortOption> items,
  }) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<ExaminationListMode>(
        initialValue: value,
        hint: Text(label),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryGreen, width: 1.4),
          ),
        ),
        items: [
          for (final item in items)
            DropdownMenuItem<ExaminationListMode>(
              value: item.mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 16, color: _primaryGreen),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
        selectedItemBuilder: (context) {
          return [
            for (final item in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 16, color: _primaryGreen),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
          ];
        },
        onChanged: (mode) {
          if (mode == null) return;
          final token = context.read<AuthViewModel>().currentUser?.token ?? '';
          vm.applyListMode(token: token, mode: mode);
        },
        style: const TextStyle(
          color: Color(0xFF1A2B3C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExaminationViewModel vm) {
    final examinations = _visibleExaminations(vm);

    if (vm.isLoading && vm.examinations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }

    if (vm.errorMessage != null && vm.examinations.isEmpty) {
      return _errorState(context, vm);
    }

    if (examinations.isEmpty) {
      return _emptyState('Chưa có ca khám mới hôm nay.');
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: _primaryGreen,
                onRefresh: () {
                  final currentUser = context.read<AuthViewModel>().currentUser;
                  final token = currentUser?.token ?? '';
                  if (widget.patient == null) {
                    return vm.loadExaminations(token: token);
                  }
                  return vm.loadPatientExaminations(
                    patientId: _patientDetailId,
                    token: token,
                  );
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: examinations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _examinationCard(examinations[index]),
                ),
              ),
            ),
            if (widget.patient == null)
              PaginationBar(
                currentPage: vm.currentPage,
                totalPages: vm.totalPages,
                totalElements: vm.totalElements,
                pageSize: vm.pageSize,
                isLoading: vm.isLoading,
                itemLabel: 'ca khám',
                onPageChanged: (page) {
                  final token =
                      context.read<AuthViewModel>().currentUser?.token ?? '';
                  vm.goToPage(token: token, page: page);
                },
                onPageSizeChanged: (size) {
                  final token =
                      context.read<AuthViewModel>().currentUser?.token ?? '';
                  vm.changePageSize(token: token, size: size);
                },
              ),
          ],
        ),
        if (vm.isLoadingDetail)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.42),
              child: const Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openExaminationDetail(ExaminationEntity examination) async {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final vm = context.read<ExaminationViewModel>();
    final opened = await vm.openExaminationDetail(
      examination: examination,
      token: token,
    );
    if (!mounted || opened) return;
    final message = vm.detailErrorMessage ?? 'Khong the tai chi tiet ca kham';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Widget _examinationCard(ExaminationEntity examination) {
    return InkWell(
      onTap: () => _openExaminationDetail(examination),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _cell(
                'ID ca khám',
                examination.examinationId > 0
                    ? examination.examinationId.toString()
                    : '---',
                isStrong: true,
              ),
            ),
            Expanded(
              flex: 4,
              child: _cell(
                'Tên bệnh nhân',
                examination.patientName.isEmpty
                    ? widget.patient?.fullName ?? '---'
                    : examination.patientName,
                isStrong: true,
              ),
            ),
            Expanded(
              flex: 1,
              child: _cell('Ngày sinh', examination.patientDateOfBirthDisplay),
            ),
            Expanded(
              flex: 2,
              child: _cell('Giới tính', examination.patientGenderDisplay),
            ),
            Expanded(
              flex: 2,
              child: _cell('Ngày chụp', examination.studyDateDisplay),
            ),
            const SizedBox(width: 12),
            _statusBadge(examination),
          ],
        ),
      ),
    );
  }

  Widget _cell(String label, String value, {bool isStrong = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A9A96)),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ExaminationEntity examination) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ExaminationStatusUtils.backgroundColor(examination.statusGroup),
        borderRadius: BorderRadius.circular(20),
        border: ExaminationStatusUtils.border(examination.statusGroup),
      ),
      child: Text(
        examination.statusDisplay,
        style: TextStyle(
          color: ExaminationStatusUtils.foregroundColor(
            examination.statusGroup,
          ),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, ExaminationViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 48),
          const SizedBox(height: 12),
          Text(
            vm.errorMessage ?? 'Không thể tải danh sách ca khám',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final currentUser = context.read<AuthViewModel>().currentUser;
              final token = currentUser?.token ?? '';
              if (widget.patient == null) {
                vm.loadExaminations(token: token);
              } else {
                vm.loadPatientExaminations(
                  patientId: _patientDetailId,
                  token: token,
                );
              }
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            color: Color(0xFFADB5BD),
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return ExaminationStatusUtils.color(status);
  }

  List<ExaminationEntity> _visibleExaminations(ExaminationViewModel vm) {
    final source = widget.newExaminations.isNotEmpty && vm.examinations.isEmpty
        ? widget.newExaminations
        : vm.examinations;
    return List.unmodifiable(source);
  }
}
