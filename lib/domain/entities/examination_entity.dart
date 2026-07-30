import 'package:intl/intl.dart';

import '../../core/utils/examination_status_utils.dart';

class AiPredictionResultEntity {
  final int dicomInstanceId;
  final int aiAnalysisId;
  final int aiResultId;
  final String kneeSide;
  final int predictedGrade;
  final int confirmedGrade;
  final int effectiveGrade;
  final double confidence;
  final String description;
  final Map<String, double> details;
  final String roiImageUrl;
  final String gradcamImageUrl;
  final String annotatedImageUrl;
  final String reviewDecision;
  final String reviewNote;
  final int reviewedByDoctorId;
  final DateTime? reviewedAt;

  const AiPredictionResultEntity({
    this.dicomInstanceId = 0,
    this.aiAnalysisId = 0,
    this.aiResultId = 0,
    this.kneeSide = '',
    this.predictedGrade = 0,
    this.confirmedGrade = 0,
    this.effectiveGrade = 0,
    this.confidence = 0,
    this.description = '',
    this.details = const {},
    this.roiImageUrl = '',
    this.gradcamImageUrl = '',
    this.annotatedImageUrl = '',
    this.reviewDecision = '',
    this.reviewNote = '',
    this.reviewedByDoctorId = 0,
    this.reviewedAt,
  });

  bool get isReviewed => reviewedAt != null;

  int get displayGrade {
    if (effectiveGrade > 0) return effectiveGrade;
    if (confirmedGrade > 0) return confirmedGrade;
    return predictedGrade;
  }

  String get predictedGradeDisplay =>
      displayGrade > 0 ? 'Grade $displayGrade' : '---';

  String get kneeSideDisplay {
    switch (kneeSide.toUpperCase()) {
      case 'LEFT':
        return 'Gối trái';
      case 'RIGHT':
        return 'Gối phải';
      default:
        return kneeSide.isEmpty ? 'Kết quả AI' : kneeSide;
    }
  }

  String get confidenceDisplay {
    if (confidence <= 0) return '---';
    final normalized = confidence > 1 ? confidence : confidence * 100;
    return '${normalized.toStringAsFixed(1)}%';
  }
}

class ExaminationImageEntity {
  final int dicomInstanceId;
  final int examinationId;
  final String encounterCode;
  final String status;
  final DateTime? visitTime;
  final String bodyPart;
  final String imageUrl;
  final String annotatedImageUrl;
  final List<AiPredictionResultEntity> aiResults;

  const ExaminationImageEntity({
    this.dicomInstanceId = 0,
    required this.examinationId,
    required this.encounterCode,
    required this.status,
    this.visitTime,
    this.bodyPart = '',
    required this.imageUrl,
    this.annotatedImageUrl = '',
    this.aiResults = const [],
  });
}

class ExaminationEntity {
  final int patientDbId;
  final String patientCode;
  final String patientName;
  final String patientGender;
  final DateTime? patientDateOfBirth;
  final int examinationId;
  final String encounterCode;
  final String status;
  final DateTime? studyDate;
  final DateTime? visitTime;
  final String thumbnailUrl;
  final String bodyPart;
  final String referringPhysician;
  final String studyTime;
  final String chiefComplaint;
  final String clinicalNotes;
  final String priority;
  final String finalDiagnosis;
  final String description;
  final String doctorName;
  final int doctorId;
  final bool isViewed;
  final int maxPredictedGrade;
  final List<ExaminationImageEntity> images;

  const ExaminationEntity({
    this.patientDbId = 0,
    this.patientCode = '',
    this.patientName = '',
    this.patientGender = '',
    this.patientDateOfBirth,
    required this.examinationId,
    required this.encounterCode,
    required this.status,
    this.studyDate,
    this.visitTime,
    required this.thumbnailUrl,
    required this.bodyPart,
    required this.referringPhysician,
    this.studyTime = '',
    this.chiefComplaint = '',
    this.clinicalNotes = '',
    this.priority = '',
    this.finalDiagnosis = '',
    this.description = '',
    this.doctorName = '',
    this.doctorId = 0,
    this.isViewed = false,
    this.maxPredictedGrade = 0,
    required this.images,
  });

  String get statusGroup {
    final normalized = status.toUpperCase();
    if (normalized == ExaminationStatusUtils.aiProcessing) {
      return ExaminationStatusUtils.aiProcessing;
    }
    if (normalized == ExaminationStatusUtils.needVerify) {
      return ExaminationStatusUtils.needVerify;
    }
    if (normalized == ExaminationStatusUtils.verified) {
      return ExaminationStatusUtils.verified;
    }
    if (normalized == ExaminationStatusUtils.reportGenerated) {
      return ExaminationStatusUtils.reportGenerated;
    }
    if (normalized == ExaminationStatusUtils.reportExported) {
      return ExaminationStatusUtils.reportExported;
    }
    return normalized;
  }

  int get patientAge {
    if (patientDateOfBirth == null) return 0;
    final now = DateTime.now();
    var age = now.year - patientDateOfBirth!.year;
    if (now.month < patientDateOfBirth!.month ||
        (now.month == patientDateOfBirth!.month &&
            now.day < patientDateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get patientAgeDisplay => patientAge > 0 ? '$patientAge' : '---';

  String get patientDateOfBirthDisplay {
    if (patientDateOfBirth == null) return '---';
    return DateFormat('dd/MM/yyyy').format(patientDateOfBirth!);
  }

  String get patientGenderDisplay {
    switch (patientGender.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      case 'OTHER':
        return 'Khác';
      default:
        return patientGender.isEmpty ? '---' : patientGender;
    }
  }

  String get statusDisplay {
    return ExaminationStatusUtils.display(statusGroup);
  }

  String get studyDateDisplay {
    if (studyDate == null) return '---';
    return DateFormat('dd/MM/yyyy').format(studyDate!);
  }

  String get visitTimeDisplay {
    if (visitTime == null) return '---';
    return DateFormat('dd/MM/yyyy HH:mm').format(visitTime!);
  }
}
