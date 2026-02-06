import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/database/app_database.dart';
import '../core/storage/file_storage_service.dart';

/// Handles JSON backup export and import of all user data.
class DataExportService {
  final FileStorageService _fileStorage;

  DataExportService(this._fileStorage);

  /// Export all user data to a JSON file.
  /// Returns the file path of the exported backup.
  Future<String> exportData() async {
    final db = await AppDatabase.database;

    final studyTexts = await db.query('study_texts');
    final paragraphs = await db.query('paragraphs');
    final videoResources = await db.query('video_resources');
    final transcriptSegments = await db.query('transcript_segments');
    final vocabularyEntries = await db.query('vocabulary_entries');
    final reviewSchedules = await db.query('review_schedules');
    final shadowingSessions = await db.query('shadowing_sessions');
    final learningActivities = await db.query('learning_activities');
    final assessmentReports = await db.query('assessment_reports');

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'study_texts': studyTexts,
      'paragraphs': paragraphs,
      'video_resources': videoResources,
      'transcript_segments': transcriptSegments,
      'vocabulary_entries': vocabularyEntries,
      'review_schedules': reviewSchedules,
      'shadowing_sessions': shadowingSessions,
      'learning_activities': learningActivities,
      'assessment_reports': assessmentReports,
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'linguaflow_backup_$timestamp.json';
    final filePath = p.join(_fileStorage.appDir.path, filename);

    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    return filePath;
  }

  /// Import user data from a JSON backup file.
  /// Returns the number of records imported.
  Future<int> importData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('备份文件不存在');
    }

    final content = await file.readAsString();
    final backup = jsonDecode(content) as Map<String, dynamic>;

    final version = backup['version'] as int?;
    if (version != 1) {
      throw Exception('不支持的备份版本: $version');
    }

    final db = await AppDatabase.database;
    int totalImported = 0;

    await db.transaction((txn) async {
      totalImported += await _importTable(
          txn, 'study_texts', backup['study_texts'] as List?);
      totalImported += await _importTable(
          txn, 'paragraphs', backup['paragraphs'] as List?);
      totalImported += await _importTable(
          txn, 'video_resources', backup['video_resources'] as List?);
      totalImported += await _importTable(
          txn, 'transcript_segments', backup['transcript_segments'] as List?);
      totalImported += await _importTable(
          txn, 'vocabulary_entries', backup['vocabulary_entries'] as List?);
      totalImported += await _importTable(
          txn, 'review_schedules', backup['review_schedules'] as List?);
      totalImported += await _importTable(
          txn, 'shadowing_sessions', backup['shadowing_sessions'] as List?);
      totalImported += await _importTable(
          txn, 'learning_activities', backup['learning_activities'] as List?);
      totalImported += await _importTable(
          txn, 'assessment_reports', backup['assessment_reports'] as List?);
    });

    return totalImported;
  }

  Future<int> _importTable(
      dynamic txn, String table, List? rows) async {
    if (rows == null || rows.isEmpty) return 0;

    int count = 0;
    for (final row in rows) {
      try {
        await txn.insert(table, Map<String, dynamic>.from(row as Map),
            conflictAlgorithm: 5 /* ConflictAlgorithm.ignore */);
        count++;
      } catch (_) {
        // Skip conflicting rows
      }
    }
    return count;
  }
}
