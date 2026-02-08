import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/transcript_segment.dart';
import '../../domain/entities/video_resource.dart';
import '../models/transcript_segment_model.dart';
import '../models/video_resource_model.dart';

/// Local SQLite datasource for video study CRUD operations.
class VideoStudyLocalDatasource {
  /// Retrieve all video resources with segment counts, ordered by most recently updated.
  Future<List<VideoResource>> getAllVideoResources() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT vr.*, COUNT(ts.id) as segment_count
      FROM video_resources vr
      LEFT JOIN transcript_segments ts ON vr.id = ts.video_resource_id
      GROUP BY vr.id
      ORDER BY vr.updated_at DESC
    ''');
    return rows.map((row) {
      final entity = VideoResourceModel.fromMap(row).toEntity();
      final count = row['segment_count'] as int? ?? 0;
      return entity.copyWith(segmentCount: count);
    }).toList();
  }

  /// Retrieve a video resource by its YouTube video ID.
  Future<VideoResource?> getVideoResourceByYoutubeId(
      String youtubeVideoId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'video_resources',
      where: 'youtube_video_id = ?',
      whereArgs: [youtubeVideoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final videoResource = VideoResourceModel.fromMap(rows.first).toEntity();
    final segments = await getSegmentsForVideo(videoResource.id);
    return videoResource.copyWith(segments: segments);
  }

  /// Retrieve a single video resource by [id].
  Future<VideoResource?> getVideoResourceById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'video_resources',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final videoResource = VideoResourceModel.fromMap(rows.first).toEntity();

    // Attach transcript segments.
    final segments = await getSegmentsForVideo(id);
    return videoResource.copyWith(segments: segments);
  }

  /// Insert or update a video resource.
  Future<void> insertVideoResource(VideoResource videoResource) async {
    final db = await AppDatabase.database;
    final model = VideoResourceModel.fromEntity(videoResource);
    await db.insert(
      'video_resources',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a video resource and its associated transcript segments.
  Future<void> deleteVideoResource(String id) async {
    final db = await AppDatabase.database;
    // Segments are deleted by CASCADE foreign key.
    await db.delete(
      'video_resources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retrieve all transcript segments for a given [videoResourceId].
  Future<List<TranscriptSegment>> getSegmentsForVideo(
      String videoResourceId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'transcript_segments',
      where: 'video_resource_id = ?',
      whereArgs: [videoResourceId],
      orderBy: 'segment_index ASC',
    );
    return rows
        .map((row) => TranscriptSegmentModel.fromMap(row).toEntity())
        .toList();
  }

  /// Insert or replace transcript segments.
  Future<void> insertSegments(List<TranscriptSegment> segments) async {
    final db = await AppDatabase.database;
    final batch = db.batch();
    for (final segment in segments) {
      final model = TranscriptSegmentModel.fromEntity(segment);
      batch.insert(
        'transcript_segments',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
