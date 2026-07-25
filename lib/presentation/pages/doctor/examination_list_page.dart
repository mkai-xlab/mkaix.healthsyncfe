import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

  const ExaminationListPage({
    super.key,
    this.patient,
    this.embedded = false,
    this.newExaminations = const [],
  });

  @override
  State<ExaminationListPage> createState() => _ExaminationListPageState();
}

class _ExaminationListPageState extends State<ExaminationListPage> {
  static const Color _primaryGreen = AppColors.primary;
  static const Color _pageBg = AppColors.surface1;

  bool _didLoad = false;
  ExaminationEntity? _selectedExamination;

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
        vm.loadExaminations(token: token);
      } else {
        vm.loadPatientExaminations(patientId: _patientDetailId, token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedExamination = _selectedExamination;
    if (selectedExamination != null) {
      final detail = ExaminationDetailPage(
        examination: selectedExamination,
        onBack: () => setState(() => _selectedExamination = null),
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
        ],
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
      return _emptyState('Chưa có ca khám');
    }

    return Column(
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
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    );
  }

  Widget _examinationCard(ExaminationEntity examination) {
    return InkWell(
      onTap: () => setState(() => _selectedExamination = examination),
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
    final color = _statusColor(examination.statusGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        examination.statusDisplay,
        style: TextStyle(
          color: color,
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
    switch (status) {
      case 'PENDING':
        return const Color(0xFFB7791F);
      case 'ANALYZING':
        return const Color(0xFF3182CE);
      case 'AWAITING_REVIEW':
        return const Color(0xFF805AD5);
      case 'NEED_VERIFY':
      case 'NEED_REVERIFY':
        return const Color(0xFFD97706);
      case 'AI_COMPLETED':
        return const Color(0xFF2563EB);
      case 'COMPLETED':
        return _primaryGreen;
      default:
        return const Color(0xFF718096);
    }
  }

  List<ExaminationEntity> _visibleExaminations(ExaminationViewModel vm) {
    final source = widget.newExaminations.isNotEmpty && vm.examinations.isEmpty
        ? widget.newExaminations
        : vm.examinations;
    return List.unmodifiable(source);
  }
}
