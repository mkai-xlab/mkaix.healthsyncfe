import '../entities/doctor_account_entity.dart';

abstract class DoctorProfileRepository {
  Future<DoctorAccountEntity> getProfile({required String token});

  Future<DoctorAccountEntity> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  });

  Future<DoctorAccountEntity> uploadAvatar({
    required String token,
    required List<int> bytes,
    required String filename,
  });
}
