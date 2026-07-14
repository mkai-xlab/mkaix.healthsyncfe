import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';

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

  ExaminationEntity get examination => widget.examination;

  List<String> get _imageUrls {
    final urls = examination.images
        .map((image) => image.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) return urls;
    if (examination.thumbnailUrl.isNotEmpty) return [examination.thumbnailUrl];
    return const [];
  }

  String get _selectedImageUrl {
    final urls = _imageUrls;
    if (urls.isEmpty) return '';
    final safeIndex = _selectedImageIndex.clamp(0, urls.length - 1).toInt();
    return urls[safeIndex];
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
                final isNarrow = constraints.maxWidth < 980;
                if (isNarrow) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _imageViewer(token, height: 480),
                        const SizedBox(height: 16),
                        _examInfoPanel(),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 7, child: _imageViewer(token)),
                      const SizedBox(width: 18),
                      SizedBox(width: 320, child: _examInfoPanel()),
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
            height: 38,
            color: const Color(0xFF17211F),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text(
                  'Ảnh chụp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_imageUrls.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedImageIndex + 1}/${_imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.zoom_in, color: Colors.white70),
                  tooltip: 'Phóng to',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: _selectedImageUrl.isEmpty
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
              child: _selectedImageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 54,
                      ),
                    )
                  : Image.network(
                      _selectedImageUrl,
                      headers: token.isEmpty
                          ? null
                          : {'Authorization': 'Bearer $token'},
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 54,
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_imageUrls.length > 1) _thumbnailStrip(token),
        ],
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
        itemCount: _imageUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final imageUrl = _imageUrls[index];
          final isSelected = index == _selectedImageIndex;
          return InkWell(
            onTap: () => setState(() => _selectedImageIndex = index),
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
                      _selectedImageUrl,
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
              if (_imageUrls.length > 1)
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
                      'Ảnh ${_selectedImageIndex + 1}/${_imageUrls.length}',
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

  Widget _examInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin ca khám',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(
              'ID ca khám',
              examination.examinationId > 0
                  ? examination.examinationId.toString()
                  : '---',
            ),
            _infoRow('Trạng thái', examination.statusDisplay),
            _infoRow(
              'Vùng chụp',
              examination.bodyPart.isEmpty ? '---' : examination.bodyPart,
            ),
            _infoRow('Ngày chụp', examination.studyDateDisplay),
            _infoRow(
              'Giờ chụp',
              examination.studyTime.isEmpty ? '---' : examination.studyTime,
            ),
            _infoRow('Thời gian khám', examination.visitTimeDisplay),
            _infoRow(
              'Bác sĩ chỉ định',
              examination.referringPhysician.isEmpty
                  ? '---'
                  : examination.referringPhysician,
            ),
            _infoRow(
              'Bác sĩ phụ trách',
              examination.doctorName.isEmpty ? '---' : examination.doctorName,
            ),
            _infoRow(
              'Mức ưu tiên',
              examination.priority.isEmpty ? '---' : examination.priority,
            ),
            _infoRow(
              'Lý do khám',
              examination.chiefComplaint.isEmpty
                  ? '---'
                  : examination.chiefComplaint,
            ),
            _infoRow(
              'Ghi chú lâm sàng',
              examination.clinicalNotes.isEmpty
                  ? '---'
                  : examination.clinicalNotes,
            ),
            _infoRow(
              'Chẩn đoán cuối',
              examination.finalDiagnosis.isEmpty
                  ? '---'
                  : examination.finalDiagnosis,
            ),
            _infoRow(
              'Mô tả',
              examination.description.isEmpty ? '---' : examination.description,
            ),
            _infoRow('Số ảnh', examination.images.length.toString()),
            _infoRow(
              'Encounter code',
              examination.encounterCode.isEmpty
                  ? '---'
                  : examination.encounterCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A9A96)),
          ),
          const SizedBox(height: 5),
          Text(
            value,
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
}
