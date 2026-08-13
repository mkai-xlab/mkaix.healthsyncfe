import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/dicom_websocket_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../core/utils/error_message_utils.dart';

class NotificationViewModel extends ChangeNotifier {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadNotificationsUseCase getUnreadNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase;

  NotificationViewModel({
    required this.getNotificationsUseCase,
    required this.getUnreadNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllNotificationsAsReadUseCase,
    DicomWebSocketService? webSocketService,
  }) : webSocketService = webSocketService ?? DicomWebSocketService() {
    _notificationSubscription = this.webSocketService.notifications.listen(
      _handleRealtimeNotification,
    );
  }

  final DicomWebSocketService webSocketService;
  StreamSubscription<DicomUploadNotification>? _notificationSubscription;

  List<NotificationEntity> _notifications = [];
  List<NotificationEntity> get notifications =>
      List.unmodifiable(_notifications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _visibleCount = 10;
  int get visibleCount => _visibleCount;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  List<NotificationEntity> get visibleNotifications =>
      _notifications.take(_visibleCount).toList();

  bool get canShowMore => _visibleCount < _notifications.length;

  Future<void> connectRealtime(String token) async {
    if (token.trim().isEmpty) return;
    try {
      await webSocketService.connect(token);
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      notifyListeners();
    }
  }

  void disconnectRealtime() {
    webSocketService.disconnect();
  }

  void reset() {
    webSocketService.disconnect();
    _notifications = [];
    _visibleCount = 10;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadNotifications(String token) async {
    if (token.trim().isEmpty || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await getNotificationsUseCase.execute(token: token);
      result.sort((a, b) {
        final bTime = b.createdAt ?? DateTime(1900);
        final aTime = a.createdAt ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
      _notifications = result;
      _normalizeVisibleCount();
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadNotifications(String token) =>
      _loadUnreadNotifications(token);

  Future<void> _loadUnreadNotifications(String token) async {
    if (token.trim().isEmpty || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await getUnreadNotificationsUseCase.execute(token: token);
      result.sort((a, b) {
        final bTime = b.createdAt ?? DateTime(1900);
        final aTime = a.createdAt ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
      _notifications = result;
      _normalizeVisibleCount();
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void showMore() {
    if (!canShowMore) return;
    _visibleCount = (_visibleCount + 1).clamp(0, _notifications.length).toInt();
    notifyListeners();
  }

  Future<void> markAsRead({required int id, required String token}) async {
    if (id <= 0 || token.trim().isEmpty) return;
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;

    final previous = _notifications[index];
    _notifications = [
      for (final item in _notifications)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    notifyListeners();

    try {
      await markNotificationAsReadUseCase.execute(id: id, token: token);
    } catch (e) {
      _notifications = [
        for (final item in _notifications)
          if (item.id == id) previous else item,
      ];
      _errorMessage = userFriendlyErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String token) async {
    if (token.trim().isEmpty || unreadCount == 0) return;
    final previous = _notifications;
    _notifications = [
      for (final item in _notifications)
        if (item.isRead) item else item.copyWith(isRead: true),
    ];
    notifyListeners();

    try {
      await markAllNotificationsAsReadUseCase.execute(token: token);
    } catch (e) {
      _notifications = previous;
      _errorMessage = userFriendlyErrorMessage(e);
      notifyListeners();
    }
  }

  void _normalizeVisibleCount() {
    if (_notifications.isEmpty) {
      _visibleCount = 10;
      return;
    }
    if (_visibleCount < 10) _visibleCount = 10;
    if (_visibleCount > _notifications.length) {
      _visibleCount = _notifications.length;
    }
  }

  void _handleRealtimeNotification(DicomUploadNotification notification) {
    final title = notification.title.trim();
    final message = notification.message.trim();
    if (title.isEmpty && message.isEmpty) return;

    final item = NotificationEntity(
      id: DateTime.now().microsecondsSinceEpoch,
      title: title.isEmpty ? 'Thông báo' : title,
      message: message,
      type: notification.type,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notifications = [
      item,
      ..._notifications.where((existing) {
        return existing.title != item.title ||
            existing.message != item.message ||
            existing.type != item.type;
      }),
    ];
    _normalizeVisibleCount();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    webSocketService.dispose();
    super.dispose();
  }
}
