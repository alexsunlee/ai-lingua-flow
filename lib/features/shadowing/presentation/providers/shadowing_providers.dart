import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/shadowing_local_datasource.dart';
import '../../data/repositories/shadowing_repository_impl.dart';
import '../../domain/entities/shadowing_session.dart';
import '../../domain/repositories/shadowing_repository.dart';

final _shadowingDatasourceProvider = Provider<ShadowingLocalDatasource>(
  (ref) => ShadowingLocalDatasource(),
);

final _shadowingRepositoryProvider = Provider<ShadowingRepository>(
  (ref) => ShadowingRepositoryImpl(ref.read(_shadowingDatasourceProvider)),
);

/// All shadowing sessions, most recent first.
final shadowingSessionsProvider =
    FutureProvider<List<ShadowingSession>>((ref) async {
  final repo = ref.read(_shadowingRepositoryProvider);
  return repo.getAllSessions();
});

/// Sessions for a specific source.
final shadowingSessionsForSourceProvider =
    FutureProvider.family<List<ShadowingSession>, String>(
        (ref, sourceId) async {
  final repo = ref.read(_shadowingRepositoryProvider);
  return repo.getSessionsForSource(sourceId);
});

/// Available sources for shadowing (study texts + video resources).
final shadowingSourcesProvider =
    FutureProvider<List<ShadowingSource>>((ref) async {
  final db = await AppDatabase.database;

  final textResults = await db.query(
    'study_texts',
    columns: ['id', 'title', 'original_text', 'created_at'],
    orderBy: 'updated_at DESC',
  );

  final videoResults = await db.query(
    'video_resources',
    columns: ['id', 'title', 'youtube_url', 'created_at'],
    orderBy: 'updated_at DESC',
  );

  final sources = <ShadowingSource>[];

  for (final row in textResults) {
    final originalText = row['original_text'] as String?;
    String? summary;
    if (originalText != null && originalText.isNotEmpty) {
      summary = originalText.substring(0, min(100, originalText.length));
    }
    sources.add(ShadowingSource(
      id: row['id'] as String,
      title: row['title'] as String,
      type: 'text',
      createdAt: DateTime.parse(row['created_at'] as String),
      summary: summary,
    ));
  }

  for (final row in videoResults) {
    sources.add(ShadowingSource(
      id: row['id'] as String,
      title: row['title'] as String,
      type: 'video',
      createdAt: DateTime.parse(row['created_at'] as String),
    ));
  }

  sources.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sources;
});

class ShadowingSource {
  final String id;
  final String title;
  final String type;
  final DateTime createdAt;
  final String? summary;

  const ShadowingSource({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    this.summary,
  });
}
