import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/examination_dashboard_totals_entity.dart';
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
          final stats = _DashboardStats.from(
            vm.examinations,
            totalElements: vm.totalElements,
            dashboardTotals: vm.dashboardTotals,
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
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final user = context.read<AuthViewModel>().currentUser;
    final doctorName = user?.name ?? 'Bác sĩ';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Header
          _DashboardHeader(
            greeting: greeting,
            doctorName: doctorName,
            todayDate: DateFormat('dd/MM/yyyy').format(now),
            todayExams: stats.todayCount,
            severeCases: stats.severeCount,
          ),
          const SizedBox(height: 24),

          if (warning != null) ...[
            _WarningBanner(message: warning!, onRetry: onRetry),
            const SizedBox(height: 20),
          ],

          // Responsive Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 4;
              double childAspectRatio = 2.0;

              if (width < 600) {
                crossAxisCount = 1;
                childAspectRatio = 2.5;
              } else if (width < 900) {
                crossAxisCount = 2;
                childAspectRatio = 2.2;
              } else if (width < 1200) {
                crossAxisCount = 3;
                childAspectRatio = 2.0;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: childAspectRatio,
                children: [
                  _StatCard(
                    title: 'Tổng số ca',
                    value: stats.total.toString(),
                    trend: '+${stats.todayCount} hôm nay',
                    icon: Icons.groups_2_outlined,
                    accent: _primary,
                  ),
                  _StatCard(
                    title: 'Ca khám nặng',
                    value: stats.severeCount.toString(),
                    trend: '${stats.severePercent}%',
                    icon: Icons.priority_high_rounded,
                    accent: AppColors.error,
                  ),
                  _StatCard(
                    title: 'Đã hoàn thành',
                    value: stats.completedCount.toString(),
                    trend: '${stats.completedPercent}%',
                    icon: Icons.verified_outlined,
                    accent: AppColors.success,
                  ),
                  _StatCard(
                    title: 'Chờ xác nhận',
                    value: stats.pendingCount.toString(),
                    trend: 'cần xử lý',
                    icon: Icons.pending_actions_outlined,
                    accent: AppColors.warning,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Charts Row
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
                    const SizedBox(height: 20),
                    middle,
                    const SizedBox(height: 20),
                    right,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: left),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: middle),
                  const SizedBox(width: 20),
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

  String _getGreeting(int hour) {
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

// Dashboard Header Widget
class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String doctorName;
  final String todayDate;
  final int todayExams;
  final int severeCases;

  const _DashboardHeader({
    required this.greeting,
    required this.doctorName,
    required this.todayDate,
    required this.todayExams,
    required this.severeCases,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $doctorName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  todayDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryXLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$todayExams ca khám hôm nay',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (severeCases > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$severeCases ca khám nặng',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
        ],
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
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(stats.weeklyCounts.length, (index) {
                  final count = stats.weeklyCounts[index];
                  final heightFactor = maxCount > 0 ? count / maxCount : 0;
                  final isToday = index == stats.weeklyCounts.length - 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                height: heightFactor * 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isToday
                                        ? [
                                            AppColors.primaryLight,
                                            AppColors.primary,
                                          ]
                                        : [
                                            AppColors.primaryXLight.withOpacity(
                                              0.3,
                                            ),
                                            AppColors.primaryLight.withOpacity(
                                              0.2,
                                            ),
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(stats.weekdayLabels.length, (index) {
                final isToday = index == stats.weekdayLabels.length - 1;
                return Expanded(
                  child: Text(
                    stats.weekdayLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ),
          ],
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
      title: 'Ca khám nặng cần chú ý',
      titleColor: AppColors.error,
      child: Column(
        children: stats.severeExaminations.isEmpty
            ? [
                const SizedBox(height: 30),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.successLight.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    size: 28,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không có ca khám nặng',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    fontSize: 17,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examination.patientName.isEmpty
                      ? examination.patientCode
                      : examination.patientName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  examination.description.isNotEmpty
                      ? examination.description
                      : examination.chiefComplaint.isNotEmpty
                      ? examination.chiefComplaint
                      : 'Không có mô tả',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              grade > 0 ? 'GRADE $grade' : 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
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
    ExaminationDashboardTotalsEntity? dashboardTotals,
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
      total: dashboardTotals?.total ?? totalElements ?? sorted.length,
      totalResults: dashboardTotals?.total ?? totalElements ?? sorted.length,
      todayCount: todayCount,
      severeCount: dashboardTotals?.severe ?? severe.length,
      completedCount: dashboardTotals?.verified ?? completed,
      pendingCount: dashboardTotals?.unverified ?? pending,
      lowGradeCount: low,
      midGradeCount: mid,
      grade4Count: g4,
      unknownGradeCount: unknown,
    );
  }

  int get severePercent => _percentOf(severeCount, totalResults);
  int get completedPercent => _percent(completedCount);
  int get lowGradePercent => _percent(lowGradeCount);
  int get midGradePercent => _percent(midGradeCount);
  int get grade4Percent => _percent(grade4Count);
  int get unknownGradePercent => _percent(unknownGradeCount);

  int _percent(int value) {
    if (total <= 0) return 0;
    return ((value / total) * 100).round();
  }

  int _percentOf(int value, int denominator) {
    if (denominator <= 0) return 0;
    return ((value / denominator) * 100).round();
  }
}
