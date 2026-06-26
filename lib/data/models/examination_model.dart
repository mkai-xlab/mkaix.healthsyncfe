import '../../domain/entities/examination_entity.dart';

class ExaminationImageModel extends ExaminationImageEntity {
  const ExaminationImageModel({
    required super.examinationId,
    required super.encounterCode,
    required super.status,
    super.visitTime,
    required super.imageUrl,
  });

  factory ExaminationImageModel.fromJson(Map<String, dynamic> json) {
    return ExaminationImageModel(
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
    required super.images,
  });

  factory ExaminationModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? patientJson,
  }) {
    return ExaminationModel(
      patientDbId: patientJson?['id'] is int
          ? patientJson!['id'] as int
          : int.tryParse(patientJson?['id']?.toString() ?? '') ?? 0,
      patientCode:
          patientJson?['patientCode']?.toString() ??
          patientJson?['patient_id']?.toString() ??
          '',
      patientName: patientJson?['fullName']?.toString() ?? '',
      patientGender: patientJson?['gender']?.toString() ?? '',
      patientDateOfBirth: patientJson?['dateOfBirth'] != null
          ? DateTime.tryParse(patientJson!['dateOfBirth'].toString())
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
