import '../entities/examination_dashboard_totals_entity.dart';
import '../entities/examination_entity.dart';
import '../entities/examination_page_entity.dart';
import '../entities/patient_grade_stats_entity.dart';

abstract class ExaminationRepository {
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
    bool isPersonal = false,
  });

  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
  });

  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  });

  Future<List<PatientGradeStatsEntity>> getPatientGradeStatistics({
    required String token,
    bool isPersonal = false,
  });

  Future<List<ExaminationEntity>> getExaminations({required String token});

  Future<List<ExaminationEntity>> getDoctorExaminations({
    required int doctorId,
    required String token,
  });

  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  });

  Future<ExaminationPageEntity> getPatientExaminationsPage({
    required String patientId,
    required String token,
    int page = 0,
    int size = 10,
  });

  Future<ExaminationEntity> getExaminationById({
    required int examinationId,
    required String token,
  });

  Future<void> markExaminationViewed({
    required int examinationId,
    required String token,
  });
}
