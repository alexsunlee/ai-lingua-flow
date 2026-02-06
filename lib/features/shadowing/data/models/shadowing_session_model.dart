import 'dart:convert';

import '../../domain/entities/shadowing_session.dart';

class ShadowingSessionModel extends ShadowingSession {
  const ShadowingSessionModel({
    required super.id,
    required super.sourceType,
    required super.sourceId,
    required super.sentenceText,
    super.sentenceIndex,
    super.recordingFilePath,
    super.recognizedText,
    super.pronunciationScore,
    super.feedbackJson,
    required super.createdAt,
  });

  factory ShadowingSessionModel.fromMap(Map<String, dynamic> map) {
    return ShadowingSessionModel(
      id: map['id'] as String,
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as String,
      sentenceText: map['sentence_text'] as String,
      sentenceIndex: map['sentence_index'] as int? ?? 0,
      recordingFilePath: map['recording_file_path'] as String?,
      recognizedText: map['recognized_text'] as String?,
      pronunciationScore: map['pronunciation_score'] as double?,
      feedbackJson: map['feedback_json'] != null
          ? jsonDecode(map['feedback_json'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory ShadowingSessionModel.fromEntity(ShadowingSession entity) {
    return ShadowingSessionModel(
      id: entity.id,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      sentenceText: entity.sentenceText,
      sentenceIndex: entity.sentenceIndex,
      recordingFilePath: entity.recordingFilePath,
      recognizedText: entity.recognizedText,
      pronunciationScore: entity.pronunciationScore,
      feedbackJson: entity.feedbackJson,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_type': sourceType,
      'source_id': sourceId,
      'sentence_text': sentenceText,
      'sentence_index': sentenceIndex,
      'recording_file_path': recordingFilePath,
      'recognized_text': recognizedText,
      'pronunciation_score': pronunciationScore,
      'feedback_json': feedbackJson != null ? jsonEncode(feedbackJson) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
