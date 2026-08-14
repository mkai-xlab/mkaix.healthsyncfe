import '../../data/datasources/dicom_remote_datasource.dart';
import '../interface_repositories/dicom_repository.dart';

class FetchDicomUnreadNotificationsUseCase {
  final DicomRepository repository;

  FetchDicomUnreadNotificationsUseCase(this.repository);

  Future<DicomUploadNotificationPollResult> execute({required String token}) {
    return repository.fetchUnreadNotifications(token: token);
  }
}
