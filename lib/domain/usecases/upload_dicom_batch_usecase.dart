import '../../data/datasources/dicom_remote_datasource.dart';
import '../interface_repositories/dicom_repository.dart';

class UploadDicomBatchUseCase {
  final DicomRepository repository;

  UploadDicomBatchUseCase(this.repository);

  Future<DicomUploadSubmission> execute({
    required List<DicomUploadFile> files,
    required String token,
  }) {
    return repository.uploadBatch(files: files, token: token);
  }
}
