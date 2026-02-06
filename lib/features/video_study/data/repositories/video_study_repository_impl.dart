import '../../domain/entities/transcript_segment.dart';
import '../../domain/entities/video_resource.dart';
import '../../domain/repositories/video_study_repository.dart';
import '../datasources/video_study_local_datasource.dart';

/// Concrete implementation of [VideoStudyRepository] backed by SQLite.
class VideoStudyRepositoryImpl implements VideoStudyRepository {
  final VideoStudyLocalDatasource _localDatasource;

  VideoStudyRepositoryImpl({
    required VideoStudyLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<List<VideoResource>> getAllVideoResources() {
    return _localDatasource.getAllVideoResources();
  }

  @override
  Future<VideoResource?> getVideoResourceById(String id) {
    return _localDatasource.getVideoResourceById(id);
  }

  @override
  Future<void> saveVideoResource(VideoResource videoResource) {
    return _localDatasource.insertVideoResource(videoResource);
  }

  @override
  Future<void> deleteVideoResource(String id) {
    return _localDatasource.deleteVideoResource(id);
  }

  @override
  Future<List<TranscriptSegment>> getSegmentsForVideo(
      String videoResourceId) {
    return _localDatasource.getSegmentsForVideo(videoResourceId);
  }

  @override
  Future<void> saveSegments(List<TranscriptSegment> segments) {
    return _localDatasource.insertSegments(segments);
  }
}
