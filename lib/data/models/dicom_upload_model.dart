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
  final List<DicomTagModel> tags;
  final List<DicomBatchErrorModel> errors;
  final List<DicomSuccessfulPatientModel> successfulPatients;
  final Map<String, dynamic> raw;

  const BatchDicomUploadModel({
    required this.tags,
    required this.errors,
    required this.successfulPatients,
    required this.raw,
  });

  factory BatchDicomUploadModel.fromJson(Map<String, dynamic> json) {
    final tags = <DicomTagModel>[];
    final errors = (json['errors'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              DicomBatchErrorModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final successfulPatients = (json['successfulPatients'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => DicomSuccessfulPatientModel.fromJson(
            Map<String, dynamic>.from(item),
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
      errorReason: json['errorReason']?.toString() ?? '',
    );
  }
}

class DicomSuccessfulPatientModel {
  final DicomPatientSummaryModel patient;
  final List<DicomExaminationSummaryModel> recentExaminations;

  const DicomSuccessfulPatientModel({
    required this.patient,
    required this.recentExaminations,
  });

  factory DicomSuccessfulPatientModel.fromJson(Map<String, dynamic> json) {
    final patientJson = json['patient'];
    return DicomSuccessfulPatientModel(
      patient: patientJson is Map
          ? DicomPatientSummaryModel.fromJson(
              Map<String, dynamic>.from(patientJson),
            )
          : const DicomPatientSummaryModel(),
      recentExaminations: (json['recentExaminations'] as List? ?? const [])
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
      patientId: json['patient_id']?.toString() ?? '',
    );
  }
}

class DicomExaminationSummaryModel {
  final int examinationId;
  final String encounterCode;
  final String status;
  final String bodyPart;
  final String thumbnailUrl;
  final int imageCount;

  const DicomExaminationSummaryModel({
    this.examinationId = 0,
    this.encounterCode = '',
    this.status = '',
    this.bodyPart = '',
    this.thumbnailUrl = '',
    this.imageCount = 0,
  });

  factory DicomExaminationSummaryModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    return DicomExaminationSummaryModel(
      examinationId: json['examinationId'] is int
          ? json['examinationId'] as int
          : int.tryParse(json['examinationId']?.toString() ?? '') ?? 0,
      encounterCode: json['encounterCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      bodyPart: json['bodyPart']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      imageCount: images is List ? images.length : 0,
    );
  }
}
