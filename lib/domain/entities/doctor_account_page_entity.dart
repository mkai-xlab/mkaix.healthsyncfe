import 'doctor_account_entity.dart';

class DoctorAccountPageEntity {
  final List<DoctorAccountEntity> content;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  const DoctorAccountPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });
}
