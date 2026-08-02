import '../../domain/entities/examination_dashboard_totals_entity.dart';
import '../../domain/entities/examination_entity.dart';
import '../../domain/entities/examination_page_entity.dart';
import '../../domain/entities/patient_grade_stats_entity.dart';
import '../../domain/interface_repositories/examination_repository.dart';
import '../datasources/examination_remote_datasource.dart';

class ExaminationRepositoryImpl implements ExaminationRepository {
  final ExaminationRemoteDataSource remoteDataSource;

  ExaminationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
  }) {
    return remoteDataSource.getExaminationsPage(
      token: token,
      page: page,
      size: size,
      mode: mode,
      direction: direction,
      date: date,
    );
  }

  @override
  Future<List<ExaminationEntity>> getExaminations({required String token}) {
    return remoteDataSource.getExaminations(token: token);
  }

  @override
  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
  }) {
    return remoteDataSource.getMyDashboardTotals(token: token);
  }

  @override
  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  }) {
    return remoteDataSource.getMyRecentExaminationsPage(
      token: token,
      page: page,
      size: size,
    );
  }

  @override
  Future<List<PatientGradeStatsEntity>> getPatientGradeStatistics({
    required String token,
  }) {
    return remoteDataSource.getPatientGradeStatistics(token: token);
  }

  @override
  Future<List<ExaminationEntity>> getDoctorExaminations({
    required int doctorId,
    required String token,
  }) {
    return remoteDataSource.getDoctorExaminations(
      doctorId: doctorId,
      token: token,
    );
  }

  @override
  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  }) {
    return remoteDataSource.getPatientExaminations(
      patientId: patientId,
      token: token,
    );
  }

  @override
  Future<ExaminationEntity> getExaminationById({
    required int examinationId,
    required String token,
  }) {
    return remoteDataSource.getExaminationById(
      examinationId: examinationId,
      token: token,
    );
  }

  @override
  Future<void> markExaminationViewed({
    required int examinationId,
    required String token,
  }) {
    return remoteDataSource.markExaminationViewed(
      examinationId: examinationId,
      token: token,
    );
  }
}
