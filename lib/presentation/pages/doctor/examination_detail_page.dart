import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/examination_status_utils.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'patient_detail_page.dart';

enum _ImageMode { original, annotated, roi, gradcam }

class _ReportAction {
  final IconData icon;
  final String label;
  final bool enabled;
  final String disabledTooltip;
  final VoidCallback onPressed;

  const _ReportAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.disabledTooltip,
    required this.onPressed,
  });
}

class ExaminationDetailPage extends StatefulWidget {
  final ExaminationEntity examination;
  final VoidCallback onBack;
  final ValueChanged<PatientEntity>? onOpenPatientDetail;

  const ExaminationDetailPage({
    super.key,
    required this.examination,
    required this.onBack,
    this.onOpenPatientDetail,
  });

  @override
  State<ExaminationDetailPage> createState() => _ExaminationDetailPageState();
}

class _ExaminationDetailPageState extends State<ExaminationDetailPage> {
  static const Color _primaryGreen = AppColors.primary;
  static const Color _pageBg = AppColors.surface1;

  int _selectedImageIndex = 0;
  int _selectedResultIndex = 0;
  _ImageMode _imageMode = _ImageMode.original;
  bool _isReviewSubmitting = false;
  bool _isReportGenerating = false;
  final Set<int> _locallyReviewedAiResultIds = {};

  ExaminationEntity get examination => widget.examination;

  ExaminationImageEntity? get _selectedImage {
    if (examination.images.isEmpty) return null;
    final safeIndex = _selectedImageIndex.clamp(
      0,
      examination.images.length - 1,
    );
    return examination.images[safeIndex.toInt()];
  }

  AiPredictionResultEntity? get _selectedAiResult {
    final image = _selectedImage;
    if (image == null || image.aiResults.isEmpty) return null;
    final safeIndex = _selectedResultIndex.clamp(0, image.aiResults.length - 1);
    return image.aiResults[safeIndex.toInt()];
  }

  String get _selectedOriginalUrl {
    final image = _selectedImage;
    if (image != null && image.imageUrl.isNotEmpty) {
      return _absoluteUrl(image.imageUrl);
    }
    if (examination.thumbnailUrl.isNotEmpty) {
      return _absoluteUrl(examination.thumbnailUrl);
    }
    return '';
  }

  String get _selectedAnnotatedUrl {
    final image = _selectedImage;
    final result = _selectedAiResult;
    if (image != null && image.annotatedImageUrl.isNotEmpty) {
      return _absoluteUrl(image.annotatedImageUrl);
    }
    if (result != null && result.annotatedImageUrl.isNotEmpty) {
      return _absoluteUrl(result.annotatedImageUrl);
    }
    return '';
  }

  String get _selectedRoiUrl {
    final result = _selectedAiResult;
    if (result == null || result.roiImageUrl.isEmpty) return '';
    return _absoluteUrl(result.roiImageUrl);
  }

  String get _selectedGradcamUrl {
    final result = _selectedAiResult;
    if (result == null || result.gradcamImageUrl.isEmpty) return '';
    return _absoluteUrl(result.gradcamImageUrl);
  }

  String get _viewerUrl {
    final modeUrl = switch (_imageMode) {
      _ImageMode.original => _selectedOriginalUrl,
      _ImageMode.annotated => _selectedAnnotatedUrl,
      _ImageMode.roi => _selectedRoiUrl,
      _ImageMode.gradcam => _selectedGradcamUrl,
    };
    if (modeUrl.isNotEmpty) return modeUrl;

    for (final fallback in [
      _selectedOriginalUrl,
      _selectedAnnotatedUrl,
      _selectedRoiUrl,
      _selectedGradcamUrl,
    ]) {
      if (fallback.isNotEmpty) return fallback;
    }
    return '';
  }

  bool get _canShowOriginal => _selectedOriginalUrl.isNotEmpty;
  bool get _canShowAnnotated => _selectedAnnotatedUrl.isNotEmpty;
  bool get _canShowRoi => _selectedRoiUrl.isNotEmpty;
  bool get _canShowGradcam => _selectedGradcamUrl.isNotEmpty;

  bool get _canGenerateReport {
    final normalizedStatus = examination.status.trim().toUpperCase();
    final normalizedGroup = examination.statusGroup.trim().toUpperCase();
    return normalizedStatus == ExaminationStatusUtils.verified ||
        normalizedGroup == ExaminationStatusUtils.verified;
  }

