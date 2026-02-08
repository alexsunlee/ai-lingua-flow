import 'transcript_segment.dart';

class VideoResource {
  final String id;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String title;
  final String? channelName;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? audioFilePath;
  final String? studyTextId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TranscriptSegment>? segments;
  final int segmentCount; // Runtime field, populated by list query

  const VideoResource({
    required this.id,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.title,
    this.channelName,
    this.thumbnailUrl,
    this.durationSeconds,
    this.audioFilePath,
    this.studyTextId,
    required this.createdAt,
    required this.updatedAt,
    this.segments,
    this.segmentCount = 0,
  });

  VideoResource copyWith({
    String? id,
    String? youtubeUrl,
    String? youtubeVideoId,
    String? title,
    String? channelName,
    String? thumbnailUrl,
    int? durationSeconds,
    String? audioFilePath,
    String? studyTextId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TranscriptSegment>? segments,
    int? segmentCount,
  }) {
    return VideoResource(
      id: id ?? this.id,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      studyTextId: studyTextId ?? this.studyTextId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      segments: segments ?? this.segments,
      segmentCount: segmentCount ?? this.segmentCount,
    );
  }
}
