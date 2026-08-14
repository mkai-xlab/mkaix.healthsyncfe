import '../entities/notification_entity.dart';
import '../interface_repositories/notification_repository.dart';

class GetUnreadNotificationsUseCase {
  final NotificationRepository repository;

  GetUnreadNotificationsUseCase(this.repository);

  Future<List<NotificationEntity>> execute({required String token}) {
    return repository.getUnreadNotifications(token: token);
  }
}
