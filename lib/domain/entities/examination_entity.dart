import 'package:intl/intl.dart';

class ExaminationImageEntity {
  final int examinationId;
  final String encounterCode;
  final String status;
  final DateTime? visitTime;
  final String imageUrl;

  const ExaminationImageEntity({
    required this.examinationId,
    required this.encounterCode,
    required this.status,
    this.visitTime,
    required this.imageUrl,
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
    required this.images,
  });

  String get statusGroup {
    final normalized = status.toUpperCase();
    if (normalized == 'PENDING_REVIEW') return 'PENDING';
    if (normalized == 'AWAITING_REVIEW') return 'AWAITING_REVIEW';
    if (normalized == 'ANALYZING') return 'ANALYZING';
    if (normalized == 'COMPLETED') return 'COMPLETED';
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
    switch (statusGroup) {
      case 'PENDING':
        return 'Đang chờ';
      case 'ANALYZING':
        return 'Đang phân tích';
      case 'AWAITING_REVIEW':
        return 'Chờ nhận xét';
      case 'COMPLETED':
        return 'Hoàn thành';
      default:
        return status.isEmpty ? 'Không rõ' : status;
    }
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
