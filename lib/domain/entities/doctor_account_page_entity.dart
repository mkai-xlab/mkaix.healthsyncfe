import 'doctor_account_entity.dart';

class DoctorAccountPageEntity {
  final List<DoctorAccountEntity> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool isLast;

  const DoctorAccountPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    this.pageNumber = 0,
    this.pageSize = 10,
    required this.isLast,
  });
}
