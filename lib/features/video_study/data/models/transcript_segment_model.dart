import '../../domain/entities/transcript_segment.dart';

class TranscriptSegmentModel {
  final String id;
  final String videoResourceId;
  final int segmentIndex;
  final int startMs;
  final int endMs;
  final String originalText;
  final String? translatedText;

  const TranscriptSegmentModel({
    required this.id,
    required this.videoResourceId,
    required this.segmentIndex,
    required this.startMs,
    required this.endMs,
    required this.originalText,
    this.translatedText,
  });

  /// Create a model from a SQLite row map.
  factory TranscriptSegmentModel.fromMap(Map<String, dynamic> map) {
    return TranscriptSegmentModel(
      id: map['id'] as String,
      videoResourceId: map['video_resource_id'] as String,
      segmentIndex: map['segment_index'] as int,
      startMs: map['start_ms'] as int,
      endMs: map['end_ms'] as int,
      originalText: map['original_text'] as String,
      translatedText: map['translated_text'] as String?,
    );
  }

  /// Convert to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'video_resource_id': videoResourceId,
      'segment_index': segmentIndex,
      'start_ms': startMs,
      'end_ms': endMs,
      'original_text': originalText,
      'translated_text': translatedText,
    };
  }

  /// Convert from domain entity to data model.
  factory TranscriptSegmentModel.fromEntity(TranscriptSegment entity) {
    return TranscriptSegmentModel(
      id: entity.id,
      videoResourceId: entity.videoResourceId,
      segmentIndex: entity.segmentIndex,
      startMs: entity.startMs,
      endMs: entity.endMs,
      originalText: entity.originalText,
      translatedText: entity.translatedText,
    );
  }

  /// Convert data model to domain entity.
  TranscriptSegment toEntity() {
    return TranscriptSegment(
      id: id,
      videoResourceId: videoResourceId,
      segmentIndex: segmentIndex,
      startMs: startMs,
      endMs: endMs,
      originalText: originalText,
      translatedText: translatedText,
    );
  }
}
