import '../interface_repositories/admin_repository.dart';

class ToggleDoctorStatusUseCase {
  final AdminRepository repository;

  ToggleDoctorStatusUseCase(this.repository);

  Future<void> execute({
    required int id,
    required bool activate,
    required String token,
    String? reason,
  }) {
    return repository.toggleDoctorStatus(
      id: id,
      activate: activate,
      token: token,
      reason: reason,
    );
  }
}