  bool get _canViewOrDownloadReport {
    final normalizedStatus = examination.status.trim().toUpperCase();
    final normalizedGroup = examination.statusGroup.trim().toUpperCase();
    return normalizedStatus == ExaminationStatusUtils.reportExported ||
        normalizedGroup == ExaminationStatusUtils.reportExported;
  }

  String get _imageModeLabel {
    switch (_imageMode) {
      case _ImageMode.original:
        return 'Ảnh gốc';
      case _ImageMode.annotated:
        return 'Ảnh khoanh vùng';
      case _ImageMode.roi:
        return 'Ảnh cắt gối';
      case _ImageMode.gradcam:
        return 'Grad-CAM';
    }
  }

  bool _isModeAvailable(_ImageMode mode) {
    switch (mode) {
      case _ImageMode.original:
        return _canShowOriginal;
      case _ImageMode.annotated:
        return _canShowAnnotated;
      case _ImageMode.roi:
        return _canShowRoi;
      case _ImageMode.gradcam:
        return _canShowGradcam;
    }
  }

  String _modeMissingMessage(_ImageMode mode) {
    switch (mode) {
      case _ImageMode.original:
        return 'Chưa có ảnh gốc';
      case _ImageMode.annotated:
        return 'Chưa có ảnh khoanh vùng';
      case _ImageMode.roi:
        return 'Chưa có ảnh cắt gối';
      case _ImageMode.gradcam:
        return 'Chưa có Grad-CAM';
    }
  }

  _ImageMode _firstAvailableMode() {
    for (final mode in _ImageMode.values) {
      if (_isModeAvailable(mode)) return mode;
    }
    return _ImageMode.original;
  }

  void _selectImage(int index) {
    setState(() {
      _selectedImageIndex = index;
      _selectedResultIndex = 0;
      if (!_isModeAvailable(_imageMode)) _imageMode = _firstAvailableMode();
    });
  }

  void _selectAiResult(int index) {
    setState(() {
      _selectedResultIndex = index;
      if (!_isModeAvailable(_imageMode)) _imageMode = _firstAvailableMode();
    });
  }

