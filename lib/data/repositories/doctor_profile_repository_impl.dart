import '../../domain/entities/doctor_account_entity.dart';
import '../../domain/interface_repositories/doctor_profile_repository.dart';
import '../datasources/doctor_profile_remote_datasource.dart';

class DoctorProfileRepositoryImpl implements DoctorProfileRepository {
  final DoctorProfileRemoteDataSource remoteDataSource;

  DoctorProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DoctorAccountEntity> getProfile({required String token}) {
    return remoteDataSource.getProfile(token: token);
  }

  @override
  Future<DoctorAccountEntity> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) {
    return remoteDataSource.updateProfile(token: token, payload: payload);
  }

  @override
  Future<DoctorAccountEntity> uploadAvatar({
    required String token,
    required List<int> bytes,
    required String filename,
  }) {
    return remoteDataSource.uploadAvatar(
      token: token,
      bytes: bytes,
      filename: filename,
    );
  }
}
