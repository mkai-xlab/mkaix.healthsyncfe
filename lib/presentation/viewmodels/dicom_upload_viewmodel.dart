import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/dicom_remote_datasource.dart';
import '../../data/models/dicom_upload_model.dart';

class DicomUploadViewModel extends ChangeNotifier {
  final DicomRemoteDataSource remoteDataSource;

  DicomUploadViewModel(this.remoteDataSource);

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  final Stopwatch _uploadStopwatch = Stopwatch();
  Timer? _uploadTimer;

  Duration _uploadElapsed = Duration.zero;
  Duration get uploadElapsed => _uploadElapsed;

  Duration? _lastUploadDuration;
  Duration? get lastUploadDuration => _lastUploadDuration;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DicomUploadFile> _selectedFiles = [];
  List<DicomUploadFile> get selectedFiles => List.unmodifiable(_selectedFiles);

  List<DicomTagModel> _tags = [];
  List<DicomTagModel> get tags => _tags;

  List<DicomBatchErrorModel> _batchErrors = [];
  List<DicomBatchErrorModel> get batchErrors => List.unmodifiable(_batchErrors);

  List<DicomSuccessfulPatientModel> _successfulPatients = [];
  List<DicomSuccessfulPatientModel> get successfulPatients =>
      List.unmodifiable(_successfulPatients);

