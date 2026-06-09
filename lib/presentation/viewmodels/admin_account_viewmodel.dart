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
  Future<void> fetchFirstPage(String token) async {
    // Thêm token
    _currentPage = 0;
    _isLastPage = false;
    _isLoading = true;
    _errorMessage = null;
    _accounts.clear();
    notifyListeners();

    await _loadMoreData(token); // Truyền token
  }

  /// Tải các trang tiếp theo khi Admin cuộn xuống đáy
  Future<void> fetchNextPage(String token) async {
    // Thêm token
    if (_isLoading || _isLastPage) return;
    _isLoading = true;
    notifyListeners();

    _currentPage++;
    await _loadMoreData(token); // Truyền token
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
      await fetchFirstPage(
        token,
      ); // Tải lại trang đầu để thấy user mới, truyền token
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thay đổi trạng thái hoạt động của bác sĩ
  Future<bool> toggleDoctorStatus(int id, bool activate, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.toggleDoctorStatus(
        id: id,
        activate: activate,
        token: token,
      );
      await fetchFirstPage(token); // Refresh danh sách, truyền token
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadMoreData(String token) async {
    // Thêm token
    try {
      final result = await dataSource.getDoctorAccounts(
        page: _currentPage,
        size: 15, // Tăng size lên một chút để lấp đầy màn hình Web/Tablet
        token: token, // Truyền token
      );
      final List<DoctorAccountModel> newAccounts =
          (result['content'] as List<DoctorAccountModel>?) ??
          []; // Sửa từ 'accounts' sang 'content'

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
