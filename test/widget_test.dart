import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lingua_flow/core/utils/text_parser.dart';

void main() {
  group('TextParser', () {
    test('tokenizes English text into words and spaces', () {
      final tokens = TextParser.tokenize('Hello world');
      expect(tokens.length, 3); // Hello, ' ', world
      expect(tokens[0].text, 'Hello');
      expect(tokens[0].isWord, true);
      expect(tokens[1].text, ' ');
      expect(tokens[1].isWord, false);
      expect(tokens[2].text, 'world');
      expect(tokens[2].isWord, true);
    });

    test('tokenizes Chinese characters individually', () {
      final tokens = TextParser.tokenize('你好');
      expect(tokens.length, 2);
      expect(tokens[0].text, '你');
      expect(tokens[0].isWord, true);
      expect(tokens[1].text, '好');
      expect(tokens[1].isWord, true);
    });

    test('handles mixed English and Chinese', () {
      final tokens = TextParser.tokenize('Hello 你好');
      final words = tokens.where((t) => t.isWord).toList();
      expect(words.length, 3); // Hello, 你, 好
    });

    test('handles punctuation', () {
      final tokens = TextParser.tokenize('Hello, world!');
      final words = tokens.where((t) => t.isWord).toList();
      expect(words.length, 2);
      expect(words[0].text, 'Hello');
      expect(words[1].text, 'world');
    });

    test('handles contractions', () {
      final tokens = TextParser.tokenize("don't");
      final words = tokens.where((t) => t.isWord).toList();
      expect(words.length, 1);
      expect(words[0].text, "don't");
    });

    test('extractWords returns only word strings', () {
      final words = TextParser.extractWords('Hello, beautiful world!');
      expect(words, ['Hello', 'beautiful', 'world']);
    });

    test('handles empty string', () {
      expect(TextParser.tokenize(''), isEmpty);
      expect(TextParser.extractWords(''), isEmpty);
    });
  });
}
