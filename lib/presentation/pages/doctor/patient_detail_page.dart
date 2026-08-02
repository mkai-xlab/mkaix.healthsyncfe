import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/examination_status_utils.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/examination_viewmodel.dart';

class PatientDetailPage extends StatefulWidget {
  final PatientEntity patient;
  final bool embedded;

  const PatientDetailPage({
    super.key,
    required this.patient,
    this.embedded = false,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  static const Color _primaryGreen = AppColors.primary;
  static const Color _pageBg = AppColors.surface1;

  bool _didLoad = false;

  String get _patientDetailId {
    return widget.patient.id.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<ExaminationViewModel>().loadPatientExaminations(
        patientId: _patientDetailId,
        token: token,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: _pageBg,
      child: Consumer<ExaminationViewModel>(
        builder: (context, vm, _) {
          final examinations = _sortedExaminations(vm.examinations);
          return Column(
            children: [
              if (!widget.embedded) _standaloneTopBar(context),
              Expanded(
                child: RefreshIndicator(
                  color: _primaryGreen,
                  onRefresh: () {
                    final token =
                        context.read<AuthViewModel>().currentUser?.token ?? '';
                    return vm.loadPatientExaminations(
                      patientId: _patientDetailId,
                      token: token,
                    );
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                          child: _patientHeader(vm, examinations.length),
                        ),
                      ),
                      if (vm.isLoading && examinations.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _primaryGreen,
                            ),
                          ),
                        )
                      else if (vm.errorMessage != null && examinations.isEmpty)
                        SliverFillRemaining(child: _errorState(context, vm))
                      else if (examinations.isEmpty)
                        const SliverFillRemaining(child: _EmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                          sliver: SliverList.separated(
                            itemCount: examinations.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final examination = examinations[index];
                              return _examCard(
                                examination,
                                onTap: () => _showExamDialog(
                                  context,
                                  examinations,
                                  index,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(backgroundColor: _pageBg, body: content);
  }

  Widget _standaloneTopBar(BuildContext context) {
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
              widget.patient.fullName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

  Widget _patientHeader(ExaminationViewModel vm, int examCount) {
    final patient = widget.patient;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE6F4F1),
                child: Text(
                  patient.fullName.isNotEmpty
                      ? patient.fullName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã bệnh nhân: ${patient.patientCode.isEmpty ? '---' : patient.patientCode}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$examCount lần khám',
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 30,
            runSpacing: 12,
            children: [
              _infoField('Ngày sinh', patient.dobDisplay),
              _infoField('Tuổi / giới tính', patient.displayAgeGender),
              _infoField('Điện thoại', patient.phone ?? '---'),
              _infoField('Email', patient.email ?? '---'),
              _infoField('Địa chỉ', patient.address ?? '---'),
            ],
          ),
          if (vm.isLoading && examCount > 0) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(
              color: _primaryGreen,
              backgroundColor: Color(0xFFE6F4F1),
              minHeight: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A9A96),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examCard(
    ExaminationEntity examination, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                color: _primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _examDateTime(examination),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B3C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusBadge(examination),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _cardMeta(
                        Icons.image_outlined,
                        'Số ảnh',
                        examination.images.length.toString(),
                      ),
                      _cardMeta(
                        Icons.accessibility_new,
                        'Vùng chụp',
                        examination.bodyPart.isEmpty
                            ? '---'
                            : examination.bodyPart,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Color(0xFF718096)),
          ],
        ),
      ),
    );
  }

  Widget _cardMeta(
    IconData icon,
    String label,
    String value, {
    bool strong = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: strong ? _primaryGreen : const Color(0xFF718096),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? _primaryGreen : const Color(0xFF1A2B3C),
          ),
        ),
      ],
    );
  }

  void _showExamDialog(
    BuildContext context,
    List<ExaminationEntity> examinations,
    int selectedIndex,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _ExaminationDialog(
          examinations: examinations,
          initialIndex: selectedIndex,
        );
      },
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
            vm.errorMessage ?? 'Không thể tải chi tiết bệnh nhân',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              vm.loadPatientExaminations(
                patientId: _patientDetailId,
                token: token,
              );
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

  List<ExaminationEntity> _sortedExaminations(
    List<ExaminationEntity> examinations,
  ) {
    final sorted = List<ExaminationEntity>.from(examinations);
    sorted.sort((a, b) => _examTime(b).compareTo(_examTime(a)));
    return sorted;
  }

  DateTime _examTime(ExaminationEntity examination) {
    return examination.visitTime ??
        examination.studyDate ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _examDateTime(ExaminationEntity examination) {
    final time = examination.visitTime ?? examination.studyDate;
    if (time == null) return '---';
    return _formatDateTime(time);
  }

  String _formatDateTime(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExaminationDialog extends StatefulWidget {
  final List<ExaminationEntity> examinations;
  final int initialIndex;

  const _ExaminationDialog({
    required this.examinations,
    required this.initialIndex,
  });

  @override
  State<_ExaminationDialog> createState() => _ExaminationDialogState();
}

class _ExaminationDialogState extends State<_ExaminationDialog> {
  static const Color _primaryGreen = AppColors.primary;
  int _primaryIndex = 0;
  int? _secondaryIndex;
  int _primaryImageIndex = 0;
  int _secondaryImageIndex = 0;

  ExaminationEntity get _primaryExamination =>
      widget.examinations[_primaryIndex];

  ExaminationEntity? get _secondaryExamination {
    final index = _secondaryIndex;
    if (index == null) return null;
    if (index < 0 || index >= widget.examinations.length) return null;
    return widget.examinations[index];
  }

  List<String> _imageUrlsFor(ExaminationEntity examination) {
    final urls = examination.images
        .map(
          (image) => image.annotatedImageUrl.isNotEmpty
              ? image.annotatedImageUrl
              : image.imageUrl,
        )
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) return urls;
    if (examination.thumbnailUrl.isNotEmpty) return [examination.thumbnailUrl];
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _primaryIndex = widget.initialIndex.clamp(
      0,
      widget.examinations.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    final secondaryExamination = _secondaryExamination;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 760),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: const Color(0xFFF0F4F3),
            child: secondaryExamination == null
                ? Row(
                    children: [
                      Expanded(child: _primaryPanel(context, token)),
                      SizedBox(width: 280, child: _examSideList()),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _comparisonPanel(
                          context,
                          token,
                          secondaryExamination,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _primaryPanel(BuildContext context, String token) {
    return Column(
      children: [
        _panelHeader(
          context,
          examination: _primaryExamination,
          isHighlighted: true,
          showCloseDialog: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: _panelContent(
              token,
              _primaryExamination,
              imageIndex: _primaryImageIndex,
              isHighlighted: true,
              onImageSelected: (index) =>
                  setState(() => _primaryImageIndex = index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _comparisonPanel(
    BuildContext context,
    String token,
    ExaminationEntity secondaryExamination,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _panelHeader(
                context,
                examination: _primaryExamination,
                isHighlighted: true,
                showCloseDialog: true,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
            Expanded(
              child: _panelHeader(
                context,
                examination: secondaryExamination,
                showCloseSecondary: true,
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _panelContent(
                    token,
                    _primaryExamination,
                    imageIndex: _primaryImageIndex,
                    isHighlighted: true,
                    onImageSelected: (index) =>
                        setState(() => _primaryImageIndex = index),
                  ),
                ),
                const SizedBox(width: 18),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _panelContent(
                    token,
                    secondaryExamination,
                    imageIndex: _secondaryImageIndex,
                    onImageSelected: (index) =>
                        setState(() => _secondaryImageIndex = index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelHeader(
    BuildContext context, {
    required ExaminationEntity examination,
    bool isHighlighted = false,
    bool showCloseDialog = false,
    bool showCloseSecondary = false,
  }) {
    return Container(
      color: isHighlighted ? const Color(0xFFF0FAF7) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          if (isHighlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Đang xem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _examDateTime(examination),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  examination.statusDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          if (showCloseSecondary)
            IconButton(
              onPressed: () => setState(() {
                _secondaryIndex = null;
                _secondaryImageIndex = 0;
              }),
              tooltip: 'Tắt ca khám phụ',
              icon: const Icon(Icons.close, size: 20),
            ),
          if (showCloseDialog)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              tooltip: 'Đóng',
            ),
        ],
      ),
    );
  }

  Widget _panelContent(
    String token,
    ExaminationEntity examination, {
    required int imageIndex,
    bool isHighlighted = false,
    required ValueChanged<int> onImageSelected,
  }) {
    return Container(
      padding: isHighlighted ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: isHighlighted
          ? BoxDecoration(
              color: const Color(0xFFF0FAF7),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _xrayViewer(
            token,
            examination,
            imageIndex: imageIndex,
            onImageSelected: onImageSelected,
          ),
          const SizedBox(height: 16),
          _examDetailCard(examination),
        ],
      ),
    );
  }

  Widget _examDetailCard(ExaminationEntity examination) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 30,
        runSpacing: 14,
        children: [
          _detailField('Trạng thái', examination.statusDisplay),
          _detailField('Vùng chụp', examination.bodyPart),
          _detailField('Ngày chụp', examination.studyDateDisplay),
          _detailField('Giờ chụp', examination.studyTime),
          _detailField('Thời gian khám', examination.visitTimeDisplay),
          _detailField('Bác sĩ chỉ định', examination.referringPhysician),
          _detailField('Bác sĩ phụ trách', examination.doctorName),
          _detailField('Mức ưu tiên', examination.priority),
          _detailField('Lý do khám', examination.chiefComplaint),
          _detailField('Ghi chú lâm sàng', examination.clinicalNotes),
          _detailField('Chẩn đoán cuối', examination.finalDiagnosis),
          _detailField('Mô tả', examination.description),
          _detailField('Số ảnh', examination.images.length.toString()),
        ],
      ),
    );
  }

  Widget _xrayViewer(
    String token,
    ExaminationEntity examination, {
    required int imageIndex,
    required ValueChanged<int> onImageSelected,
  }) {
    final imageUrls = _imageUrlsFor(examination);
    final hasImages = imageUrls.isNotEmpty;
    final selectedUrl = hasImages
        ? imageUrls[imageIndex.clamp(0, imageUrls.length - 1)]
        : '';
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              height: 38,
              color: const Color(0xFF17211F),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'Ảnh X-quang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (hasImages)
                    Text(
                      '${imageIndex + 1}/${imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: hasImages
                    ? Image.network(
                        selectedUrl,
                        headers: token.isEmpty
                            ? null
                            : {'Authorization': 'Bearer $token'},
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 60,
                          );
                        },
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 60,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Ca khám này chưa có ảnh X-quang',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
              ),
            ),
            if (imageUrls.length > 1)
              Container(
                height: 76,
                color: const Color(0xFF111816),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == imageIndex;
                    return InkWell(
                      onTap: () => onImageSelected(index),
                      child: Container(
                        width: 70,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _primaryGreen : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Image.network(
                          imageUrls[index],
                          headers: token.isEmpty
                              ? null
                              : {'Authorization': 'Bearer $token'},
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailField(String label, String value) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A9A96)),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '---' : value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examSideList() {
    final secondaryCandidates = List.generate(
      widget.examinations.length,
      (index) => index,
    ).where((index) => index != _primaryIndex).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ca khám phụ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: secondaryCandidates.isEmpty
                ? const Center(
                    child: Text(
                      'Không có ca khám khác để đối chiếu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                    ),
                  )
                : ListView.separated(
                    itemCount: secondaryCandidates.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final examIndex = secondaryCandidates[index];
                      final examination = widget.examinations[examIndex];
                      return InkWell(
                        onTap: () => setState(() {
                          _secondaryIndex = examIndex;
                          _secondaryImageIndex = 0;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _examDateTime(examination),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A2B3C),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                examination.bodyPart.isEmpty
                                    ? 'Vùng chụp: ---'
                                    : 'Vùng chụp: ${examination.bodyPart}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                examination.statusDisplay,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _examDateTime(ExaminationEntity examination) {
    final time = examination.visitTime ?? examination.studyDate;
    if (time == null) return '---';
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, color: Color(0xFFADB5BD), size: 56),
          SizedBox(height: 14),
          Text(
            'Bệnh nhân chưa có lần khám nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}
