import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DoctorHomepage extends StatefulWidget {
  const DoctorHomepage({super.key});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (!isMobile) _buildSidebar(context),
          // Main Content
          Expanded(child: _buildMainContent(context)),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF1B5A4E),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7E6E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.healing,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'VIỆN Y HỌC CÓ TRUYỀN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Text(
                  'QUÂN ĐỘI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'HỖ TRỢ CHẨN ĐOÁN X-QUANG KHỚP GỐI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(0, 'Trang chủ', Icons.home_outlined),
                _buildNavItem(1, 'Danh sách bệnh nhân', Icons.people_outline),
                _buildNavItem(
                  2,
                  'Hỗ trợ chẩn đoán',
                  Icons.medical_information_outlined,
                ),
                _buildNavItem(3, 'Thông báo', Icons.notifications_outlined),
                _buildNavItem(4, 'Hỗ trợ', Icons.help_outline),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.white70,
                size: 20,
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              onTap: () {
                context.read<AuthViewModel>().logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedNavIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      shape: isSelected
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1B5A4E),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D7E6E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.healing,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VIỆN Y HỌC CÓ TRUYỀN QUÂN ĐỘI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildNavItem(0, 'Trang chủ', Icons.home_outlined),
                  _buildNavItem(1, 'Danh sách bệnh nhân', Icons.people_outline),
                  _buildNavItem(
                    2,
                    'Hỗ trợ chẩn đoán',
                    Icons.medical_information_outlined,
                  ),
                  _buildNavItem(3, 'Thông báo', Icons.notifications_outlined),
                  _buildNavItem(4, 'Hỗ trợ', Icons.help_outline),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  context.read<AuthViewModel>().logout();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),
                  // Charts and Alerts Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KL Grade Section
                      Expanded(flex: 1, child: _buildKLGradeSection()),
                      const SizedBox(width: 20),
                      // Trend Analysis Section
                      Expanded(flex: 1, child: _buildTrendAnalysisSection()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Critical Cases Alert
                  _buildCriticalCasesAlert(),
                  const SizedBox(height: 24),
                  // Patient List Table
                  _buildPatientListTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Mobile Menu Button
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF2D7E6E)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          // Search Bar
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bệnh nhân...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D7E6E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D7E6E)),
            onPressed: () {},
          ),
          // Profile Button
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF2D7E6E),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Row(
      children: [
        _buildStatCard(
          'Tổng số ca hôm nay',
          '148',
          '+12%',
          Colors.green,
          Icons.trending_up,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Ca nguy cơ cao',
          '32',
          '+5%',
          Colors.red,
          Icons.trending_up,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Đã hoàn thành',
          '112',
          '',
          const Color(0xFF2D7E6E),
          Icons.check_circle,
        ),
        const SizedBox(width: 16),
        _buildStatCard('Chờ xác nhận', '04', '', Colors.orange, Icons.schedule),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String? changePercent,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (changePercent != null && changePercent.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        changePercent,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKLGradeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố KL Grade',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildGradeBar(
                    'Grade 0-1\n(35%)',
                    0.35,
                    const Color(0xFF4CAF50),
                  ),
                  _buildGradeBar(
                    'Grade 2-3\n(30%)',
                    0.30,
                    const Color(0xFFFFC107),
                  ),
                  _buildGradeBar('Khác\n(20%)', 0.20, const Color(0xFFBDBDBD)),
                  _buildGradeBar(
                    'Grade 4\n(15%)',
                    0.15,
                    const Color(0xFFF44336),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBar(String label, double percentage, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 50,
          height: 150 * percentage,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xu hướng phân tích',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '7 ngày qua',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple trend chart
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5,
                    (index) =>
                        Container(height: 1, color: Colors.grey.shade200),
                  ),
                ),
                // Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTrendBar(130, 'T2'),
                    _buildTrendBar(150, 'T3'),
                    _buildTrendBar(145, 'T4'),
                    _buildTrendBar(180, 'T5'),
                    _buildTrendBar(160, 'T6'),
                    _buildTrendBar(170, 'T7'),
                    _buildTrendBar(200, 'CN'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF2D7E6E),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCriticalCasesAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cảnh báo ca nghiêm trọng trong',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Critical cases list
          _buildCriticalCaseItem(
            'BN: Lê Văn A',
            'GRADE 4',
            'Thuyền hóa khớp gối nặng...',
          ),
          const SizedBox(height: 12),
          _buildCriticalCaseItem(
            'BN: Trần Thị B',
            'GRADE 4',
            'Hạp khớp khớp gối trong...',
          ),
          const SizedBox(height: 12),
          _buildCriticalCaseItem(
            'BN: Phạm Minh C',
            'GRADE 3',
            'Tăng sóng nóa dữa xương...',
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalCaseItem(
    String patient,
    String grade,
    String description,
  ) {
    final gradeColor = grade == 'GRADE 4' ? Colors.red : Colors.orange;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: gradeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            grade,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientListTable() {
    final patients = [
      {
        'maBN': '#BN-2023-001',
        'hoTen': 'Nguyễn Văn Khải',
        'tuoi': '54 tuổi • Nam',
        'tgPhanTich': '14:20 - 24/10/2023',
        'klGrade': 'Grade 4',
        'mucDo': 'Rất cao',
        'trangThai': 'Đã xác nhận',
      },
      {
        'maBN': '#BN-2023-012',
        'hoTen': 'Lê Thị Mai',
        'tuoi': '42 tuổi • Nữ',
        'tgPhanTich': '13:45 - 24/10/2023',
        'klGrade': 'Grade 2',
        'mucDo': 'Trung bình',
        'trangThai': 'Chờ quyết',
      },
      {
        'maBN': '#BN-2023-045',
        'hoTen': 'Trương Minh Đạt',
        'tuoi': '68 tuổi • Nam',
        'tgPhanTich': '11:10 - 24/10/2023',
        'klGrade': 'Grade 3',
        'mucDo': 'Cao',
        'trangThai': 'Đã xác nhận',
      },
      {
        'maBN': '#BN-2023-089',
        'hoTen': 'Phạm Quỳnh Anh',
        'tuoi': '39 tuổi • Nữ',
        'tgPhanTich': '09:30 - 24/10/2023',
        'klGrade': 'Grade 1',
        'mucDo': 'Thấp',
        'trangThai': 'Đã xác nhận',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử phân tích gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF2D7E6E),
                      ),
                      label: const Text(
                        'Bộ lọc',
                        style: TextStyle(color: Color(0xFF2D7E6E)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Xuất báo cáo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7E6E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Mã bệnh nhân')),
                DataColumn(label: Text('Thông tin bệnh nhân')),
                DataColumn(label: Text('Thời gian phân tích')),
                DataColumn(label: Text('KL Grade')),
                DataColumn(label: Text('Mức độ nguy cơ')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: patients.map((patient) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        patient['maBN']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            patient['hoTen']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            patient['tuoi']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        patient['tgPhanTich']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(
                            patient['klGrade']!,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          patient['klGrade']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(patient['klGrade']!),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskColor(
                            patient['mucDo']!,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          patient['mucDo']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getRiskColor(patient['mucDo']!),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            patient['trangThai']!,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          patient['trangThai']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getStatusColor(patient['trangThai']!),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF2D7E6E),
                          size: 18,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          // Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị 1 - 4 trên 144 kết quả',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.grey),
                      onPressed: () {},
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7E6E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '2',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '3',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.grey),
                      onPressed: () {},
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

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'Grade 1':
        return Colors.green;
      case 'Grade 2':
        return Colors.orange;
      case 'Grade 3':
        return Colors.orange;
      case 'Grade 4':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Thấp':
        return Colors.green;
      case 'Trung bình':
        return Colors.orange;
      case 'Cao':
        return Colors.orange;
      case 'Rất cao':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã xác nhận':
        return Colors.green;
      case 'Chờ quyết':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
