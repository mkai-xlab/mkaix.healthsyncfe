import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/toast_service.dart';
import '../../../data/models/dicom_upload_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dicom_upload_viewmodel.dart';

class FileUploadPage extends StatelessWidget {
  final VoidCallback? onGoToExaminationList;

  const FileUploadPage({super.key, this.onGoToExaminationList});

  static const _primary = AppColors.primary;
  static const _border = AppColors.border;
  static const _surface = AppColors.surface1;

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';

    return Consumer<DicomUploadViewModel>(
      builder: (context, vm, _) {
        final pendingSummary = vm.pendingAiResultSummary;
        if (pendingSummary != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final summary = vm.consumePendingAiResultSummary();
            if (summary == null) return;
            _showAiResultSummaryDialog(context, summary);
          });
        }

        return Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _stageStrip(vm),
                  const SizedBox(height: 16),
                  Expanded(child: _currentStep(context, vm, token)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAiResultSummaryDialog(
    BuildContext context,
    AiResultSummary summary,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AiResultSummaryDialog(
          summary: summary,
          onOpenExaminationList: () {
            Navigator.of(dialogContext).pop();
            onGoToExaminationList?.call();
          },
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
      const _StageView('Upload'),
      const _StageView('Xử lý'),
      const _StageView('Xác nhận'),
    ];
    final activeIndex = _activeStepIndex(vm);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: _panelDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(stages.length * 2 - 1, (visualIndex) {
          if (visualIndex.isOdd) {
            final connectorIndex = visualIndex ~/ 2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: _stepConnector(connectorIndex < activeIndex),
              ),
            );
          }
          final stepIndex = visualIndex ~/ 2;
          return _stepItem(stages[stepIndex], stepIndex, activeIndex);
        }),
      ),
    );
  }

  int _activeStepIndex(DicomUploadViewModel vm) {
    switch (vm.stage) {
      case DicomUploadStage.uploading:
      case DicomUploadStage.processing:
        return 1;
      case DicomUploadStage.waitingVerification:
        return 2;
      case DicomUploadStage.completed:
        return 3;
      case DicomUploadStage.idle:
      case DicomUploadStage.failed:
        return 0;
    }
  }

  Widget _currentStep(
    BuildContext context,
    DicomUploadViewModel vm,
    String token,
  ) {
    switch (vm.stage) {
      case DicomUploadStage.uploading:
      case DicomUploadStage.processing:
        return _processingStep(vm);
      case DicomUploadStage.waitingVerification:
        return _verificationPanel(vm, token);
      case DicomUploadStage.idle:
      case DicomUploadStage.failed:
        return _uploadWorkflow(context, vm, token);
      case DicomUploadStage.completed:
        return _completedStep(vm);
    }
  }

  Widget _stepItem(_StageView stage, int index, int activeIndex) {
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepNode(index, activeIndex),
          const SizedBox(height: 8),
          _stepLabel(stage, index, activeIndex),
        ],
      ),
    );
  }

  Widget _stepNode(int index, int activeIndex) {
    final isDone = index < activeIndex;
    final isCurrent = index == activeIndex;
    final isUpcoming = index > activeIndex;
    final color = isDone
        ? AppColors.success
        : isCurrent
        ? AppColors.info
        : AppColors.borderStrong;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isDone ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: isCurrent ? 5 : 4),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : isUpcoming
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.borderStrong,
                  shape: BoxShape.circle,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _stepConnector(bool active) {
    return Container(
      height: 2,
      color: active ? AppColors.info : AppColors.border,
    );
  }

  Widget _stepLabel(_StageView stage, int index, int activeIndex) {
    final isDone = index < activeIndex;
    final isCurrent = index == activeIndex;
    final color = isDone
        ? AppColors.success
        : isCurrent
        ? AppColors.info
        : AppColors.textSecondary;
    return Text(
      stage.label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isCurrent || isDone ? FontWeight.w800 : FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _processingStep(DicomUploadViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryXLight,
                ),
                child: const Icon(
                  Icons.cloud_sync_outlined,
                  color: _primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _stageLabel(vm.stage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
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
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              LinearProgressIndicator(
                value: vm.progress?.clamp(0, 1).toDouble(),
                minHeight: 9,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: const Color(0xFFE2E8F0),
                color: _primary,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Thời gian: ${_formatDuration(vm.uploadElapsed)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thời gian: ${_formatDuration(vm.uploadElapsed)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completedStep(DicomUploadViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successLight,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đã xác nhận bệnh nhân',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đã xác nhận ${vm.verifiedPatientCount} bệnh nhân. Bạn có thể xem danh sách ca khám hoặc tiếp tục upload lượt mới.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: vm.clear,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Tiếp tục upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onGoToExaminationList == null
                          ? null
                          : () {
                              vm.clear();
                              onGoToExaminationList?.call();
                            },
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Đi tới danh sách ca khám'),
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
            ],
          ),
        ),
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
            final pendingFilesHeight = (constraints.maxHeight - 260).clamp(
              160.0,
              320.0,
            );
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                          'Nhiều file .dcm hoặc nhiều file .zip. Không upload lẫn hai loại trong cùng lượt.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Mỗi file tối đa 100MB, tổng tối đa 500MB/lần upload.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: vm.isUploading
                              ? null
                              : () async {
                                  await vm.pickFiles();
                                  if (!context.mounted ||
                                      vm.errorMessage == null) {
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
                        if (vm.selectedFiles.isNotEmpty) ...[
                          _selectedFilesSummary(vm),
                          if (vm.hasSelectedFileOverSizeLimit) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Vui lòng bỏ tệp vượt quá 100MB.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          if (vm.isSelectedBatchOverSizeLimit) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Vui lòng bỏ bớt tệp để tổng dung lượng không quá 500MB.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          height: pendingFilesHeight,
                          child: _pendingFiles(vm),
                        ),
                        if (vm.uploadStatusMessage != null) ...[
                          const SizedBox(height: 12),
                          _statusBox(vm),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _uploadActionButton(context, vm, token),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _uploadActionButton(
    BuildContext context,
    DicomUploadViewModel vm,
    String token,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: !vm.canUploadSelected
            ? null
            : () async {
                await vm.uploadSelected(token);
                if (!context.mounted) return;
                if (vm.errorMessage != null) {
                  AppToast.showError(vm.errorMessage!);
                } else if (vm.stage == DicomUploadStage.waitingVerification) {
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
        label: Text(vm.isUploading ? 'Đang upload' : 'Bắt đầu upload'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderStrong,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _selectedFilesSummary(DicomUploadViewModel vm) {
    final totalBytes = vm.selectedFilesTotalSizeBytes;
    final isOverLimit = vm.isSelectedBatchOverSizeLimit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isOverLimit
            ? AppColors.errorLight.withValues(alpha: 0.48)
            : AppColors.primaryXLight.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOverLimit ? AppColors.error : _border),
      ),
      child: Row(
        children: [
          Icon(
            isOverLimit ? Icons.error_outline : Icons.storage_outlined,
            size: 17,
            color: isOverLimit ? AppColors.error : _primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${vm.selectedFiles.length} tệp đã chọn',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            'Tổng: ${_formatMegabytes(totalBytes)} MB',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isOverLimit ? AppColors.error : _primary,
            ),
          ),
        ],
      ),
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

  Widget _verificationPanel(DicomUploadViewModel vm, String token) {
    final patients = vm.successfulPatients;
    final acceptedPatientCodes = vm.acceptedPatientCodesForVerification;
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
            '${vm.verifiedPatientCount}/${patients.length} bệnh nhân đã chọn • ${acceptedPatientCodes.length} mã bệnh nhân • ${vm.batchErrors.length} file lỗi',
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
                    ? () async {
                        await vm.verifyPatients(token);
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
                      : vm.isUploading
                      ? 'Đang xác nhận...'
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
                value: vm.progress?.clamp(0, 1).toDouble(),
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
                    'Thời gian: ${_formatDuration(vm.uploadElapsed)}',
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
    if (vm.stage == DicomUploadStage.waitingVerification) {
      return vm.successfulPatients.isNotEmpty && vm.verifiedPatientCount == 0;
    }
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

  String _formatMegabytes(int bytes) {
    return (bytes / 1024 / 1024).toStringAsFixed(1);
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

class _AiResultSummaryDialog extends StatelessWidget {
  final AiResultSummary summary;
  final VoidCallback onOpenExaminationList;

  const _AiResultSummaryDialog({
    required this.summary,
    required this.onOpenExaminationList,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryXLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.message.isNotEmpty) ...[
              Text(
                summary.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
            ],
            const Text(
              'Thống kê số lượng bệnh nhân theo KL Grade',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _AnimatedAiGradeBarChart(items: summary.items),
            const SizedBox(height: 4),
            _AiResultTotalRow(total: summary.totalPatientCount),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: onOpenExaminationList,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Đi đến danh sách ca khám'),
        ),
      ],
    );
  }
}

class _AiResultTotalRow extends StatelessWidget {
  final int total;

  const _AiResultTotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tổng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$total bệnh nhân',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedAiGradeBarChart extends StatefulWidget {
  final List<AiGradeSummaryItem> items;

  const _AnimatedAiGradeBarChart({required this.items});

  @override
  State<_AnimatedAiGradeBarChart> createState() =>
      _AnimatedAiGradeBarChartState();
}

class _AnimatedAiGradeBarChartState extends State<_AnimatedAiGradeBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = widget.items.fold<int>(
      1,
      (max, item) => item.count > max ? item.count : max,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in widget.items) ...[
              _AiGradeBarRow(
                item: item,
                maxCount: maxCount,
                progress: progress,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _AiGradeBarRow extends StatelessWidget {
  final AiGradeSummaryItem item;
  final int maxCount;
  final double progress;

  const _AiGradeBarRow({
    required this.item,
    required this.maxCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final widthFactor = maxCount <= 0
        ? 0.0
        : (item.count / maxCount) * progress;
    final animatedCount = (item.count * progress).round();

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 16,
              color: AppColors.surface2,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widthFactor.clamp(0.0, 1.0),
                child: Container(color: item.color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            animatedCount.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StageView {
  final String label;

  const _StageView(this.label);
}
