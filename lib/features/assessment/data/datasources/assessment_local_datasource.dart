import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/assessment_report_model.dart';
import '../models/learning_activity_model.dart';

class AssessmentLocalDatasource {
  // ---------------------------------------------------------------------------
  // Learning Activities
  // ---------------------------------------------------------------------------

  /// Insert a learning activity.
  Future<void> insertActivity(LearningActivityModel model) async {
    final db = await AppDatabase.database;
    await db.insert(
      'learning_activities',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve activities within [start] and [end] dates (inclusive),
  /// ordered by creation date descending.
  Future<List<LearningActivityModel>> getActivities({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'learning_activities',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
    return rows.map(LearningActivityModel.fromMap).toList();
  }

  /// Retrieve activities filtered by [activityType], ordered by creation date
  /// descending.
  Future<List<LearningActivityModel>> getActivitiesByType(
      String activityType) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'learning_activities',
      where: 'activity_type = ?',
      whereArgs: [activityType],
      orderBy: 'created_at DESC',
    );
    return rows.map(LearningActivityModel.fromMap).toList();
  }

  /// Retrieve all activities, ordered by creation date descending.
  Future<List<LearningActivityModel>> getAllActivities() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'learning_activities',
      orderBy: 'created_at DESC',
    );
    return rows.map(LearningActivityModel.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Assessment Reports
  // ---------------------------------------------------------------------------

  /// Insert or replace an assessment report.
  Future<void> insertReport(AssessmentReportModel model) async {
    final db = await AppDatabase.database;
    await db.insert(
      'assessment_reports',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all assessment reports, ordered by creation date descending.
  Future<List<AssessmentReportModel>> getReports() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'assessment_reports',
      orderBy: 'created_at DESC',
    );
    return rows.map(AssessmentReportModel.fromMap).toList();
  }

  /// Retrieve the latest assessment report, or `null` if none exists.
  Future<AssessmentReportModel?> getLatestReport() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'assessment_reports',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AssessmentReportModel.fromMap(rows.first);
  }

  /// Delete an assessment report by [id].
  Future<void> deleteReport(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'assessment_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
