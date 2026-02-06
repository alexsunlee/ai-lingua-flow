import '../entities/transcript_segment.dart';
import '../entities/video_resource.dart';

abstract class VideoStudyRepository {
  /// Retrieve all video resources, ordered by most recently updated.
  Future<List<VideoResource>> getAllVideoResources();

  /// Retrieve a single video resource by [id], with its segments attached.
  Future<VideoResource?> getVideoResourceById(String id);

  /// Insert or update a video resource.
  Future<void> saveVideoResource(VideoResource videoResource);

  /// Delete a video resource and its associated transcript segments.
  Future<void> deleteVideoResource(String id);

  /// Retrieve all transcript segments belonging to the given [videoResourceId].
  Future<List<TranscriptSegment>> getSegmentsForVideo(String videoResourceId);

  /// Insert or replace transcript segments for a given video resource.
  Future<void> saveSegments(List<TranscriptSegment> segments);
}
