import '../entities/patient_page_entity.dart';

abstract class PatientRepository {
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    bool isPersonal = false,
    int page = 0,
    int size = 10,
  });
}
