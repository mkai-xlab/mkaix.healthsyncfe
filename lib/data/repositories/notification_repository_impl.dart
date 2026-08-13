import '../../domain/entities/notification_entity.dart';
import '../../domain/interface_repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NotificationEntity>> getNotifications({required String token}) {
    return remoteDataSource.getNotifications(token: token);
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications({
    required String token,
  }) {
    return remoteDataSource.getUnreadNotifications(token: token);
  }

  @override
  Future<void> markAsRead({required int id, required String token}) {
    return remoteDataSource.markAsRead(id: id, token: token);
  }

  @override
  Future<int> markAllAsRead({required String token}) {
    return remoteDataSource.markAllAsRead(token: token);
  }
}
