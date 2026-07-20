import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/examination_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/examination_viewmodel.dart';

class DoctorDashboardPage extends StatefulWidget {
  final bool embedded;

  const DoctorDashboardPage({super.key, this.embedded = false});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  static const Color _bg = AppColors.surface1;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<ExaminationViewModel>().loadDashboardExaminations(
        token: token,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: _bg,
      child: Consumer<ExaminationViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.examinations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final stats = vm.examinations.isEmpty
              ? _DashboardStats.sample()
              : _DashboardStats.from(
                  vm.examinations,
                  totalElements: vm.totalElements,
                );
          return _DashboardContent(
            stats: stats,
            warning: vm.errorMessage,
            onRetry: () {
              final token =
                  context.read<AuthViewModel>().currentUser?.token ?? '';
              vm.loadDashboardExaminations(token: token);
            },
          );
        },
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(backgroundColor: _bg, body: content);
  }
}

class _DashboardContent extends StatelessWidget {
  final _DashboardStats stats;
  final String? warning;
  final VoidCallback? onRetry;

  const _DashboardContent({required this.stats, this.warning, this.onRetry});

  static const Color _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warning != null) ...[
            _WarningBanner(message: warning!, onRetry: onRetry),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                title: 'Tổng số ca',
                value: stats.total.toString(),
                trend: '+${stats.todayCount} hôm nay',
                icon: Icons.groups_2_outlined,
                accent: _primary,
              ),
              _StatCard(
                title: 'Ca nguy cơ cao',
                value: stats.severeCount.toString(),
                trend: '${stats.severePercent}%',
                icon: Icons.priority_high_rounded,
                accent: const Color(0xFFD71920),
              ),
              _StatCard(
                title: 'Đã hoàn thành',
                value: stats.completedCount.toString(),
                trend: '${stats.completedPercent}%',
                icon: Icons.verified_outlined,
                accent: _primary,
              ),
              _StatCard(
                title: 'Chờ xác nhận',
                value: stats.pendingCount.toString().padLeft(2, '0'),
                trend: 'cần xử lý',
                icon: Icons.more_horiz_rounded,
                accent: const Color(0xFFD4A017),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1060;
              final left = _GradeDistributionCard(stats: stats);
              final middle = _TrendCard(stats: stats);
              final right = _SevereAlertCard(stats: stats);
              if (!wide) {
                return Column(
                  children: [
                    left,
                    const SizedBox(height: 16),
                    middle,
                    const SizedBox(height: 16),
                    right,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: left),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: middle),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _RecentTable(stats: stats),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _WarningBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD4A017), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đang hiển thị dữ liệu mẫu do chưa tải được dashboard: $message',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B4E00)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 118,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    trend,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Color(0xFF4B5563))),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeDistributionCard extends StatelessWidget {
  final _DashboardStats stats;

  const _GradeDistributionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Phân bố KL Grade',
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 126,
                    height: 126,
                    child: CircularProgressIndicator(
                      value: stats.total == 0
                          ? 0
                          : stats.grade4Count / stats.total,
                      strokeWidth: 12,
                      color: const Color(0xFFD71920),
                      backgroundColor: const Color(0xFFE7F5F1),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stats.total.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text('Tổng số', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend('Grade 0-1', stats.lowGradePercent, AppColors.primary),
              _Legend(
                'Grade 2-3',
                stats.midGradePercent,
                const Color(0xFFD4A017),
              ),
              _Legend('Grade 4', stats.grade4Percent, const Color(0xFFD71920)),
              _Legend(
                'Khác',
                stats.unknownGradePercent,
                const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final _DashboardStats stats;

  const _TrendCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.weeklyCounts.fold<int>(1, (m, e) => e > m ? e : m);
    return _Panel(
      title: 'Xu hướng phân tích',
      trailing: const _SmallBadge('7 ngày qua'),
      child: SizedBox(
        height: 236,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(stats.weeklyCounts.length, (index) {
            final count = stats.weeklyCounts[index];
            final height = 42 + (count / maxCount) * 118;
            final isToday = index == stats.weeklyCounts.length - 1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: height,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : const Color(0xFFE0F4EF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stats.weekdayLabels[index],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SevereAlertCard extends StatelessWidget {
  final _DashboardStats stats;

  const _SevereAlertCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Cảnh báo ca nghiêm trọng',
      titleColor: const Color(0xFFD71920),
      child: Column(
        children: stats.severeExaminations.isEmpty
            ? [
                const SizedBox(height: 36),
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 42,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                const Text('Chưa có ca nghiêm trọng'),
              ]
            : stats.severeExaminations
                  .take(3)
                  .map((item) => _SevereItem(examination: item))
                  .toList(),
      ),
    );
  }
}

class _RecentTable extends StatelessWidget {
  final _DashboardStats stats;

  const _RecentTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Lịch sử phân tích gần đây',
      trailing: const _SmallBadge('Bộ lọc'),
      child: Column(
        children: [
          const Divider(height: 24),
          _TableHeader(),
          const Divider(height: 20),
          if (stats.recentExaminations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Chưa có dữ liệu phân tích'),
            )
          else
            ...stats.recentExaminations
                .take(5)
                .map((item) => _TableRow(examination: item)),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hiển thị ${stats.recentExaminations.isEmpty ? 0 : 1} - '
              '${stats.recentExaminations.take(5).length} trên ${stats.totalResults} kết quả',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color titleColor;

  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
    this.titleColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const _Legend(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text('$label ($percent%)')),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;

  const _SmallBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _SevereItem extends StatelessWidget {
  final ExaminationEntity examination;

  const _SevereItem({required this.examination});

  @override
  Widget build(BuildContext context) {
    final grade = examination.maxPredictedGrade;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examination.patientName.isEmpty
                      ? examination.patientCode
                      : 'BN: ${examination.patientName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  examination.description.isNotEmpty
                      ? examination.description
                      : examination.chiefComplaint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            grade > 0 ? 'GRADE $grade' : 'N/A',
            style: TextStyle(
              color: grade >= 4
                  ? const Color(0xFFD71920)
                  : const Color(0xFFD4A017),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 2, child: Text('Mã bệnh nhân')),
        Expanded(flex: 3, child: Text('Thông tin bệnh nhân')),
        Expanded(flex: 3, child: Text('Thời gian phân tích')),
        Expanded(flex: 2, child: Text('KL Grade')),
        Expanded(flex: 2, child: Text('Mức độ nguy cơ')),
        Expanded(flex: 2, child: Text('Trạng thái')),
        SizedBox(width: 42, child: Text('')),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final ExaminationEntity examination;

  const _TableRow({required this.examination});

  @override
  Widget build(BuildContext context) {
    final grade = examination.maxPredictedGrade;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(examination.patientCode)),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examination.patientName.isEmpty
                      ? '---'
                      : examination.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${examination.patientAgeDisplay} tuổi • ${examination.patientGenderDisplay}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(_formatDateTime(examination))),
          Expanded(
            flex: 2,
            child: Text(
              grade > 0 ? 'Grade $grade' : '---',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(flex: 2, child: _RiskBadge(grade: grade)),
          Expanded(
            flex: 2,
            child: _StatusBadge(text: examination.statusDisplay),
          ),
          const SizedBox(
            width: 42,
            child: Icon(Icons.visibility_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(ExaminationEntity item) {
    final date = item.visitTime ?? item.studyDate;
    if (date == null) return '---';
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }
}

class _RiskBadge extends StatelessWidget {
  final int grade;

  const _RiskBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    final high = grade >= 4;
    final medium = grade >= 2;
    final label = high ? 'Rất cao' : (medium ? 'Cao' : 'Thấp');
    final color = high
        ? const Color(0xFFD71920)
        : (medium ? const Color(0xFFE8942D) : AppColors.primary);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;

  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF8EF),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      ),
    );
  }
}

class _DashboardStats {
  final List<ExaminationEntity> examinations;
  final List<ExaminationEntity> recentExaminations;
  final List<ExaminationEntity> severeExaminations;
  final List<int> weeklyCounts;
  final List<String> weekdayLabels;
  final int total;
  final int totalResults;
  final int todayCount;
  final int severeCount;
  final int completedCount;
  final int pendingCount;
  final int lowGradeCount;
  final int midGradeCount;
  final int grade4Count;
  final int unknownGradeCount;

  const _DashboardStats({
    required this.examinations,
    required this.recentExaminations,
    required this.severeExaminations,
    required this.weeklyCounts,
    required this.weekdayLabels,
    required this.total,
    required this.totalResults,
    required this.todayCount,
    required this.severeCount,
    required this.completedCount,
    required this.pendingCount,
    required this.lowGradeCount,
    required this.midGradeCount,
    required this.grade4Count,
    required this.unknownGradeCount,
  });

  factory _DashboardStats.from(
    List<ExaminationEntity> source, {
    int? totalElements,
  }) {
    final sorted = [...source]
      ..sort((a, b) {
        final bDate = b.visitTime ?? b.studyDate ?? DateTime(1900);
        final aDate = a.visitTime ?? a.studyDate ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final weeklyCounts = List<int>.filled(7, 0);
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final weekdayLabels = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      return labels[date.weekday - 1];
    });

    var todayCount = 0;
    var completed = 0;
    var pending = 0;
    var low = 0;
    var mid = 0;
    var g4 = 0;
    var unknown = 0;

    for (final item in sorted) {
      final date = item.visitTime ?? item.studyDate;
      if (date != null) {
        final day = DateTime(date.year, date.month, date.day);
        if (day == today) todayCount++;
        final diff = day.difference(weekStart).inDays;
        if (diff >= 0 && diff < 7) weeklyCounts[diff]++;
      }
      if (item.statusGroup == 'COMPLETED') completed++;
      if ({
        'PENDING',
        'NEED_VERIFY',
        'NEED_REVERIFY',
        'AWAITING_REVIEW',
        'AI_COMPLETED',
      }.contains(item.statusGroup)) {
        pending++;
      }
      final grade = item.maxPredictedGrade;
      if (grade <= 0) {
        unknown++;
      } else if (grade <= 1) {
        low++;
      } else if (grade <= 3) {
        mid++;
      } else {
        g4++;
      }
    }

    final severe = sorted.where((item) => item.maxPredictedGrade >= 4).toList();
    return _DashboardStats(
      examinations: sorted,
      recentExaminations: sorted,
      severeExaminations: severe,
      weeklyCounts: weeklyCounts,
      weekdayLabels: weekdayLabels,
      total: sorted.length,
      totalResults: totalElements ?? sorted.length,
      todayCount: todayCount,
      severeCount: severe.length,
      completedCount: completed,
      pendingCount: pending,
      lowGradeCount: low,
      midGradeCount: mid,
      grade4Count: g4,
      unknownGradeCount: unknown,
    );
  }

  factory _DashboardStats.sample() {
    final now = DateTime.now();
    final samples = [
      ExaminationEntity(
        patientCode: '#BN-2023-001',
        patientName: 'Trần Thị Hoa',
        patientGender: 'FEMALE',
        patientDateOfBirth: DateTime(now.year - 62, 4, 12),
        examinationId: 1,
        encounterCode: 'EX-001',
        status: 'COMPLETED',
        visitTime: now.subtract(const Duration(hours: 2)),
        thumbnailUrl: '',
        bodyPart: 'Knee',
        referringPhysician: '',
        description: 'Thoái hóa khớp nặng, tràn dịch khớp',
        maxPredictedGrade: 4,
        images: const [],
      ),
      ExaminationEntity(
        patientCode: '#BN-2023-045',
        patientName: 'Trương Minh Đạt',
        patientGender: 'MALE',
        patientDateOfBirth: DateTime(now.year - 68, 8, 2),
        examinationId: 2,
        encounterCode: 'EX-002',
        status: 'NEED_VERIFY',
        visitTime: now.subtract(const Duration(hours: 5)),
        thumbnailUrl: '',
        bodyPart: 'Knee',
        referringPhysician: '',
        description: 'Hẹp khe khớp nghiêm trọng',
        maxPredictedGrade: 3,
        images: const [],
      ),
      ExaminationEntity(
        patientCode: '#BN-2023-089',
        patientName: 'Phạm Quỳnh Anh',
        patientGender: 'FEMALE',
        patientDateOfBirth: DateTime(now.year - 35, 1, 20),
        examinationId: 3,
        encounterCode: 'EX-003',
        status: 'COMPLETED',
        visitTime: now.subtract(const Duration(days: 1, hours: 3)),
        thumbnailUrl: '',
        bodyPart: 'Knee',
        referringPhysician: '',
        description: 'Tăng sừng hóa đầu xương',
        maxPredictedGrade: 1,
        images: const [],
      ),
      ExaminationEntity(
        patientCode: '#BN-2023-102',
        patientName: 'Lê Văn A',
        patientGender: 'MALE',
        patientDateOfBirth: DateTime(now.year - 59, 6, 9),
        examinationId: 4,
        encounterCode: 'EX-004',
        status: 'AWAITING_REVIEW',
        visitTime: now.subtract(const Duration(days: 2, hours: 1)),
        thumbnailUrl: '',
        bodyPart: 'Knee',
        referringPhysician: '',
        description: 'Cần bác sĩ xác nhận kết quả AI',
        maxPredictedGrade: 4,
        images: const [],
      ),
      ExaminationEntity(
        patientCode: '#BN-2023-118',
        patientName: 'Nguyễn Thị B',
        patientGender: 'FEMALE',
        patientDateOfBirth: DateTime(now.year - 47, 11, 4),
        examinationId: 5,
        encounterCode: 'EX-005',
        status: 'AI_COMPLETED',
        visitTime: now.subtract(const Duration(days: 3, hours: 6)),
        thumbnailUrl: '',
        bodyPart: 'Knee',
        referringPhysician: '',
        description: 'AI đã phân tích, chờ xác nhận',
        maxPredictedGrade: 2,
        images: const [],
      ),
    ];
    return _DashboardStats.from(samples, totalElements: samples.length);
  }

  int get severePercent => _percent(severeCount);
  int get completedPercent => _percent(completedCount);
  int get lowGradePercent => _percent(lowGradeCount);
  int get midGradePercent => _percent(midGradeCount);
  int get grade4Percent => _percent(grade4Count);
  int get unknownGradePercent => _percent(unknownGradeCount);

  int _percent(int value) {
    if (total <= 0) return 0;
    return ((value / total) * 100).round();
  }
}
