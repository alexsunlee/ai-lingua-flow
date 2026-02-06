import 'dart:convert';

import '../../domain/entities/learning_activity.dart';

class LearningActivityModel extends LearningActivity {
  const LearningActivityModel({
    required super.id,
    required super.activityType,
    super.sourceId,
    super.durationSeconds,
    super.wordsEncountered,
    super.newWordsAdded,
    super.contentDifficultyScore,
    super.metadataJson,
    required super.createdAt,
  });

  /// Create a [LearningActivityModel] from a SQLite row map.
  factory LearningActivityModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['metadata_json'] != null &&
        (map['metadata_json'] as String).isNotEmpty) {
      metadata = jsonDecode(map['metadata_json'] as String)
          as Map<String, dynamic>;
    }

    return LearningActivityModel(
      id: map['id'] as String,
      activityType: map['activity_type'] as String,
      sourceId: map['source_id'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      wordsEncountered: map['words_encountered'] as int? ?? 0,
      newWordsAdded: map['new_words_added'] as int? ?? 0,
      contentDifficultyScore:
          (map['content_difficulty_score'] as num?)?.toDouble(),
      metadataJson: metadata,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create a [LearningActivityModel] from a domain entity.
  factory LearningActivityModel.fromEntity(LearningActivity entity) {
    return LearningActivityModel(
      id: entity.id,
      activityType: entity.activityType,
      sourceId: entity.sourceId,
      durationSeconds: entity.durationSeconds,
      wordsEncountered: entity.wordsEncountered,
      newWordsAdded: entity.newWordsAdded,
      contentDifficultyScore: entity.contentDifficultyScore,
      metadataJson: entity.metadataJson,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to a map suitable for SQLite insert / update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_type': activityType,
      'source_id': sourceId,
      'duration_seconds': durationSeconds,
      'words_encountered': wordsEncountered,
      'new_words_added': newWordsAdded,
      'content_difficulty_score': contentDifficultyScore,
      'metadata_json':
          metadataJson != null ? jsonEncode(metadataJson) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
