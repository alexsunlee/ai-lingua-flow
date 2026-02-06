import '../../domain/entities/assessment_report.dart';
import '../../domain/entities/learning_activity.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/assessment_local_datasource.dart';
import '../models/assessment_report_model.dart';
import '../models/learning_activity_model.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentLocalDatasource _localDatasource;

  const AssessmentRepositoryImpl({
    required AssessmentLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<void> logActivity(LearningActivity activity) async {
    final model = LearningActivityModel.fromEntity(activity);
    await _localDatasource.insertActivity(model);
  }

  @override
  Future<List<LearningActivity>> getActivities({
    required DateTime start,
    required DateTime end,
  }) async {
    return _localDatasource.getActivities(start: start, end: end);
  }

  @override
  Future<List<LearningActivity>> getActivitiesByType(
      String activityType) async {
    return _localDatasource.getActivitiesByType(activityType);
  }

  @override
  Future<void> saveReport(AssessmentReport report) async {
    final model = AssessmentReportModel.fromEntity(report);
    await _localDatasource.insertReport(model);
  }

  @override
  Future<List<AssessmentReport>> getReports() async {
    return _localDatasource.getReports();
  }

  @override
  Future<AssessmentReport?> getLatestReport() async {
    return _localDatasource.getLatestReport();
  }
}
