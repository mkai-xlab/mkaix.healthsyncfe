import '../../data/models/role_model.dart';
import '../../domain/entities/doctor_account_page_entity.dart';
import '../../domain/interface_repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DoctorAccountPageEntity> getDoctorAccounts({
    required int page,
    required int size,
    required String token,
    String? name,
    String? status,
  }) {
    return remoteDataSource.getDoctorAccounts(
      page: page,
      size: size,
      token: token,
      name: name,
      status: status,
    );
  }

  @override
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  }) async {
    return await remoteDataSource.createDoctor(
      doctorData: doctorData,
      token: token,
    );
  }

  @override
  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required int roleId,
    required String token,
  }) {
    return remoteDataSource.createUser(
      fullName: fullName,
      email: email,
      phone: phone,
      roleId: roleId,
      token: token,
    );
  }

  @override
  Future<List<RoleModel>> getRoles({required String token}) {
    return remoteDataSource.getRoles(token: token);
  }

  @override
  Future<void> toggleDoctorStatus({
    required int id,
    required bool activate,
    required String token,
    String? reason,
  }) async {
    return await remoteDataSource.toggleDoctorStatus(
      id: id,
      activate: activate,
      token: token,
      reason: reason,
    );
  }
}
