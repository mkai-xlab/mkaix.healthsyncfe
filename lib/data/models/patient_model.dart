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
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender']?.toString() ?? 'OTHER',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
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
