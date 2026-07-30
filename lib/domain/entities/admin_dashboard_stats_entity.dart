class AdminDashboardStatsEntity {
  final int totalExaminations;
  final int verifiedExaminations;
  final int unverifiedExaminations;
  final int severeExaminations;
  final int totalDicomStudies;
  final int totalPatients;
  final int totalDoctors;
  final int activeDoctors;
  final Map<int, int> gradeCounts;
  final String? warningMessage;

  const AdminDashboardStatsEntity({
    required this.totalExaminations,
    required this.verifiedExaminations,
    required this.unverifiedExaminations,
    required this.severeExaminations,
    required this.totalDicomStudies,
    required this.totalPatients,
    required this.totalDoctors,
    required this.activeDoctors,
    required this.gradeCounts,
    this.warningMessage,
  });

  static const empty = AdminDashboardStatsEntity(
    totalExaminations: 0,
    verifiedExaminations: 0,
    unverifiedExaminations: 0,
    severeExaminations: 0,
    totalDicomStudies: 0,
    totalPatients: 0,
    totalDoctors: 0,
    activeDoctors: 0,
    gradeCounts: {},
  );

  int get inactiveDoctors {
    final inactive = totalDoctors - activeDoctors;
    return inactive < 0 ? 0 : inactive;
  }

  int get totalGradeCount {
    return gradeCounts.values.fold<int>(0, (total, count) => total + count);
  }
}
