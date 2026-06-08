import 'package:flutter/material.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/usecases/get_all_patients_usecase.dart';

class DoctorViewModel extends ChangeNotifier {
  final GetAllPatientsUseCase getAllPatientsUseCase;

  DoctorViewModel({required this.getAllPatientsUseCase});

  List<PatientEntity> _patients = [];
  List<PatientEntity> get patients => _patients;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  String _lastKeyword = '';

  Future<void> fetchPatients({
    String keyword = '',
    int page = 0,
    int size = 10,
  }) async {
    _isLoading = true;
    _currentPage = page;
    _lastKeyword = keyword;
    notifyListeners();

    try {
      final result = await getAllPatientsUseCase.execute(
        keyword: keyword,
        page: page,
        size: size,
      );
      _patients = result.content;
      _totalElements = result.totalElements;
      _totalPages = result.totalPages;
    } catch (e) {
      debugPrint("Error fetching patients: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
