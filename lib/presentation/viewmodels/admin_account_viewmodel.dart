import 'package:flutter/material.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/doctor_account_model.dart';

class AdminAccountViewModel extends ChangeNotifier {
  final AdminRemoteDataSource dataSource;
  AdminAccountViewModel(this.dataSource);

  List<DoctorAccountModel> _accounts = [];
  List<DoctorAccountModel> get accounts => _accounts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  bool _isLastPage = false;
  bool get isLastPage => _isLastPage;

  /// Tải trang đầu tiên (hoặc khi Pull-to-Refresh)
  Future<void> fetchFirstPage() async {
    _currentPage = 0;
    _isLastPage = false;
    _isLoading = true;
    _errorMessage = null;
    _accounts.clear();
    notifyListeners();

    await _loadMoreData();
  }

  /// Tải các trang tiếp theo khi Admin cuộn xuống đáy
  Future<void> fetchNextPage() async {
    if (_isLoading || _isLastPage) return;
    _isLoading = true;
    notifyListeners();

    _currentPage++;
    await _loadMoreData();
  }

  /// Tạo tài khoản bác sĩ mới
  Future<bool> createDoctor(
    Map<String, dynamic> doctorData,
    String token,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.createDoctor(doctorData: doctorData, token: token);
      await fetchFirstPage(); // Tải lại trang đầu để thấy user mới
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreData() async {
    try {
      final result = await dataSource.getDoctorAccounts(
        page: _currentPage,
        size: 15, // Tăng size lên một chút để lấp đầy màn hình Web/Tablet
      );
      final List<DoctorAccountModel> newAccounts =
          result['accounts'] as List<DoctorAccountModel>;

      _accounts.addAll(newAccounts);
      _isLastPage = (result['isLast'] as bool?) ?? true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
