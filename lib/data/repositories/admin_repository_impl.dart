import '../../domain/interface_repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    return await remoteDataSource.createDoctor(
      doctorData: doctorData,
      token: token,
    );
  }

  @override
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
  }) async {
    return await remoteDataSource.toggleDoctorStatus(
        id: id, activate: activate, token: token);
  }
}
