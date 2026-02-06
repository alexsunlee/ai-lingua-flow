/// Tokenizes text into tappable word segments.
class TextParser {
  TextParser._();

  /// Tokenize text into words and whitespace/punctuation segments.
  /// Returns list of [TextToken].
  static List<TextToken> tokenize(String text) {
    if (text.isEmpty) return [];

    final tokens = <TextToken>[];
    final buffer = StringBuffer();
    bool? lastWasWord;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isWord = _isWordChar(char);

      if (lastWasWord != null && isWord != lastWasWord) {
        tokens.add(TextToken(
          text: buffer.toString(),
          isWord: lastWasWord,
        ));
        buffer.clear();
      }

      // Chinese characters are each their own word token
      if (_isChinese(char)) {
        if (buffer.isNotEmpty) {
          tokens.add(TextToken(
            text: buffer.toString(),
            isWord: lastWasWord ?? false,
          ));
          buffer.clear();
        }
        tokens.add(TextToken(text: char, isWord: true));
        lastWasWord = null;
        continue;
      }

      buffer.write(char);
      lastWasWord = isWord;
    }

    if (buffer.isNotEmpty) {
      tokens.add(TextToken(
        text: buffer.toString(),
        isWord: lastWasWord ?? false,
      ));
    }

    return tokens;
  }

  /// Extract only the word tokens (for counting, analysis, etc).
  static List<String> extractWords(String text) {
    return tokenize(text)
        .where((t) => t.isWord)
        .map((t) => t.text.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static bool _isWordChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    // Letters, digits, apostrophe (for contractions like don't)
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        (code >= 48 && code <= 57) || // 0-9
        code == 39 || // apostrophe
        code == 8217 || // right single quotation mark
        _isChinese(char);
  }

  static bool _isChinese(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    // CJK Unified Ideographs range
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0xF900 && code <= 0xFAFF);
  }
}

class TextToken {
  final String text;
  final bool isWord;

  const TextToken({required this.text, required this.isWord});

  @override
  String toString() => 'TextToken("$text", isWord: $isWord)';
}
