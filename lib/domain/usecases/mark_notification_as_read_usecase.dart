import '../interface_repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<void> execute({required int id, required String token}) {
    return repository.markAsRead(id: id, token: token);
  }
}
