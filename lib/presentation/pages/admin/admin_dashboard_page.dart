import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/admin_dashboard_viewmodel.dart';
import '../../viewmodels/audit_log_viewmodel.dart';

class AdminDashboardPage extends StatelessWidget {
  final VoidCallback onViewAllAuditLogs;

  const AdminDashboardPage({super.key, required this.onViewAllAuditLogs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản trị hệ thống',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Giám sát hoạt động hệ thống AI hỗ trợ chẩn đoán X-quang khớp gối',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _DashboardStats(),
          const SizedBox(height: 24),
          const SizedBox(height: 410, child: _KLGradeDistribution()),
          const SizedBox(height: 24),
          _RecentActivityLog(onViewAllAuditLogs: onViewAllAuditLogs),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardViewModel>(
      builder: (context, vm, _) {
        final stats = vm.stats;
        final verifiedProgress = stats.totalExaminations <= 0
            ? 0.0
            : stats.verifiedExaminations / stats.totalExaminations;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            Row(
              children: [
                _StatCard(
                  title: 'Tổng số ca phân tích',
                  value: _formatCount(stats.totalExaminations),
                  subtitle:
                      '${_formatCount(stats.totalDicomStudies)} DICOM studies',
                  color: Colors.blue,
                  icon: Icons.assessment,
                  showProgress: true,
                  progressValue: verifiedProgress.clamp(0.0, 1.0),
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Ca nguy cơ cao',
                  value: _formatCount(stats.severeExaminations),
                  subtitle: 'KL nặng cần theo dõi',
                  color: Colors.orange,
                  icon: Icons.warning_amber,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Chờ xác nhận',
                  value: _formatCount(stats.unverifiedExaminations),
                  subtitle:
                      '${_formatCount(stats.verifiedExaminations)} đã xác nhận',
                  color: Colors.teal,
                  icon: Icons.fact_check_outlined,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Bác sĩ hoạt động',
                  value: _formatCount(stats.activeDoctors),
                  subtitle: '${_formatCount(stats.totalDoctors)} tổng bác sĩ',
                  color: Colors.purple,
                  icon: Icons.people,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Bệnh nhân',
                  value: _formatCount(stats.totalPatients),
                  subtitle: 'Tổng hồ sơ bệnh nhân',
                  color: Colors.green,
                  icon: Icons.personal_injury_outlined,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final bool showProgress;
  final double progressValue;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.showProgress = false,
    this.progressValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            if (showProgress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KLGradeDistribution extends StatelessWidget {
  const _KLGradeDistribution();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardViewModel>(
      builder: (context, vm, _) {
        final segments = _adminGradeSegments(vm.stats.gradeCounts);
        final total = segments.fold<int>(0, (sum, item) => sum + item.value);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân bổ bệnh nhân theo KL Grade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(220, 220),
                                painter: _DonutChartPainter(
                                  segments: segments,
                                  emptyColor: const Color(0xFFE7F5F1),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatCount(total),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Tổng số',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final segment in segments) ...[
                            _LegendItem(
                              label: segment.label,
                              value: segment.value,
                              total: total,
                              color: segment.color,
                            ),
                            if (segment != segments.last)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_AdminGradeSegment> _adminGradeSegments(Map<int, int> gradeCounts) {
    return [
      _AdminGradeSegment(
        label: 'KL 0',
        value: gradeCounts[0] ?? 0,
        color: const Color(0xFF2F855A),
      ),
      _AdminGradeSegment(
        label: 'KL 1',
        value: gradeCounts[1] ?? 0,
        color: const Color(0xFF38A169),
      ),
      _AdminGradeSegment(
        label: 'KL 2',
        value: gradeCounts[2] ?? 0,
        color: const Color(0xFFD4A017),
      ),
      _AdminGradeSegment(
        label: 'KL 3',
        value: gradeCounts[3] ?? 0,
        color: const Color(0xFFE67E22),
      ),
      _AdminGradeSegment(
        label: 'KL 4',
        value: gradeCounts[4] ?? 0,
        color: const Color(0xFFD71920),
      ),
    ];
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : ((value / total) * 100).round();
    final progress = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityLog extends StatelessWidget {
  final VoidCallback onViewAllAuditLogs;

  const _RecentActivityLog({required this.onViewAllAuditLogs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoạt động hệ thống gần đây',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: onViewAllAuditLogs,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D7E6E),
                  ),
                  child: const Text(
                    'Xem tất cả lịch sử >',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Consumer<AuditLogViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (vm.errorMessage != null && vm.logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                );
              }
              if (vm.logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có nhật ký hoạt động.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }

              final logs = vm.logs.take(5).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final actor = log.userDisplay;
                  final initial = actor.characters.first.toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _avatarColor(initial),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatAuditLogTime(log.timeStamp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                actor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.descriptionDisplay,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatAuditLogTime(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('HH:mm:ss, dd/MM/yyyy').format(date);
  }

  Color _avatarColor(String initial) {
    switch (initial) {
      case 'M':
        return const Color(0xFF4CAF50);
      case 'H':
        return const Color(0xFFFF9800);
      case 'S':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }
}

class _AdminGradeSegment {
  final String label;
  final int value;
  final Color color;

  const _AdminGradeSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_AdminGradeSegment> segments;
  final Color emptyColor;

  const _DonutChartPainter({required this.segments, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;
    final total = segments.fold<int>(0, (sum, item) => sum + item.value);

    if (total <= 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.emptyColor != emptyColor;
  }
}

String _formatCount(int value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}
