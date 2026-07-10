import '../../domain/entities/examination_entity.dart';

class ExaminationImageModel extends ExaminationImageEntity {
  const ExaminationImageModel({
    super.dicomInstanceId,
    required super.examinationId,
    required super.encounterCode,
    required super.status,
    super.visitTime,
    required super.imageUrl,
  });

  factory ExaminationImageModel.fromJson(Map<String, dynamic> json) {
    return ExaminationImageModel(
      dicomInstanceId: json['dicomInstanceId'] is int
          ? json['dicomInstanceId'] as int
          : int.tryParse(json['dicomInstanceId']?.toString() ?? '') ?? 0,
      examinationId: json['examinationId'] is int
          ? json['examinationId'] as int
          : int.tryParse(json['examinationId']?.toString() ?? '') ?? 0,
      encounterCode: json['encounterCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      visitTime: json['visitTime'] != null
          ? DateTime.tryParse(json['visitTime'].toString())
          : null,
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class ExaminationModel extends ExaminationEntity {
  const ExaminationModel({
    super.patientDbId,
    super.patientCode,
    super.patientName,
    super.patientGender,
    super.patientDateOfBirth,
    required super.examinationId,
    required super.encounterCode,
    required super.status,
    super.studyDate,
    super.visitTime,
    required super.thumbnailUrl,
    required super.bodyPart,
    required super.referringPhysician,
    super.studyTime,
    super.chiefComplaint,
    super.clinicalNotes,
    super.priority,
    super.finalDiagnosis,
    super.description,
    super.doctorName,
    required super.images,
  });

  factory ExaminationModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? patientJson,
  }) {
    final resolvedPatientJson = json['patient'] is Map
        ? Map<String, dynamic>.from(json['patient'] as Map)
        : patientJson;
    final doctorJson = json['doctor'] is Map
        ? Map<String, dynamic>.from(json['doctor'] as Map)
        : null;
    return ExaminationModel(
      patientDbId: resolvedPatientJson?['id'] is int
          ? resolvedPatientJson!['id'] as int
          : int.tryParse(resolvedPatientJson?['id']?.toString() ?? '') ?? 0,
      patientCode:
          resolvedPatientJson?['patientCode']?.toString() ??
          resolvedPatientJson?['patient_id']?.toString() ??
          '',
      patientName: resolvedPatientJson?['fullName']?.toString() ?? '',
      patientGender: resolvedPatientJson?['gender']?.toString() ?? '',
      patientDateOfBirth: resolvedPatientJson?['dateOfBirth'] != null
          ? DateTime.tryParse(resolvedPatientJson!['dateOfBirth'].toString())
          : null,
      examinationId: json['examinationId'] is int
          ? json['examinationId'] as int
          : int.tryParse(json['examinationId']?.toString() ?? '') ?? 0,
      encounterCode: json['encounterCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      studyDate: json['studyDate'] != null
          ? DateTime.tryParse(json['studyDate'].toString())
          : null,
      visitTime: json['visitTime'] != null
          ? DateTime.tryParse(json['visitTime'].toString())
          : null,
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      bodyPart: json['bodyPart']?.toString() ?? '',
      referringPhysician: json['referringPhysician']?.toString() ?? '',
      studyTime: json['studyTime']?.toString() ?? '',
      chiefComplaint: json['chiefComplaint']?.toString() ?? '',
      clinicalNotes: json['clinicalNotes']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      finalDiagnosis: json['finalDiagnosis']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      doctorName:
          doctorJson?['fullName']?.toString() ??
          doctorJson?['username']?.toString() ??
          '',
      images: (json['images'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ExaminationImageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
