import '../entities/doctor_account_entity.dart';
import '../interface_repositories/doctor_profile_repository.dart';

class GetDoctorProfileUseCase {
  final DoctorProfileRepository repository;

  GetDoctorProfileUseCase(this.repository);

  Future<DoctorAccountEntity> execute({required String token}) {
    return repository.getProfile(token: token);
  }
}
