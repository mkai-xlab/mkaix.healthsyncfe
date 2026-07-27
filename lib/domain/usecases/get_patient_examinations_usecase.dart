import '../entities/examination_dashboard_totals_entity.dart';
import '../entities/examination_entity.dart';
import '../entities/examination_page_entity.dart';
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
  }) {
    return repository.getExaminationsPage(
      token: token,
      page: page,
      size: size,
      mode: mode,
      direction: direction,
      date: date,
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
