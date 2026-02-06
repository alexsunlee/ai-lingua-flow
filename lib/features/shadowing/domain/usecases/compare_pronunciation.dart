import '../../../../core/network/gemini_client.dart';

/// Result of a pronunciation comparison.
class PronunciationResult {
  final double score;
  final List<WordFeedback> wordFeedback;
  final List<String> suggestions;

  const PronunciationResult({
    required this.score,
    this.wordFeedback = const [],
    this.suggestions = const [],
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'wordFeedback':
            wordFeedback.map((w) => w.toJson()).toList(),
        'suggestions': suggestions,
      };

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      score: (json['score'] as num).toDouble(),
      wordFeedback: (json['wordFeedback'] as List<dynamic>?)
              ?.map((e) => WordFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Feedback for a single word in the reference text.
class WordFeedback {
  final String word;

  /// 'correct', 'wrong', or 'close'
  final String status;
  final String? recognizedAs;

  const WordFeedback({
    required this.word,
    required this.status,
    this.recognizedAs,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'status': status,
        if (recognizedAs != null) 'recognizedAs': recognizedAs,
      };

  factory WordFeedback.fromJson(Map<String, dynamic> json) {
    return WordFeedback(
      word: json['word'] as String,
      status: json['status'] as String,
      recognizedAs: json['recognizedAs'] as String?,
    );
  }
}

/// Compares the user's recognized speech against the reference text.
///
/// A local Levenshtein-based score is always computed. When [useGemini] is
/// true the Gemini model is queried for richer word-level feedback.
class ComparePronunciation {
  final GeminiClient? _geminiClient;

  const ComparePronunciation({GeminiClient? geminiClient})
      : _geminiClient = geminiClient;

  /// Execute the comparison.
  ///
  /// [referenceText] is the original sentence the user was supposed to read.
  /// [recognizedText] is what the STT engine actually heard.
  /// When [useGemini] is true (and a client is available), Gemini will provide
  /// detailed word-level feedback.
  Future<PronunciationResult> call({
    required String referenceText,
    required String recognizedText,
    bool useGemini = false,
  }) async {
    // -- Local score (always computed) --
    final refWords = _normalizeWords(referenceText);
    final recWords = _normalizeWords(recognizedText);

    final localScore = _wordOverlapScore(refWords, recWords);
    final localWordFeedback = _buildWordFeedback(refWords, recWords);

    // -- Optional Gemini enrichment --
    if (useGemini && _geminiClient != null && _geminiClient.isConfigured) {
      try {
        return await _geminiCompare(referenceText, recognizedText, localScore);
      } catch (_) {
        // Fall back to local result on any Gemini error.
      }
    }

    return PronunciationResult(
      score: localScore,
      wordFeedback: localWordFeedback,
      suggestions: _buildSuggestions(localWordFeedback),
    );
  }

  // ---------------------------------------------------------------------------
  // Local helpers
  // ---------------------------------------------------------------------------

  List<String> _normalizeWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Compute a 0-100 score based on word overlap ratio with Levenshtein
  /// tolerance for close matches.
  double _wordOverlapScore(List<String> refWords, List<String> recWords) {
    if (refWords.isEmpty) return recWords.isEmpty ? 100.0 : 0.0;

    int matches = 0;
    final used = List<bool>.filled(recWords.length, false);

    for (final ref in refWords) {
      for (var j = 0; j < recWords.length; j++) {
        if (used[j]) continue;
        if (ref == recWords[j] || _levenshtein(ref, recWords[j]) <= 1) {
          matches++;
          used[j] = true;
          break;
        }
      }
    }

    final precision = recWords.isEmpty ? 0.0 : matches / recWords.length;
    final recall = matches / refWords.length;
    final f1 =
        (precision + recall) == 0 ? 0.0 : 2 * precision * recall / (precision + recall);

    return (f1 * 100).clamp(0, 100).roundToDouble();
  }

  /// Build per-word feedback using the recognized words.
  List<WordFeedback> _buildWordFeedback(
      List<String> refWords, List<String> recWords) {
    final feedback = <WordFeedback>[];
    final used = List<bool>.filled(recWords.length, false);

    for (final ref in refWords) {
      String status = 'wrong';
      String? recognizedAs;

      for (var j = 0; j < recWords.length; j++) {
        if (used[j]) continue;
        if (ref == recWords[j]) {
          status = 'correct';
          used[j] = true;
          break;
        } else if (_levenshtein(ref, recWords[j]) <= 1) {
          status = 'close';
          recognizedAs = recWords[j];
          used[j] = true;
          break;
        }
      }

      feedback.add(WordFeedback(
        word: ref,
        status: status,
        recognizedAs: status != 'correct' ? recognizedAs : null,
      ));
    }

    return feedback;
  }

  List<String> _buildSuggestions(List<WordFeedback> feedback) {
    final wrong =
        feedback.where((f) => f.status == 'wrong').map((f) => f.word).toList();
    final close =
        feedback.where((f) => f.status == 'close').map((f) => f.word).toList();

    final suggestions = <String>[];
    if (wrong.isNotEmpty) {
      suggestions.add('注意以下单词的发音: ${wrong.join(', ')}');
    }
    if (close.isNotEmpty) {
      suggestions.add('以下单词发音接近但不够准确: ${close.join(', ')}');
    }
    if (wrong.isEmpty && close.isEmpty) {
      suggestions.add('发音非常好，继续保持!');
    }
    return suggestions;
  }

  /// Classic Levenshtein edit distance.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;

    var prev = List<int>.generate(cols, (j) => j);
    var curr = List<int>.filled(cols, 0);

    for (var i = 1; i < rows; i++) {
      curr[0] = i;
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1, // deletion
          curr[j - 1] + 1, // insertion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[cols - 1];
  }

  // ---------------------------------------------------------------------------
  // Gemini enrichment
  // ---------------------------------------------------------------------------

  Future<PronunciationResult> _geminiCompare(
    String referenceText,
    String recognizedText,
    double localScore,
  ) async {
    final prompt = '''
You are a pronunciation assessment engine. Compare the user's spoken text against the reference text and provide detailed feedback.

Reference text: "$referenceText"
User's spoken text: "$recognizedText"

Return a JSON object with:
- "score": an integer from 0 to 100 representing overall pronunciation accuracy
- "wordFeedback": an array where each element has:
  - "word": the reference word
  - "status": "correct", "wrong", or "close"
  - "recognizedAs": what the user actually said (only if status is not "correct")
- "suggestions": an array of 1-3 brief improvement suggestions in Chinese

Be strict but fair. Consider word order and pronunciation closeness.
''';

    final result = await _geminiClient!.generateStructured(prompt: prompt);

    final score = (result['score'] as num?)?.toDouble() ?? localScore;
    final wordFeedbackRaw = result['wordFeedback'] as List<dynamic>? ?? [];
    final suggestionsRaw = result['suggestions'] as List<dynamic>? ?? [];

    return PronunciationResult(
      score: score.clamp(0, 100),
      wordFeedback: wordFeedbackRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => WordFeedback.fromJson(e))
          .toList(),
      suggestions: suggestionsRaw.map((e) => e.toString()).toList(),
    );
  }
}
