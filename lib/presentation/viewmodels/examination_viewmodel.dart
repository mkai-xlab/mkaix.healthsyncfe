import 'package:flutter/material.dart';

import '../../domain/entities/examination_entity.dart';
import '../../domain/usecases/get_patient_examinations_usecase.dart';

class ExaminationViewModel extends ChangeNotifier {
  final GetPatientExaminationsUseCase getPatientExaminationsUseCase;

  ExaminationViewModel({required this.getPatientExaminationsUseCase});

  List<ExaminationEntity> _examinations = [];
  List<ExaminationEntity> get examinations => List.unmodifiable(_examinations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedStatus = '';
  String get selectedStatus => _selectedStatus;

  List<ExaminationEntity> get filteredExaminations {
    if (_selectedStatus.isEmpty) return List.unmodifiable(_examinations);
    return _examinations
        .where((examination) => examination.statusGroup == _selectedStatus)
        .toList();
  }

  Future<void> loadDoctorExaminations({
    required String doctorId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _selectedStatus = '';
    notifyListeners();

    try {
      final parsedDoctorId = int.tryParse(doctorId);
      if (parsedDoctorId == null || parsedDoctorId <= 0) {
        throw Exception('Không tìm thấy doctorId hợp lệ để tải ca khám');
      }
      _examinations = await getPatientExaminationsUseCase.executeDoctor(
        doctorId: parsedDoctorId,
        token: token,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientExaminations({
    required String patientId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _examinations = [];
    _selectedStatus = '';
    notifyListeners();

    try {
      _examinations = await getPatientExaminationsUseCase.execute(
        patientId: patientId,
        token: token,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }

  void clear() {
    _examinations = [];
    _errorMessage = null;
    _selectedStatus = '';
    notifyListeners();
  }
}
