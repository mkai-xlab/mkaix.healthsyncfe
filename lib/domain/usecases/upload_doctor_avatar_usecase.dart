import '../entities/doctor_account_entity.dart';
import '../interface_repositories/doctor_profile_repository.dart';

class UploadDoctorAvatarUseCase {
  final DoctorProfileRepository repository;

  UploadDoctorAvatarUseCase(this.repository);

  Future<DoctorAccountEntity> execute({
    required String token,
    required List<int> bytes,
    required String filename,
  }) {
    return repository.uploadAvatar(
      token: token,
      bytes: bytes,
      filename: filename,
    );
  }
}
