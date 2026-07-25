import '../entities/examination_entity.dart';
import '../entities/examination_page_entity.dart';

abstract class ExaminationRepository {
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  });

  Future<int> getMyTotalSevereExaminations({required String token});

  Future<List<ExaminationEntity>> getExaminations({required String token});

  Future<List<ExaminationEntity>> getDoctorExaminations({
    required int doctorId,
    required String token,
  });

  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  });
}
