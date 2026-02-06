class VocabularyEntry {
  final String id;
  final String word;
  final String language;
  final String? pronunciation;
  final String? translation;
  final String? explanation;
  final String? etymology;
  final List<String> exampleSentences;
  final List<String> synonyms;
  final String? sourceType;
  final String? sourceId;
  final String? sourceContext;
  final String? audioFilePath;
  final DateTime createdAt;

  const VocabularyEntry({
    required this.id,
    required this.word,
    this.language = 'en',
    this.pronunciation,
    this.translation,
    this.explanation,
    this.etymology,
    this.exampleSentences = const [],
    this.synonyms = const [],
    this.sourceType,
    this.sourceId,
    this.sourceContext,
    this.audioFilePath,
    required this.createdAt,
  });
}
