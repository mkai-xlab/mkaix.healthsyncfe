import '../interface_repositories/notification_repository.dart';

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUseCase(this.repository);

  Future<int> execute({required String token}) {
    return repository.markAllAsRead(token: token);
  }
}
