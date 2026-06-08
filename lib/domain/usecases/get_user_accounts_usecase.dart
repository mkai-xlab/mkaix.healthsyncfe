import '../entities/user_account_page_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class GetUserAccountsUseCase {
  final AdminRemoteDataSource dataSource;

  GetUserAccountsUseCase(this.dataSource);

  Future<UserAccountPageEntity> execute({
    required int page,
    required int size,
  }) {
    return dataSource.getUserAccounts(page: page, size: size);
  }
}
