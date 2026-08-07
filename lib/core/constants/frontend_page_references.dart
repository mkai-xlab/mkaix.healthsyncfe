class FrontendPageReference {
  final String key;
  final String label;
  final String role;

  const FrontendPageReference({
    required this.key,
    required this.label,
    required this.role,
  });
}

const List<FrontendPageReference> frontendPageReferences = [
  FrontendPageReference(
    key: 'doctor_dashboard_page',
    label: 'Dashboard bác sĩ',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'patient_list_page',
    label: 'Danh sách bệnh nhân',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'patient_detail_page',
    label: 'Chi tiết bệnh nhân',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'examination_list_page',
    label: 'Danh sách ca khám',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'dicom_upload_page',
    label: 'Tải ảnh DICOM',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'file_upload_page',
    label: 'Tải file DICOM',
    role: 'DOCTOR',
  ),
];
