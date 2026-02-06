import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/network/gemini_client.dart';
import '../entities/paragraph.dart';
import '../entities/study_text.dart';
import '../repositories/text_study_repository.dart';

class AnalyzeText {
  final TextStudyRepository _repository;
  final GeminiClient _geminiClient;

  const AnalyzeText({
    required TextStudyRepository repository,
    required GeminiClient geminiClient,
  })  : _repository = repository,
        _geminiClient = geminiClient;

  /// Analyze [text] with the given [title].
  ///
  /// 1. Splits the text into paragraphs.
  /// 2. Calls Gemini to translate, extract knowledge, and summarize each
  ///    paragraph.
  /// 3. Persists the [StudyText] and its [Paragraph]s to the database.
  /// 4. Returns the study text id.
  Future<String> call({
    required String title,
    required String text,
    String sourceLanguage = 'en',
    String targetLanguage = 'zh',
  }) async {
    const uuid = Uuid();
    final studyTextId = uuid.v4();
    final now = DateTime.now();

    // Split into non-empty paragraphs.
    final rawParagraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // If only one paragraph after splitting on blank lines, try single newlines.
    final paragraphTexts = rawParagraphs.length <= 1 && text.contains('\n')
        ? text
            .split('\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList()
        : rawParagraphs;

    // Build the prompt for Gemini.
    final numberedParagraphs = paragraphTexts
        .asMap()
        .entries
        .map((e) => '[${e.key}] ${e.value}')
        .join('\n\n');

    final prompt = '''
You are a language-learning assistant. The user is studying English text and needs a Chinese analysis.

Below are paragraphs of English text, each prefixed with an index number in square brackets.

For EACH paragraph, provide:
1. "translation" — a natural, accurate Chinese (简体中文) translation.
2. "knowledge" — a list of key phrases or grammar points worth learning. Each item should have "phrase" (the English phrase), "explanation" (brief explanation in Chinese), and "pos" (part of speech, e.g. noun, verb, phrase).
3. "summary" — a one-sentence Chinese summary of the paragraph's main idea.

Return a JSON object with a single key "paragraphs" whose value is an array of objects, one per paragraph, in the same order. Each object must have:
- "index": the paragraph index (integer)
- "translation": string
- "knowledge": array of {"phrase": string, "explanation": string, "pos": string}
- "summary": string

TEXT:
$numberedParagraphs
''';

    final result = await _geminiClient.generateStructured(prompt: prompt);

    // Parse Gemini response.
    final paragraphResults = result['paragraphs'] as List<dynamic>? ?? [];

    final paragraphs = <Paragraph>[];
    for (var i = 0; i < paragraphTexts.length; i++) {
      // Find the matching result by index, or fall back to positional.
      Map<String, dynamic>? matched;
      for (final item in paragraphResults) {
        if (item is Map<String, dynamic> && item['index'] == i) {
          matched = item;
          break;
        }
      }
      matched ??= (i < paragraphResults.length &&
              paragraphResults[i] is Map<String, dynamic>)
          ? paragraphResults[i] as Map<String, dynamic>
          : null;

      paragraphs.add(Paragraph(
        id: uuid.v4(),
        studyTextId: studyTextId,
        paragraphIndex: i,
        originalText: paragraphTexts[i],
        translatedText: matched?['translation'] as String?,
        knowledgeJson: matched?['knowledge'] != null
            ? jsonEncode(matched!['knowledge'])
            : null,
        summary: matched?['summary'] as String?,
      ));
    }

    // Persist.
    final studyText = StudyText(
      id: studyTextId,
      title: title,
      originalText: text,
      sourceType: 'manual',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      analysisJson: jsonEncode(result),
      createdAt: now,
      updatedAt: now,
      paragraphs: paragraphs,
    );

    await _repository.saveStudyText(studyText);
    await _repository.saveParagraphs(paragraphs);

    return studyTextId;
  }
}
