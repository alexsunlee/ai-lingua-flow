import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/shadowing_session_model.dart';

class ShadowingLocalDatasource {
  Future<List<ShadowingSessionModel>> getSessionsForSource(
      String sourceId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'shadowing_sessions',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'sentence_index ASC',
    );
    return results.map((m) => ShadowingSessionModel.fromMap(m)).toList();
  }

  Future<List<ShadowingSessionModel>> getAllSessions() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'shadowing_sessions',
      orderBy: 'created_at DESC',
    );
    return results.map((m) => ShadowingSessionModel.fromMap(m)).toList();
  }

  Future<ShadowingSessionModel?> getSessionById(String id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'shadowing_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ShadowingSessionModel.fromMap(results.first);
  }

  Future<void> insertSession(ShadowingSessionModel session) async {
    final db = await AppDatabase.database;
    await db.insert(
      'shadowing_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'shadowing_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
