import 'dart:async';
import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/toast_service.dart';
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
  static const int maxUploadBatchSizeBytes = 100 * 1024 * 1024;
  static const String maxUploadBatchSizeLabel = '100MB';

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

  double? _progress;
  double? get progress => _progress;

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

  bool _isWaitingForBatchResult = false;
  bool get isWaitingForBatchResult => _isWaitingForBatchResult;

  bool _showLongProcessingHint = false;
  bool get showLongProcessingHint => _showLongProcessingHint;

  _PendingBatchResultWait? _activeBatchResultWait;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _uploadStatusMessage;
  String? get uploadStatusMessage => _uploadStatusMessage;

  List<DicomUploadFile> _selectedFiles = [];
  List<DicomUploadFile> get selectedFiles => List.unmodifiable(_selectedFiles);

  int get selectedFilesTotalSizeBytes => _totalFileSizeBytes(_selectedFiles);

  bool get isSelectedBatchOverSizeLimit =>
      selectedFilesTotalSizeBytes > maxUploadBatchSizeBytes;

  bool get canUploadSelected =>
      _selectedFiles.isNotEmpty &&
      !_isUploading &&
      !isSelectedBatchOverSizeLimit;

  bool get hasSelectedZip =>
      _selectedFiles.any((file) => _isZipFile(file.name));

  bool get isZipBatch =>
      _selectedFiles.isNotEmpty &&
      _selectedFiles.every((file) => _isZipFile(file.name));

  List<DicomTagModel> _tags = [];
  List<DicomTagModel> get tags => _tags;

  List<DicomBatchErrorModel> _batchErrors = [];
  List<DicomBatchErrorModel> get batchErrors => List.unmodifiable(_batchErrors);

  List<DicomVerifyResponse> _lastVerifyResponses = [];
  List<DicomVerifyResponse> get lastVerifyResponses =>
      List.unmodifiable(_lastVerifyResponses);

  final List<DicomUploadNotification> _postCompletionNotifications = [];
  List<DicomUploadNotification> get postCompletionNotifications =>
      List.unmodifiable(_postCompletionNotifications);

  String _uploadSessionId = '';
  String get uploadSessionId => _uploadSessionId;

  List<String> _uploadSessionIds = [];
  List<String> get uploadSessionIds => List.unmodifiable(_uploadSessionIds);

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
      acceptedPatientCodesBySession.isNotEmpty &&
      acceptedPatientCodesForVerification.isNotEmpty &&
      verifiedPatientCount > 0;

  List<String> get acceptedPatientCodesForVerification {
    final codes = <String>{};
    for (final patient in _successfulPatients) {
      if (!_verifiedPatientKeys.contains(_patientKey(patient))) continue;
      final code = _patientCode(patient);
      if (code.isNotEmpty) codes.add(code);
    }
    return codes.toList();
  }

  Map<String, List<String>> get acceptedPatientCodesBySession {
    final grouped = <String, Set<String>>{};
    for (final patient in _successfulPatients) {
      if (!_verifiedPatientKeys.contains(_patientKey(patient))) continue;
      final sessionId = patient.uploadSessionId.isNotEmpty
          ? patient.uploadSessionId
          : _uploadSessionId;
      final code = _patientCode(patient);
      if (sessionId.isEmpty || code.isEmpty) continue;
      grouped.putIfAbsent(sessionId, () => <String>{}).add(code);
    }
    return grouped.map((key, value) => MapEntry(key, value.toList()));
  }

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

    if (_totalFileSizeBytes(mergedFiles) > maxUploadBatchSizeBytes) {
      _errorMessage =
          'Tổng dung lượng một lần upload không được vượt quá $maxUploadBatchSizeLabel.';
      notifyListeners();
      return;
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
    _progress = null;
    _uploadStatusMessage = 'Đang kết nối kênh xử lý DICOM...';
    _lastUploadDuration = null;
    _startUploadTimer();
    notifyListeners();

    try {
      final uploadingFiles = List<DicomUploadFile>.from(_selectedFiles);

      try {
        await webSocketService.connect(token);
      } catch (e) {
        throw Exception(
          'Không thể kết nối WebSocket để nhận danh sách bệnh nhân sau upload. Vui lòng thử lại.',
        );
      }

      _uploadStatusMessage = isZipBatch
          ? 'Đang upload ${uploadingFiles.length} file ZIP...'
          : 'Đang upload ${uploadingFiles.length} file DICOM...';
      _progress = null;
      notifyListeners();

      final results = <BatchDicomUploadModel>[];
      if (isZipBatch) {
        for (var index = 0; index < uploadingFiles.length; index++) {
          final file = uploadingFiles[index];
          _uploadStatusMessage =
              'Đang upload ZIP ${index + 1}/${uploadingFiles.length}: ${file.name}';
          _progress = null;
          notifyListeners();
          final result = await _uploadZipAndResolve(file: file, token: token);
          results.add(result);
        }
      } else {
        final result = await _uploadDicomBatchAndResolve(
          files: uploadingFiles,
          token: token,
        );
        results.add(result);
      }

      if (results.isEmpty) {
        throw Exception('Không nhận được kết quả upload DICOM.');
      }

      _applyBatchResults(results, uploadingFiles);
      _selectedFiles = [];
      if (_successfulPatients.isNotEmpty) {
        _stage = DicomUploadStage.waitingVerification;
        _progress = null;
        _uploadStatusMessage = _batchErrors.isEmpty
            ? 'Cần bác sĩ xác nhận danh sách bệnh nhân.'
            : 'Có ${_batchErrors.length} file lỗi, cần xác nhận ${_successfulPatients.length} bệnh nhân hợp lệ.';
      } else {
        _stage = DicomUploadStage.failed;
        _progress = null;
        _errorMessage = _batchErrors.isEmpty
            ? 'Backend đã xử lý xong nhưng không tìm thấy bệnh nhân hoặc ảnh DICOM hợp lệ.'
            : 'Phát hiện ${_batchErrors.length} file lỗi, không có bệnh nhân hợp lệ để xác nhận.';
        _uploadStatusMessage = _errorMessage;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _stage = DicomUploadStage.failed;
      _progress = null;
    } finally {
      _stopUploadTimer();
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<BatchDicomUploadModel> _uploadZipAndResolve({
    required DicomUploadFile file,
    required String token,
  }) async {
    final pendingBatchResult = _startBatchResultWait();
    try {
      final submission = await remoteDataSource.uploadZipBatch(
        file: file,
        token: token,
      );
      return _resolveUploadResult(
        submission: submission,
        pendingBatchResult: pendingBatchResult,
      );
    } catch (_) {
      await pendingBatchResult.cancel();
      rethrow;
    }
  }

  Future<BatchDicomUploadModel> _uploadDicomBatchAndResolve({
    required List<DicomUploadFile> files,
    required String token,
  }) async {
    final pendingBatchResult = _startBatchResultWait();
    try {
      final submission = await remoteDataSource.uploadBatch(
        files: files,
        token: token,
      );
      return _resolveUploadResult(
        submission: submission,
        pendingBatchResult: pendingBatchResult,
      );
    } catch (_) {
      await pendingBatchResult.cancel();
      rethrow;
    }
  }

  Future<BatchDicomUploadModel> _resolveUploadResult({
    required DicomUploadSubmission submission,
    required _PendingBatchResultWait pendingBatchResult,
  }) async {
    var result = submission.result;
    if (submission.accepted) {
      final message = submission.message?.trim();
      _uploadStatusMessage = message?.isNotEmpty == true
          ? 'Upload file thành công. $message Đang chờ WebSocket trả danh sách bệnh nhân...'
          : 'Upload file thành công. Đang chờ WebSocket trả danh sách bệnh nhân...';
      _stage = DicomUploadStage.processing;
      _progress = null;
      _isWaitingForBatchResult = true;
      _showLongProcessingHint = false;
      notifyListeners();
      result = await pendingBatchResult.future;
    } else if (_isEmptyBatchResult(result)) {
      _uploadStatusMessage =
          'Upload file thành công nhưng API chưa có danh sách bệnh nhân. Đang chờ WebSocket...';
      _stage = DicomUploadStage.processing;
      _progress = null;
      _isWaitingForBatchResult = true;
      _showLongProcessingHint = false;
      notifyListeners();
      try {
        final webSocketResult = await pendingBatchResult.future;
        if (!_isEmptyBatchResult(webSocketResult)) {
          result = webSocketResult;
        }
      } catch (_) {
        await pendingBatchResult.cancel();
      }
    } else {
      await pendingBatchResult.cancel();
    }

    if (result == null) {
      throw Exception('Không nhận được kết quả upload DICOM.');
    }
    _isWaitingForBatchResult = false;
    _showLongProcessingHint = false;
    _activeBatchResultWait = null;
    return result;
  }

  _PendingBatchResultWait _startBatchResultWait() {
    final completer = Completer<BatchDicomUploadModel>();
    Timer? longProcessingTimer;

    void completeFrom(String source, BatchDicomUploadModel result) {
      if (completer.isCompleted) return;
      debugPrint(
        '[DICOM batch result resolved] source=$source, '
        'patients=${result.successfulPatients.length}, '
        'errors=${result.errors.length}',
      );
      longProcessingTimer?.cancel();
      _isWaitingForBatchResult = false;
      _showLongProcessingHint = false;
      _activeBatchResultWait = null;
      completer.complete(result);
    }

    void completeError(String message) {
      if (completer.isCompleted) return;
      debugPrint('[DICOM batch result resolved] error=$message');
      longProcessingTimer?.cancel();
      _isWaitingForBatchResult = false;
      _showLongProcessingHint = false;
      _activeBatchResultWait = null;
      completer.completeError(Exception(message));
      webSocketService.cancelPendingBatchResultWait();
    }

    webSocketService.waitForNextBatchResult().then(
      (result) => completeFrom('websocket', result),
      onError: (Object error) {
        debugPrint('[DICOM WebSocket wait] ignored error: $error');
      },
    );

    longProcessingTimer = Timer(const Duration(seconds: 60), () {
      if (completer.isCompleted) return;
      _showLongProcessingHint = true;
      _uploadStatusMessage =
          'Upload đã được tiếp nhận. Frontend đang chờ DICOM_BATCH_RESULT từ WebSocket.';
      notifyListeners();
    });

    final wait = _PendingBatchResultWait(
      future: completer.future.whenComplete(() {
        longProcessingTimer?.cancel();
      }),
      cancel: () async {
        longProcessingTimer?.cancel();
        _activeBatchResultWait = null;
        await webSocketService.cancelPendingBatchResultWait();
      },
      fail: completeError,
    );
    _activeBatchResultWait = wait;
    return wait;
  }

  void _applyBatchResults(
    List<BatchDicomUploadModel> results,
    List<DicomUploadFile> uploadingFiles,
  ) {
    final combined = BatchDicomUploadModel(
      uploadSessionId: results
          .map((result) => result.uploadSessionId)
          .where((id) => id.isNotEmpty)
          .join(','),
      tags: results.expand((result) => result.tags).toList(),
      errors: results.expand((result) => result.errors).toList(),
      successfulPatients: results
          .expand((result) => result.successfulPatients)
          .toList(),
      raw: {'results': results.map((result) => result.raw).toList()},
    );
    _applyBatchResult(combined, uploadingFiles);
  }

  Future<void> verifyPatients(String token) async {
    final groupedCodes = acceptedPatientCodesBySession;
    if (groupedCodes.isEmpty) {
      _errorMessage = 'Không tìm thấy uploadSessionId để xác nhận.';
      notifyListeners();
      return;
    }
    if (acceptedPatientCodesForVerification.isEmpty) {
      _errorMessage = 'Vui lòng chọn ít nhất 1 bệnh nhân để xác nhận.';
      notifyListeners();
      return;
    }

    _isUploading = true;
    _errorMessage = null;
    _uploadStatusMessage = 'Đang xác nhận danh sách bệnh nhân...';
    _lastVerifyResponses = [];
    notifyListeners();

    try {
      final verifyResponses = <DicomVerifyResponse>[];
      for (final entry in groupedCodes.entries) {
        final response = await remoteDataSource.verifyUploadSession(
          uploadSessionId: entry.key,
          acceptedPatientCodes: entry.value,
          token: token,
        );
        verifyResponses.add(response);
      }
      _lastVerifyResponses = verifyResponses;
      await _activeBatchResultWait?.cancel();
      _activeBatchResultWait = null;
      await webSocketService.cancelPendingBatchResultWait();
      _stage = DicomUploadStage.completed;
      _progress = null;
      _uploadStatusMessage = 'Đã xác nhận $verifiedPatientCount bệnh nhân.';
      _stopUploadTimer();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  String? _validateSelectedFiles() {
    if (_selectedFiles.any((file) => !_isSupportedFile(file.name))) {
      return 'Chỉ hỗ trợ file .dcm hoặc .zip.';
    }

    if (_totalFileSizeBytes(_selectedFiles) > maxUploadBatchSizeBytes) {
      return 'Tổng dung lượng một lần upload không được vượt quá $maxUploadBatchSizeLabel.';
    }

    final hasZip = _selectedFiles.any((file) => _isZipFile(file.name));
    final hasDcm = _selectedFiles.any((file) => _isDcmFile(file.name));
    if (hasZip && hasDcm) {
      return 'Không upload lẫn file ZIP và DICOM trong cùng một lượt.';
    }
    return null;
  }

  void _applyBatchResult(
    BatchDicomUploadModel result,
    List<DicomUploadFile> uploadingFiles,
  ) {
    _uploadSessionId = result.uploadSessionId;
    _uploadSessionIds = result.successfulPatients
        .map((patient) => patient.uploadSessionId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (_uploadSessionIds.isEmpty && _uploadSessionId.isNotEmpty) {
      _uploadSessionIds = _uploadSessionId
          .split(',')
          .where((id) => id.trim().isNotEmpty)
          .map((id) => id.trim())
          .toList();
    }
    _tags = result.tags;
    _batchErrors = result.errors;
    _successfulPatients = result.successfulPatients;
    _verifiedPatientKeys
      ..clear()
      ..addAll(_successfulPatients.map(_patientKey));
    debugPrint(
      '[DICOM upload viewmodel batch] '
      'session=$_uploadSessionId, '
      'patients=${_successfulPatients.length}, '
      'errors=${_batchErrors.length}, '
      'dicomInstanceCount=${dicomInstanceIdsForVerification.length}',
    );
    _showBatchSuccessToast();
    _showBatchErrorToast();
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

  void _showBatchSuccessToast() {
    if (_successfulPatients.isEmpty) return;

    final patientCount = _successfulPatients.length;
    final errorSuffix = _batchErrors.isEmpty
        ? ''
        : ', ${_batchErrors.length} file lỗi';
    AppToast.showSuccess(
      'Đã xử lý $patientCount bệnh nhân$errorSuffix. Vui lòng xác nhận danh sách.',
      title: 'Upload DICOM thành công',
    );
  }

  void _showBatchErrorToast() {
    if (_batchErrors.isEmpty) return;

    final firstError = _batchErrors.first;
    final filename = firstError.filename.trim();
    final reason = firstError.errorReason.trim();
    final detail = [
      if (filename.isNotEmpty) filename,
      if (reason.isNotEmpty) reason,
    ].join(': ');
    final message = [
      '${_batchErrors.length} file DICOM bị lỗi.',
      if (detail.isNotEmpty) detail,
    ].join('\n');

    if (_successfulPatients.isEmpty) {
      AppToast.showError(message, title: 'Upload DICOM thất bại');
      return;
    }

    AppToast.showWarning(message, title: 'Upload DICOM có file lỗi');
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
    _progress = null;
    _uploadStatusMessage = null;
    _isWaitingForBatchResult = false;
    _showLongProcessingHint = false;
    _activeBatchResultWait?.cancel();
    _activeBatchResultWait = null;
    notifyListeners();
  }

  void clearUploadedFiles() {
    _uploadedFiles.clear();
    notifyListeners();
  }

  void _clearBatchResult() {
    _tags = [];
    _batchErrors = [];
    _uploadSessionId = '';
    _uploadSessionIds = [];
    _successfulPatients = [];
    _verifiedPatientKeys.clear();
    _uploadStatusMessage = null;
    _isWaitingForBatchResult = false;
    _showLongProcessingHint = false;
  }

  String _patientCode(DicomSuccessfulPatientModel patient) {
    final summary = patient.patient;
    if (summary.patientCode.isNotEmpty) return summary.patientCode;
    if (summary.patientId.isNotEmpty) return summary.patientId;
    if (summary.id > 0) return summary.id.toString();
    return '';
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

    final uploadFlowClosed =
        _stage == DicomUploadStage.completed ||
        _stage == DicomUploadStage.failed;
    if (uploadFlowClosed) {
      _postCompletionNotifications.add(notification);
      if (message.isNotEmpty) {
        _showWebSocketToast(notification, title, message);
      }
      notifyListeners();
      return;
    }

    if (message.isNotEmpty) {
      _showWebSocketToast(notification, title, message);
    }

    if (notification.type == 'DICOM_BATCH_RESULT') {
      _uploadStatusMessage =
          'Upload DICOM thành công, đang chuẩn bị danh sách xác nhận.';
    } else if (notification.type == 'SYSTEM' &&
        title == 'DICOM Upload Complete' &&
        message.contains('Session:')) {
      _errorMessage =
          'Backend báo hoàn tất upload nhưng không trả danh sách bệnh nhân. Vui lòng kiểm tra backend serialize/Redis.';
      _stage = DicomUploadStage.failed;
      _progress = null;
      _activeBatchResultWait?.fail(
        'Backend báo hoàn tất upload nhưng không trả danh sách bệnh nhân. Vui lòng kiểm tra backend serialize/Redis.',
      );
    } else {
      _uploadStatusMessage = [
        if (title.isNotEmpty) title,
        if (message.isNotEmpty) message,
      ].join(': ');
    }
    final hasActiveUploadWait =
        _isUploading ||
        _isWaitingForBatchResult ||
        _activeBatchResultWait != null;
    if ((_stage == DicomUploadStage.uploading ||
            _stage == DicomUploadStage.idle) &&
        hasActiveUploadWait) {
      _stage = DicomUploadStage.processing;
      _progress = null;
    }
    notifyListeners();
  }

  void _showWebSocketToast(
    DicomUploadNotification notification,
    String title,
    String message,
  ) {
    final (displayTitle, displayMessage) = _cleanNotificationToast(
      title,
      message,
    );
    if (displayMessage.isEmpty) return;

    switch (notification.type) {
      case 'ERROR':
        AppToast.showError(displayMessage, title: displayTitle);
      case 'AI_RESULT':
      case 'DICOM_BATCH_RESULT':
        AppToast.showSuccess(displayMessage, title: displayTitle);
      case 'SYSTEM':
        AppToast.showInfo(displayMessage, title: displayTitle);
      default:
        AppToast.showInfo(displayMessage, title: displayTitle);
    }
  }

  (String, String) _cleanNotificationToast(String title, String message) {
    var cleaned = message.trim();
    var cleanedTitle = title.trim();
    final decoded = _tryDecodeJsonMap(cleaned);
    if (decoded != null) {
      cleanedTitle = (decoded['title']?.toString().trim().isNotEmpty ?? false)
          ? decoded['title'].toString().trim()
          : cleanedTitle;
      cleaned = decoded['message']?.toString().trim() ?? cleaned;
    }

    final prefixedMessage = RegExp(
      r'^message\s*:\s*"?([\s\S]*?)"?$',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (prefixedMessage != null) {
      cleaned = prefixedMessage.group(1)?.trim() ?? '';
    }
    return (cleanedTitle, cleaned);
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
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

  int _totalFileSizeBytes(List<DicomUploadFile> files) {
    return files.fold<int>(0, (sum, file) => sum + file.bytes.length);
  }

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
    _activeBatchResultWait?.cancel();
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

class _PendingBatchResultWait {
  final Future<BatchDicomUploadModel> future;
  final Future<void> Function() cancel;
  final void Function(String message) fail;

  const _PendingBatchResultWait({
    required this.future,
    required this.cancel,
    required this.fail,
  });
}
