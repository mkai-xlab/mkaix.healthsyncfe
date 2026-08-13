import '../entities/doctor_account_entity.dart';
import '../interface_repositories/doctor_profile_repository.dart';

class UpdateDoctorProfileUseCase {
  final DoctorProfileRepository repository;

  UpdateDoctorProfileUseCase(this.repository);

  Future<DoctorAccountEntity> execute({
    required String token,
    required Map<String, dynamic> payload,
  }) {
    return repository.updateProfile(token: token, payload: payload);
  }
}
