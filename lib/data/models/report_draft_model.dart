import '../../core/utils/date_time_utils.dart';

class ReportDraftModel {
  final int examinationId;
  final String patientCode;
  final String ministryName;
  final String hospitalName;
  final String departmentName;
  final String formCode;
  final String clinicalDepartment;
  final String doctorName;
  final String leftKlGrade;
  final String rightKlGrade;
  final String documentNumber;
  final String attemptNumber;
  final String patientName;
  final String age;
  final String gender;
  final String address;
  final List<String> findings;
  final String conclusion;
  final String signaturePlace;
  final DateTime? signatureDate;

  const ReportDraftModel({
    required this.examinationId,
    required this.patientCode,
    required this.ministryName,
    required this.hospitalName,
    required this.departmentName,
    required this.formCode,
    required this.clinicalDepartment,
    required this.doctorName,
    required this.leftKlGrade,
    required this.rightKlGrade,
    required this.documentNumber,
    required this.attemptNumber,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.address,
    required this.findings,
    required this.conclusion,
    required this.signaturePlace,
    required this.signatureDate,
  });

  factory ReportDraftModel.fromJson(Map<String, dynamic> json) {
    return ReportDraftModel(
      examinationId: _intAt(json, 'examinationId'),
      patientCode: _stringAt(json, 'patientCode'),
      ministryName: _stringAt(json, 'ministryName'),
      hospitalName: _stringAt(json, 'hospitalName'),
      departmentName: _stringAt(json, 'departmentName'),
      formCode: _stringAt(json, 'formCode'),
      clinicalDepartment: _stringAt(json, 'clinicalDepartment'),
      doctorName: _stringAt(json, 'doctorName'),
      leftKlGrade: _stringAt(json, 'leftKlGrade'),
      rightKlGrade: _stringAt(json, 'rightKlGrade'),
      documentNumber: _stringAt(json, 'documentNumber'),
      attemptNumber: _stringAt(json, 'attemptNumber'),
      patientName: _stringAt(json, 'patientName'),
      age: _stringAt(json, 'age'),
      gender: _stringAt(json, 'gender'),
      address: _stringAt(json, 'address'),
      findings: (json['findings'] as List? ?? const [])
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      conclusion: _stringAt(json, 'conclusion'),
      signaturePlace: _stringAt(json, 'signaturePlace'),
      signatureDate: parseLocalDate(json['signatureDate']),
    );
  }
}

String _stringAt(Map<String, dynamic> json, String key) {
  return json[key]?.toString().trim() ?? '';
}

int _intAt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
