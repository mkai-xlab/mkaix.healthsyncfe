import '../entities/user_account_page_entity.dart';

abstract class AdminRepository {
  Future<void> createDoctor({
    required Map<String, dynamic> doctorData,
    required String token,
  });
}
