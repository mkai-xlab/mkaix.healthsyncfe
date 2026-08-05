import '../entities/patient_page_entity.dart';
import '../interface_repositories/patient_repository.dart';

class GetAllPatientsUseCase {
  final PatientRepository repository;
  GetAllPatientsUseCase(this.repository);

  Future<PatientPageEntity> execute({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    bool isPersonal = false,
    int page = 0,
    int size = 10,
  }) {
    return repository.getAllPatients(
      token: token,
      fullName: fullName,
      patientCode: patientCode,
      gender: gender,
      isPersonal: isPersonal,
      page: page,
      size: size,
    );
  }
}
