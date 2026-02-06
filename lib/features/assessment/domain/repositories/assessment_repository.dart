import '../entities/assessment_report.dart';
import '../entities/learning_activity.dart';

abstract class AssessmentRepository {
  /// Log a new learning activity.
  Future<void> logActivity(LearningActivity activity);

  /// Retrieve activities within [start] and [end] dates (inclusive).
  Future<List<LearningActivity>> getActivities({
    required DateTime start,
    required DateTime end,
  });

  /// Retrieve activities filtered by [activityType].
  Future<List<LearningActivity>> getActivitiesByType(String activityType);

  /// Save an assessment report.
  Future<void> saveReport(AssessmentReport report);

  /// Retrieve all assessment reports, ordered by most recent first.
  Future<List<AssessmentReport>> getReports();

  /// Retrieve the latest assessment report, or `null` if none exists.
  Future<AssessmentReport?> getLatestReport();
}
