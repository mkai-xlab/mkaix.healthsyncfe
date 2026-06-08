import 'package:intl/intl.dart';

class PatientEntity {
  final String id;
  final String patientCode;
  final String fullName;
  final int age;
  final String gender;
  final DateTime? analysisTime;
  final String klGrade;
  final String riskLevel;
  final String status;

  PatientEntity({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.age,
    required this.gender,
    this.analysisTime,
    required this.klGrade,
    required this.riskLevel,
    required this.status,
  });

  String get displayAgeGender => "$age tuổi • $gender";

  String get formattedAnalysisTime {
    if (analysisTime == null) return '---';
    return DateFormat('HH:mm - dd/MM/yyyy').format(analysisTime!);
  }
}
