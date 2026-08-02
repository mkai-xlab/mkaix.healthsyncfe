import 'examination_entity.dart';

class ExaminationPageEntity {
  final List<ExaminationEntity> content;
  final int totalElements;
  final int totalPages;
  final bool isLast;
  final int pageNumber;
  final int pageSize;

  const ExaminationPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
    required this.pageNumber,
    required this.pageSize,
  });
}
