import '../../domain/entities/patient_entity.dart';
import '../../domain/entities/patient_page_entity.dart';
import '../../domain/interface_repositories/patient_repository.dart';
import '../models/patient_model.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remoteDataSource;

  PatientRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PatientPageEntity> getAllPatients({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> pageable,
  }) async {
    return await remoteDataSource.getAllPatients(
      filter: filter,
      pageable: pageable,
    );
  }
}
