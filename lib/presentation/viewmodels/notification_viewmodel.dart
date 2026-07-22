import 'package:flutter/material.dart';

import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationViewModel(this.remoteDataSource);

  List<NotificationEntity> _notifications = [];
  List<NotificationEntity> get notifications =>
      List.unmodifiable(_notifications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _visibleCount = 10;
  int get visibleCount => _visibleCount;

  int get unreadCount => _notifications.length;

  List<NotificationEntity> get visibleNotifications =>
      _notifications.take(_visibleCount).toList();

  bool get canShowMore => _visibleCount < _notifications.length;

  Future<void> loadUnreadNotifications(String token) async {
    if (token.trim().isEmpty || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await remoteDataSource.getUnreadNotifications(
        token: token,
      );
      result.sort((a, b) {
        final bTime = b.createdAt ?? DateTime(1900);
        final aTime = a.createdAt ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
      _notifications = result;
      _normalizeVisibleCount();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    final removed = _notifications.where((item) => item.id == id).toList();
    _notifications = _notifications.where((item) => item.id != id).toList();
    _normalizeVisibleCount();
    notifyListeners();

    try {
      await remoteDataSource.markAsRead(id: id, token: token);
    } catch (e) {
      _notifications = [...removed, ..._notifications];
      _notifications.sort((a, b) {
        final bTime = b.createdAt ?? DateTime(1900);
        final aTime = a.createdAt ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
}
