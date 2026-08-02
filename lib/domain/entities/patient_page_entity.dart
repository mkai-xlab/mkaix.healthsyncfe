import 'patient_entity.dart';

class PatientPageEntity {
  final List<PatientEntity> content;
  final int totalElements;
  final int totalPages;
  final bool isLast;
  final int pageNumber;
  final int pageSize;

  PatientPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
    required this.pageNumber,
    required this.pageSize,
  });
}
