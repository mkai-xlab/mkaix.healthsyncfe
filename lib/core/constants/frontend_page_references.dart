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
  // Doctor pages
  FrontendPageReference(
    key: 'ai_clinical_chat_page',
    label: 'AI Chat',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'doctor_dashboard_page',
    label: 'Dashboard bác sĩ',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'doctor_profile_page',
    label: 'Hồ sơ bác sĩ',
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
    key: 'examination_detail_page',
    label: 'Chi tiết ca khám',
    role: 'DOCTOR',
  ),
  FrontendPageReference(
    key: 'file_upload_page',
    label: 'Tải file DICOM',
    role: 'DOCTOR',
  ),

  FrontendPageReference(
    key: 'knowledge_documents_page',
    label: 'Quáº£n lĂ½ kho tri thá»©c y khoa',
    role: 'DOCTOR',
  ),

  // Admin pages
  FrontendPageReference(
    key: 'admin_dashboard_page',
    label: 'Dashboard quản trị',
    role: 'ADMIN',
  ),
  FrontendPageReference(
    key: 'admin_user_management_page',
    label: 'Quản lý người dùng',
    role: 'ADMIN',
  ),
  FrontendPageReference(
    key: 'feature_permission_catalog_page',
    label: 'Quản lý phân quyền',
    role: 'ADMIN',
  ),
  FrontendPageReference(
    key: 'audit_log_page',
    label: 'Lịch sử hoạt động',
    role: 'ADMIN',
  ),
  FrontendPageReference(
    key: 'admin_system_settings_page',
    label: 'Cấu hình hệ thống',
    role: 'ADMIN',
  ),
  FrontendPageReference(
    key: 'knowledge_documents_page',
    label: 'Quản lý tài liệu',
    role: 'ADMIN',
  ),
];
