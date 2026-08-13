import '../../data/models/role_model.dart';
import '../entities/doctor_account_page_entity.dart';

abstract class AdminRepository {
  Future<DoctorAccountPageEntity> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
    String? status,
  });

  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  });

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  });

  Future<List<RoleModel>> getRoles({required String token});

  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
    String? reason,
  });
}
