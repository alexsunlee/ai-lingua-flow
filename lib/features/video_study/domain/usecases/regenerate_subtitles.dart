import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/youtube_datasource.dart';
import '../../data/datasources/video_study_local_datasource.dart';
import '../entities/transcript_segment.dart';
import '../entities/video_resource.dart';

class RegenerateSubtitles {
  final YouTubeDatasource _youtubeDatasource;
  final VideoStudyLocalDatasource _localDatasource;
  final _uuid = const Uuid();

  RegenerateSubtitles({
    required YouTubeDatasource youtubeDatasource,
    required VideoStudyLocalDatasource localDatasource,
  })  : _youtubeDatasource = youtubeDatasource,
        _localDatasource = localDatasource;

  /// Re-attempts subtitle extraction for a video that has none.
  /// Returns true if subtitles were successfully generated and saved.
  Future<bool> call({required VideoResource videoResource}) async {
    debugPrint('[RegenerateSubtitles] Starting for video: '
        '${videoResource.youtubeVideoId} (${videoResource.title})');

    // 1. Try YouTube captions first.
    var rawSegments = await _youtubeDatasource
        .extractCaptions(videoResource.youtubeVideoId);
    debugPrint(
        '[RegenerateSubtitles] YouTube captions: ${rawSegments.length}');

    // 2. If empty, use Gemini video understanding via URL (no download).
    if (rawSegments.isEmpty) {
      debugPrint('[RegenerateSubtitles] No YouTube captions, '
          'using Gemini video understanding...');
      try {
        rawSegments = await _youtubeDatasource.transcribeVideoWithGemini(
          youtubeUrl: videoResource.youtubeUrl,
        );
        debugPrint('[RegenerateSubtitles] Gemini returned: '
            '${rawSegments.length} segments');

        // Validate timestamps — retry if all 00:00.
        if (_youtubeDatasource.hasAllZeroTimestamps(rawSegments)) {
          debugPrint(
              '[RegenerateSubtitles] All timestamps 00:00, retrying...');
          rawSegments = await _youtubeDatasource.transcribeVideoWithGemini(
            youtubeUrl: videoResource.youtubeUrl,
            isRetry: true,
          );
          debugPrint('[RegenerateSubtitles] Retry returned: '
              '${rawSegments.length} segments');
        }
      } catch (e) {
        debugPrint(
            '[RegenerateSubtitles] Gemini transcription failed: $e');
      }
    }

    if (rawSegments.isEmpty) {
      debugPrint(
          '[RegenerateSubtitles] No segments from any source, returning false');
      return false;
    }

    // 3. Translate segments into Chinese via text generation.
    rawSegments = await _youtubeDatasource.translateSegments(rawSegments);

    // 4. Convert and save.
    final segments = rawSegments.asMap().entries.map((e) {
      return TranscriptSegment(
        id: _uuid.v4(),
        videoResourceId: videoResource.id,
        segmentIndex: e.key,
        startMs: e.value.startMs,
        endMs: e.value.endMs,
        originalText: e.value.text,
        translatedText: e.value.translation,
      );
    }).toList();

    await _localDatasource.insertSegments(segments);
    debugPrint(
        '[RegenerateSubtitles] Saved ${segments.length} segments to DB');
    return true;
  }
}