  final List<DicomUploadedFileSessionItem> _uploadedFiles = [];
  List<DicomUploadedFileSessionItem> get uploadedFiles =>
      List.unmodifiable(_uploadedFiles);

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['dcm', 'DCM'],
    );
    if (result == null) return;

    final invalidFile = _firstInvalidFileName(
      result.files.map((file) => file.name),
    );
    if (invalidFile != null) {
      _errorMessage = 'Chỉ hỗ trợ file .DCM hoặc .dcm.';
      notifyListeners();
      return;
    }

    final files = result.files
        .where((file) => file.bytes != null)
        .map(
          (file) => DicomUploadFile(
            name: file.name,
            bytes: Uint8List.fromList(file.bytes!),
          ),
        )
        .toList();

    if (files.length != result.files.length) {
      _errorMessage = 'Không đọc được nội dung file đã chọn.';
      notifyListeners();
      return;
    }

    _addSelectedFiles(files);
  }

  Future<void> handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    final invalidFile = _firstInvalidFileName(files.map((file) => file.name));
    if (invalidFile != null) {
      _errorMessage = 'Chỉ hỗ trợ file .DCM hoặc .dcm.';
      _isDragging = false;
      notifyListeners();
      return;
    }

    try {
      final selectedFiles = <DicomUploadFile>[];
      for (final file in files) {
        selectedFiles.add(
          DicomUploadFile(name: file.name, bytes: await file.readAsBytes()),
        );
      }
      _addSelectedFiles(selectedFiles);
    } catch (_) {
      _errorMessage = 'Không đọc được nội dung file đã kéo thả.';
      _isDragging = false;
      notifyListeners();
    }
  }

  void setDragging(bool value) {
    if (_isDragging == value) return;
    _isDragging = value;
    notifyListeners();
  }

  void _addSelectedFiles(List<DicomUploadFile> files) {
    if (files.isEmpty) {
      _errorMessage = 'Vui lòng chọn ít nhất 1 file DICOM.';
      notifyListeners();
      return;
    }

    if (files.any((file) => !_isDcmFile(file.name))) {
      _errorMessage = 'Chỉ hỗ trợ file .DCM hoặc .dcm.';
      notifyListeners();
      return;
    }

    final mergedFiles = List<DicomUploadFile>.from(_selectedFiles);
    var duplicateCount = 0;
    for (final file in files) {
      final alreadySelected = mergedFiles.any(
        (selected) =>
            selected.name == file.name &&
            selected.bytes.length == file.bytes.length,
      );
      if (alreadySelected) {
        duplicateCount++;
        continue;
      }
      mergedFiles.add(file);
    }

    _selectedFiles = mergedFiles;
    _clearBatchResult();
    _errorMessage = duplicateCount > 0
        ? 'Đã bỏ qua $duplicateCount file trùng trong danh sách chờ gửi.'
        : null;
    _isDragging = false;
    _lastUploadDuration = null;
    _uploadElapsed = Duration.zero;
    notifyListeners();
  }

  Future<void> uploadSelected(String token) async {
    if (_selectedFiles.isEmpty) {
      _errorMessage = 'Vui lòng chọn file DICOM trước khi upload.';
      notifyListeners();
      return;
    }

    _isUploading = true;
    _errorMessage = null;
    _lastUploadDuration = null;
    _startUploadTimer();
    notifyListeners();

    try {
      final uploadingFiles = List<DicomUploadFile>.from(_selectedFiles);
      final result = await remoteDataSource.uploadBatch(
        files: uploadingFiles,
        token: token,
      );
      _tags = result.tags;
      _batchErrors = result.errors;
      _successfulPatients = result.successfulPatients;
      final uploadedAt = DateTime.now();
      for (final file in uploadingFiles.reversed) {
        _uploadedFiles.insert(
          0,
          DicomUploadedFileSessionItem(
            fileName: file.name,
            fileSize: file.bytes.length,
            uploadedAt: uploadedAt,
            duration: _uploadStopwatch.elapsed,
            tagCount: _tags.length,
            successfulPatientCount: _successfulPatients.length,
            errorCount: _batchErrors.length,
            tags: List.unmodifiable(_tags),
            successfulPatients: List.unmodifiable(_successfulPatients),
            errors: List.unmodifiable(_batchErrors),
            batchFileCount: uploadingFiles.length,
          ),
        );
      }
      _selectedFiles = [];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _stopUploadTimer();
      _isUploading = false;
      notifyListeners();
    }
  }

  void removeSelectedFileAt(int index) {
    if (index < 0 || index >= _selectedFiles.length) return;
    final updatedFiles = List<DicomUploadFile>.from(_selectedFiles)
      ..removeAt(index);
    _selectedFiles = updatedFiles;
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _selectedFiles = [];
    _clearBatchResult();
    _errorMessage = null;
    _isDragging = false;
    _lastUploadDuration = null;
    _uploadElapsed = Duration.zero;
    notifyListeners();
  }

  void clearUploadedFiles() {
    _uploadedFiles.clear();
    notifyListeners();
  }

  void _clearBatchResult() {
    _tags = [];
    _batchErrors = [];
    _successfulPatients = [];
  }

  void _startUploadTimer() {
    _uploadTimer?.cancel();
    _uploadStopwatch
      ..reset()
      ..start();
    _uploadElapsed = Duration.zero;
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _uploadElapsed = _uploadStopwatch.elapsed;
      notifyListeners();
    });
  }

  void _stopUploadTimer() {
    _uploadStopwatch.stop();
    _uploadTimer?.cancel();
    _uploadTimer = null;
    _uploadElapsed = _uploadStopwatch.elapsed;
    _lastUploadDuration = _uploadElapsed;
  }

  bool _isDcmFile(String name) => name.toLowerCase().endsWith('.dcm');

  String? _firstInvalidFileName(Iterable<String> names) {
    for (final name in names) {
      if (!_isDcmFile(name)) return name;
    }
    return null;
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }
}

class DicomUploadedFileSessionItem {
  final String fileName;
  final int fileSize;
  final DateTime uploadedAt;
  final Duration duration;
  final int tagCount;
  final int successfulPatientCount;
  final int errorCount;
  final List<DicomTagModel> tags;
  final List<DicomSuccessfulPatientModel> successfulPatients;
  final List<DicomBatchErrorModel> errors;
  final int batchFileCount;

  const DicomUploadedFileSessionItem({
    required this.fileName,
    required this.fileSize,
    required this.uploadedAt,
    required this.duration,
    required this.tagCount,
    required this.successfulPatientCount,
    required this.errorCount,
    required this.tags,
    required this.successfulPatients,
    required this.errors,
    required this.batchFileCount,
  });
}
