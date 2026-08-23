import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    required super.id,
    required super.patientCode,
    required super.fullName,
    super.dateOfBirth,
    required super.gender,
    super.phone,
    super.email,
    super.address,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.createdAt,
    super.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      patientCode: json['patientCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth: parseLocalDate(json['dateOfBirth']),
      gender: json['gender']?.toString() ?? 'OTHER',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      createdAt: parseUtcInstantToLocal(json['createdAt']),
      updatedAt: parseUtcInstantToLocal(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientCode': patientCode,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth != null
        ? dateOfBirth!.toIso8601String().split('T')[0]
        : null,
    'gender': gender,
    'phone': phone,
    'email': email,
    'address': address,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
  };
}