  void _selectImageMode(_ImageMode mode) {
    if (!_isModeAvailable(mode)) return;
    setState(() => _imageMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    return Container(
      color: _pageBg,
      child: Column(
        children: [
          _patientHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1040;
                final horizontalPadding = isNarrow ? 16.0 : 24.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    children: [
                      if (isNarrow) ...[
                        _imageViewer(token, height: 460),
                        const SizedBox(height: 16),
                        _aiPanel(),
                      ] else
                        SizedBox(
                          height: 620,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 7, child: _imageViewer(token)),
                              const SizedBox(width: 18),
                              SizedBox(width: 360, child: _aiPanel()),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      _examInfoPanel(),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _reportActions(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientHeader() {
    final canOpenPatient = examination.patientDbId > 0;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: _primaryGreen, size: 20),
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEAF8F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: canOpenPatient ? _openPatientDetail : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _headerField(
                        'ID ca khám',
                        examination.examinationId > 0
                            ? examination.examinationId.toString()
                            : '---',
                      ),
                      _headerField(
                        'Tên bệnh nhân',
                        examination.patientName.isEmpty
                            ? '---'
                            : examination.patientName,
                      ),
                      _headerField(
                        'Ngày sinh',
                        examination.patientDateOfBirthDisplay,
                      ),
                      _headerField(
                        'Giới tính',
                        examination.patientGenderDisplay,
                      ),
                      _headerField('Ngày chụp', examination.studyDateDisplay),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _statusBadge(),
        ],
      ),
    );
  }

  Widget _headerField(String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A9A96),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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

  void _openPatientDetail() {
    final patient = PatientEntity(
      id: examination.patientDbId,
      patientCode: examination.patientCode,
      fullName: examination.patientName,
      dateOfBirth: examination.patientDateOfBirth,
      gender: examination.patientGender,
      phone: null,
      email: null,
      address: null,
    );

    if (widget.onOpenPatientDetail != null) {
      widget.onOpenPatientDetail!(patient);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
    );
  }

  Widget _imageViewer(String token, {double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 42,
            color: const Color(0xFF17211F),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _viewerModeButton('Ảnh gốc', _ImageMode.original),
                const SizedBox(width: 8),
                _viewerModeButton('Khoanh vùng', _ImageMode.annotated),
                const SizedBox(width: 8),
                _viewerModeButton('ROI', _ImageMode.roi),
                const SizedBox(width: 8),
                _viewerModeButton('Grad-CAM', _ImageMode.gradcam),
                const Spacer(),
                if (examination.images.isNotEmpty)
                  Text(
                    '${_selectedImageIndex + 1}/${examination.images.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _viewerUrl.isEmpty
                      ? null
                      : () => _showFullscreenImage(context, token),
                  icon: const Icon(Icons.fullscreen, color: Colors.white70),
                  tooltip: 'Toàn màn hình',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: _viewerUrl.isEmpty
                  ? _emptyImageState()
                  : Image.network(
                      _viewerUrl,
                      headers: token.isEmpty
                          ? null
                          : {'Authorization': 'Bearer $token'},
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _emptyImageState();
                      },
                    ),
            ),
          ),
          if (examination.images.length > 1) _thumbnailStrip(token),
        ],
      ),
    );
  }

  Widget _viewerModeButton(String label, _ImageMode mode) {
    final isSelected = _imageMode == mode;
    final isEnabled = _isModeAvailable(mode);
    return Tooltip(
      message: isEnabled ? label : _modeMissingMessage(mode),
      child: InkWell(
        onTap: isEnabled ? () => _selectImageMode(mode) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyImageState() {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white54,
        size: 54,
      ),
    );
  }

  Widget _thumbnailStrip(String token) {
    return Container(
      height: 78,
      color: const Color(0xFF111816),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: examination.images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final image = examination.images[index];
          final imageUrl = _absoluteUrl(
            image.imageUrl.isNotEmpty
                ? image.imageUrl
                : image.annotatedImageUrl,
          );
          final isSelected = index == _selectedImageIndex;
          return InkWell(
            onTap: () => _selectImage(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    headers: token.isEmpty
                        ? null
                        : {'Authorization': 'Bearer $token'},
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Colors.black,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 22,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String token) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      _viewerUrl,
                      headers: token.isEmpty
                          ? null
                          : {'Authorization': 'Bearer $token'},
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Đóng',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_imageModeLabel - Ảnh ${_selectedImageIndex + 1}/${examination.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _aiPanel() {
    final result = _selectedAiResult;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: result == null ? _aiProcessingState() : _aiResultState(result),
    );
  }

  Widget _aiProcessingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(Icons.analytics_outlined, 'Kết quả phân tích'),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _primaryGreen,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Đang xử lý kết quả AI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Kết quả phân tích sẽ hiển thị khi backend trả aiResults.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aiResultState(AiPredictionResultEntity result) {
    final grade = result.displayGrade;
    final riskColor = _riskColor(grade);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _panelTitle(Icons.analytics_outlined, 'Kết quả phân tích'),
                if ((_selectedImage?.aiResults.length ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  _kneeSelector(),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: riskColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KELLGREN-LAWRENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.predictedGradeDisplay.toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: riskColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _gradeDescription(grade),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _metricBar(
                  label: 'Độ tin cậy',
                  value: result.confidence,
                  color: _primaryGreen,
                ),
                if (result.details.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ..._sortedKlDetails(result.details).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _metricBar(
                        label: 'KL${entry.key}',
                        value: entry.value,
                        color: _detailColor(entry.value),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _aiReviewButton(result),
      ],
    );
  }

  Widget _aiReviewButton(AiPredictionResultEntity result) {
    final reviewed = _isAiResultReviewed(result);
    final disabled = reviewed || result.aiResultId <= 0 || _isReviewSubmitting;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : () => _openAiReviewDialog(result),
        icon: reviewed
            ? const Icon(Icons.check_circle_outline, size: 18)
            : _isReviewSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified_outlined, size: 18),
        label: Text(reviewed ? 'Đã xác nhận' : 'Xác nhận'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderStrong,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _openAiReviewDialog(AiPredictionResultEntity result) async {
    final review = await showDialog<_AiReviewPayload>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AiReviewDialog(
        result: result,
        doctorName:
            context.read<AuthViewModel>().currentUser?.displayName ?? 'Bác sĩ',
      ),
    );
    if (review == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận kết quả?'),
        content: Text(
          review.agreeWithAi
              ? 'Bạn chắc chắn muốn xác nhận kết quả AI hiện tại?'
              : 'Bạn chắc chắn muốn lưu KL${review.confirmedGrade} thay cho kết quả AI?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _submitAiReview(result, review);
  }

  Future<void> _submitAiReview(
    AiPredictionResultEntity result,
    _AiReviewPayload review,
  ) async {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    setState(() => _isReviewSubmitting = true);
    try {
      final uri = Uri.parse(
        review.agreeWithAi
            ? ApiConstants.aiResultConfirmEndpoint(result.aiResultId)
            : ApiConstants.aiResultKlGradeEndpoint(result.aiResultId),
      );
      final response = await http
          .put(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!review.agreeWithAi) 'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: review.agreeWithAi
                ? null
                : jsonEncode({
                    'confirmedKlGrade': review.confirmedGrade,
                    'reviewNote': review.reviewNote,
                  }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _locallyReviewedAiResultIds.add(result.aiResultId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận kết quả AI.'),
            backgroundColor: AppColors.success,
          ),
        );
        return;
      }

      final body = utf8.decode(response.bodyBytes);
      var message = 'Không thể xác nhận kết quả AI (${response.statusCode})';
      try {
        final data = jsonDecode(body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {
        if (body.trim().isNotEmpty) message = body;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isReviewSubmitting = false);
    }
  }

  Widget _kneeSelector() {
    final results =
        _selectedImage?.aiResults ?? const <AiPredictionResultEntity>[];
    if (results.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < results.length; index++)
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAiResultReviewed(results[index])) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 15,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(results[index].kneeSideDisplay),
              ],
            ),
            selected: index == _selectedResultIndex,
            showCheckmark: false,
            onSelected: results.length == 1
                ? null
                : (selected) {
                    if (selected) _selectAiResult(index);
                  },
            selectedColor: _primaryGreen.withValues(alpha: 0.14),
            backgroundColor: const Color(0xFFF8FAFC),
            disabledColor: _primaryGreen.withValues(alpha: 0.1),
            labelStyle: TextStyle(
              color: index == _selectedResultIndex
                  ? _primaryGreen
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color:
                  index == _selectedResultIndex &&
                      _isAiResultReviewed(results[index])
                  ? _primaryGreen
                  : index == _selectedResultIndex
                  ? _primaryGreen.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
              width:
                  index == _selectedResultIndex &&
                      _isAiResultReviewed(results[index])
                  ? 2
                  : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }

  bool _isAiResultReviewed(AiPredictionResultEntity result) {
    return result.isReviewed ||
        _locallyReviewedAiResultIds.contains(result.aiResultId);
  }

  Widget _panelTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryGreen, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final normalized = value > 1 ? value / 100 : value;
    final clamped = normalized.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${(clamped * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            color: color,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _examInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(Icons.assignment_outlined, 'Thông tin chi tiết ca khám'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = constraints.maxWidth < 760
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 14,
                    children: [
                      _infoTile(
                        'ID ca khám',
                        examination.examinationId > 0
                            ? examination.examinationId.toString()
                            : '---',
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Trạng thái',
                        examination.statusDisplay,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Vùng chụp',
                        examination.bodyPart.isEmpty
                            ? '---'
                            : examination.bodyPart,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Ngày chụp',
                        examination.studyDateDisplay,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Giờ chụp',
                        examination.studyTime.isEmpty
                            ? '---'
                            : examination.studyTime,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Thời gian khám',
                        examination.visitTimeDisplay,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Bác sĩ chỉ định',
                        examination.referringPhysician.isEmpty
                            ? '---'
                            : examination.referringPhysician,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Bác sĩ phụ trách',
                        examination.doctorName.isEmpty
                            ? '---'
                            : examination.doctorName,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Mức ưu tiên',
                        examination.priority.isEmpty
                            ? '---'
                            : examination.priority,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Lý do khám',
                        examination.chiefComplaint.isEmpty
                            ? '---'
                            : examination.chiefComplaint,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Ghi chú lâm sàng',
                        examination.clinicalNotes.isEmpty
                            ? '---'
                            : examination.clinicalNotes,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Chẩn đoán cuối',
                        examination.finalDiagnosis.isEmpty
                            ? '---'
                            : examination.finalDiagnosis,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Mô tả',
                        examination.description.isEmpty
                            ? '---'
                            : examination.description,
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Số ảnh',
                        examination.images.length.toString(),
                        width: columnWidth,
                      ),
                      _infoTile(
                        'Encounter code',
                        examination.encounterCode.isEmpty
                            ? '---'
                            : examination.encounterCode,
                        width: columnWidth,
                      ),
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

  Widget _reportActions() {
    final actions = [
      _ReportAction(
        icon: Icons.task_alt_outlined,
        label: _isReportGenerating
            ? 'Đang tạo báo cáo'
            : 'Hoàn thành ca khám, tạo báo cáo',
        enabled: _canGenerateReport && !_isReportGenerating,
        disabledTooltip: 'Chỉ khả dụng khi ca khám đã xác nhận',
        onPressed: _confirmAndGenerateReport,
      ),
      _ReportAction(
        icon: Icons.visibility_outlined,
        label: 'Xem báo cáo',
        enabled: _canViewOrDownloadReport,
        disabledTooltip: 'Chỉ khả dụng khi báo cáo đã được xuất',
        onPressed: _showReportIntegrationPending,
      ),
      _ReportAction(
        icon: Icons.download_outlined,
        label: 'Tải báo cáo',
        enabled: _canViewOrDownloadReport,
        disabledTooltip: 'Chỉ khả dụng khi báo cáo đã được xuất',
        onPressed: _showReportIntegrationPending,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;
        if (isNarrow) {
          return Column(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                _reportActionButton(
                  icon: actions[index].icon,
                  label: actions[index].label,
                  enabled: actions[index].enabled,
                  disabledTooltip: actions[index].disabledTooltip,
                  onPressed: actions[index].onPressed,
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: _reportActionButton(
                  icon: actions[index].icon,
                  label: actions[index].label,
                  enabled: actions[index].enabled,
                  disabledTooltip: actions[index].disabledTooltip,
                  onPressed: actions[index].onPressed,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _reportActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required String disabledTooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: enabled ? label : disabledTooltip,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 21),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: const Color(0xFF94A3B8),
            elevation: enabled ? 2 : 0,
            shadowColor: _primaryGreen.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndGenerateReport() async {
    if (_isReportGenerating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo báo cáo?'),
        content: const Text(
          'Bạn có chắc chắn muốn hoàn thành ca khám và tạo báo cáo không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _generateReport();
  }

  Future<void> _generateReport() async {
    final examinationId = examination.examinationId;
    if (examinationId <= 0) {
      _showReportMessage('Không tìm thấy ID ca khám hợp lệ.', isError: true);
      return;
    }

    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    if (token.trim().isEmpty) {
      _showReportMessage('Phiên đăng nhập không hợp lệ.', isError: true);
      return;
    }

    setState(() => _isReportGenerating = true);
    try {
      final uri = Uri.parse(
        ApiConstants.examinationReportEndpoint(examinationId),
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = utf8.decode(response.bodyBytes).trim();
        final detail = body.isEmpty ? '' : ' $body';
        _showReportMessage('Đã tạo báo cáo thành công.$detail');
        return;
      }

      _showReportMessage(_reportErrorMessage(response), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showReportMessage(
        'Không thể tạo báo cáo: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isReportGenerating = false);
    }
  }

  String _reportErrorMessage(http.Response response) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return 'Không thể tạo báo cáo (${response.statusCode}).';
    }

    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    } catch (_) {
      return body;
    }

    return 'Không thể tạo báo cáo (${response.statusCode}).';
  }

  void _showReportMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _showReportIntegrationPending() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng báo cáo sẽ được nối API ở bước tiếp theo.'),
      ),
    );
  }

  Widget _infoTile(String label, String value, {required double width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A9A96),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _riskColor(int grade) {
    if (grade >= 4) return AppColors.error;
    if (grade >= 2) return const Color(0xFFD97706);
    return _primaryGreen;
  }

  Color _detailColor(double value) {
    final normalized = value > 1 ? value / 100 : value;
    if (normalized >= 0.75) return AppColors.error;
    if (normalized >= 0.45) return const Color(0xFFD97706);
    return _primaryGreen;
  }

  List<MapEntry<int, double>> _sortedKlDetails(Map<String, double> details) {
    final byGrade = <int, double>{};
    for (final entry in details.entries) {
      final grade = _gradeFromDetailKey(entry.key);
      if (grade != null && grade >= 0 && grade <= 4) {
        byGrade[grade] = entry.value;
      }
    }

    return [4, 3, 2, 1, 0]
        .where(byGrade.containsKey)
        .map((grade) => MapEntry(grade, byGrade[grade]!))
        .toList();
  }

  int? _gradeFromDetailKey(String key) {
    final match = RegExp(r'[0-4]').firstMatch(key);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String _gradeDescription(int grade) {
    switch (grade) {
      case 1:
        return 'Nghi ngờ thoái hóa nhẹ';
      case 2:
        return 'Thoái hóa nhẹ';
      case 3:
        return 'Thoái hóa trung bình';
      case 4:
        return 'Giai đoạn cuối (Nghiêm trọng)';
      default:
        return grade > 0 ? 'Grade $grade' : 'Chưa xác định';
    }
  }

  String _absoluteUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiConstants.baseUrl);
    if (url.startsWith('/api/v1/')) {
      return base.replace(path: url).toString();
    }
    if (url.startsWith('/')) {
      return base.replace(path: url).toString();
    }
    return base.replace(path: '${base.path}/$url').toString();
  }
}

class _AiReviewPayload {
  final bool agreeWithAi;
  final int confirmedGrade;
  final String reviewNote;

  const _AiReviewPayload({
    required this.agreeWithAi,
    required this.confirmedGrade,
    required this.reviewNote,
  });
}

class _AiReviewDialog extends StatefulWidget {
  final AiPredictionResultEntity result;
  final String doctorName;

  const _AiReviewDialog({required this.result, required this.doctorName});

  @override
  State<_AiReviewDialog> createState() => _AiReviewDialogState();
}

class _AiReviewDialogState extends State<_AiReviewDialog> {
  late bool _agreeWithAi;
  late int _selectedGrade;
  late final TextEditingController _noteController;
  String? _noteError;

  @override
  void initState() {
    super.initState();
    _agreeWithAi = true;
    _selectedGrade = widget.result.displayGrade.clamp(0, 4).toInt();
    _noteController = TextEditingController(text: widget.result.reviewNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      backgroundColor: Colors.white,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: const Row(
          children: [
            Icon(Icons.rate_review_outlined, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Nhận xét của bác sĩ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _infoField('Tên bác sĩ', widget.doctorName)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoField('Ngày đánh giá', _formatDate(now)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _aiResultCard(widget.result),
              const SizedBox(height: 18),
              const Text(
                'Nhận định của bác sĩ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _decisionTile(
                      label: 'Đồng ý với AI',
                      selected: _agreeWithAi,
                      onTap: () => setState(() => _agreeWithAi = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _decisionTile(
                      label: 'Không đồng ý',
                      selected: !_agreeWithAi,
                      onTap: () => setState(() => _agreeWithAi = false),
                    ),
                  ),
                ],
              ),
              if (!_agreeWithAi) ...[
                const SizedBox(height: 16),
                const Text(
                  'KL Grade (theo bác sĩ)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var grade = 0; grade <= 4; grade++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: grade == 4 ? 0 : 6),
                          child: _gradeOption(grade),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  onChanged: (_) {
                    if (_noteError != null) setState(() => _noteError = null);
                  },
                  minLines: 4,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: 'Nhập nhận xét, diễn giải lâm sàng...',
                    errorText: _noteError,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!_agreeWithAi && _noteController.text.trim().isEmpty) {
              setState(
                () =>
                    _noteError = 'Vui lòng nhập mô tả khi không đồng ý với AI.',
              );
              return;
            }
            Navigator.of(context).pop(
              _AiReviewPayload(
                agreeWithAi: _agreeWithAi,
                confirmedGrade: _selectedGrade,
                reviewNote: _noteController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.verified_outlined, size: 18),
          label: const Text('Xác nhận'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.trim().isEmpty ? '---' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _gradeOption(int grade) {
    final selected = _selectedGrade == grade;
    final color = _gradeColor(grade);
    return InkWell(
      onTap: () => setState(() => _selectedGrade = grade),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Center(
          child: Text(
            'KL $grade',
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Color _gradeColor(int grade) {
    switch (grade) {
      case 0:
        return const Color(0xFF059669);
      case 1:
        return const Color(0xFF65A30D);
      case 2:
        return const Color(0xFFD97706);
      case 3:
        return const Color(0xFFEA580C);
      case 4:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _aiResultCard(AiPredictionResultEntity result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kết quả AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KL ${result.displayGrade}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryXLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Độ tin cậy: ${result.confidenceDisplay}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryXLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
