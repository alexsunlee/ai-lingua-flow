import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';

class GeminiClient {
  GenerativeModel? _model;
  String? _apiKey;

  void configure(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: AppConstants.geminiTemperature,
      ),
    );
  }

  bool get isConfigured => _model != null && _apiKey != null;

  GenerativeModel get _ensureModel {
    if (_model == null) {
      throw const GeminiException(
        message: '请先在设置中配置 Gemini API 密钥',
      );
    }
    return _model!;
  }

  /// Generate structured JSON output with retry logic.
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    Schema? responseSchema,
  }) async {
    _ensureModel; // Check configuration
    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: AppConstants.geminiTemperature,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );

    return _withRetry(() async {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const GeminiException(message: 'Empty response from Gemini');
      }
      try {
        return jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        throw GeminiException(message: 'Failed to parse JSON response: $e');
      }
    });
  }

  /// Generate free-form text with retry logic.
  Future<String> generateText({required String prompt}) async {
    return _withRetry(() async {
      final response =
          await _ensureModel.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const GeminiException(message: 'Empty response from Gemini');
      }
      return text;
    });
  }

  /// Validate API key by making a simple test call.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final testModel = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0,
          maxOutputTokens: 10,
        ),
      );
      final response =
          await testModel.generateContent([Content.text('Say "ok"')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Exponential backoff retry: 1s, 2s, 4s, 8s, 16s.
  /// Only retries on 429, 5xx, or timeout errors.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= AppConstants.geminiMaxRetries || !_isRetryable(e)) {
          if (e is GeminiException) rethrow;
          throw GeminiException(message: e.toString());
        }
        final delay = Duration(seconds: 1 << (attempt - 1)); // 1, 2, 4, 8, 16
        await Future.delayed(delay);
      }
    }
  }

  bool _isRetryable(Object error) {
    if (error is TimeoutException) return true;
    final msg = error.toString().toLowerCase();
    if (msg.contains('429') || msg.contains('rate limit')) return true;
    if (msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('504')) {
      return true;
    }
    if (msg.contains('timeout') || msg.contains('timed out')) return true;
    return false;
  }
}
