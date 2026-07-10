import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/dicom_websocket_service.dart';
import '../../data/datasources/dicom_remote_datasource.dart';
import '../../data/models/dicom_upload_model.dart';

enum DicomUploadStage {
  idle,
  uploading,
  processing,
  waitingVerification,
  completed,
  failed,
}

class DicomUploadViewModel extends ChangeNotifier {
  final DicomRemoteDataSource remoteDataSource;
  final DicomWebSocketService webSocketService;

  DicomUploadViewModel(
    this.remoteDataSource, {
    DicomWebSocketService? webSocketService,
  }) : webSocketService = webSocketService ?? DicomWebSocketService() {
    _notificationSubscription = this.webSocketService.notifications.listen(
      _handleUploadNotification,
    );
  }

  StreamSubscription<DicomUploadNotification>? _notificationSubscription;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  DicomUploadStage _stage = DicomUploadStage.idle;
  DicomUploadStage get stage => _stage;

  double _progress = 0;
  double get progress => _progress;

  bool get isProcessActive =>
      _stage != DicomUploadStage.idle &&
      _stage != DicomUploadStage.completed &&
      _stage != DicomUploadStage.failed;

  final Stopwatch _uploadStopwatch = Stopwatch();
  Timer? _uploadTimer;

  Duration _uploadElapsed = Duration.zero;
  Duration get uploadElapsed => _uploadElapsed;

  Duration? _lastUploadDuration;
  Duration? get lastUploadDuration => _lastUploadDuration;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _uploadStatusMessage;
  String? get uploadStatusMessage => _uploadStatusMessage;

  List<DicomUploadFile> _selectedFiles = [];
  List<DicomUploadFile> get selectedFiles => List.unmodifiable(_selectedFiles);

  bool get isZipBatch =>
      _selectedFiles.length == 1 && _isZipFile(_selectedFiles.first.name);

  bool get hasSelectedZip =>
      _selectedFiles.any((file) => _isZipFile(file.name));

  List<DicomTagModel> _tags = [];
  List<DicomTagModel> get tags => _tags;

  List<DicomBatchErrorModel> _batchErrors = [];
  List<DicomBatchErrorModel> get batchErrors => List.unmodifiable(_batchErrors);

  List<DicomSuccessfulPatientModel> _successfulPatients = [];
  List<DicomSuccessfulPatientModel> get successfulPatients =>
      List.unmodifiable(_successfulPatients);

  final Set<String> _verifiedPatientKeys = {};
  Set<String> get verifiedPatientKeys => Set.unmodifiable(_verifiedPatientKeys);

  int get verifiedPatientCount => _successfulPatients
      .where((patient) => _verifiedPatientKeys.contains(_patientKey(patient)))
      .length;

  List<int> get dicomInstanceIdsForVerification {
    final ids = <int>{};
    for (final patient in _successfulPatients) {
      if (!_verifiedPatientKeys.contains(_patientKey(patient))) continue;
      for (final examination in patient.recentExaminations) {
        for (final image in examination.images) {
          if (image.dicomInstanceId > 0) {
            ids.add(image.dicomInstanceId);
          }
        }
      }
    }
    return ids.toList();
  }

  bool get canVerifyPatients =>
      _stage == DicomUploadStage.waitingVerification &&
      dicomInstanceIdsForVerification.isNotEmpty &&
      verifiedPatientCount > 0;

  bool isPatientVerified(DicomSuccessfulPatientModel patient) {
    return _verifiedPatientKeys.contains(_patientKey(patient));
  }

  bool get areAllPatientsVerified =>
      _successfulPatients.isNotEmpty &&
      _successfulPatients.every(
        (patient) => _verifiedPatientKeys.contains(_patientKey(patient)),
      );

  void setPatientVerified(DicomSuccessfulPatientModel patient, bool value) {
    final key = _patientKey(patient);
    if (value) {
      _verifiedPatientKeys.add(key);
    } else {
      _verifiedPatientKeys.remove(key);
    }
    notifyListeners();
  }

