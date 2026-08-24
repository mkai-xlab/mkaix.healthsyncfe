import '../../domain/entities/patient_page_entity.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/interface_repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remoteDataSource;
  PatientRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    bool isPersonal = false,
    int page = 0,
    int size = 10,
  }) async {
    return await remoteDataSource.getAllPatients(
      token: token,
      fullName: fullName,
      patientCode: patientCode,
      gender: gender,
      isPersonal: isPersonal,
      page: page,
      size: size,
    );
  }

  @override
  Future<PatientEntity> getPatientDetails({
    required String token,
    required String patientCode,
  }) async {
    return await remoteDataSource.getPatientDetails(
      token: token,
      patientCode: patientCode,
    );
  }
}
