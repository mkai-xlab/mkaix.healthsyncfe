import '../entities/patient_entity.dart';
import '../entities/patient_page_entity.dart';
import '../interface_repositories/patient_repository.dart';

class GetAllPatientsUseCase {
  final PatientRepository repository;

  GetAllPatientsUseCase(this.repository);

  /// Thực thi việc lấy danh sách bệnh nhân với bộ lọc và phân trang.
  /// [keyword] được ánh xạ vào 'filter' theo yêu cầu của API doc.
  /// [page] và [size] được ánh xạ vào 'pageable'.
  Future<PatientPageEntity> execute({
    String keyword = '',
    int page = 0,
    int size = 10,
  }) {
    return repository.getAllPatients(
      filter: {'keyword': keyword},
      pageable: {'page': page, 'size': size},
    );
  }
}
