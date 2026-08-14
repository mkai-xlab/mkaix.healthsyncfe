import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/toast_service.dart';
import '../../../data/datasources/knowledge_document_remote_datasource.dart';
import '../../../data/models/knowledge_document_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/knowledge_document_viewmodel.dart';

class KnowledgeDocumentsPage extends StatefulWidget {
  const KnowledgeDocumentsPage({super.key});

  @override
  State<KnowledgeDocumentsPage> createState() => _KnowledgeDocumentsPageState();
}

class _KnowledgeDocumentsPageState extends State<KnowledgeDocumentsPage> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<KnowledgeDocumentViewModel>().loadDocuments(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthViewModel>().currentUser?.token ?? '';

    return Consumer<KnowledgeDocumentViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onUpload: () => _showUploadDialog(context, token)),
              const SizedBox(height: 28),
              _DocumentFilterBar(vm: vm),
              const SizedBox(height: 18),
              if (vm.isLoading)
                const _LoadingPanel()
              else if (vm.errorMessage != null)
                _ErrorPanel(
                  message: vm.errorMessage!,
                  onRetry: () => vm.loadDocuments(token),
                )
              else
                _DocumentTable(documents: vm.filteredDocuments),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUploadDialog(BuildContext context, String token) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _KnowledgeUploadDialog(token: token),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onUpload;

  const _Header({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách tài liệu & bài báo khoa học',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Quản lý và xem xét các tài liệu lâm sàng, tài liệu về AI và tài liệu nghiên cứu.',
                style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: const Text('Tải lên tài liệu mới'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentFilterBar extends StatelessWidget {
  final KnowledgeDocumentViewModel vm;

  const _DocumentFilterBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: vm.setSearchQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Tìm kiếm tài liệu...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: vm.selectedStatus,
              borderRadius: BorderRadius.circular(8),
              items: vm.availableStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_statusFilterLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                vm.setStatusFilter(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusFilterLabel(String status) {
    if (status == 'ALL') return 'Tất cả trạng thái';
    return _DocumentStatusView.fromStatus(status).label;
  }
}

class _DocumentTable extends StatelessWidget {
  final List<KnowledgeDocumentModel> documents;

  const _DocumentTable({required this.documents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFEFF4FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _DocumentHeaderCell('TÊN TÀI LIỆU')),
                Expanded(child: _DocumentHeaderCell('LOẠI')),
                Expanded(child: _DocumentHeaderCell('PHẠM VI')),
                Expanded(child: _DocumentHeaderCell('NGÀY TẢI')),
                Expanded(child: _DocumentHeaderCell('TRẠNG THÁI\nAI')),
              ],
            ),
          ),
          if (documents.isEmpty)
            const _EmptyState()
          else
            for (final document in documents) _DocumentRow(document: document),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${documents.isEmpty ? 0 : 1} to ${documents.length} of ${documents.length} results',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 8),
                const Text('1', style: TextStyle(color: Color(0xFF9CA3AF))),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final KnowledgeDocumentModel document;

  const _DocumentRow({required this.document});

  @override
  Widget build(BuildContext context) {
    final statusView = _DocumentStatusView.fromStatus(document.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                if (document.originalName.trim().isNotEmpty &&
                    document.originalName != document.displayName) ...[
                  const SizedBox(height: 4),
                  Text(
                    document.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: Text(_sourceTypeLabel(document.sourceType))),
          Expanded(child: Text(_accessScopeLabel(document.accessScope))),
          Expanded(child: Text(_formatDate(document.createdAt))),
          Expanded(
            child: Tooltip(
              message: document.errorMessage ?? statusView.label,
              child: Row(
                children: [
                  Icon(statusView.icon, size: 16, color: statusView.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      statusView.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusView.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceTypeLabel(String value) {
    switch (value.toUpperCase()) {
      case 'FILE':
      case 'DOCUMENT':
        return 'Tài liệu';
      case 'URL':
        return 'URL';
      case 'REPORT':
        return 'Báo cáo';
      default:
        return value.trim().isEmpty ? '--' : value;
    }
  }

  String _accessScopeLabel(String value) {
    switch (value.toUpperCase()) {
      case 'ALL':
        return 'Tất cả';
      case 'DOCTOR':
        return 'Bác sĩ';
      case 'ADMIN':
        return 'Admin';
      case 'OWNER':
        return 'Người tạo';
      default:
        return value.trim().isEmpty ? '--' : value;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('dd/MM/yyyy').format(value);
  }
}

class _KnowledgeUploadDialog extends StatefulWidget {
  final String token;

  const _KnowledgeUploadDialog({required this.token});

  @override
  State<_KnowledgeUploadDialog> createState() => _KnowledgeUploadDialogState();
}

class _AccessScopeOption {
  final String value;
  final String label;

  const _AccessScopeOption({required this.value, required this.label});
}

class _KnowledgeUploadDialogState extends State<_KnowledgeUploadDialog> {
  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'docs'];
  static const _accessScopeOptions = [
    _AccessScopeOption(value: 'ALL', label: 'Tất cả'),
    _AccessScopeOption(value: 'DOCTOR', label: 'Bác sĩ'),
    _AccessScopeOption(value: 'ADMIN', label: 'Admin'),
    _AccessScopeOption(value: 'OWNER', label: 'Người tạo'),
  ];

  final _titleController = TextEditingController();
  final List<KnowledgeUploadFile> _files = [];
  String _selectedAccessScope = 'ALL';
  bool _isDragging = false;
  String? _validationError;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<KnowledgeDocumentViewModel>().isUploading;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: const Text(
        'Tải lên tài liệu',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kéo-thả hoặc chọn một hay nhiều tài liệu để bổ sung vào kho tri thức AI.',
              style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
            ),
            const SizedBox(height: 16),
            _dropZone(isUploading),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccessScope,
              decoration: const InputDecoration(
                labelText: 'Phạm vi truy cập',
                border: OutlineInputBorder(),
              ),
              items: _accessScopeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                );
              }).toList(),
              onChanged: isUploading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _selectedAccessScope = value);
                    },
            ),
            const SizedBox(height: 12),
            if (_files.length == 1) ...[
              TextField(
                controller: _titleController,
                enabled: !isUploading,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Để trống để dùng tên file',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_files.isNotEmpty) ...[_selectedFilesList(isUploading)],
            if (_validationError != null) ...[
              const SizedBox(height: 10),
              Text(
                _validationError!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _files.isEmpty || isUploading ? null : _upload,
          icon: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(isUploading ? 'Đang tải lên...' : 'Tải lên'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dropZone(bool isUploading) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: isUploading
          ? null
          : (detail) async {
              setState(() => _isDragging = false);
              final droppedFiles = <KnowledgeUploadFile>[];
              for (final file in detail.files) {
                droppedFiles.add(
                  KnowledgeUploadFile(
                    name: file.name,
                    size: await file.length(),
                    bytes: await file.readAsBytes(),
                  ),
                );
              }
              _addFiles(droppedFiles);
            },
      child: InkWell(
        onTap: isUploading ? null : _pickFiles,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          decoration: BoxDecoration(
            color: _isDragging
                ? AppColors.primaryXLight
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _validationError == null
                  ? AppColors.borderStrong
                  : AppColors.error,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 42,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 10),
              Text(
                _files.isEmpty
                    ? 'Kéo-thả tài liệu vào đây hoặc nhấn để chọn'
                    : 'Đã chọn ${_files.length} tài liệu',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Định dạng: .pdf, .doc, .docx, .docs',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedFilesList(bool isUploading) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _files.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final file = _files[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatFileSize(file.size),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa file',
                  onPressed: isUploading
                      ? null
                      : () => setState(() => _files.removeAt(index)),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    _addFiles(
      result.files
          .map(
            (file) => KnowledgeUploadFile(
              name: file.name,
              size: file.size,
              path: file.path,
              bytes: file.bytes,
            ),
          )
          .toList(),
    );
  }

  void _addFiles(List<KnowledgeUploadFile> files) {
    final invalid = files.where((file) {
      return !_allowedExtensions.contains(_fileExtension(file.name));
    }).toList();

    if (invalid.isNotEmpty) {
      setState(() {
        _validationError =
            'Chỉ hỗ trợ PDF, DOC, DOCX hoặc DOCS. Vui lòng kiểm tra lại file.';
      });
      return;
    }

    setState(() {
      _validationError = null;
      for (final file in files) {
        final alreadySelected = _files.any((item) => item.name == file.name);
        if (!alreadySelected) _files.add(file);
      }
      if (_files.length != 1) _titleController.clear();
    });
  }

  Future<void> _upload() async {
    final vm = context.read<KnowledgeDocumentViewModel>();
    final success = await vm.uploadDocuments(
      token: widget.token,
      files: List.unmodifiable(_files),
      title: _files.length == 1 ? _titleController.text : null,
      accessScope: _selectedAccessScope,
    );

    if (!mounted) return;
    if (!success) {
      final message = vm.errorMessage ?? 'Không thể tải tài liệu lên.';
      AppToast.showError(message);
      return;
    }

    Navigator.of(context).pop();
    AppToast.showSuccess('Đã gửi tài liệu để AI phân tích.');
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().trim().split('.');
    if (parts.length < 2) return '';
    return parts.last;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Không rõ dung lượng';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }
}

class _DocumentStatusView {
  final String label;
  final Color color;
  final IconData icon;

  const _DocumentStatusView({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory _DocumentStatusView.fromStatus(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'INDEXED':
      case 'SUCCESS':
      case 'COMPLETED':
        return const _DocumentStatusView(
          label: 'Đã phân tích',
          color: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case 'QUEUED':
      case 'PROCESSING':
      case 'INDEXING':
      case 'PENDING':
        return const _DocumentStatusView(
          label: 'Đang phân tích AI...',
          color: Color(0xFFD97706),
          icon: Icons.sync,
        );
      case 'FAILED':
      case 'ERROR':
        return const _DocumentStatusView(
          label: 'Phân tích không thành công',
          color: AppColors.error,
          icon: Icons.error_outline,
        );
      default:
        return _DocumentStatusView(
          label: rawStatus.trim().isEmpty ? 'Chưa xác định' : rawStatus,
          color: const Color(0xFF6B7280),
          icon: Icons.info_outline,
        );
    }
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: const Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: Color(0xFF9CA3AF)),
          SizedBox(height: 14),
          Text(
            'Chưa có tài liệu nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tải lên tài liệu đầu tiên để bắt đầu quản lý kho tri thức.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _DocumentHeaderCell extends StatelessWidget {
  final String text;

  const _DocumentHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4B5563),
        letterSpacing: 0.4,
      ),
    );
  }
}
