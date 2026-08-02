import '../../core/constants/api_constants.dart';
import '../../domain/entities/examination_entity.dart';

class AiPredictionResultModel extends AiPredictionResultEntity {
  const AiPredictionResultModel({
    super.dicomInstanceId,
    super.aiAnalysisId,
    super.aiResultId,
    super.kneeSide,
    super.predictedGrade,
    super.confirmedGrade,
    super.effectiveGrade,
    super.confidence,
    super.description,
    super.details,
    super.roiImageUrl,
    super.gradcamImageUrl,
    super.annotatedImageUrl,
    super.reviewDecision,
    super.reviewNote,
    super.reviewedByDoctorId,
    super.reviewedAt,
  });

  factory AiPredictionResultModel.fromJson(Map<String, dynamic> json) {
    final detailsJson = json['details'];
    final details = <String, double>{};
    if (detailsJson is Map) {
      detailsJson.forEach((key, value) {
        final parsed = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
        if (parsed != null) details[key.toString()] = parsed;
      });
    }

    return AiPredictionResultModel(
      dicomInstanceId: _intAt(json, ['dicomInstanceId', 'dicom_instance_id']),
      aiAnalysisId: _intAt(json, ['aiAnalysisId', 'ai_analysis_id']),
      aiResultId: _intAt(json, ['aiResultId', 'ai_result_id', 'id']),
      kneeSide:
          json['kneeSide']?.toString() ?? json['knee_side']?.toString() ?? '',
      predictedGrade: _nullableIntAt(json, [
        'predictedGrade',
        'predicted_grade',
      ]),
      confirmedGrade: _nullableIntAt(json, [
        'confirmedGrade',
        'confirmed_grade',
      ]),
      effectiveGrade: _nullableIntAt(json, [
        'effectiveGrade',
        'effective_grade',
      ]),
      confidence: _doubleAt(json, ['confidence']),
      description: json['description']?.toString() ?? '',
      details: details,
      roiImageUrl:
          json['roiImageUrl']?.toString() ??
          json['roi_image_url']?.toString() ??
          '',
      gradcamImageUrl:
          json['gradcamImageUrl']?.toString() ??
          json['gradcam_image_url']?.toString() ??
          '',
      annotatedImageUrl:
          json['annotatedImageUrl']?.toString() ??
          json['annotated_image_url']?.toString() ??
          '',
      reviewDecision:
          json['reviewDecision']?.toString() ??
          json['review_decision']?.toString() ??
          '',
      reviewNote:
          json['reviewNote']?.toString() ??
          json['review_note']?.toString() ??
          '',
      reviewedByDoctorId: _intAt(json, [
        'reviewedByDoctorId',
        'reviewed_by_doctor_id',
      ]),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
    );
  }
}

class ExaminationImageModel extends ExaminationImageEntity {
  const ExaminationImageModel({
    super.dicomInstanceId,
    required super.examinationId,
    required super.encounterCode,
    required super.status,
    super.visitTime,
    super.bodyPart,
    required super.imageUrl,
    super.annotatedImageUrl,
    super.aiResults,
  });

  factory ExaminationImageModel.fromJson(Map<String, dynamic> json) {
    final dicomInstanceId = _intAt(json, [
      'dicomInstanceId',
      'dicom_instance_id',
    ]);
    final imageUrl = json['imageUrl']?.toString() ?? '';
    final annotatedImageUrl =
        json['annotatedImageUrl']?.toString() ??
        json['annotated_image_url']?.toString() ??
        '';
    final aiResults = json['aiResults'] is List
        ? (json['aiResults'] as List)
              .whereType<Map>()
              .map(
                (item) => AiPredictionResultModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <AiPredictionResultEntity>[];

    return ExaminationImageModel(
      dicomInstanceId: dicomInstanceId,
      examinationId: _intAt(json, ['examinationId', 'examination_id', 'id']),
      encounterCode: json['encounterCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      visitTime: json['visitTime'] != null
          ? DateTime.tryParse(json['visitTime'].toString())
          : null,
      bodyPart: json['bodyPart']?.toString() ?? '',
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : dicomInstanceId > 0
          ? ApiConstants.dicomInstanceImageEndpoint(dicomInstanceId)
          : '',
      annotatedImageUrl: annotatedImageUrl,
      aiResults: aiResults,
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
    super.doctorId,
    super.isViewed,
    super.maxPredictedGrade,
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
      examinationId: _intAt(json, ['examinationId', 'examination_id', 'id']),
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
      doctorId: _intAt(json, ['doctorId', 'doctor_id']),
      isViewed:
          json['isViewed'] == true ||
          json['isViewed'] == 1 ||
          json['is_viewed'] == true ||
          json['is_viewed'] == 1,
      maxPredictedGrade: _intAt(json, [
        'maxPredictedGrade',
        'max_predicted_grade',
      ]),
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

int _intAt(Map<String, dynamic> json, List<String> keys) {
  return _nullableIntAt(json, keys) ?? 0;
}

int? _nullableIntAt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key) || json[key] == null) continue;
    final value = json[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

double _doubleAt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}
