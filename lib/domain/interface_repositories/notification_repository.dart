import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({required String token});

  Future<List<NotificationEntity>> getUnreadNotifications({
    required String token,
  });

  Future<void> markAsRead({required int id, required String token});

  Future<int> markAllAsRead({required String token});
}
