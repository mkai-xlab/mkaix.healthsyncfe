import 'package:flutter/material.dart';

import '../../data/datasources/doctor_profile_remote_datasource.dart';
import '../../domain/entities/doctor_account_entity.dart';
import '../../core/utils/error_message_utils.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final DoctorProfileRemoteDataSource dataSource;

  DoctorProfileViewModel(this.dataSource);

  DoctorAccountEntity? _profile;
  DoctorAccountEntity? get profile => _profile;
  String? _profileToken;

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
    final normalizedToken = token.trim();
    if (_profileToken != null && _profileToken != normalizedToken) {
      _profile = null;
      _profileToken = null;
      _errorMessage = null;
    }

    if (_isLoading) return;
    if (!forceRefresh && _profile != null && _profileToken == normalizedToken) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await dataSource.getProfile(token: normalizedToken);
      _profileToken = normalizedToken;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
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
      final normalizedToken = token.trim();
      _profile = await dataSource.updateProfile(
        token: normalizedToken,
        payload: payload,
      );
      _profileToken = normalizedToken;
      return true;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
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
      final normalizedToken = token.trim();
      _profile = await dataSource.uploadAvatar(
        token: normalizedToken,
        bytes: bytes,
        filename: filename,
      );
      _profileToken = normalizedToken;
      return true;
    } catch (e) {
      _errorMessage = userFriendlyErrorMessage(e);
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    _profileToken = null;
    _errorMessage = null;
    _isLoading = false;
    _isUpdating = false;
    notifyListeners();
  }
}
