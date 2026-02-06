import '../../../../core/database/app_database.dart';
import '../models/review_schedule_model.dart';
import '../models/vocabulary_entry_model.dart';

class VocabularyLocalDatasource {
  // ──────────────── Vocabulary Entries ────────────────

  /// Retrieve all vocabulary entries ordered by most recently created.
  Future<List<VocabularyEntryModel>> getAllEntries() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'vocabulary_entries',
      orderBy: 'created_at DESC',
    );
    return rows.map(VocabularyEntryModel.fromMap).toList();
  }

  /// Retrieve a single vocabulary entry by [id].
  Future<VocabularyEntryModel?> getEntryById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'vocabulary_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VocabularyEntryModel.fromMap(rows.first);
  }

  /// Insert a new vocabulary entry.
  Future<void> insertEntry(VocabularyEntryModel model) async {
    final db = await AppDatabase.database;
    await db.insert('vocabulary_entries', model.toMap());
  }

  /// Update an existing vocabulary entry.
  Future<void> updateEntry(VocabularyEntryModel model) async {
    final db = await AppDatabase.database;
    await db.update(
      'vocabulary_entries',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  /// Delete a vocabulary entry by [id].
  Future<void> deleteEntry(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'vocabulary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search entries whose word or translation matches [query].
  Future<List<VocabularyEntryModel>> searchEntries(String query) async {
    final db = await AppDatabase.database;
    final pattern = '%$query%';
    final rows = await db.query(
      'vocabulary_entries',
      where: 'word LIKE ? OR translation LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'created_at DESC',
    );
    return rows.map(VocabularyEntryModel.fromMap).toList();
  }

  /// Get all vocabulary entries that are due for review on or before [date].
  ///
  /// Joins vocabulary_entries with review_schedules and returns entries
  /// whose next_review_date is on or before the provided date.
  Future<List<VocabularyEntryModel>> getDueReviews(DateTime date) async {
    final db = await AppDatabase.database;
    final dateStr = date.toIso8601String();
    final rows = await db.rawQuery(
      '''
      SELECT ve.* FROM vocabulary_entries ve
      INNER JOIN review_schedules rs ON ve.id = rs.vocabulary_entry_id
      WHERE rs.next_review_date <= ?
      ORDER BY rs.next_review_date ASC
      ''',
      [dateStr],
    );
    return rows.map(VocabularyEntryModel.fromMap).toList();
  }

  // ──────────────── Review Schedules ────────────────

  /// Get the review schedule for a given vocabulary entry.
  Future<ReviewScheduleModel?> getScheduleForEntry(
      String vocabularyEntryId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'review_schedules',
      where: 'vocabulary_entry_id = ?',
      whereArgs: [vocabularyEntryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReviewScheduleModel.fromMap(rows.first);
  }

  /// Insert or update a review schedule.
  Future<void> saveSchedule(ReviewScheduleModel model) async {
    final db = await AppDatabase.database;
    final existing = await db.query(
      'review_schedules',
      where: 'id = ?',
      whereArgs: [model.id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('review_schedules', model.toMap());
    } else {
      await db.update(
        'review_schedules',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );
    }
  }
}
