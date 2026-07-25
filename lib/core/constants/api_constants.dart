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
  static String patientByIdEndpoint(String patientId) =>
      '$patientsEndpoint/$patientId';
  static const String examinationsEndpoint = '$baseUrl/examinations';
  static String examinationByIdEndpoint(int id) => '$examinationsEndpoint/$id';
  static String examinationReportEndpoint(int id) =>
      '$examinationsEndpoint/$id/generate-report';
  static String markExaminationViewedEndpoint(int id) =>
      '$examinationsEndpoint/$id/view';
  static String examinationsByPatientEndpoint(String patientId) =>
      '$examinationsEndpoint/patient/$patientId';
  static String examinationsByPatientStudyMonthEndpoint(String patientId) =>
      '$examinationsEndpoint/patient/$patientId/filter/study-month';
  static String examinationsByDoctorEndpoint(int doctorId) =>
      '$examinationsEndpoint/doctor/$doctorId';
  static const String examinationsTotalEndpoint = '$examinationsEndpoint/total';
  static const String examinationsTotalVerifiedEndpoint =
      '$examinationsEndpoint/total-verified';
  static const String examinationsTotalUnverifiedEndpoint =
      '$examinationsEndpoint/total-unverified';
  static const String examinationsTotalSevereEndpoint =
      '$examinationsEndpoint/total-severe';
  static const String examinationsStatusEndpoint =
      '$examinationsEndpoint/status';
  static const String examinationsGradeEndpoint = '$examinationsEndpoint/grade';
  static const String examinationsUploadDateFilterEndpoint =
      '$examinationsEndpoint/filter/upload-date';
  static const String examinationsStudyDateFilterEndpoint =
      '$examinationsEndpoint/filter/study-date';
  static const String examinationsUploadDateSortEndpoint =
      '$examinationsEndpoint/sort/upload-date';
  static const String examinationsStudyDateSortEndpoint =
      '$examinationsEndpoint/sort/study-date';
  static const String patientGradeStatisticsEndpoint =
      '$examinationsEndpoint/statistics/patients-by-grade';
  static const String myTotalExaminationsEndpoint =
      '$examinationsEndpoint/my-total';
  static const String myTotalVerifiedExaminationsEndpoint =
      '$examinationsEndpoint/my-total-verified';
  static const String myTotalUnverifiedExaminationsEndpoint =
      '$examinationsEndpoint/my-total-unverified';
  static const String myTotalSevereExaminationsEndpoint =
      '$examinationsEndpoint/my-total-severe';
  static const String userAccountsEndpoint = '$baseUrl/users';
  static const String staffUsersEndpoint = '$baseUrl/users/staff';

  // doctors endpoints
  static const String doctorsEndpoint = '$baseUrl/doctors';
  static const String createDoctorsEndpoint = '$baseUrl/doctors';
  static const String activeDoctorsEndpoint = '$baseUrl/doctors/active';
  static const String doctorProfileEndpoint = '$baseUrl/doctors/profile';
  static String doctorByIdEndpoint(int id) => '$doctorsEndpoint/$id';
  static String activateDoctorEndpoint(int id) =>
      '$doctorsEndpoint/$id/activate';
  static String deactivateDoctorEndpoint(int id) =>
      '$doctorsEndpoint/$id/deactivate';

  // permission / role endpoints
  static const String permissionsEndpoint = '$baseUrl/permissions';
  static const String permissionsTreeEndpoint = '$baseUrl/permissions/tree';
  static const String rolePermissionsEndpoint = '$baseUrl/permissions/role';
  static const String rolesEndpoint = '$baseUrl/roles';
  static const String featuresEndpoint = '$baseUrl/features';
  static String featureByIdEndpoint(String id) => '$featuresEndpoint/$id';
  static String permissionByIdEndpoint(String id) => '$permissionsEndpoint/$id';

  // AI endpoints
  static const String aiPredictBatchEndpoint = '$baseUrl/ai/predict-batch';
  static String aiHeatmapEndpoint(int aiResultId) =>
      '$baseUrl/ai/heatmap/$aiResultId';

  // DICOM endpoints
  static const String notificationsUnreadEndpoint =
      '$baseUrl/notifications/unread';
  static const String notificationsSendEndpoint = '$baseUrl/notifications/send';
  static String markNotificationReadEndpoint(int id) =>
      '$baseUrl/notifications/$id/read';
  static const String dicomUploadEndpoint = '$baseUrl/dicom/upload';
  static const String dicomUploadBatchEndpoint = '$baseUrl/dicom/upload/batch';
  static const String dicomUploadZipBatchEndpoint =
      '$baseUrl/dicom/upload/zip-batch';
  static const String dicomVerifyEndpoint = '$baseUrl/dicom/verify';
  static String dicomUploadSessionEndpoint(String sessionId) =>
      '$baseUrl/dicom/upload-session/$sessionId';
  static const String dicomTotalStudiesEndpoint =
      '$baseUrl/dicom/total-studies';
  static String dicomInstanceImageEndpoint(int id) =>
      '$baseUrl/dicom/instances/$id/image';
  static String dicomInstanceRawEndpoint(int id) =>
      '$baseUrl/dicom/instances/$id/raw';

  // Audit endpoints
  static const String auditLogsEndpoint = '$baseUrl/audit-logs';

  static String get webSocketUrl {
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(
          scheme: uri.scheme == 'https' ? 'wss' : 'ws',
          path: '${uri.path}/ws',
        )
        .toString();
  }
}
