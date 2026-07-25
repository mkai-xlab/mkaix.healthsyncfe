import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';

enum _ImageMode { original, annotated, roi, gradcam }

class ExaminationDetailPage extends StatefulWidget {
  final ExaminationEntity examination;
  final VoidCallback onBack;

  const ExaminationDetailPage({
    super.key,
    required this.examination,
    required this.onBack,
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

  List<AiPredictionResultEntity> get _allAiResults {
    return examination.images.expand((image) => image.aiResults).toList();
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
                _headerField('Giới tính', examination.patientGenderDisplay),
                _headerField('Ngày chụp', examination.studyDateDisplay),
              ],
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
    return SingleChildScrollView(
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
              border: Border.all(color: riskColor.withValues(alpha: 0.18)),
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
            ...result.details.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _metricBar(
                  label: _detailLabel(entry.key),
                  value: entry.value,
                  color: _detailColor(entry.value),
                ),
              ),
            ),
          ],
          if (_allAiResults.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              'Tổng kết quả AI trong ca: ${_allAiResults.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
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
            label: Text(results[index].kneeSideDisplay),
            selected: index == _selectedResultIndex,
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
              color: index == _selectedResultIndex
                  ? _primaryGreen.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
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
              return Wrap(
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
                    examination.bodyPart.isEmpty ? '---' : examination.bodyPart,
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
                    examination.priority.isEmpty ? '---' : examination.priority,
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
              );
            },
          ),
        ],
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
    final color = _statusColor(examination.statusGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        examination.statusDisplay,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

  String _detailLabel(String key) {
    final spaced = key.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) {
        return '${match.group(1)} ${match.group(2)}';
      },
    );
    if (spaced.isEmpty) return 'Chỉ số AI';
    return spaced[0].toUpperCase() + spaced.substring(1);
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
