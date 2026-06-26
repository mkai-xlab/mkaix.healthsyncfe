import '../../domain/entities/examination_entity.dart';
import '../../domain/interface_repositories/examination_repository.dart';
import '../datasources/examination_remote_datasource.dart';

class ExaminationRepositoryImpl implements ExaminationRepository {
  final ExaminationRemoteDataSource remoteDataSource;

  ExaminationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ExaminationEntity>> getAllExaminations({required String token}) {
    return remoteDataSource.getAllExaminations(token: token);
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
}
