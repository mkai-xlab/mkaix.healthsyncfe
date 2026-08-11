import '../entities/examination_dashboard_totals_entity.dart';
import '../entities/daily_examination_stat_entity.dart';
import '../entities/examination_entity.dart';
import '../entities/examination_page_entity.dart';
import '../entities/patient_grade_stats_entity.dart';
import '../interface_repositories/examination_repository.dart';

class GetPatientExaminationsUseCase {
  final ExaminationRepository repository;

  GetPatientExaminationsUseCase(this.repository);

  Future<List<ExaminationEntity>> executeAll({required String token}) {
    return repository.getExaminations(token: token);
  }

  Future<ExaminationPageEntity> executeAllPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
    bool isPersonal = false,
  }) {
    return repository.getExaminationsPage(
      token: token,
      page: page,
      size: size,
      mode: mode,
      direction: direction,
      date: date,
      isPersonal: isPersonal,
    );
  }

  Future<ExaminationDashboardTotalsEntity> executeMyDashboardTotals({
    required String token,
  }) {
    return repository.getMyDashboardTotals(token: token);
  }

  Future<ExaminationPageEntity> executeMyRecentPage({
    required String token,
    int page = 0,
    int size = 10,
  }) {
    return repository.getMyRecentExaminationsPage(
      token: token,
      page: page,
      size: size,
    );
  }

  Future<List<PatientGradeStatsEntity>> executePatientGradeStatistics({
    required String token,
    bool isPersonal = false,
  }) {
    return repository.getPatientGradeStatistics(
      token: token,
      isPersonal: isPersonal,
    );
  }

  Future<List<DailyExaminationStatEntity>> executeDailyLast7DaysStatistics({
    required String token,
    bool isPersonal = false,
  }) {
    return repository.getDailyLast7DaysStatistics(
      token: token,
      isPersonal: isPersonal,
    );
  }

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

  Future<ExaminationPageEntity> executePatientPage({
    required String patientId,
    required String token,
    int page = 0,
    int size = 10,
  }) {
    return repository.getPatientExaminationsPage(
      patientId: patientId,
      token: token,
      page: page,
      size: size,
    );
  }

  Future<ExaminationEntity> executeDetail({
    required int examinationId,
    required String token,
  }) {
    return repository.getExaminationById(
      examinationId: examinationId,
      token: token,
    );
  }

  Future<void> executeMarkViewed({
    required int examinationId,
    required String token,
  }) {
    return repository.markExaminationViewed(
      examinationId: examinationId,
      token: token,
    );
  }
}
