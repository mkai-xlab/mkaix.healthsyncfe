import '../entities/patient_entity.dart';
import '../entities/patient_page_entity.dart';

abstract class PatientRepository {
  /// Lấy danh sách bệnh nhân từ nguồn dữ liệu (API/Local)
  /// [filter] chứa các tham số tìm kiếm
  /// [pageable] chứa thông tin phân trang
  Future<PatientPageEntity> getAllPatients({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> pageable,
  });
}
