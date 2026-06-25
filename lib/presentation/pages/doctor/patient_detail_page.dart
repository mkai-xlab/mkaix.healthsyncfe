import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/patient_entity.dart';
import '../../../data/mock/mock_exams.dart';
import '../../viewmodels/auth_viewmodel.dart';

class PatientDetailPage extends StatefulWidget {
  final PatientEntity patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  int _selectedExamIndex = 0;
  int _selectedImageIndex = 0;
  final _noteController = TextEditingController();

  static const Color _primaryGreen = Color(0xFF2D7E6E);
  static const Color _darkGreen = Color(0xFF1B5A4E);

  List<MockExam> get _exams => MockExams.forPatient(widget.patient.patientCode);

  MockExam? get _currentExam =>
      _exams.isEmpty ? null : _exams[_selectedExamIndex];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: isMobile
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPatientInfoBar(),
                        const SizedBox(height: 16),
                        _buildLeftPanel(),
                        const SizedBox(height: 16),
                        _buildXrayViewer(),
                        const SizedBox(height: 16),
                        _buildRightPanel(),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel
                      SizedBox(
                        width: 260,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildLeftPanel(),
                        ),
                      ),
                      // Center — X-ray viewer
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPatientInfoBar(),
                              const SizedBox(height: 16),
                              _buildXrayViewer(),
                            ],
                          ),
                        ),
                      ),
                      // Right panel
                      SizedBox(
                        width: 240,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildRightPanel(),
                        ),
                      ),
                    ],
                  ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ← Nút back
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: _primaryGreen,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // Search
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bệnh nhân, hồ sơ, mã số...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFADB5BD),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFF718096),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Doctor info
          Consumer<AuthViewModel>(
            builder: (_, vm, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE6F4F1),
                  child: Text(
                    vm.currentUser?.name.isNotEmpty == true
                        ? vm.currentUser!.name[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BS. ${vm.currentUser?.name ?? 'Bác sĩ'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2B3C),
                      ),
                    ),
                    const Text(
                      'Chẩn đoán hình ảnh',
                      style: TextStyle(fontSize: 10, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoBox(String asset) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.local_hospital, size: 18, color: _primaryGreen),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PATIENT INFO BAR
  // ─────────────────────────────────────────────
  Widget _buildPatientInfoBar() {
    final p = widget.patient;
    final exam = _currentExam;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: action buttons + risk badge
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, size: 15),
                label: const Text(
                  'Tạo chẩn đoán mới',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                label: const Text(
                  'Xuất báo cáo PDF',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              // AI status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, color: _primaryGreen, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Trạng thái AI: Đã hoàn thành',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFFE53E3E), size: 7),
                    SizedBox(width: 5),
                    Text(
                      'Nghiêm trọng · Grade 4',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          const SizedBox(height: 10),
          // Row 2: patient fields
          Wrap(
            spacing: 28,
            runSpacing: 8,
            children: [
              _infoField('MÃ BỆNH NHÂN', p.patientCode),
              _infoField('HỌ VÀ TÊN', p.fullName),
              _infoField(
                'TUỔI / GIỚI TÍNH',
                '${p.age > 0 ? p.age.toString() : 'N/A'} / ${p.genderDisplay}',
              ),
              _infoField(
                'NGÀY KHÁM',
                exam != null ? _fmtDate(exam.examDate) : '—',
              ),
              if (exam != null) _infoField('GIAO THỨC', exam.protocol),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF718096),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2B3C),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LEFT PANEL
  // ─────────────────────────────────────────────
  Widget _buildLeftPanel() {
    final exam = _currentExam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OCR info
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 16,
                    color: _primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thông tin OCR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exam != null) ...[
                _ocrRow('Ngày chụp:', _fmtDateTime(exam.examDate)),
                const SizedBox(height: 6),
                _ocrRow('Thiết bị:', exam.device),
                const SizedBox(height: 6),
                _ocrRow('Giao thức:', exam.protocol),
                const SizedBox(height: 10),
                Text(
                  'Ghi chú lâm sàng:',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.diagnosis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
              ] else
                const Text(
                  'Chưa có dữ liệu OCR',
                  style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lịch sử y tế
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_outlined, size: 16, color: _primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Lịch sử y tế',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_exams.isEmpty)
                const Text(
                  'Chưa có lần khám nào',
                  style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                )
              else
                ...List.generate(_exams.length, (i) {
                  final e = _exams[i];
                  final isSelected = i == _selectedExamIndex;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedExamIndex = i;
                      _selectedImageIndex = 0;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE6F4F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: _primaryGreen)
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryGreen
                                  : const Color(0xFFCBD5E0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fmtDate(e.examDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? _primaryGreen
                                        : const Color(0xFF718096),
                                  ),
                                ),
                                Text(
                                  e.protocol,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A2B3C),
                                  ),
                                ),
                                Text(
                                  e.device,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF718096),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (e.images.isNotEmpty)
                            const Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: Color(0xFF718096),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ghi chú bác sĩ
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.edit_note_outlined,
                    size: 16,
                    color: _primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ghi chú bác sĩ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập nhận xét của bác sĩ...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFADB5BD),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lưu ghi chú'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quay lại
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Quay lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A5568),
              side: const BorderSide(color: Color(0xFFCBD5E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // X-RAY VIEWER (CENTER)
  // ─────────────────────────────────────────────
  Widget _buildXrayViewer() {
    final exam = _currentExam;
    final images = exam?.images ?? [];

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Tab bar: Ảnh gốc / Grad-CAM / Overlay AI
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
            ),
            child: Row(
              children: [
                _xrayTab('Ảnh gốc', true),
                _xrayTab('Grad-CAM', false),
                _xrayTab('Overlay AI', false),
                const Spacer(),
                // Tools
                _iconTool(Icons.zoom_in),
                _iconTool(Icons.zoom_out),
                _iconTool(Icons.rotate_right_outlined),
                _iconTool(Icons.brightness_6_outlined),
                _iconTool(Icons.contrast_outlined),
              ],
            ),
          ),

          // Image display
          Container(
            height: 420,
            color: Colors.black,
            child: images.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white30,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có ảnh X-quang cho lần khám này',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main image
                      Positioned.fill(
                        child: Image.asset(
                          images[_selectedImageIndex],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white30,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                      // Image counter
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          children: [
                            // Dimensions
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'W: 2048  H: 1024',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Prev/next
                            _navBtn(
                              Icons.chevron_left,
                              _selectedImageIndex > 0
                                  ? () => setState(() => _selectedImageIndex--)
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_selectedImageIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _navBtn(
                              Icons.chevron_right,
                              _selectedImageIndex < images.length - 1
                                  ? () => setState(() => _selectedImageIndex++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Thumbnails
          if (images.length > 1)
            Container(
              height: 72,
              color: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = i),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: i == _selectedImageIndex
                            ? _primaryGreen
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(
                          Icons.image,
                          color: Colors.white30,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _xrayTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? _primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? _primaryGreen : const Color(0xFF718096),
        ),
      ),
    );
  }

  Widget _iconTool(IconData icon) {
    return IconButton(
      icon: Icon(icon, size: 18, color: const Color(0xFF718096)),
      onPressed: () {},
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.black54 : Colors.black26,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RIGHT PANEL
  // ─────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Column(
      children: [
        // AI Analysis result
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, size: 14, color: _primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Kết quả AI Analysis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Grade display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: const [
                    Text(
                      'KELLGREN · LAWRENCE',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF718096),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'GRADE 4',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                        height: 1,
                      ),
                    ),
                    Text(
                      'Giai đoạn cuối (Nghiêm trọng)',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE53E3E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _confidenceBar('Độ tin cậy (Confidence)', 0.984, '98.4%'),
              const SizedBox(height: 10),
              _confidenceBar(
                'Xác suất cần thiếp phẫu thuật',
                0.803,
                '80.3%',
                color: const Color(0xFFE53E3E),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // AI Insights
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lightbulb_outline, size: 14, color: _primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'AI Insights & Gợi ý',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _insightItem(
                Icons.warning_amber_rounded,
                const Color(0xFFE53E3E),
                const Color(0xFFFFF0F0),
                'Cảnh báo rủi ro cao',
                'Thu hẹp khoang khớp hoàn toàn. Xuất hiện gai xương lớn và tiêu biến đầu xương.',
              ),
              const SizedBox(height: 8),
              _insightItem(
                Icons.medical_services_outlined,
                const Color(0xFFD97706),
                const Color(0xFFFEF3C7),
                'Chẩn đoán gợi ý',
                'Thoái hóa khớp gối nguyên phát. Cần cân nhắc phẫu thuật thay khớp gối toàn phần.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ca liên quan
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.people_outline, size: 14, color: _primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'Ca liên quan tương đồng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _similarCase('BN-2023-0142', '88% tương đồng hình thái'),
              const SizedBox(height: 8),
              _similarCase('BN-2022-0988', '82% tương đồng hình thái'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confidenceBar(
    String label,
    double value,
    String text, {
    Color color = _primaryGreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _insightItem(
    IconData icon,
    Color iconColor,
    Color bg,
    String title,
    String body,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4A5568),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarCase(String code, String similarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 14, color: _primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                Text(
                  similarity,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 13, color: Color(0xFF718096)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STATUS BAR
  // ─────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Container(
      color: const Color(0xFF1A2B3C),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: const [
          Text(
            'Phiên bản hệ thống: KNEE-AI v4.0.2',
            style: TextStyle(fontSize: 9, color: Colors.white38),
          ),
          SizedBox(width: 16),
          Text('•', style: TextStyle(color: Colors.white24)),
          SizedBox(width: 16),
          Text(
            'Kết nối: PACS-SERVER-01 (Đang hoạt động)',
            style: TextStyle(fontSize: 9, color: Colors.white38),
          ),
          Spacer(),
          Text(
            '© 2026 Viện Y Học Cổ Truyền Quân Đội · Phân ban AI',
            style: TextStyle(fontSize: 9, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _ocrRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} – ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} AM';
}
