import '../entities/doctor_account_page_entity.dart';
import '../interface_repositories/admin_repository.dart';

class GetDoctorAccountsUseCase {
  final AdminRepository repository;

  GetDoctorAccountsUseCase(this.repository);

  Future<DoctorAccountPageEntity> execute({
    required int page,
    required int size,
    required String token,
    String? name,
    String? status,
  }) {
    return repository.getDoctorAccounts(
      page: page,
      size: size,
      token: token,
      name: name,
      status: status,
    );
  }
}
