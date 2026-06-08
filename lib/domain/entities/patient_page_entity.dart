import 'patient_entity.dart';

class PatientPageEntity {
  final List<PatientEntity> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  PatientPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });
}
