/// Lần khám mock — dùng tạm khi backend chưa có dữ liệu
class MockExam {
  final String id;
  final DateTime examDate;
  final String diagnosis; // kết quả / ghi chú
  final String device; // thiết bị chụp
  final String protocol; // protocol chụp
  final List<String> images; // asset paths

  const MockExam({
    required this.id,
    required this.examDate,
    required this.diagnosis,
    required this.device,
    required this.protocol,
    required this.images,
  });
}

class MockExams {
  /// Trả về danh sách lần khám theo patientCode
  static List<MockExam> forPatient(String patientCode) {
    return _data[patientCode] ?? [];
  }

  static final Map<String, List<MockExam>> _data = {
    '2600056713': [
      MockExam(
        id: 'EX-2026-001',
        examDate: DateTime(2026, 3, 15, 9, 42),
        diagnosis:
            'Chụp X-quang khớp gối thẳng. Giao thức: Gối thẳng (GOI THANG). '
            'Thiết bị: GE Healthcare Optima XR646. KVP: 54.',
        device: 'GE Healthcare Optima XR646',
        protocol: 'GOI THANG',
        images: [
          'lib/presentation/images/BaSinh_GoiThang1.png',
          'lib/presentation/images/BaSinh_GoiThang2.png',
        ],
      ),
      MockExam(
        id: 'EX-2025-047',
        examDate: DateTime(2025, 10, 3, 14, 15),
        diagnosis: 'Chụp kiểm tra định kỳ. Khớp gối chưa có thay đổi đáng kể.',
        device: 'GE Healthcare Optima XR646',
        protocol: 'GOI THANG',
        images: [],
      ),
    ],
    'BN-2026-0042': [
      MockExam(
        id: 'EX-2026-010',
        examDate: DateTime(2026, 2, 20, 10, 0),
        diagnosis: 'Chụp khớp gối trái. Phát hiện hẹp khe khớp nhẹ.',
        device: 'Siemens YSIO Max',
        protocol: 'KNEE AP',
        images: [],
      ),
    ],
  };
}
