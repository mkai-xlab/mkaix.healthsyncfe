class ApiConstants {
  static const String swaggerUiUrl =
      'http://54.254.113.71:8000/api/v1/swagger-ui/index.html#/';
  static const String baseUrl = 'http://54.254.113.71:8000/api/v1';
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String forgotPasswordEndpoint = '$baseUrl/auth/forgot-password';
  static const String resetPasswordEndpoint = '$baseUrl/auth/reset-password';
  static const String changePasswordEndpoint = '$baseUrl/auth/change-password';
  static const String patientsEndpoint = '$baseUrl/patients';
  static String patientDetailsEndpoint(String patientId) =>
      '$patientsEndpoint/$patientId/details';
  static const String examinationsEndpoint = '$baseUrl/examinations';
  static String examinationByIdEndpoint(int id) => '$examinationsEndpoint/$id';
  static String examinationsByPatientEndpoint(String patientId) =>
      '$examinationsEndpoint/patient/$patientId';
  static String examinationsByDoctorEndpoint(int doctorId) =>
      '$examinationsEndpoint/doctor/$doctorId';
  static const String userAccountsEndpoint = '$baseUrl/users';

  // doctors endpoints
  static const String doctorsEndpoint = '$baseUrl/doctors';
  static const String createDoctorsEndpoint = '$baseUrl/doctors';

  // permission / role endpoints
  static const String permissionsEndpoint = '$baseUrl/permissions';
  static const String permissionsTreeEndpoint = '$baseUrl/permissions/tree';
  static const String rolePermissionsEndpoint = '$baseUrl/permissions/role';
  static const String rolesEndpoint = '$baseUrl/roles';

  // DICOM endpoints
  static const String dicomUploadEndpoint = '$baseUrl/dicom/upload';
  static const String dicomUploadBatchEndpoint = '$baseUrl/dicom/upload/batch';
}
