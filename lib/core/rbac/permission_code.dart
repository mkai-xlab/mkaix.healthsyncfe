enum PermissionCode {
  viewDoctorDashboard('VIEW_DOCTOR_DASHBOARD'),
  readPatientList('READ_PATIENT_LIST'),
  viewPatientDetail('VIEW_PATIENT_DETAIL'),
  createPatientExam('CREATE_PATIENT_EXAM'),
  viewExaminationList('VIEW_EXAMINATION_LIST'),
  viewExaminationDetail('VIEW_EXAMINATION_DETAIL'),
  uploadDicomImage('UPLOAD_DICOM_IMAGE'),
  useAiChat('USE_AI_CHAT'),
  manageMedicalKnowledge('MANAGE_MEDICAL_KNOWLEDGE'),
  viewAiResult('VIEW_AI_RESULT'),
  generatePdfReport('GENERATE_PDF_REPORT'),
  exportDownloadPdf('EXPORT_DOWNLOAD_PDF'),
  addClinicalComment('ADD_CLINICAL_COMMENT'),
  overrideAiGrade('OVERRIDE_AI_GRADE'),
  confirmConclusion('CONFIRM_CONCLUSION'),
  compareXaiSideBySide('COMPARE_XAI_SIDE_BY_SIDE');

  const PermissionCode(this.value);

  final String value;

  static PermissionCode? fromValue(String value) {
    final normalized = value.trim().toUpperCase();
    for (final code in PermissionCode.values) {
      if (code.value == normalized) return code;
    }
    return null;
  }
}
