import '../../domain/entities/video_resource.dart';

class VideoResourceModel {
  final String id;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String title;
  final String? channelName;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? audioFilePath;
  final String? studyTextId;
  final String createdAt;
  final String updatedAt;

  const VideoResourceModel({
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
  });

  /// Create a model from a SQLite row map.
  factory VideoResourceModel.fromMap(Map<String, dynamic> map) {
    return VideoResourceModel(
      id: map['id'] as String,
      youtubeUrl: map['youtube_url'] as String,
      youtubeVideoId: map['youtube_video_id'] as String,
      title: map['title'] as String,
      channelName: map['channel_name'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      audioFilePath: map['audio_file_path'] as String?,
      studyTextId: map['study_text_id'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  /// Convert to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'title': title,
      'channel_name': channelName,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'audio_file_path': audioFilePath,
      'study_text_id': studyTextId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert from domain entity to data model.
  factory VideoResourceModel.fromEntity(VideoResource entity) {
    return VideoResourceModel(
      id: entity.id,
      youtubeUrl: entity.youtubeUrl,
      youtubeVideoId: entity.youtubeVideoId,
      title: entity.title,
      channelName: entity.channelName,
      thumbnailUrl: entity.thumbnailUrl,
      durationSeconds: entity.durationSeconds,
      audioFilePath: entity.audioFilePath,
      studyTextId: entity.studyTextId,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  /// Convert data model to domain entity.
  VideoResource toEntity() {
    return VideoResource(
      id: id,
      youtubeUrl: youtubeUrl,
      youtubeVideoId: youtubeVideoId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      audioFilePath: audioFilePath,
      studyTextId: studyTextId,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
