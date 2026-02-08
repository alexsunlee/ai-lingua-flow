import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/datasources/youtube_datasource.dart';
import '../../data/datasources/video_study_local_datasource.dart';
import '../entities/transcript_segment.dart';
import '../entities/video_resource.dart';

class ProcessVideo {
  final YouTubeDatasource _youtubeDatasource;
  final VideoStudyLocalDatasource _localDatasource;
  final _uuid = const Uuid();

  ProcessVideo({
    required YouTubeDatasource youtubeDatasource,
    required VideoStudyLocalDatasource localDatasource,
  })  : _youtubeDatasource = youtubeDatasource,
        _localDatasource = localDatasource;

  /// Takes a YouTube URL, fetches metadata and captions, saves to DB,
  /// and returns the video resource ID.
  Future<String> call({required String youtubeUrl}) async {
    // 1. Extract video ID from the URL.
    final videoId = VideoId(youtubeUrl);

    // Check for existing video with same YouTube ID.
    final existing =
        await _localDatasource.getVideoResourceByYoutubeId(videoId.value);
    if (existing != null) {
      return existing.id;
    }

    // 2. Fetch video metadata from YouTube.
    final metadata = await _youtubeDatasource.fetchVideoMetadata(videoId.value);

    // 3. Generate a unique ID for this resource.
    final resourceId = _uuid.v4();
    final now = DateTime.now();

    // 4. Create the video resource entity.
    final videoResource = VideoResource(
      id: resourceId,
      youtubeUrl: youtubeUrl,
      youtubeVideoId: videoId.value,
      title: metadata.title,
      channelName: metadata.channelName,
      thumbnailUrl: metadata.thumbnailUrl,
      durationSeconds: metadata.durationSeconds,
      createdAt: now,
      updatedAt: now,
    );

    // 5. Save the video resource to local database.
    await _localDatasource.insertVideoResource(videoResource);

    // 6. Extract captions / transcript segments.
    try {
      final rawSegments =
          await _youtubeDatasource.extractCaptions(videoId.value);

      final segments = <TranscriptSegment>[];
      for (int i = 0; i < rawSegments.length; i++) {
        final raw = rawSegments[i];
        segments.add(TranscriptSegment(
          id: _uuid.v4(),
          videoResourceId: resourceId,
          segmentIndex: i,
          startMs: raw.startMs,
          endMs: raw.endMs,
          originalText: raw.text,
        ));
      }

      debugPrint('[ProcessVideo] YouTube captions: ${segments.length} segments');

      // If no YouTube captions, send YouTube URL directly to Gemini.
      List<RawCaptionSegment> geminiSegments = [];
      if (segments.isEmpty) {
        debugPrint('[ProcessVideo] No YouTube captions, '
            'using Gemini video understanding...');
        try {
          geminiSegments =
              await _youtubeDatasource.transcribeVideoWithGemini(
            youtubeUrl: youtubeUrl,
          );
          debugPrint('[ProcessVideo] Gemini returned: ${geminiSegments.length} segments');

          // Translate via text generation.
          if (geminiSegments.isNotEmpty) {
            geminiSegments =
                await _youtubeDatasource.translateSegments(geminiSegments);
          }

          for (int i = 0; i < geminiSegments.length; i++) {
            final raw = geminiSegments[i];
            segments.add(TranscriptSegment(
              id: _uuid.v4(),
              videoResourceId: resourceId,
              segmentIndex: i,
              startMs: raw.startMs,
              endMs: raw.endMs,
              originalText: raw.text,
              translatedText: raw.translation,
            ));
          }
        } catch (e) {
          debugPrint('[ProcessVideo] Gemini video transcription failed: $e');
        }
      }

      debugPrint('[ProcessVideo] Final segment count: ${segments.length}');
      if (segments.isNotEmpty) {
        await _localDatasource.insertSegments(segments);
        debugPrint('[ProcessVideo] Saved ${segments.length} segments to DB');
      }
    } catch (e) {
      // Captions may not be available; the video is still saved.
      // Gemini transcription fallback can be attempted later.
    }

    return resourceId;
  }
}
