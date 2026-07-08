import '../entities/examination_entity.dart';
import '../interface_repositories/examination_repository.dart';

class GetPatientExaminationsUseCase {
  final ExaminationRepository repository;

  GetPatientExaminationsUseCase(this.repository);

  Future<List<ExaminationEntity>> executeDoctor({
    required int doctorId,
    required String token,
  }) {
    return repository.getDoctorExaminations(doctorId: doctorId, token: token);
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
