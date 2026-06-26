import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/dicom_remote_datasource.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dicom_upload_viewmodel.dart';

class DicomUploadPage extends StatelessWidget {
  const DicomUploadPage({super.key});

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
                        SizedBox(height: 420, child: _sessionList(vm)),
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
                          Expanded(flex: 4, child: _sessionList(vm)),
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
        _showToast(
          context,
          message: vm.errorMessage!,
          backgroundColor: const Color(0xFFD14343),
          icon: Icons.error_outline,
        );
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
                      context,
                      message: vm.errorMessage!,
                      backgroundColor: const Color(0xFFD14343),
                      icon: Icons.error_outline,
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
                    TextButton.icon(
                      onPressed: vm.isUploading ? null : vm.clear,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Xóa'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF66736F),
                        visualDensity: VisualDensity.compact,
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
                        _pendingFileTile(files[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _pendingFileTile(DicomUploadFile file) {
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
      ],
    );
  }

  Widget _sessionList(DicomUploadViewModel vm) {
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
                  'File đã upload phiên này',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2B27),
                  ),
                ),
              ),
              if (vm.uploadedFiles.isNotEmpty)
                IconButton(
                  onPressed: vm.clearUploadedFiles,
                  tooltip: 'Xóa lịch sử phiên',
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  color: const Color(0xFF66736F),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${vm.uploadedFiles.length} file',
            style: const TextStyle(fontSize: 12, color: Color(0xFF66736F)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE1ECE8)),
          const SizedBox(height: 12),
          Expanded(
            child: vm.uploadedFiles.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa upload file nào trong phiên này',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF7A8581)),
                    ),
                  )
                : ListView.separated(
                    itemCount: vm.uploadedFiles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _uploadedFileTile(vm.uploadedFiles[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _uploadedFileTile(DicomUploadedFileSessionItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1ECE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline,
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
                  item.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2B27),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatBytes(item.fileSize)} • batch ${item.batchFileCount} file • ${item.successfulPatientCount} BN • ${item.errorCount} lỗi • ${_formatDuration(item.duration)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF66736F),
                  ),
                ),
                if (item.successfulPatients.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.successfulPatients.first.patient.fullName.isNotEmpty
                        ? item.successfulPatients.first.patient.fullName
                        : item.successfulPatients.first.patient.patientCode,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF006B5A),
                    ),
                  ),
                ] else if (item.errors.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.errors.first.errorReason.isNotEmpty
                        ? item.errors.first.errorReason
                        : item.errors.first.filename,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD14343),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatClock(item.uploadedAt),
            style: const TextStyle(fontSize: 11, color: Color(0xFF7A8581)),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final hasError = vm.errorMessage != null || vm.batchErrors.isNotEmpty;
    final backgroundColor = vm.errorMessage != null
        ? const Color(0xFFD14343)
        : vm.batchErrors.isNotEmpty
        ? const Color(0xFFB7791F)
        : _primaryGreen;
    final icon = vm.errorMessage != null
        ? Icons.error_outline
        : vm.batchErrors.isNotEmpty
        ? Icons.warning_amber_outlined
        : Icons.check_circle_outline;
    final message =
        vm.errorMessage ??
        'Upload batch xong: ${vm.successfulPatients.length} bệnh nhân thành công, ${vm.batchErrors.length} file lỗi.';

    _showToast(
      context,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      trailing: hasError
          ? Text(
              vm.batchErrors.isNotEmpty
                  ? '${vm.batchErrors.length} lỗi'
                  : 'Lỗi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Widget? trailing,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing],
          ],
        ),
      ),
    );
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

  String _formatClock(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
