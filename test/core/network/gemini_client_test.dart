import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lingua_flow/core/network/gemini_client.dart';
import 'package:ai_lingua_flow/core/error/exceptions.dart';

void main() {
  group('GeminiClient', () {
    late GeminiClient client;

    setUp(() {
      client = GeminiClient();
    });

    test('isConfigured returns false before configure()', () {
      expect(client.isConfigured, false);
    });

    test('isConfigured returns true after configure()', () {
      client.configure('test-api-key');
      expect(client.isConfigured, true);
    });

    test('generateText throws when not configured', () {
      expect(
        () => client.generateText(prompt: 'test'),
        throwsA(isA<GeminiException>()),
      );
    });

    test('generateStructured throws when not configured', () {
      expect(
        () => client.generateStructured(prompt: 'test'),
        throwsA(isA<GeminiException>()),
      );
    });
  });
}
