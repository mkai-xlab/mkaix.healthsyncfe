class ExaminationDashboardTotalsEntity {
  final int total;
  final int verified;
  final int unverified;
  final int severe;
  final String? warningMessage;

  const ExaminationDashboardTotalsEntity({
    required this.total,
    required this.verified,
    required this.unverified,
    required this.severe,
    this.warningMessage,
  });
}
