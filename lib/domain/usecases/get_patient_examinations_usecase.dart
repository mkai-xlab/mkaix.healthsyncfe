import '../entities/examination_entity.dart';
import '../interface_repositories/examination_repository.dart';

class GetPatientExaminationsUseCase {
  final ExaminationRepository repository;

  GetPatientExaminationsUseCase(this.repository);

  Future<List<ExaminationEntity>> executeAll({required String token}) {
    return repository.getAllExaminations(token: token);
  }

  Future<List<ExaminationEntity>> execute({
    required String patientId,
    required String token,
  }) {
    return repository.getPatientExaminations(
      patientId: patientId,
      token: token,
    );
  }
}
