import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lingua_flow/features/shadowing/domain/usecases/compare_pronunciation.dart';

void main() {
  late ComparePronunciation comparePronunciation;

  setUp(() {
    comparePronunciation = const ComparePronunciation();
  });

  group('ComparePronunciation - local scoring', () {
    test('perfect match gives score of 100', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: 'hello world',
      );
      expect(result.score, 100.0);
    });

    test('completely different gives score near 0', () async {
      final result = await comparePronunciation.call(
        referenceText: 'the quick brown fox',
        recognizedText: 'xyz abc def ghi',
      );
      expect(result.score, lessThan(20));
    });

    test('partial match gives intermediate score', () async {
      final result = await comparePronunciation.call(
        referenceText: 'the quick brown fox',
        recognizedText: 'the quick red fox',
      );
      expect(result.score, greaterThan(50));
      expect(result.score, lessThan(100));
    });

    test('empty reference and empty recognized gives 100', () async {
      final result = await comparePronunciation.call(
        referenceText: '',
        recognizedText: '',
      );
      expect(result.score, 100.0);
    });

    test('empty recognized with non-empty reference gives 0', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: '',
      );
      expect(result.score, 0.0);
    });

    test('word feedback marks correct words as correct', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: 'hello world',
      );
      expect(result.wordFeedback.length, 2);
      expect(result.wordFeedback[0].status, 'correct');
      expect(result.wordFeedback[1].status, 'correct');
    });

    test('word feedback marks wrong words as wrong', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: 'goodbye universe',
      );
      expect(result.wordFeedback.length, 2);
      expect(result.wordFeedback[0].status, 'wrong');
      expect(result.wordFeedback[1].status, 'wrong');
    });

    test('close match (1 edit distance) marked as close', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello',
        recognizedText: 'hallo',
      );
      expect(result.wordFeedback.first.status, 'close');
    });

    test('suggestions are generated for wrong words', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: 'goodbye universe',
      );
      expect(result.suggestions, isNotEmpty);
      expect(result.suggestions.first, contains('注意'));
    });

    test('suggestions for perfect score are positive', () async {
      final result = await comparePronunciation.call(
        referenceText: 'hello world',
        recognizedText: 'hello world',
      );
      expect(result.suggestions, isNotEmpty);
      expect(result.suggestions.first, contains('好'));
    });

    test('is case-insensitive', () async {
      final result = await comparePronunciation.call(
        referenceText: 'Hello World',
        recognizedText: 'hello world',
      );
      expect(result.score, 100.0);
    });

    test('ignores punctuation', () async {
      final result = await comparePronunciation.call(
        referenceText: 'Hello, world!',
        recognizedText: 'hello world',
      );
      expect(result.score, 100.0);
    });
  });
}
