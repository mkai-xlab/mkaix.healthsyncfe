abstract class AdminRepository {
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  });
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
  });
}
