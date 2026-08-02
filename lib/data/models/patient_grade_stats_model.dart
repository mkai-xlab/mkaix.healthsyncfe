import '../../domain/entities/patient_grade_stats_entity.dart';

class PatientGradeStatsModel extends PatientGradeStatsEntity {
  const PatientGradeStatsModel({
    required super.grade,
    required super.patientCount,
  });

  factory PatientGradeStatsModel.fromJson(Map<String, dynamic> json) {
    return PatientGradeStatsModel(
      grade: _parseInt(json['grade'], fallback: -1),
      patientCount: _parseInt(json['patientCount']),
    );
  }

  static int _parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
