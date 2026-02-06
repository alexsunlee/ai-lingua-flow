import 'dart:convert';

import '../../domain/entities/vocabulary_entry.dart';

class VocabularyEntryModel extends VocabularyEntry {
  const VocabularyEntryModel({
    required super.id,
    required super.word,
    super.language,
    super.pronunciation,
    super.translation,
    super.explanation,
    super.etymology,
    super.exampleSentences,
    super.synonyms,
    super.sourceType,
    super.sourceId,
    super.sourceContext,
    super.audioFilePath,
    required super.createdAt,
  });

  /// Create a [VocabularyEntryModel] from a SQLite row map.
  factory VocabularyEntryModel.fromMap(Map<String, dynamic> map) {
    return VocabularyEntryModel(
      id: map['id'] as String,
      word: map['word'] as String,
      language: (map['language'] as String?) ?? 'en',
      pronunciation: map['pronunciation'] as String?,
      translation: map['translation'] as String?,
      explanation: map['explanation'] as String?,
      etymology: map['etymology'] as String?,
      exampleSentences: _decodeJsonList(map['example_sentences'] as String?),
      synonyms: _decodeJsonList(map['synonyms'] as String?),
      sourceType: map['source_type'] as String?,
      sourceId: map['source_id'] as String?,
      sourceContext: map['source_context'] as String?,
      audioFilePath: map['audio_file_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create a [VocabularyEntryModel] from a domain entity.
  factory VocabularyEntryModel.fromEntity(VocabularyEntry entry) {
    return VocabularyEntryModel(
      id: entry.id,
      word: entry.word,
      language: entry.language,
      pronunciation: entry.pronunciation,
      translation: entry.translation,
      explanation: entry.explanation,
      etymology: entry.etymology,
      exampleSentences: entry.exampleSentences,
      synonyms: entry.synonyms,
      sourceType: entry.sourceType,
      sourceId: entry.sourceId,
      sourceContext: entry.sourceContext,
      audioFilePath: entry.audioFilePath,
      createdAt: entry.createdAt,
    );
  }

  /// Convert to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'language': language,
      'pronunciation': pronunciation,
      'translation': translation,
      'explanation': explanation,
      'etymology': etymology,
      'example_sentences': jsonEncode(exampleSentences),
      'synonyms': jsonEncode(synonyms),
      'source_type': sourceType,
      'source_id': sourceId,
      'source_context': sourceContext,
      'audio_file_path': audioFilePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<String> _decodeJsonList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
