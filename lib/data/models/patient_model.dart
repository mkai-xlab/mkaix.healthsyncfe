import '../../domain/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    required super.id,
    required super.patientCode,
    required super.fullName,
    required super.age,
    required super.gender,
    super.analysisTime,
    required super.klGrade,
    required super.riskLevel,
    required super.status,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id']?.toString() ?? '',
      patientCode: json['patientCode'] ?? '',
      fullName: json['fullName'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      analysisTime: json['analysisTime'] != null
          ? DateTime.tryParse(json['analysisTime'])
          : null,
      klGrade: json['klGrade'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
