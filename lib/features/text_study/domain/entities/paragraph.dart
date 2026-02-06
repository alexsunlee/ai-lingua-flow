class Paragraph {
  final String id;
  final String studyTextId;
  final int paragraphIndex;
  final String originalText;
  final String? translatedText;
  final String? knowledgeJson;
  final String? summary;

  const Paragraph({
    required this.id,
    required this.studyTextId,
    required this.paragraphIndex,
    required this.originalText,
    this.translatedText,
    this.knowledgeJson,
    this.summary,
  });

  Paragraph copyWith({
    String? id,
    String? studyTextId,
    int? paragraphIndex,
    String? originalText,
    String? translatedText,
    String? knowledgeJson,
    String? summary,
  }) {
    return Paragraph(
      id: id ?? this.id,
      studyTextId: studyTextId ?? this.studyTextId,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      knowledgeJson: knowledgeJson ?? this.knowledgeJson,
      summary: summary ?? this.summary,
    );
  }
}
