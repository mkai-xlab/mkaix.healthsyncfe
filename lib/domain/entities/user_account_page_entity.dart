import 'user_account_entity.dart';

class UserAccountPageEntity {
  final List<UserAccountEntity> content;
  final int totalElements;
  final int totalPages;

  UserAccountPageEntity({
    required this.content,
    required this.totalElements,
    required this.totalPages,
  });
}