  void setAllPatientsVerified(bool value) {
    _verifiedPatientKeys.clear();
    if (value) {
      _verifiedPatientKeys.addAll(_successfulPatients.map(_patientKey));
    }
    notifyListeners();
  }

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
      allowedExtensions: const ['dcm', 'zip'],
    );
    if (result == null) return;

    final invalidFile = _firstInvalidFileName(
      result.files.map((file) => file.name),
    );
    if (invalidFile != null) {
      _errorMessage = 'Chỉ hỗ trợ file .dcm hoặc .zip.';
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
      _errorMessage = 'Chỉ hỗ trợ file .dcm hoặc .zip.';
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

    if (files.any((file) => !_isSupportedFile(file.name))) {
      _errorMessage = 'Chỉ hỗ trợ file .dcm hoặc .zip.';
      notifyListeners();
      return;
    }

    final mergedFiles = List<DicomUploadFile>.from(_selectedFiles);
    final hasZip =
        mergedFiles.any((file) => _isZipFile(file.name)) ||
        files.any((file) => _isZipFile(file.name));
    final hasDcm =
        mergedFiles.any((file) => _isDcmFile(file.name)) ||
        files.any((file) => _isDcmFile(file.name));

    if (hasZip && hasDcm) {
      _errorMessage = 'Không upload lẫn file ZIP và DICOM trong cùng một lượt.';
      notifyListeners();
      return;
    }

    final zipCount = [
      ...mergedFiles,
      ...files,
    ].where((file) => _isZipFile(file.name)).length;
    if (zipCount > 1) {
      _errorMessage = 'Mỗi lượt chỉ upload một file ZIP.';
      notifyListeners();
      return;
    }

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
      _errorMessage = 'Vui lòng chọn file DICOM hoặc ZIP trước khi upload.';
      notifyListeners();
      return;
    }

    final validationError = _validateSelectedFiles();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isUploading = true;
    _errorMessage = null;
    _stage = DicomUploadStage.uploading;
    _progress = 0.10;
    _uploadStatusMessage = 'Đang kết nối kênh xử lý DICOM...';
    _lastUploadDuration = null;
    _startUploadTimer();
    notifyListeners();

    try {
      final uploadingFiles = List<DicomUploadFile>.from(_selectedFiles);

      var webSocketReady = false;
      Future<BatchDicomUploadModel>? webSocketResultFuture;
      try {
        await webSocketService.connect(token);
        webSocketReady = true;
        webSocketResultFuture = webSocketService.waitForNextBatchResult();
      } catch (e) {
        _uploadStatusMessage =
            'Chưa kết nối được WebSocket, đang chờ phản hồi trực tiếp từ API.';
        notifyListeners();
      }

      _uploadStatusMessage = isZipBatch
          ? 'Đang upload file ZIP...'
          : 'Đang upload ${uploadingFiles.length} file DICOM...';
      _progress = 0.18;
      notifyListeners();

      final submission = isZipBatch
          ? await remoteDataSource.uploadZipBatch(
              file: uploadingFiles.first,
              token: token,
            )
          : await remoteDataSource.uploadBatch(
              files: uploadingFiles,
              token: token,
            );

      var result = submission.result;
      if (submission.accepted) {
        if (!webSocketReady) {
          throw Exception(
            'Backend đã tiếp nhận file nhưng WebSocket chưa kết nối được để nhận kết quả xử lý.',
          );
        }
        _uploadStatusMessage = submission.message?.trim().isNotEmpty == true
            ? submission.message
            : 'Backend đã nhận file, đang chờ kết quả xử lý...';
        _stage = DicomUploadStage.processing;
        _progress = 0.45;
        notifyListeners();
        result = await webSocketResultFuture;
      } else if (_isEmptyBatchResult(result) && webSocketResultFuture != null) {
        _uploadStatusMessage =
            'API đã trả kết quả rỗng, đang kiểm tra thêm phản hồi WebSocket...';
        _stage = DicomUploadStage.processing;
        _progress = 0.55;
        notifyListeners();
        try {
          final webSocketResult = await webSocketResultFuture;
          if (!_isEmptyBatchResult(webSocketResult)) {
            result = webSocketResult;
          }
        } catch (_) {
          await webSocketService.cancelPendingBatchResultWait();
          // Giữ kết quả HTTP nếu quá trình chờ WebSocket bị hủy hoặc kết nối lỗi.
        }
      } else {
        await webSocketService.cancelPendingBatchResultWait();
      }

      if (result == null) {
        throw Exception('Không nhận được kết quả upload DICOM.');
      }

      _applyBatchResult(result, uploadingFiles);
      _selectedFiles = [];
      if (_successfulPatients.isNotEmpty) {
        _stage = DicomUploadStage.waitingVerification;
        _progress = 0.85;
        _uploadStatusMessage = _batchErrors.isEmpty
            ? 'Cần bác sĩ xác nhận danh sách bệnh nhân.'
            : 'Có ${_batchErrors.length} file lỗi, cần xác nhận ${_successfulPatients.length} bệnh nhân hợp lệ.';
      } else {
        _stage = DicomUploadStage.failed;
        _progress = 0;
        _errorMessage = _batchErrors.isEmpty
            ? 'Backend đã xử lý xong nhưng không tìm thấy bệnh nhân hoặc ảnh DICOM hợp lệ.'
            : 'Phát hiện ${_batchErrors.length} file lỗi, không có bệnh nhân hợp lệ để xác nhận.';
        _uploadStatusMessage = _errorMessage;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _stage = DicomUploadStage.failed;
      _progress = 0;
    } finally {
      _stopUploadTimer();
      _isUploading = false;
      notifyListeners();
    }
  }

  void verifyPatients() {
    final ids = dicomInstanceIdsForVerification;
    if (ids.isEmpty) {
      _errorMessage = 'Không tìm thấy dicomInstanceId để xác nhận.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _stage = DicomUploadStage.completed;
    _progress = 1;
    _uploadStatusMessage = 'Đã xác nhận $verifiedPatientCount bệnh nhân.';
    _stopUploadTimer();
    notifyListeners();
  }

  String? _validateSelectedFiles() {
    if (_selectedFiles.any((file) => !_isSupportedFile(file.name))) {
      return 'Chỉ hỗ trợ file .dcm hoặc .zip.';
    }

    final hasZip = _selectedFiles.any((file) => _isZipFile(file.name));
    final hasDcm = _selectedFiles.any((file) => _isDcmFile(file.name));
    if (hasZip && hasDcm) {
      return 'Không upload lẫn file ZIP và DICOM trong cùng một lượt.';
    }
    if (hasZip && _selectedFiles.length > 1) {
      return 'Mỗi lượt chỉ upload một file ZIP.';
    }
    return null;
  }

  void _applyBatchResult(
    BatchDicomUploadModel result,
    List<DicomUploadFile> uploadingFiles,
  ) {
    _tags = result.tags;
    _batchErrors = result.errors;
    _successfulPatients = result.successfulPatients;
    _verifiedPatientKeys
      ..clear()
      ..addAll(_successfulPatients.map(_patientKey));
    debugPrint(
      '[DICOM upload viewmodel batch] '
      'patients=${_successfulPatients.length}, '
      'errors=${_batchErrors.length}, '
      'dicomInstanceCount=${dicomInstanceIdsForVerification.length}',
    );
    if (_successfulPatients.isEmpty) {
      _uploadStatusMessage =
          'Backend đã trả kết quả nhưng chưa có bệnh nhân cần xác nhận.';
    }
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
  }

  bool _isEmptyBatchResult(BatchDicomUploadModel? result) {
    return result != null &&
        result.successfulPatients.isEmpty &&
        result.errors.isEmpty;
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
    _stage = DicomUploadStage.idle;
    _progress = 0;
    _uploadStatusMessage = null;
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
    _verifiedPatientKeys.clear();
    _uploadStatusMessage = null;
  }

  String _patientKey(DicomSuccessfulPatientModel patient) {
    final summary = patient.patient;
    final patientIdentity = summary.id > 0
        ? 'id:${summary.id}'
        : summary.patientCode.isNotEmpty
        ? 'code:${summary.patientCode}'
        : summary.patientId.isNotEmpty
        ? 'patient:${summary.patientId}'
        : 'name:${summary.fullName}';
    final examinationIdentity = patient.recentExaminations
        .map((examination) {
          if (examination.examinationId > 0) {
            return examination.examinationId;
          }
          if (examination.encounterCode.isNotEmpty) {
            return examination.encounterCode;
          }
          return examination.images
              .map((image) => image.dicomInstanceId)
              .join(',');
        })
        .join('|');
    return '$patientIdentity::$examinationIdentity';
  }

  void _handleUploadNotification(DicomUploadNotification notification) {
    final title = notification.title.trim();
    final message = notification.message.trim();
    if (title.isEmpty && message.isEmpty) return;

    if (notification.type == 'DICOM_BATCH_RESULT') {
      _uploadStatusMessage =
          'Upload DICOM thành công, đang chuẩn bị danh sách xác nhận.';
    } else {
      _uploadStatusMessage = [
        if (title.isNotEmpty) title,
        if (message.isNotEmpty) message,
      ].join(': ');
    }
    if (_stage == DicomUploadStage.uploading ||
        _stage == DicomUploadStage.idle) {
      _stage = DicomUploadStage.processing;
      _progress = _progress < 0.45 ? 0.45 : _progress;
    }
    notifyListeners();
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

  bool _isZipFile(String name) => name.toLowerCase().endsWith('.zip');

  bool _isSupportedFile(String name) => _isDcmFile(name) || _isZipFile(name);

  String? _firstInvalidFileName(Iterable<String> names) {
    for (final name in names) {
      if (!_isSupportedFile(name)) return name;
    }
    return null;
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _notificationSubscription?.cancel();
    webSocketService.dispose();
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
