class DicomTagModel {
  final String tag;
  final String name;
  final String value;
  final Map<String, dynamic> raw;

  const DicomTagModel({
    required this.tag,
    required this.name,
    required this.value,
    required this.raw,
  });

  factory DicomTagModel.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return '';
    }

    final tag = pick(['tag', 'tagId', 'dicomTag', 'code', 'key']);
    final name = pick(['name', 'tagName', 'keyword', 'description']);
    final value = pick(['value', 'tagValue', 'displayValue']);

    return DicomTagModel(
      tag: tag,
      name: name.isEmpty ? tag : name,
      value: value,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class BatchDicomUploadModel {
  final String uploadSessionId;
  final List<DicomTagModel> tags;
  final List<DicomBatchErrorModel> errors;
  final List<DicomSuccessfulPatientModel> successfulPatients;
  final Map<String, dynamic> raw;

  const BatchDicomUploadModel({
    required this.uploadSessionId,
    required this.tags,
    required this.errors,
    required this.successfulPatients,
    required this.raw,
  });

  factory BatchDicomUploadModel.fromJson(Map<String, dynamic> json) {
    final tags = <DicomTagModel>[];
    final uploadSessionId =
        _valueAt(json, ['uploadSessionId', 'upload_session_id'])?.toString() ??
        '';
    final errors = (_listAt(json, ['errors']) ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              DicomBatchErrorModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final successfulPatients =
        (_listAt(json, ['successfulPatients', 'successful_patients']) ??
                const [])
            .whereType<Map>()
            .map(
              (item) => DicomSuccessfulPatientModel.fromJson(
                Map<String, dynamic>.from(item),
                uploadSessionId: uploadSessionId,
              ),
            )
            .toList();

    void collectTags(dynamic value) {
      if (value is List) {
        for (final item in value) {
          collectTags(item);
        }
        return;
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        if (_looksLikeTag(map)) {
          tags.add(DicomTagModel.fromJson(map));
          return;
        }
        for (final child in map.values) {
          collectTags(child);
        }
      }
    }

    collectTags(json);
    return BatchDicomUploadModel(
      uploadSessionId: uploadSessionId,
      tags: tags,
      errors: errors,
      successfulPatients: successfulPatients,
      raw: Map<String, dynamic>.from(json),
    );
  }

  static bool _looksLikeTag(Map<String, dynamic> json) {
    const tagKeys = {
      'tag',
      'tagId',
      'dicomTag',
      'code',
      'key',
      'name',
      'tagName',
      'keyword',
      'value',
      'tagValue',
      'displayValue',
    };
    return json.keys.any(tagKeys.contains);
  }
}

class DicomBatchErrorModel {
  final String filename;
  final String errorReason;

  const DicomBatchErrorModel({
    required this.filename,
    required this.errorReason,
  });

  factory DicomBatchErrorModel.fromJson(Map<String, dynamic> json) {
    return DicomBatchErrorModel(
      filename: json['filename']?.toString() ?? '',
      errorReason:
          _valueAt(json, ['errorReason', 'error_reason'])?.toString() ?? '',
    );
  }
}

class DicomSuccessfulPatientModel {
  final String uploadSessionId;
  final DicomPatientSummaryModel patient;
  final List<DicomExaminationSummaryModel> recentExaminations;

  const DicomSuccessfulPatientModel({
    this.uploadSessionId = '',
    required this.patient,
    required this.recentExaminations,
  });

  factory DicomSuccessfulPatientModel.fromJson(
    Map<String, dynamic> json, {
    String uploadSessionId = '',
  }) {
    final patientJson = json['patient'];
    final examinations =
        _listAt(json, ['recentExaminations', 'recent_examinations']) ??
        const [];
    return DicomSuccessfulPatientModel(
      uploadSessionId:
          _valueAt(json, [
            'uploadSessionId',
            'upload_session_id',
          ])?.toString() ??
          uploadSessionId,
      patient: patientJson is Map
          ? DicomPatientSummaryModel.fromJson(
              Map<String, dynamic>.from(patientJson),
            )
          : const DicomPatientSummaryModel(),
      recentExaminations: examinations
          .whereType<Map>()
          .map(
            (item) => DicomExaminationSummaryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class DicomPatientSummaryModel {
  final int id;
  final String patientCode;
  final String fullName;
  final String gender;
  final String patientId;

  const DicomPatientSummaryModel({
    this.id = 0,
    this.patientCode = '',
    this.fullName = '',
    this.gender = '',
    this.patientId = '',
  });

  factory DicomPatientSummaryModel.fromJson(Map<String, dynamic> json) {
    return DicomPatientSummaryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      patientCode: json['patientCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      patientId: _valueAt(json, ['patient_id', 'patientId'])?.toString() ?? '',
    );
  }
}

class DicomExaminationSummaryModel {
  final int examinationId;
  final String encounterCode;
  final String status;
  final DateTime? studyDate;
  final DateTime? visitTime;
  final String studyTime;
  final String bodyPart;
  final String thumbnailUrl;
  final String referringPhysician;
  final String chiefComplaint;
  final String clinicalNotes;
  final String priority;
  final String finalDiagnosis;
  final String description;
  final List<DicomExaminationImageSummaryModel> images;
  final int imageCount;

  const DicomExaminationSummaryModel({
    this.examinationId = 0,
    this.encounterCode = '',
    this.status = '',
    this.studyDate,
    this.visitTime,
    this.studyTime = '',
    this.bodyPart = '',
    this.thumbnailUrl = '',
    this.referringPhysician = '',
    this.chiefComplaint = '',
    this.clinicalNotes = '',
    this.priority = '',
    this.finalDiagnosis = '',
    this.description = '',
    this.images = const [],
    this.imageCount = 0,
  });

  factory DicomExaminationSummaryModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    final parsedImages = images is List
        ? images
              .whereType<Map>()
              .map(
                (item) => DicomExaminationImageSummaryModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <DicomExaminationImageSummaryModel>[];
    return DicomExaminationSummaryModel(
      examinationId: json['examinationId'] is int
          ? json['examinationId'] as int
          : int.tryParse(
                  _valueAt(json, [
                        'examinationId',
                        'examination_id',
                      ])?.toString() ??
                      '',
                ) ??
                0,
      encounterCode:
          _valueAt(json, ['encounterCode', 'encounter_code'])?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      studyDate: _valueAt(json, ['studyDate', 'study_date']) != null
          ? DateTime.tryParse(
              _valueAt(json, ['studyDate', 'study_date']).toString(),
            )
          : null,
      visitTime: _valueAt(json, ['visitTime', 'visit_time']) != null
          ? DateTime.tryParse(
              _valueAt(json, ['visitTime', 'visit_time']).toString(),
            )
          : null,
      studyTime: _valueAt(json, ['studyTime', 'study_time'])?.toString() ?? '',
      bodyPart: _valueAt(json, ['bodyPart', 'body_part'])?.toString() ?? '',
      thumbnailUrl:
          _valueAt(json, ['thumbnailUrl', 'thumbnail_url'])?.toString() ?? '',
      referringPhysician:
          _valueAt(json, [
            'referringPhysician',
            'referring_physician',
          ])?.toString() ??
          '',
      chiefComplaint:
          _valueAt(json, ['chiefComplaint', 'chief_complaint'])?.toString() ??
          '',
      clinicalNotes:
          _valueAt(json, ['clinicalNotes', 'clinical_notes'])?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      finalDiagnosis:
          _valueAt(json, ['finalDiagnosis', 'final_diagnosis'])?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      images: parsedImages,
      imageCount: parsedImages.isNotEmpty
          ? parsedImages.length
          : images is List
          ? images.length
          : 0,
    );
  }
}

class DicomExaminationImageSummaryModel {
  final int dicomInstanceId;
  final int examinationId;
  final String encounterCode;
  final String status;
  final DateTime? visitTime;
  final String imageUrl;

  const DicomExaminationImageSummaryModel({
    this.dicomInstanceId = 0,
    this.examinationId = 0,
    this.encounterCode = '',
    this.status = '',
    this.visitTime,
    this.imageUrl = '',
  });

  factory DicomExaminationImageSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DicomExaminationImageSummaryModel(
      dicomInstanceId: json['dicomInstanceId'] is int
          ? json['dicomInstanceId'] as int
          : int.tryParse(
                  _valueAt(json, [
                        'dicomInstanceId',
                        'dicom_instance_id',
                      ])?.toString() ??
                      '',
                ) ??
                0,
      examinationId: json['examinationId'] is int
          ? json['examinationId'] as int
          : int.tryParse(
                  _valueAt(json, [
                        'examinationId',
                        'examination_id',
                      ])?.toString() ??
                      '',
                ) ??
                0,
      encounterCode:
          _valueAt(json, ['encounterCode', 'encounter_code'])?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      visitTime: _valueAt(json, ['visitTime', 'visit_time']) != null
          ? DateTime.tryParse(
              _valueAt(json, ['visitTime', 'visit_time']).toString(),
            )
          : null,
      imageUrl:
          json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          json['url']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['thumbnail_url']?.toString() ??
          '',
    );
  }
}

Object? _valueAt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

List<dynamic>? _listAt(Map<String, dynamic> json, List<String> keys) {
  final value = _valueAt(json, keys);
  return value is List ? value : null;
}
