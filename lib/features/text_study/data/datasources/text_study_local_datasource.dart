import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/paragraph_model.dart';
import '../models/study_text_model.dart';

class TextStudyLocalDatasource {
  // ---------------------------------------------------------------------------
  // Study Texts
  // ---------------------------------------------------------------------------

  /// Retrieve all study texts ordered by most recently updated.
  Future<List<StudyTextModel>> getAllStudyTexts() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'study_texts',
      orderBy: 'updated_at DESC',
    );
    return rows.map(StudyTextModel.fromMap).toList();
  }

  /// Retrieve a single study text by [id], or `null` if not found.
  Future<StudyTextModel?> getStudyTextById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'study_texts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StudyTextModel.fromMap(rows.first);
  }

  /// Insert or replace a study text.
  Future<void> insertStudyText(StudyTextModel model) async {
    final db = await AppDatabase.database;
    await db.insert(
      'study_texts',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a study text by [id]. Paragraphs are cascade-deleted by the
  /// foreign key constraint.
  Future<void> deleteStudyText(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'study_texts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Paragraphs
  // ---------------------------------------------------------------------------

  /// Retrieve all paragraphs for a given [studyTextId], ordered by index.
  Future<List<ParagraphModel>> getParagraphsForText(String studyTextId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'paragraphs',
      where: 'study_text_id = ?',
      whereArgs: [studyTextId],
      orderBy: 'paragraph_index ASC',
    );
    return rows.map(ParagraphModel.fromMap).toList();
  }

  /// Insert or replace a batch of paragraphs inside a transaction.
  Future<void> insertParagraphs(List<ParagraphModel> models) async {
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      for (final model in models) {
        await txn.insert(
          'paragraphs',
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Delete all paragraphs belonging to [studyTextId].
  Future<void> deleteParagraphsForText(String studyTextId) async {
    final db = await AppDatabase.database;
    await db.delete(
      'paragraphs',
      where: 'study_text_id = ?',
      whereArgs: [studyTextId],
    );
  }
}
