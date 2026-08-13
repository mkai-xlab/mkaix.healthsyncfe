import '../entities/notification_entity.dart';
import '../interface_repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationEntity>> execute({required String token}) {
    return repository.getNotifications(token: token);
  }
}
