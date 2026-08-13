import '../../data/datasources/dicom_remote_datasource.dart';
import '../interface_repositories/dicom_repository.dart';

class UploadDicomZipBatchUseCase {
  final DicomRepository repository;

  UploadDicomZipBatchUseCase(this.repository);

  Future<DicomUploadSubmission> execute({
    required List<DicomUploadFile> files,
    required String token,
  }) {
    return repository.uploadZipBatch(files: files, token: token);
  }
}
