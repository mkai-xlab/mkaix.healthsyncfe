import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_file_service.dart';
import '../../../core/services/report_pdf_preview.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/examination_status_utils.dart';
import '../../../data/models/report_draft_model.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/doctor_viewmodel.dart';
import '../../viewmodels/examination_viewmodel.dart';
import 'patient_detail_page.dart';
import '../../../core/utils/error_message_utils.dart';

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
  bool _isReportPreviewing = false;
  bool _isReportDownloading = false;
  bool _isReportAvailable = false;
  bool _shouldRefreshListOnBack = false;
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
    if (_isReportAvailable) return true;
    final normalizedStatus = examination.status.trim().toUpperCase();
    final normalizedGroup = examination.statusGroup.trim().toUpperCase();
    return normalizedStatus == ExaminationStatusUtils.reportGenerated ||
        normalizedGroup == ExaminationStatusUtils.reportGenerated ||
        normalizedStatus == ExaminationStatusUtils.reportExported ||
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
                final topPadding = isNarrow ? 12.0 : 14.0;
                final workspaceHeight =
                    (constraints.maxHeight - topPadding - 48 - 12)
                        .clamp(500.0, 560.0)
                        .toDouble();
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    horizontalPadding,
                  ),
                  child: Column(
                    children: [
                      _aiDisclaimer(),
                      const SizedBox(height: 12),
                      if (isNarrow) ...[
                        _imageViewer(token, height: 460),
                        const SizedBox(height: 16),
                        _aiPanel(),
                      ] else
                        SizedBox(
                          height: workspaceHeight,
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
                      _examReportSummaryPanel(),
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
            onPressed: _handleBack,
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

  Future<void> _openPatientDetail() async {
    final fallbackPatient = PatientEntity(
      id: examination.patientDbId,
      patientCode: examination.patientCode,
      fullName: examination.patientName,
      dateOfBirth: examination.patientDateOfBirth,
      gender: examination.patientGender,
      phone: null,
      email: null,
      address: null,
    );

    var patient = fallbackPatient;
    final patientCode = examination.patientCode.trim();
    if (patientCode.isNotEmpty) {
      try {
        final token = context.read<AuthViewModel>().currentUser?.token ?? '';
        patient = await context.read<DoctorViewModel>().getPatientDetails(
          token: token,
          patientCode: patientCode,
        );
      } catch (e) {
        if (!mounted) return;
        AppToast.showWarning(userFriendlyErrorMessage(e));
      }
    }

    if (!mounted) return;
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
                  : _NetworkImageFrame(
                      url: _viewerUrl,
                      token: token,
                      fit: BoxFit.contain,
                      backgroundColor: Colors.black,
                      loadingIconSize: 34,
                      errorIconSize: 54,
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
                  _NetworkImageFrame(
                    url: imageUrl,
                    token: token,
                    fit: BoxFit.cover,
                    backgroundColor: Colors.black,
                    loadingIconSize: 18,
                    errorIconSize: 22,
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
                    child: _NetworkImageFrame(
                      url: _viewerUrl,
                      token: token,
                      fit: BoxFit.contain,
                      backgroundColor: Colors.black,
                      loadingIconSize: 38,
                      errorIconSize: 64,
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
    final image = _selectedImage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: image?.hasFailedAiAnalysis == true
          ? _aiFailedState(image!)
          : result == null
          ? _aiProcessingState()
          : _aiResultState(result),
    );
  }

  Widget _aiFailedState(ExaminationImageEntity image) {
    final message = image.aiErrorMessage.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(Icons.analytics_outlined, 'Kết quả phân tích'),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.errorLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Phân tích không thành công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
    final hideConfidence = _isAiResultReviewed(result);
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
                  const SizedBox(height: 10),
                  _kneeSelector(),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: riskColor,
                        ),
                      ),
                      if (grade != null && grade > 0) ...[
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
                    ],
                  ),
                ),
                if (!hideConfidence) ...[
                  const SizedBox(height: 14),
                  _metricBar(
                    label: 'Độ tin cậy',
                    value: result.confidence,
                    color: _primaryGreen,
                  ),
                ],
                if (!hideConfidence && result.details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._sortedKlDetails(result.details).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _metricBar(
                        label: 'KL${entry.key}',
                        value: entry.value,
                        color: _gradeProbabilityColor(entry.key),
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

  Widget _aiDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFACC15)),
      ),
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '⚠️ '),
            TextSpan(
              text: 'Lưu ý:',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text:
                  ' Kết quả phân tích từ Trợ lý ảo chỉ mang tính chất tham khảo và không thay thế chẩn đoán của bác sĩ!',
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: Color(0xFF92400E),
        ),
      ),
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
        _locallyReviewedAiResultIds.add(result.aiResultId);
        _shouldRefreshListOnBack = true;
        AppToast.showSuccess('Đã xác nhận kết quả AI.');
        await _refreshExaminationDetail(token);
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
      AppToast.showError(message);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(userFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isReviewSubmitting = false);
    }
  }

  Future<void> _refreshExaminationDetail(String token) async {
    final refreshed = await context
        .read<ExaminationViewModel>()
        .openExaminationDetail(examination: examination, token: token);
    if (!mounted || refreshed) return;

    final message = context.read<ExaminationViewModel>().detailErrorMessage;
    AppToast.showError(
      message == null || message.isEmpty
          ? 'Không thể tải lại chi tiết ca khám.'
          : message,
    );
  }

  void _handleBack() {
    if (!_shouldRefreshListOnBack) {
      widget.onBack();
      return;
    }

    final vm = context.read<ExaminationViewModel>();
    final auth = context.read<AuthViewModel>();
    final token = auth.currentUser?.token ?? '';
    final isPersonal = auth.isPersonalView;
    widget.onBack();
    unawaited(vm.loadExaminations(token: token, isPersonal: isPersonal));
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

  Widget _examReportSummaryPanel() {
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
          _panelTitle(Icons.fact_check_outlined, 'Kết quả và kết luận'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final itemWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _reportSummaryBlock(
                    label: 'Kết quả',
                    value: examination.findings,
                    width: itemWidth,
                  ),
                  _reportSummaryBlock(
                    label: 'Kết luận',
                    value: examination.conclusion,
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reportSummaryBlock({
    required String label,
    required String value,
    required double width,
  }) {
    final displayValue = value.trim().isEmpty ? '---' : value.trim();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C6F6A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C),
              ),
            ),
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
        icon: Icons.description_outlined,
        label: 'Xem báo cáo',
        enabled: _canViewOrDownloadReport && !_isReportPreviewing,
        disabledTooltip: 'Chỉ khả dụng khi báo cáo đã được xuất',
        onPressed: _previewReport,
      ),
      _ReportAction(
        icon: Icons.download_outlined,
        label: 'Tải báo cáo',
        enabled: _canViewOrDownloadReport && !_isReportDownloading,
        disabledTooltip: 'Chỉ khả dụng khi báo cáo đã được xuất',
        onPressed: _downloadReport,
      ),
    ]..removeWhere((action) => action.icon == Icons.download_outlined);

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
                  highlighted: index == 1,
                ),
              ],
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(
                width: index == 0 ? 320 : 150,
                child: _reportActionButton(
                  icon: actions[index].icon,
                  label: actions[index].label,
                  enabled: actions[index].enabled,
                  disabledTooltip: actions[index].disabledTooltip,
                  onPressed: actions[index].onPressed,
                  highlighted: index == 1,
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
    bool highlighted = false,
  }) {
    final backgroundColor = highlighted
        ? const Color(0xFF0EA5E9)
        : _primaryGreen;
    final shadowColor = highlighted
        ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
        : _primaryGreen.withValues(alpha: 0.25);
    return Tooltip(
      message: enabled ? label : disabledTooltip,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: highlighted ? 23 : 21),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: const Color(0xFF94A3B8),
            elevation: enabled ? 2 : 0,
            shadowColor: shadowColor,
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
    await _openReportDraftAndGenerate();
  }

  Future<void> _openReportDraftAndGenerate() async {
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
      final draft = await _fetchReportDraft(examinationId, token);
      if (!mounted) return;
      setState(() => _isReportGenerating = false);

      final payload = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReportDraftDialog(draft: draft),
      );
      if (payload == null || !mounted) return;

      await _generateReportFromDraft(payload);
    } catch (e) {
      if (!mounted) return;
      _showReportMessage(
        'Không thể tải bản nháp báo cáo: ${userFriendlyErrorMessage(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isReportGenerating = false);
    }
  }

  Future<ReportDraftModel> _fetchReportDraft(
    int examinationId,
    String token,
  ) async {
    final response = await http
        .get(
          Uri.parse(ApiConstants.examinationReportDraftEndpoint(examinationId)),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_reportErrorMessage(response));
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) {
      throw Exception('Định dạng bản nháp báo cáo không hợp lệ.');
    }
    return ReportDraftModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> _generateReportFromDraft(Map<String, dynamic> payload) async {
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
      final requestBody = jsonEncode(payload);
      debugPrint('Generate report request body: $requestBody');
      final request =
          http.Request(
              'POST',
              Uri.parse(ApiConstants.examinationReportEndpoint(examinationId)),
            )
            ..headers.addAll({
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            })
            ..bodyBytes = utf8.encode(requestBody);
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _isReportAvailable = true);
        _showReportMessage('Đã tạo báo cáo thành công.');
        await _refreshExaminationDetail(token);
        return;
      }

      _showReportMessage(_reportErrorMessage(response), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showReportMessage(
        'Không thể tạo báo cáo: ${userFriendlyErrorMessage(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isReportGenerating = false);
    }
  }

  Future<void> _previewReport() async {
    await _handleReportFileAction(
      endpoint: ApiConstants.reportPreviewEndpoint(examination.examinationId),
      fallbackFileName:
          'examination_${examination.examinationId}_report_preview.pdf',
      setLoading: (loading) => setState(() => _isReportPreviewing = loading),
      onBytes: (bytes, fileName) => showReportPdfPreviewDialog(
        context,
        bytes: bytes,
        fileName: fileName,
        onDownload: _downloadReport,
      ),
      successMessage: 'Đã mở báo cáo.',
      failurePrefix: 'Không thể xem báo cáo',
    );
  }

  Future<void> _downloadReport() async {
    await _handleReportFileAction(
      endpoint: ApiConstants.reportDownloadEndpoint(examination.examinationId),
      fallbackFileName: 'examination_${examination.examinationId}_report.pdf',
      setLoading: (loading) => setState(() => _isReportDownloading = loading),
      onBytes: (bytes, fileName) =>
          ReportFileService().downloadPdf(bytes, fileName: fileName),
      successMessage: 'Đã tải báo cáo.',
      failurePrefix: 'Không thể tải báo cáo',
    );
  }

  Future<void> _handleReportFileAction({
    required String endpoint,
    required String fallbackFileName,
    required ValueChanged<bool> setLoading,
    required Future<void> Function(Uint8List bytes, String fileName) onBytes,
    required String? successMessage,
    required String failurePrefix,
  }) async {
    if (examination.examinationId <= 0) {
      _showReportMessage('Không tìm thấy ID ca khám hợp lệ.', isError: true);
      return;
    }

    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    if (token.trim().isEmpty) {
      _showReportMessage('Phiên đăng nhập không hợp lệ.', isError: true);
      return;
    }

    setLoading(true);
    try {
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'Accept': 'application/pdf',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final fileName = _reportFileName(response, fallbackFileName);
        await onBytes(response.bodyBytes, fileName);
        if (!mounted) return;
        if (successMessage != null &&
            endpoint !=
                ApiConstants.reportPreviewEndpoint(examination.examinationId)) {
          _showReportMessage(successMessage);
        }
        return;
      }

      _showReportMessage(
        '$failurePrefix: ${_reportErrorMessage(response)}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showReportMessage(
        '$failurePrefix: ${userFriendlyErrorMessage(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setLoading(false);
    }
  }

  String _reportFileName(http.Response response, String fallback) {
    final disposition = response.headers['content-disposition'];
    if (disposition == null || disposition.trim().isEmpty) return fallback;

    final encodedMatch = RegExp(
      "filename\\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (encodedMatch != null) {
      final value = Uri.decodeFull(encodedMatch.group(1)!.trim());
      if (value.isNotEmpty) return value;
    }

    final quotedMatch = RegExp(
      'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(disposition);
    final value = quotedMatch?.group(1)?.trim();
    return value == null || value.isEmpty ? fallback : value;
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
    if (isError) {
      AppToast.showError(message);
      return;
    }
    AppToast.showSuccess(message);
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

  Color _riskColor(int? grade) {
    if (grade == null) return _primaryGreen;
    if (grade >= 4) return AppColors.error;
    if (grade >= 2) return const Color(0xFFD97706);
    return _primaryGreen;
  }

  Color _gradeProbabilityColor(int grade) {
    switch (grade) {
      case 4:
        return AppColors.error;
      case 3:
        return const Color(0xFFEA580C);
      case 2:
        return const Color(0xFFD97706);
      case 1:
        return const Color(0xFF65A30D);
      default:
        return _primaryGreen;
    }
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

  String _gradeDescription(int? grade) {
    if (grade == null) return '---';
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

class _ReportDraftDialog extends StatefulWidget {
  final ReportDraftModel draft;

  const _ReportDraftDialog({required this.draft});

  @override
  State<_ReportDraftDialog> createState() => _ReportDraftDialogState();
}

class _ReportDraftDialogState extends State<_ReportDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _documentNumberController;
  late final TextEditingController _attemptNumberController;
  late final TextEditingController _patientNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _addressController;
  late final TextEditingController _clinicalDepartmentController;
  late final TextEditingController _conclusionController;
  late final TextEditingController _signaturePlaceController;
  late DateTime _signatureDate;
  late final List<TextEditingController> _findingControllers;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _documentNumberController = TextEditingController(
      text: draft.documentNumber,
    );
    _attemptNumberController = TextEditingController(text: draft.attemptNumber);
    _patientNameController = TextEditingController(text: draft.patientName);
    _ageController = TextEditingController(text: draft.age);
    _genderController = TextEditingController(text: draft.gender);
    _addressController = TextEditingController(text: draft.address);
    _clinicalDepartmentController = TextEditingController(
      text: draft.clinicalDepartment,
    );
    _conclusionController = TextEditingController(text: draft.conclusion);
    _signaturePlaceController = TextEditingController(
      text: draft.signaturePlace,
    );
    _signatureDate = draft.signatureDate ?? DateTime.now();
    _findingControllers = (draft.findings.isEmpty ? [''] : draft.findings)
        .map((finding) => TextEditingController(text: finding))
        .toList();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _attemptNumberController.dispose();
    _patientNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _clinicalDepartmentController.dispose();
    _conclusionController.dispose();
    _signaturePlaceController.dispose();
    for (final controller in _findingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.88;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: SizedBox(
        width: 860,
        height: dialogHeight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
              color: AppColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Xem trước và chỉnh sửa phiếu chụp Xquang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: _reportPreviewPage(context, draft)),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Tạo báo cáo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportPreviewPage(BuildContext context, ReportDraftModel draft) {
    return Container(
      width: 780,
      height: 1103,
      padding: const EdgeInsets.fromLTRB(48, 44, 48, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _watermark()),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReportPreviewFooter(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _letterhead(draft),
              const SizedBox(height: 2),
              Container(height: 2, color: AppColors.primary),
              const SizedBox(height: 2),
              Container(height: 1, color: const Color(0xFF9DBCAB)),
              const SizedBox(height: 16),
              const Text(
                'PHIẾU CHỤP XQUANG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              if (_attemptNumberController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '(lần thứ ${_attemptNumberController.text.trim()})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _patientTable(),
              const SizedBox(height: 22),
              _centerSectionTitle('KẾT QUẢ'),
              _findingsPreviewEditor(),
              const SizedBox(height: 14),
              _conclusionPreviewEditor(),
              const SizedBox(height: 34),
              _signatureBlock(context, draft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _letterhead(ReportDraftModel draft) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'lib/presentation/images/logo1.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.ministryName.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Color(0xFF33414F)),
              ),
              Text(
                draft.hospitalName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                draft.departmentName.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Color(0xFF33414F)),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: 'MS: ',
                  children: [
                    TextSpan(
                      text: draft.formCode.isEmpty ? '---' : draft.formCode,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 10, color: Color(0xFF33414F)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Số: ',
                    style: TextStyle(fontSize: 10, color: Color(0xFF33414F)),
                  ),
                  SizedBox(
                    width: 128,
                    child: _paperInput(
                      _documentNumberController,
                      requiredField: false,
                      textAlign: TextAlign.right,
                      bold: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _patientTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC6D3CB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _tableLabel('Họ và tên', width: 88),
              Expanded(
                flex: 5,
                child: _tableInput(
                  _patientNameController,
                  requiredField: true,
                  bold: true,
                ),
              ),
              _tableLabel('Tuổi', width: 56),
              SizedBox(width: 66, child: _tableInput(_ageController)),
              _tableLabel('Giới tính', width: 78),
              SizedBox(width: 90, child: _tableInput(_genderController)),
            ],
          ),
          _fullWidthInfoRow('Địa chỉ', _addressController),
          _fullWidthInfoRow('Khoa', _clinicalDepartmentController),
        ],
      ),
    );
  }

  Widget _fullWidthInfoRow(String label, TextEditingController controller) {
    return Row(
      children: [
        _tableLabel(label, width: 88),
        Expanded(child: _tableInput(controller)),
      ],
    );
  }

  Widget _tableLabel(String label, {required double width}) {
    return Container(
      width: width,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8F6),
        border: Border(
          top: BorderSide(color: Color(0xFFDFE7E2)),
          right: BorderSide(color: Color(0xFFDFE7E2)),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF45555F)),
      ),
    );
  }

  Widget _tableInput(
    TextEditingController controller, {
    bool requiredField = false,
    bool bold = false,
  }) {
    return SizedBox(
      height: 34,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFDFE7E2))),
        ),
        child: _paperInput(
          controller,
          requiredField: requiredField,
          bold: bold,
        ),
      ),
    );
  }

  Widget _centerSectionTitle(String title) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        Container(
          width: 78,
          height: 1.5,
          margin: const EdgeInsets.only(top: 3, bottom: 12),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _findingsPreviewEditor() {
    return Column(
      children: [
        for (var index = 0; index < _findingControllers.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('•', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _paperInput(
                    _findingControllers[index],
                    requiredField: index == 0,
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                IconButton(
                  onPressed: _findingControllers.length == 1
                      ? null
                      : () => _removeFinding(index),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  tooltip: 'Xóa dòng',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addFinding,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm dòng kết quả'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _conclusionPreviewEditor() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KẾT LUẬN:',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          _paperInput(
            _conclusionController,
            requiredField: true,
            minLines: 2,
            maxLines: 5,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _signatureBlock(BuildContext context, ReportDraftModel draft) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          width: 270,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    child: _paperInput(
                      _signaturePlaceController,
                      requiredField: true,
                      textAlign: TextAlign.right,
                      italic: true,
                    ),
                  ),
                  const Text(', '),
                  GestureDetector(
                    onTap: () => _pickSignatureDate(context),
                    child: Text(
                      'ngày ${_signatureDate.day.toString().padLeft(2, '0')} tháng ${_signatureDate.month.toString().padLeft(2, '0')} năm ${_signatureDate.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF33414F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'BÁC SĨ CHUYÊN KHOA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 58),
              Text(
                draft.doctorName.isEmpty ? '---' : draft.doctorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _watermark() {
    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: -0.78,
          child: Text(
            'HealthSync',
            style: TextStyle(
              color: const Color(0xFFE8EFF7).withValues(alpha: 0.82),
              fontSize: 96,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _paperInput(
    TextEditingController controller, {
    bool requiredField = false,
    bool bold = false,
    bool italic = false,
    TextAlign textAlign = TextAlign.left,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textAlign: textAlign,
      validator: requiredField
          ? (value) {
              if ((value ?? '').trim().isEmpty) return 'Bắt buộc';
              return null;
            }
          : null,
      style: TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: const Color(0xFF14181D),
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
    );
  }

  Future<void> _pickSignatureDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _signatureDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _signatureDate = picked);
  }

  void _addFinding() {
    setState(() => _findingControllers.add(TextEditingController()));
  }

  void _removeFinding(int index) {
    final controller = _findingControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final findings = _findingControllers
        .map((controller) => controller.text.trim())
        .where((finding) => finding.isNotEmpty)
        .toList();
    if (findings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ít nhất một dòng kết quả')),
      );
      return;
    }

    final payload = <String, dynamic>{'findings': findings};
    void addIfNotEmpty(String key, TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) payload[key] = value;
    }

    addIfNotEmpty('documentNumber', _documentNumberController);
    addIfNotEmpty('attemptNumber', _attemptNumberController);
    addIfNotEmpty('patientName', _patientNameController);
    addIfNotEmpty('age', _ageController);
    addIfNotEmpty('gender', _genderController);
    addIfNotEmpty('address', _addressController);
    addIfNotEmpty('conclusion', _conclusionController);
    addIfNotEmpty('signaturePlace', _signaturePlaceController);
    payload['signatureDate'] = _formatReportDate(_signatureDate);

    Navigator.of(context).pop(payload);
  }

  String _formatReportDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _AiReviewDialog extends StatefulWidget {
  final AiPredictionResultEntity result;
  final String doctorName;

  const _AiReviewDialog({required this.result, required this.doctorName});

  @override
  State<_AiReviewDialog> createState() => _AiReviewDialogState();
}

class _ReportPreviewFooter extends StatelessWidget {
  const _ReportPreviewFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: Color(0xFFC3D2C9)),
        SizedBox(height: 8),
        Text(
          'Phiếu được lập với sự hỗ trợ của hệ thống HealthSync. Kết quả AI chỉ mang tính tham khảo, chẩn đoán cuối cùng thuộc về bác sĩ chuyên khoa.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF63727F), fontSize: 10, height: 1.4),
        ),
      ],
    );
  }
}

class _AiReviewDialogState extends State<_AiReviewDialog> {
  late bool _agreeWithAi;
  late int _selectedGrade;
  late final TextEditingController _noteController;
  String? _noteError;

  int? get _aiGrade {
    final grade = widget.result.displayGrade;
    if (grade == null || grade < 0 || grade > 4) return null;
    return grade;
  }

  @override
  void initState() {
    super.initState();
    _agreeWithAi = true;
    _selectedGrade = (widget.result.displayGrade ?? 0).clamp(0, 4).toInt();
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
              _aiDisclaimer(),
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
                      onTap: () => setState(_markDisagreeWithAi),
                      selectedColor: AppColors.error,
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
            if (!_agreeWithAi &&
                _aiGrade != null &&
                _selectedGrade == _aiGrade) {
              setState(
                () => _noteError =
                    'Vui lòng chọn KL khác với kết quả AI khi không đồng ý.',
              );
              return;
            }
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

  void _markDisagreeWithAi() {
    _agreeWithAi = false;
    final aiGrade = _aiGrade;
    if (aiGrade != null && _selectedGrade == aiGrade) {
      _selectedGrade = _fallbackGradeDifferentFrom(aiGrade);
    }
    _noteError = null;
  }

  int _fallbackGradeDifferentFrom(int grade) {
    if (grade < 4) return grade + 1;
    return 3;
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
    final disabled = !_agreeWithAi && _aiGrade == grade;
    final selected = _selectedGrade == grade;
    final color = _gradeColor(grade);
    return InkWell(
      onTap: disabled ? null : () => setState(() => _selectedGrade = grade),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 48,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surface1
              : selected
              ? color
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled ? AppColors.borderStrong : color,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected && !disabled
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
              color: disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.55)
                  : selected
                  ? Colors.white
                  : color,
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

  Widget _aiDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFACC15)),
      ),
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '⚠️ '),
            TextSpan(
              text: 'Lưu ý:',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text:
                  ' Kết quả phân tích từ Trợ lý ảo chỉ mang tính chất tham khảo và không thay thế chẩn đoán của bác sĩ!',
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: Color(0xFF92400E),
        ),
      ),
    );
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
                  result.displayGrade == null
                      ? 'KL ---'
                      : 'KL ${result.displayGrade}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (!result.isReviewed)
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
    Color selectedColor = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19,
              color: selected ? selectedColor : AppColors.textSecondary,
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

class _NetworkImageFrame extends StatelessWidget {
  final String url;
  final String token;
  final BoxFit fit;
  final Color backgroundColor;
  final double loadingIconSize;
  final double errorIconSize;

  const _NetworkImageFrame({
    required this.url,
    required this.token,
    required this.fit,
    required this.backgroundColor,
    required this.loadingIconSize,
    required this.errorIconSize,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _ImageFrameState(
        backgroundColor: backgroundColor,
        icon: Icons.image_not_supported_outlined,
        iconSize: errorIconSize,
      );
    }

    return Image.network(
      url,
      headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _ImageLoadingState(
          backgroundColor: backgroundColor,
          size: loadingIconSize,
          progress: null,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _ImageLoadingState(
          backgroundColor: backgroundColor,
          size: loadingIconSize,
          progress: loadingProgress.expectedTotalBytes == null
              ? null
              : loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _ImageFrameState(
          backgroundColor: backgroundColor,
          icon: Icons.broken_image_outlined,
          iconSize: errorIconSize,
        );
      },
    );
  }
}

class _ImageLoadingState extends StatelessWidget {
  final Color backgroundColor;
  final double size;
  final double? progress;

  const _ImageLoadingState({
    required this.backgroundColor,
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: size <= 20 ? 2 : 3,
            color: Colors.white70,
            backgroundColor: Colors.white12,
          ),
        ),
      ),
    );
  }
}

class _ImageFrameState extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final double iconSize;

  const _ImageFrameState({
    required this.backgroundColor,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Icon(icon, color: Colors.white54, size: iconSize),
      ),
    );
  }
}
