import '../entities/examination_entity.dart';
import '../interface_repositories/dicom_repository.dart';

class PredictDicomBatchUseCase {
  final DicomRepository repository;

  PredictDicomBatchUseCase(this.repository);

  Future<List<ExaminationEntity>> execute({
    required List<int> dicomInstanceIds,
    required String token,
  }) {
    return repository.predictBatch(
      dicomInstanceIds: dicomInstanceIds,
      token: token,
    );
  }
}
