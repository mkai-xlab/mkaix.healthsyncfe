import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../data/datasources/dicom_remote_datasource.dart';
import '../../../data/models/dicom_upload_model.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dicom_upload_viewmodel.dart';

class DicomUploadPage extends StatelessWidget {
  final ValueChanged<List<ExaminationEntity>>? onGoToExaminations;

  const DicomUploadPage({super.key, this.onGoToExaminations});

  static const Color _primaryGreen = Color(0xFF006B5A);
  static const Color _softMint = Color(0xFFAEEFDA);
  static const Color _pageBg = Color(0xFFFAFAF8);

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';

    return Container(
      color: _pageBg,
      width: double.infinity,
      child: Consumer<DicomUploadViewModel>(
        builder: (context, vm, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 980;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tạo chẩn đoán mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tải nhiều file DICOM từ thiết bị để bắt đầu quy trình chẩn đoán.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
                  ),
                  const SizedBox(height: 18),
                  if (isNarrow)
                    Column(
                      children: [
                        SizedBox(
                          height: 520,
                          child: _uploadCard(context, vm, token),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 420,
                          child: _patientResultPanel(context, vm),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _uploadCard(context, vm, token),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 4,
                            child: _patientResultPanel(context, vm),
                          ),
                        ],
                      ),
                    ),
                ],
              );

              if (isNarrow) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: content,
              );
            },
          );
        },
      ),
    );
  }

  Widget _uploadCard(
    BuildContext context,
    DicomUploadViewModel vm,
    String token,
  ) {
    return DropTarget(
      onDragEntered: (_) => vm.setDragging(true),
      onDragExited: (_) => vm.setDragging(false),
      onDragDone: (detail) async {
        await vm.handleDroppedFiles(detail.files);
        if (!context.mounted || vm.errorMessage == null) return;
        _showToast(message: vm.errorMessage!, type: AppToastType.error);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: vm.isDragging ? _primaryGreen : const Color(0xFFB8CDC6),
            width: vm.isDragging ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _dropIntro(context, vm),
            const SizedBox(height: 18),
            _selectedFile(vm),
            if (vm.isUploading || vm.lastUploadDuration != null) ...[
              const SizedBox(height: 12),
              _processingTime(vm),
            ],
            const Spacer(),
            const Divider(color: Color(0xFFB8CDC6), height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: vm.isUploading
                    ? null
                    : () async {
                        await vm.uploadSelected(token);
                        if (!context.mounted) return;
                        _showUploadToast(context, vm);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF128A72),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF8CBBAF),
                  elevation: 3,
                  shadowColor: const Color(0x33128A72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.isUploading ? 'Đang upload batch' : 'Upload batch',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (vm.isUploading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      const Icon(Icons.arrow_forward, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropIntro(BuildContext context, DicomUploadViewModel vm) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _softMint,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: _primaryGreen,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Tải lên các tệp DICOM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3532),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kéo thả nhiều file vào đây hoặc chọn từ máy tính. Chỉ hỗ trợ .DCM/.dcm.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: vm.isUploading
                ? null
                : () async {
                    await vm.pickFiles();
                    if (!context.mounted || vm.errorMessage == null) return;
                    _showToast(
                      message: vm.errorMessage!,
                      type: AppToastType.error,
                    );
                  },
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              vm.selectedFiles.isEmpty ? 'Chọn tệp' : 'Chọn thêm tệp',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectedFile(DicomUploadViewModel vm) {
    final files = vm.selectedFiles;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1ECE8)),
      ),
      child: files.isEmpty
          ? const SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  'Chưa có tệp chờ gửi',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A8581)),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${files.length} tệp chờ gửi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2B27),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: files.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _pendingFileTile(files[index], vm, index),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _pendingFileTile(
    DicomUploadFile file,
    DicomUploadViewModel vm,
    int index,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAE8E5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.insert_drive_file_outlined,
            color: _primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            file.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatBytes(file.bytes.length),
          style: const TextStyle(fontSize: 12, color: Color(0xFF66736F)),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: vm.isUploading
              ? null
              : () => vm.removeSelectedFileAt(index),
          tooltip: 'Xóa tệp',
          icon: const Icon(Icons.close, size: 18),
          color: const Color(0xFF8A2D2D),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _patientResultPanel(BuildContext context, DicomUploadViewModel vm) {
    final patients = vm.successfulPatients;
    final newExaminations = _newExaminationsFromResponse(patients);
    final canGoToExaminations = context
        .read<AuthViewModel>()
        .hasPermissionPresentation('examination_list_page');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1ECE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bệnh nhân từ response',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2B27),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${patients.length} bệnh nhân • ${newExaminations.length} ca khám',
            style: const TextStyle(fontSize: 12, color: Color(0xFF66736F)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE1ECE8)),
          const SizedBox(height: 12),
          Expanded(
            child: patients.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có bệnh nhân nào từ response upload',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF7A8581)),
                    ),
                  )
                : ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _patientResultTile(patients[index]),
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed:
                  patients.isEmpty ||
                      onGoToExaminations == null ||
                      !canGoToExaminations
                  ? null
                  : () => onGoToExaminations?.call(newExaminations),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text(
                'Đi tới ca khám',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB8CDC6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientResultTile(DicomSuccessfulPatientModel item) {
    final patient = item.patient;
    final title = patient.fullName.isNotEmpty
        ? patient.fullName
        : patient.patientCode.isNotEmpty
        ? patient.patientCode
        : patient.patientId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_outline,
              color: _primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Bệnh nhân chưa có tên' : title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2B27),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${patient.patientCode.isEmpty ? patient.patientId : patient.patientCode} • ${item.recentExaminations.length} ca khám',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF66736F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingTime(DicomUploadViewModel vm) {
    final duration = vm.isUploading
        ? vm.uploadElapsed
        : vm.lastUploadDuration ?? Duration.zero;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1ECE8)),
      ),
      child: Row(
        children: [
          Icon(
            vm.isUploading ? Icons.timer_outlined : Icons.check_circle_outline,
            color: _primaryGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            vm.isUploading ? 'Đang xử lý: ' : 'Thời gian xử lý: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF5D6663)),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadToast(BuildContext context, DicomUploadViewModel vm) {
    final type = vm.errorMessage != null
        ? AppToastType.error
        : vm.batchErrors.isNotEmpty
        ? AppToastType.warning
        : AppToastType.success;
    final message =
        vm.errorMessage ??
        'Upload batch xong: ${vm.successfulPatients.length} bệnh nhân thành công, ${vm.batchErrors.length} file lỗi.';

    _showToast(message: message, type: type);
  }

  void _showToast({required String message, required AppToastType type}) {
    if (type == AppToastType.success) {
      AppToast.showSuccess(message);
    } else if (type == AppToastType.error) {
      AppToast.showError(message);
    } else if (type == AppToastType.warning) {
      AppToast.showWarning(message);
    } else {
      AppToast.showInfo(message);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)} giây';

    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes phút ${remainingSeconds.toString().padLeft(2, '0')} giây';
  }

  List<ExaminationEntity> _newExaminationsFromResponse(
    List<DicomSuccessfulPatientModel> patients,
  ) {
    final examinations = <ExaminationEntity>[];
    for (final item in patients) {
      final patient = item.patient;
      final patientCode = patient.patientCode.isNotEmpty
          ? patient.patientCode
          : patient.patientId;
      for (final exam in item.recentExaminations) {
        examinations.add(
          ExaminationEntity(
            patientDbId: patient.id,
            patientCode: patientCode,
            patientName: patient.fullName,
            patientGender: patient.gender,
            examinationId: exam.examinationId,
            encounterCode: exam.encounterCode,
            status: exam.status,
            studyDate: exam.studyDate,
            visitTime: exam.visitTime,
            thumbnailUrl: exam.thumbnailUrl,
            bodyPart: exam.bodyPart,
            referringPhysician: exam.referringPhysician,
            studyTime: exam.studyTime,
            chiefComplaint: exam.chiefComplaint,
            clinicalNotes: exam.clinicalNotes,
            priority: exam.priority,
            finalDiagnosis: exam.finalDiagnosis,
            description: exam.description,
            images: exam.images
                .map(
                  (image) => ExaminationImageEntity(
                    examinationId: image.examinationId == 0
                        ? exam.examinationId
                        : image.examinationId,
                    encounterCode: image.encounterCode.isEmpty
                        ? exam.encounterCode
                        : image.encounterCode,
                    status: image.status.isEmpty ? exam.status : image.status,
                    visitTime: image.visitTime ?? exam.visitTime,
                    imageUrl: image.imageUrl,
                  ),
                )
                .toList(),
          ),
        );
      }
    }
    return examinations;
  }
}
