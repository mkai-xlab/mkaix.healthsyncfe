import 'package:intl/intl.dart';

class PatientEntity {
  final int id;
  final String patientCode;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender; // MALE | FEMALE | OTHER
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientEntity({
    required this.id,
    required this.patientCode,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    this.phone,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.createdAt,
    this.updatedAt,
  });

  /// Tính tuổi từ dateOfBirth
  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get genderDisplay {
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  String get displayAgeGender =>
      '${age > 0 ? '$age tuổi' : 'N/A'} • $genderDisplay';

  String get dobDisplay {
    if (dateOfBirth == null) return '---';
    return DateFormat('dd/MM/yyyy').format(dateOfBirth!);
  }

  String get createdAtDisplay {
    if (createdAt == null) return '---';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }
}
