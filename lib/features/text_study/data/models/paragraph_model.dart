import '../../domain/entities/paragraph.dart';

class ParagraphModel extends Paragraph {
  const ParagraphModel({
    required super.id,
    required super.studyTextId,
    required super.paragraphIndex,
    required super.originalText,
    super.translatedText,
    super.knowledgeJson,
    super.summary,
  });

  /// Create a [ParagraphModel] from a SQLite row map.
  factory ParagraphModel.fromMap(Map<String, dynamic> map) {
    return ParagraphModel(
      id: map['id'] as String,
      studyTextId: map['study_text_id'] as String,
      paragraphIndex: map['paragraph_index'] as int,
      originalText: map['original_text'] as String,
      translatedText: map['translated_text'] as String?,
      knowledgeJson: map['knowledge_json'] as String?,
      summary: map['summary'] as String?,
    );
  }

  /// Create a [ParagraphModel] from a domain entity.
  factory ParagraphModel.fromEntity(Paragraph entity) {
    return ParagraphModel(
      id: entity.id,
      studyTextId: entity.studyTextId,
      paragraphIndex: entity.paragraphIndex,
      originalText: entity.originalText,
      translatedText: entity.translatedText,
      knowledgeJson: entity.knowledgeJson,
      summary: entity.summary,
    );
  }

  /// Convert to a map suitable for SQLite insert / update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_text_id': studyTextId,
      'paragraph_index': paragraphIndex,
      'original_text': originalText,
      'translated_text': translatedText,
      'knowledge_json': knowledgeJson,
      'summary': summary,
    };
  }
}
