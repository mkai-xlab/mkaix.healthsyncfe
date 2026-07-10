import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/toast_service.dart';
import '../../../data/models/dicom_upload_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dicom_upload_viewmodel.dart';

class FileUploadPage extends StatelessWidget {
  const FileUploadPage({super.key});

  static const _primary = AppColors.primary;
  static const _border = AppColors.border;
  static const _surface = AppColors.surface1;

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';

    return Consumer<DicomUploadViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1020;
              final left = _uploadWorkflow(context, vm, token);
              final right = _verificationPanel(vm);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _stageStrip(vm),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isNarrow
                        ? ListView(
                            children: [
                              SizedBox(height: 520, child: left),
                              const SizedBox(height: 16),
                              SizedBox(height: 520, child: right),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: left),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: right),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload file chẩn đoán',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tải DICOM hoặc ZIP, xác nhận danh sách bệnh nhân sau khi hệ thống xử lý.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _stageStrip(DicomUploadViewModel vm) {
    final stages = [
      _StageView('Upload', Icons.cloud_upload_outlined, 0.10),
      _StageView('Xử lý', Icons.sync_outlined, 0.45),
      _StageView('Xác nhận', Icons.fact_check_outlined, 0.85),
      _StageView('Xong', Icons.check_circle_outline, 1),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: vm.progress.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: AppColors.surface2,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(vm.progress * 100).round()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          const SizedBox(width: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stages
                .map(
                  (stage) =>
                      _stagePill(stage, vm.progress + 0.001 >= stage.threshold),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _stagePill(_StageView stage, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryXLight : AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage.icon, size: 14, color: active ? _primary : AppColors.info),
          const SizedBox(width: 5),
          Text(
            stage.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? _primary : AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadWorkflow(
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
        AppToast.showError(vm.errorMessage!);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(
          borderColor: vm.isDragging ? _primary : _border,
          borderWidth: vm.isDragging ? 2 : 1,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pendingFilesHeight = (constraints.maxHeight - 330).clamp(
              96.0,
              220.0,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryXLight,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: _primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chọn file DICOM hoặc ZIP',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Nhiều file .dcm hoặc một file .zip. Không upload lẫn hai loại trong cùng lượt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: vm.isUploading
                          ? null
                          : () async {
                              await vm.pickFiles();
                              if (!context.mounted || vm.errorMessage == null) {
                                return;
                              }
                              AppToast.showError(vm.errorMessage!);
                            },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        vm.selectedFiles.isEmpty ? 'Chọn tệp' : 'Chọn thêm',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: pendingFilesHeight,
                      child: _pendingFiles(vm),
                    ),
                    if (vm.uploadStatusMessage != null) ...[
                      const SizedBox(height: 12),
                      _statusBox(vm),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: vm.isUploading
                            ? null
                            : () async {
                                await vm.uploadSelected(token);
                                if (!context.mounted) return;
                                if (vm.errorMessage != null) {
                                  AppToast.showError(vm.errorMessage!);
                                } else if (vm.stage ==
                                    DicomUploadStage.waitingVerification) {
                                  AppToast.showInfo(
                                    'Đã xử lý xong, cần bác sĩ xác nhận danh sách.',
                                  );
                                }
                              },
                        icon: vm.isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(
                          vm.isUploading ? 'Đang upload' : 'Bắt đầu upload',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.borderStrong,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _pendingFiles(DicomUploadViewModel vm) {
    final files = vm.selectedFiles;
    if (files.isEmpty) {
      return Center(
        child: Text(
          'Chưa có tệp chờ gửi',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        final isZip = file.name.toLowerCase().endsWith('.zip');
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(
                isZip ? Icons.folder_zip_outlined : Icons.description_outlined,
                color: _primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatBytes(file.bytes.length),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: vm.isUploading
                    ? null
                    : () => vm.removeSelectedFileAt(index),
                tooltip: 'Xóa tệp',
                icon: const Icon(Icons.close, size: 17),
                color: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBox(DicomUploadViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryXLight.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            vm.stage == DicomUploadStage.failed
                ? Icons.error_outline
                : Icons.info_outline,
            color: vm.stage == DicomUploadStage.failed
                ? AppColors.error
                : _primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.errorMessage ?? vm.uploadStatusMessage ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (vm.stage != DicomUploadStage.idle) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Thời gian: ${_formatDuration(vm.uploadElapsed)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationPanel(DicomUploadViewModel vm) {
    final patients = vm.successfulPatients;
    final ids = vm.dicomInstanceIdsForVerification;
    final verifiedDone = vm.stage == DicomUploadStage.completed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  verifiedDone
                      ? 'Đã xác nhận bệnh nhân'
                      : 'Cần bác sĩ xác nhận',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _statusBadge(_stageLabel(vm.stage)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${vm.verifiedPatientCount}/${patients.length} bệnh nhân đã chọn • ${ids.length} ảnh DICOM • ${vm.batchErrors.length} file lỗi',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (patients.isNotEmpty && !verifiedDone) ...[
            Material(
              color: AppColors.primaryXLight,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: CheckboxListTile(
                  value: vm.areAllPatientsVerified,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _primary,
                  title: const Text(
                    'Xác nhận tất cả bệnh nhân trong lượt upload',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onChanged: (value) =>
                      vm.setAllPatientsVerified(value ?? false),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: patients.isEmpty
                ? _emptyVerificationContent(vm)
                : ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _patientVerificationTile(
                      vm,
                      patients[index],
                      verifiedDone,
                    ),
                  ),
          ),
          if (vm.batchErrors.isNotEmpty) ...[
            const SizedBox(height: 10),
            _errorSummary(vm.batchErrors),
          ],
          const SizedBox(height: 12),
          if (_shouldShowUploadAgain(vm))
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: vm.clear,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text(
                  'Upload lại',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _verificationActionEnabled(vm)
                    ? () {
                        vm.verifyPatients();
                        if (vm.errorMessage != null) {
                          AppToast.showError(vm.errorMessage!);
                        } else {
                          AppToast.showSuccess('Đã xác nhận bệnh nhân.');
                        }
                      }
                    : null,
                icon: Icon(
                  verifiedDone
                      ? Icons.check_circle_outline
                      : Icons.verified_outlined,
                  size: 18,
                ),
                label: Text(
                  verifiedDone
                      ? 'Đã xác nhận ${vm.verifiedPatientCount} bệnh nhân'
                      : 'Xác nhận ${vm.verifiedPatientCount} bệnh nhân',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.borderStrong,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyVerificationContent(DicomUploadViewModel vm) {
    if (vm.isProcessActive) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryXLight,
                ),
                child: const Icon(
                  Icons.cloud_sync_outlined,
                  color: _primary,
                  size: 27,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _stageLabel(vm.stage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vm.uploadStatusMessage ?? 'Hệ thống đang xử lý file DICOM...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: vm.progress.clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: const Color(0xFFE2E8F0),
                color: _primary,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(vm.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Thời gian: ${_formatDuration(vm.uploadElapsed)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'Danh sách xác nhận sẽ xuất hiện sau khi hệ thống xử lý xong.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  bool _verificationActionEnabled(DicomUploadViewModel vm) {
    if (vm.isUploading) return false;
    return vm.canVerifyPatients;
  }

  bool _shouldShowUploadAgain(DicomUploadViewModel vm) {
    return vm.successfulPatients.isEmpty &&
        !vm.isProcessActive &&
        vm.stage != DicomUploadStage.idle;
  }

  Widget _patientVerificationTile(
    DicomUploadViewModel vm,
    DicomSuccessfulPatientModel item,
    bool verifiedDone,
  ) {
    final patient = item.patient;
    final title = patient.fullName.isNotEmpty
        ? patient.fullName
        : patient.patientCode.isNotEmpty
        ? patient.patientCode
        : patient.patientId;
    final imageCount = item.recentExaminations.fold<int>(
      0,
      (sum, exam) => sum + exam.images.length,
    );
    final checked = vm.isPatientVerified(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: checked,
                activeColor: _primary,
                onChanged: verifiedDone
                    ? null
                    : (value) => vm.setPatientVerified(item, value ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title.isEmpty ? 'Bệnh nhân chưa có tên' : title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _statusBadge('${item.recentExaminations.length} ca'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _meta(
                'Mã BN',
                patient.patientCode.isEmpty
                    ? patient.patientId
                    : patient.patientCode,
              ),
              _meta('Ảnh', imageCount.toString()),
              _meta('Trạng thái', _firstExamStatus(item)),
            ],
          ),
        ],
      ),
    );
  }

  String _firstExamStatus(DicomSuccessfulPatientModel item) {
    if (item.recentExaminations.isEmpty) return '---';
    final status = item.recentExaminations.first.status;
    return status.isEmpty ? '---' : status;
  }

  Widget _meta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value.isEmpty ? '---' : value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorSummary(List<DicomBatchErrorModel> errors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${errors.length} file lỗi: ${errors.take(2).map((e) => e.filename).join(', ')}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.warning),
      ),
    );
  }

  Widget _statusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryXLight,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _primary,
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration({
    Color borderColor = _border,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  String _stageLabel(DicomUploadStage stage) {
    switch (stage) {
      case DicomUploadStage.uploading:
        return 'Đang upload';
      case DicomUploadStage.processing:
        return 'Đang xử lý';
      case DicomUploadStage.waitingVerification:
        return 'Chờ xác nhận';
      case DicomUploadStage.completed:
        return 'Đã xác nhận';
      case DicomUploadStage.failed:
        return 'Lỗi';
      case DicomUploadStage.idle:
        return 'Sẵn sàng';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _StageView {
  final String label;
  final IconData icon;
  final double threshold;

  const _StageView(this.label, this.icon, this.threshold);
}
