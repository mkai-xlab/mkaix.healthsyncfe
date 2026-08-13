import '../../data/datasources/dicom_remote_datasource.dart';
import '../interface_repositories/dicom_repository.dart';

class VerifyDicomUploadSessionUseCase {
  final DicomRepository repository;

  VerifyDicomUploadSessionUseCase(this.repository);

  Future<DicomVerifyResponse> execute({
    required String uploadSessionId,
    required List<String> acceptedPatientCodes,
    required String token,
  }) {
    return repository.verifyUploadSession(
      uploadSessionId: uploadSessionId,
      acceptedPatientCodes: acceptedPatientCodes,
      token: token,
    );
  }
}
