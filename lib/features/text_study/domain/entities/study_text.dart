import 'paragraph.dart';

class StudyText {
  final String id;
  final String title;
  final String originalText;
  final String sourceType;
  final String sourceLanguage;
  final String targetLanguage;
  final String? analysisJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Paragraph>? paragraphs;

  const StudyText({
    required this.id,
    required this.title,
    required this.originalText,
    this.sourceType = 'manual',
    this.sourceLanguage = 'en',
    this.targetLanguage = 'zh',
    this.analysisJson,
    required this.createdAt,
    required this.updatedAt,
    this.paragraphs,
  });

  StudyText copyWith({
    String? id,
    String? title,
    String? originalText,
    String? sourceType,
    String? sourceLanguage,
    String? targetLanguage,
    String? analysisJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Paragraph>? paragraphs,
  }) {
    return StudyText(
      id: id ?? this.id,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      sourceType: sourceType ?? this.sourceType,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      analysisJson: analysisJson ?? this.analysisJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paragraphs: paragraphs ?? this.paragraphs,
    );
  }
}
