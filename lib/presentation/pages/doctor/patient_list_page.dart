import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/doctor_viewmodel.dart';
import '../../widgets/pagination_bar.dart';
import 'patient_detail_page.dart';

class PatientListPage extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onClearSearch;
  final ValueChanged<PatientEntity>? onOpenPatientDetail;

  const PatientListPage({
    super.key,
    this.embedded = false,
    this.onClearSearch,
    this.onOpenPatientDetail,
  });

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  static const Color _primaryGreen = AppColors.primary;
  static const Color _pageBg = AppColors.surface1;

  bool _hasRequestedPatientList = false;
  String? _hoveredPatientKey;

  String get _token => context.read<AuthViewModel>().currentUser?.token ?? '';
  bool get _isPersonalView => context.read<AuthViewModel>().isPersonalView;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Consumer<DoctorViewModel>(
        builder: (context, vm, _) {
          if (!_hasRequestedPatientList &&
              !vm.hasPendingSearch &&
              !vm.isLoading &&
              vm.patients.isEmpty &&
              vm.errorMessage == null) {
            _hasRequestedPatientList = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<DoctorViewModel>().fetchFirstPage(
                token: _token,
                isPersonal: _isPersonalView,
              );
            });
          }

          return Column(
            children: [
              if (!widget.embedded) _buildTopBar(context),
              _buildHeader(context, vm),
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
          const Expanded(
            child: Text(
              'Danh sách bệnh nhân',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DoctorViewModel vm) {
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  widget.onClearSearch?.call();
                  vm.clearFilters(_token, isPersonal: _isPersonalView);
                },
                icon: const Icon(Icons.groups_outlined, size: 16),
                label: const Text('Tất cả'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPatientTable(BuildContext context, DoctorViewModel vm) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: const Row(
            children: [
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
        Expanded(
          child: RefreshIndicator(
            color: _primaryGreen,
            onRefresh: () =>
                vm.fetchFirstPage(token: _token, isPersonal: _isPersonalView),
            child: ListView.separated(
              itemCount: vm.patients.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFEDF2F7)),
              itemBuilder: (context, i) {
                return _buildPatientRow(context, vm.patients[i]);
              },
            ),
          ),
        ),
        PaginationBar(
          currentPage: vm.currentPage,
          totalPages: vm.totalPages,
          totalElements: vm.totalElements,
          pageSize: vm.pageSize,
          isLoading: vm.isLoading,
          itemLabel: 'bệnh nhân',
          onPageChanged: (page) => vm.goToPage(_token, page),
          onPageSizeChanged: (size) => vm.changePageSize(_token, size),
        ),
      ],
    );
  }

  Widget _buildPatientRow(BuildContext context, PatientEntity p) {
    final patientKey = p.id.toString();
    final isHovered = _hoveredPatientKey == patientKey;
    return InkWell(
      onTap: () => _openPatientDetail(p),
      onHover: (hovering) {
        setState(() {
          _hoveredPatientKey = hovering ? patientKey : null;
        });
      },
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
            color: isHovered ? const Color(0xFFCFE3DC) : Colors.transparent,
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
              onPressed: () => _openPatientDetail(p),
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
            onPressed: () =>
                vm.fetchFirstPage(token: _token, isPersonal: _isPersonalView),
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

  void _openPatientDetail(PatientEntity patient) {
    if (widget.onOpenPatientDetail != null) {
      widget.onOpenPatientDetail!(patient);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
    );
  }
}

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
