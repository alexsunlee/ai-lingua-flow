import 'dart:convert';

import '../../domain/entities/assessment_report.dart';

class AssessmentReportModel extends AssessmentReport {
  const AssessmentReportModel({
    required super.id,
    required super.reportType,
    required super.periodStart,
    required super.periodEnd,
    super.overallScore,
    super.dimensionsJson,
    super.summaryText,
    super.recommendations,
    required super.createdAt,
  });

  /// Create an [AssessmentReportModel] from a SQLite row map.
  factory AssessmentReportModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? dimensions;
    if (map['dimensions_json'] != null &&
        (map['dimensions_json'] as String).isNotEmpty) {
      dimensions = jsonDecode(map['dimensions_json'] as String)
          as Map<String, dynamic>;
    }

    List<String>? recommendations;
    if (map['recommendations_json'] != null &&
        (map['recommendations_json'] as String).isNotEmpty) {
      final decoded = jsonDecode(map['recommendations_json'] as String);
      if (decoded is List) {
        recommendations = decoded.map((e) => e.toString()).toList();
      }
    }

    return AssessmentReportModel(
      id: map['id'] as String,
      reportType: map['report_type'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      dimensionsJson: dimensions,
      summaryText: map['summary_text'] as String?,
      recommendations: recommendations,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create an [AssessmentReportModel] from a domain entity.
  factory AssessmentReportModel.fromEntity(AssessmentReport entity) {
    return AssessmentReportModel(
      id: entity.id,
      reportType: entity.reportType,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      overallScore: entity.overallScore,
      dimensionsJson: entity.dimensionsJson,
      summaryText: entity.summaryText,
      recommendations: entity.recommendations,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to a map suitable for SQLite insert / update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_type': reportType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'overall_score': overallScore,
      'dimensions_json':
          dimensionsJson != null ? jsonEncode(dimensionsJson) : null,
      'summary_text': summaryText,
      'recommendations_json':
          recommendations != null ? jsonEncode(recommendations) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
