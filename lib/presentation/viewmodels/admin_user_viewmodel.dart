import 'package:flutter/material.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/usecases/get_user_accounts_usecase.dart';

class AdminUserViewModel extends ChangeNotifier {
  final GetUserAccountsUseCase getUserAccountsUseCase;

  AdminUserViewModel(this.getUserAccountsUseCase);

  List<UserAccountEntity> _accounts = [];
  List<UserAccountEntity> get accounts => _accounts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  int _totalPages = 0;

  Future<void> fetchAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pageResult = await getUserAccountsUseCase.execute(
        page: _currentPage,
        size: 10,
      );
      _accounts = pageResult.content;
      _totalPages = pageResult.totalPages;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
