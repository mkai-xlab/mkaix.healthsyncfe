import '../entities/examination_entity.dart';

abstract class ExaminationRepository {
  Future<List<ExaminationEntity>> getAllExaminations({required String token});

  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  });
}
