class AssessmentReport {
  final String id;
  final String reportType; // 'weekly', 'monthly', 'custom'
  final DateTime periodStart;
  final DateTime periodEnd;
  final double? overallScore;
  final Map<String, dynamic>? dimensionsJson; // reading, listening, speaking, vocabulary scores
  final String? summaryText;
  final List<String>? recommendations;
  final DateTime createdAt;

  const AssessmentReport({
    required this.id,
    required this.reportType,
    required this.periodStart,
    required this.periodEnd,
    this.overallScore,
    this.dimensionsJson,
    this.summaryText,
    this.recommendations,
    required this.createdAt,
  });
}
