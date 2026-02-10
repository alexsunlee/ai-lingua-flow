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

    // 2. Deduplicate by YouTube video ID (covers all URL variants).
    final existing =
        await _localDatasource.getVideoResourceByYoutubeId(videoId.value);
    if (existing != null) {
      debugPrint('[ProcessVideo] Video already exists: ${existing.id}');
      return existing.id;
    }

    // 3. Fetch video metadata from YouTube.
    final metadata =
        await _youtubeDatasource.fetchVideoMetadata(videoId.value);

    // 4. Generate a unique ID for this resource.
    final resourceId = _uuid.v4();
    final now = DateTime.now();

    // 5. Create the video resource entity.
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

    // 6. Save the video resource to local database.
    await _localDatasource.insertVideoResource(videoResource);

    // 7. Extract captions / transcript segments.
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

      debugPrint(
          '[ProcessVideo] YouTube captions: ${segments.length} segments');

      // If no YouTube captions, use Gemini video understanding via URL.
      if (segments.isEmpty) {
        debugPrint('[ProcessVideo] No YouTube captions, '
            'using Gemini video understanding...');
        final geminiSegments = await _transcribeWithRetry(youtubeUrl);

        if (geminiSegments.isNotEmpty) {
          // Translate via text generation.
          final translated =
              await _youtubeDatasource.translateSegments(geminiSegments);

          for (int i = 0; i < translated.length; i++) {
            final raw = translated[i];
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
        }
      }

      debugPrint('[ProcessVideo] Final segment count: ${segments.length}');
      if (segments.isNotEmpty) {
        await _localDatasource.insertSegments(segments);
        debugPrint(
            '[ProcessVideo] Saved ${segments.length} segments to DB');
      }
    } catch (e) {
      debugPrint('[ProcessVideo] Caption extraction failed: $e');
    }

    return resourceId;
  }

  /// Transcribe via Gemini with timestamp validation.
  /// If the first attempt returns all-zero timestamps, retries once
  /// with a more explicit prompt.
  Future<List<RawCaptionSegment>> _transcribeWithRetry(
      String youtubeUrl) async {
    try {
      var segments = await _youtubeDatasource.transcribeVideoWithGemini(
        youtubeUrl: youtubeUrl,
      );
      debugPrint('[ProcessVideo] Gemini returned: ${segments.length} segments');

      // Validate timestamps — if all 00:00, retry with stronger prompt.
      if (_youtubeDatasource.hasAllZeroTimestamps(segments)) {
        debugPrint('[ProcessVideo] All timestamps are 00:00, retrying...');
        segments = await _youtubeDatasource.transcribeVideoWithGemini(
          youtubeUrl: youtubeUrl,
          isRetry: true,
        );
        debugPrint(
            '[ProcessVideo] Retry returned: ${segments.length} segments');

        // If still all zeros, estimate from duration.
        if (_youtubeDatasource.hasAllZeroTimestamps(segments)) {
          debugPrint(
              '[ProcessVideo] Still all 00:00 after retry, estimating...');
          segments = _estimateTimestamps(segments);
        }
      }

      return segments;
    } catch (e) {
      debugPrint('[ProcessVideo] Gemini transcription failed: $e');
      return [];
    }
  }

  /// Distribute timestamps evenly across the segments based on text length
  /// when the model fails to provide real timestamps.
  List<RawCaptionSegment> _estimateTimestamps(
      List<RawCaptionSegment> segments) {
    if (segments.isEmpty) return segments;

    // Use total character count to estimate relative positions.
    final totalChars =
        segments.fold<int>(0, (sum, s) => sum + s.text.length);
    if (totalChars == 0) return segments;

    // Assume ~150 words per minute, ~5 chars per word → ~750 chars/min.
    // Estimate total duration from text length, cap at reasonable bounds.
    final estimatedDurationMs = (totalChars / 750 * 60 * 1000).round();

    final result = <RawCaptionSegment>[];
    int currentMs = 0;
    for (final s in segments) {
      final proportion = s.text.length / totalChars;
      final durationMs = (proportion * estimatedDurationMs).round();
      result.add(RawCaptionSegment(
        startMs: currentMs,
        endMs: currentMs + durationMs,
        text: s.text,
        translation: s.translation,
      ));
      currentMs += durationMs;
    }

    debugPrint('[ProcessVideo] Estimated timestamps for ${result.length} '
        'segments over ${currentMs}ms');
    return result;
  }
}
