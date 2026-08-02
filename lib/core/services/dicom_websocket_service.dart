import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../data/models/dicom_upload_model.dart';
import '../constants/api_constants.dart';

class DicomUploadNotification {
  final String type;
  final String title;
  final String message;
  final Object? data;

  const DicomUploadNotification({
    required this.type,
    required this.title,
    required this.message,
    this.data,
  });
}

class DicomWebSocketService {
  StompClient? _client;
  Completer<void>? _connectCompleter;
  StreamSubscription<BatchDicomUploadModel>? _resultSubscription;
  BatchDicomUploadModel? _pendingBatchResult;

  final StreamController<DicomUploadNotification> _notificationController =
      StreamController<DicomUploadNotification>.broadcast();
  final StreamController<BatchDicomUploadModel> _batchResultController =
      StreamController<BatchDicomUploadModel>.broadcast();

  Stream<DicomUploadNotification> get notifications =>
      _notificationController.stream;

  Future<void> connect(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Không tìm thấy token đăng nhập để kết nối WebSocket.');
    }

    if (_client != null && _connectCompleter == null) return;
    if (_connectCompleter != null) return _connectCompleter!.future;

    final completer = Completer<void>();
    _connectCompleter = completer;

    _client = StompClient(
      config: StompConfig(
        url: ApiConstants.webSocketUrl,
        stompConnectHeaders: _authHeaders(token),
        webSocketConnectHeaders: _authHeaders(token),
        onConnect: (frame) {
          debugPrint(
            '[DICOM WebSocket] connected: ${ApiConstants.webSocketUrl}',
          );
          _client?.subscribe(
            destination: '/user/queue/notifications',
            callback: _handleNotificationFrame,
          );
          debugPrint('[DICOM WebSocket] subscribed: /user/queue/notifications');
          if (!completer.isCompleted) completer.complete();
          _connectCompleter = null;
        },
        onWebSocketError: (error) {
          debugPrint('[DICOM WebSocket] error: $error');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Không thể kết nối WebSocket: $error'),
            );
          }
          _connectCompleter = null;
        },
        onStompError: (frame) {
          debugPrint('[DICOM WebSocket] stomp error: ${frame.body}');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Lỗi STOMP: ${frame.body ?? 'Không rõ lỗi'}'),
            );
          }
          _connectCompleter = null;
        },
      ),
    );

    _client?.activate();
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _connectCompleter = null;
        throw Exception('Kết nối WebSocket quá thời gian.');
      },
    );
  }

  Future<BatchDicomUploadModel> waitForNextBatchResult() {
    final pendingResult = _pendingBatchResult;
    if (pendingResult != null) {
      _pendingBatchResult = null;
      return Future.value(pendingResult);
    }

    final completer = Completer<BatchDicomUploadModel>();
    _resultSubscription?.cancel();
    _resultSubscription = _batchResultController.stream.listen((result) {
      if (!completer.isCompleted) completer.complete(result);
    });

    return completer.future.whenComplete(() {
      _resultSubscription?.cancel();
      _resultSubscription = null;
    });
  }

  Future<void> cancelPendingBatchResultWait() async {
    await _resultSubscription?.cancel();
    _resultSubscription = null;
  }

  void disconnect() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _client?.deactivate();
    _client = null;
    _connectCompleter = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _batchResultController.close();
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  void _handleNotificationFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.trim().isEmpty) return;

    debugPrint('[DICOM WebSocket raw frame] $body', wrapWidth: 1024);

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);
      final type = payload['type']?.toString() ?? '';
      final title = payload['title']?.toString() ?? '';
      final message = payload['message']?.toString() ?? '';
      final directBatchPayload = _looksLikeBatchResult(payload)
          ? payload
          : null;
      debugPrint(
        type == 'DICOM_BATCH_RESULT' || directBatchPayload != null
            ? '[DICOM WebSocket frame] type=DICOM_BATCH_RESULT, title=$title'
            : '[DICOM WebSocket frame] type=$type, title=$title, message=$message',
      );

      _notificationController.add(
        DicomUploadNotification(
          type: type,
          title: title,
          message: message,
          data: payload['data'],
        ),
      );

      final isUploadCompleteNotification = title.startsWith(
        'DICOM Upload Complete',
      );
      if (type == 'DICOM_BATCH_RESULT' ||
          directBatchPayload != null ||
          isUploadCompleteNotification) {
        final resultPayload =
            directBatchPayload ??
            _decodeBatchPayload(payload['data']) ??
            _decodeBatchPayload(payload['message']);
        if (resultPayload != null) {
          final result = BatchDicomUploadModel.fromJson(resultPayload);
          debugPrint(
            '[DICOM WebSocket parsed batch] '
            'patients=${result.successfulPatients.length}, '
            'errors=${result.errors.length}',
          );
          if (!_batchResultController.hasListener) {
            _pendingBatchResult = result;
          }
          _batchResultController.add(result);
        } else if (type == 'DICOM_BATCH_RESULT' ||
            isUploadCompleteNotification) {
          debugPrint(
            '[DICOM WebSocket parse] batch notification has no parsable '
            'payload. title=$title, type=$type',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[DICOM WebSocket parse] failed: $e');
      debugPrint('$stackTrace');
      _notificationController.add(
        DicomUploadNotification(
          type: 'SYSTEM',
          title: 'Thông báo DICOM',
          message: body,
        ),
      );
    }
  }

  Map<String, dynamic>? _decodeBatchPayload(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          return _looksLikeBatchResult(map) ? map : null;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _looksLikeBatchResult(Map<String, dynamic> payload) {
    return payload.containsKey('successfulPatients') ||
        payload.containsKey('successful_patients') ||
        payload.containsKey('uploadSessionId') ||
        payload.containsKey('upload_session_id') ||
        payload.containsKey('errors');
  }
}
