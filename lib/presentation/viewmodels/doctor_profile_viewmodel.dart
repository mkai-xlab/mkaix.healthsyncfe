import 'package:flutter/material.dart';

import '../../data/datasources/doctor_profile_remote_datasource.dart';
import '../../domain/entities/doctor_account_entity.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final DoctorProfileRemoteDataSource dataSource;

  DoctorProfileViewModel(this.dataSource);

  DoctorAccountEntity? _profile;
  DoctorAccountEntity? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile({
    required String token,
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;
    if (!forceRefresh && _profile != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await dataSource.getProfile(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    if (_isUpdating) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await dataSource.updateProfile(token: token, payload: payload);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    if (_isUpdating) return false;

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await dataSource.uploadAvatar(
        token: token,
        bytes: bytes,
        filename: filename,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    _isUpdating = false;
    notifyListeners();
  }
}
