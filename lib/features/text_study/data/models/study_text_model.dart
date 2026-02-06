import '../../domain/entities/paragraph.dart';
import '../../domain/entities/study_text.dart';

class StudyTextModel extends StudyText {
  const StudyTextModel({
    required super.id,
    required super.title,
    required super.originalText,
    super.sourceType,
    super.sourceLanguage,
    super.targetLanguage,
    super.analysisJson,
    required super.createdAt,
    required super.updatedAt,
    super.paragraphs,
  });

  /// Create a [StudyTextModel] from a SQLite row map.
  factory StudyTextModel.fromMap(Map<String, dynamic> map) {
    return StudyTextModel(
      id: map['id'] as String,
      title: map['title'] as String,
      originalText: map['original_text'] as String,
      sourceType: map['source_type'] as String? ?? 'manual',
      sourceLanguage: map['source_language'] as String? ?? 'en',
      targetLanguage: map['target_language'] as String? ?? 'zh',
      analysisJson: map['analysis_json'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Create a [StudyTextModel] from a domain entity.
  factory StudyTextModel.fromEntity(StudyText entity) {
    return StudyTextModel(
      id: entity.id,
      title: entity.title,
      originalText: entity.originalText,
      sourceType: entity.sourceType,
      sourceLanguage: entity.sourceLanguage,
      targetLanguage: entity.targetLanguage,
      analysisJson: entity.analysisJson,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      paragraphs: entity.paragraphs,
    );
  }

  /// Convert to a map suitable for SQLite insert / update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'original_text': originalText,
      'source_type': sourceType,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'analysis_json': analysisJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Attach paragraphs and return a new model with them included.
  StudyTextModel withParagraphs(List<Paragraph> paragraphs) {
    return StudyTextModel(
      id: id,
      title: title,
      originalText: originalText,
      sourceType: sourceType,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      analysisJson: analysisJson,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paragraphs: paragraphs,
    );
  }
}
