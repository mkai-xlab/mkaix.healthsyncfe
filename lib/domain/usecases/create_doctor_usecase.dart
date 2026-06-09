import '../interface_repositories/admin_repository.dart';

class CreateDoctorUseCase {
  final AdminRepository repository;

  CreateDoctorUseCase(this.repository);

  Future<void> execute({
    required Map<String, dynamic> doctorData,
    required String token,
  }) {
    return repository.createDoctor(doctorData: doctorData, token: token);
  }
}
