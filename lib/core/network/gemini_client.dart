import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';

/// Gemini 3 REST API client using dio.
///
/// Uses the v1beta endpoint directly to support Gemini 3 thinking features
/// and structured JSON output.
class GeminiClient {
  final Dio _dio;
  String? _apiKey;
  bool _configured = false;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiClient({Dio? dio}) : _dio = dio ?? Dio();

  void configure(String apiKey) {
    _apiKey = apiKey;
    _configured = true;
  }

  bool get isConfigured => _configured && _apiKey != null;

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const GeminiException(
        message: '请先在设置中配置 Gemini API 密钥',
      );
    }
  }

  /// Generate structured JSON output with retry logic.
  /// Uses thinkingLevel 'low' to save tokens on structured tasks.
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
  }) async {
    _ensureConfigured();

    return _withRetry(() async {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': AppConstants.geminiTemperature,
          'responseMimeType': 'application/json',
          'thinkingConfig': {
            'thinkingLevel': 'low',
          },
        },
      };

      final text = await _post(AppConstants.geminiModel, body);
      try {
        return jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        throw GeminiException(message: 'Failed to parse JSON response: $e');
      }
    });
  }

  /// Generate free-form text with retry logic.
  /// Uses thinkingLevel 'low' to save tokens.
  Future<String> generateText({required String prompt}) async {
    _ensureConfigured();

    return _withRetry(() async {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': AppConstants.geminiTemperature,
          'thinkingConfig': {
            'thinkingLevel': 'low',
          },
        },
      };

      return _post(AppConstants.geminiModel, body);
    });
  }

  /// Validate API key by making a minimal test call.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': 'Hi'}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 5,
          'thinkingConfig': {
            'thinkingLevel': 'minimal',
          },
        },
      };

      final url =
          '$_baseUrl/${AppConstants.geminiModelValidation}:generateContent';
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
        ),
      );

      final text = _extractText(response.data as Map<String, dynamic>);
      return text.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Generate audio speech from text using Gemini TTS model.
  /// Returns raw PCM audio bytes (24kHz, 16-bit, mono).
  Future<Uint8List> generateAudio({
    required String text,
    String voiceName = 'Kore',
  }) async {
    _ensureConfigured();

    return _withRetry(() async {
      final body = {
        'contents': [
          {
            'parts': [
              {'text': text}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': voiceName}
            }
          }
        },
      };

      final url =
          '$_baseUrl/${AppConstants.geminiTtsModel}:generateContent';
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey!,
          },
        ),
      );

      if (response.statusCode != 200) {
        throw GeminiException(
          message: 'Gemini TTS error: ${response.statusCode}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException(message: 'Empty TTS response');
      }
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw const GeminiException(message: 'Empty TTS content');
      }
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const GeminiException(message: 'Empty TTS parts');
      }
      final inlineData = parts[0]['inlineData'] as Map<String, dynamic>;
      final base64Audio = inlineData['data'] as String;
      return base64Decode(base64Audio);
    });
  }

  /// Generate structured JSON from a text prompt + inline audio.
  /// Used for audio transcription with timestamps.
  Future<Map<String, dynamic>> generateStructuredWithAudio({
    required String prompt,
    required List<int> audioBytes,
    required String mimeType,
  }) async {
    _ensureConfigured();

    return _withRetry(() async {
      final base64Audio = base64Encode(audioBytes);
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Audio,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': AppConstants.geminiTemperature,
          'responseMimeType': 'application/json',
          'thinkingConfig': {
            'thinkingLevel': 'low',
          },
        },
      };

      final text = await _post(AppConstants.geminiModel, body);
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'segments': decoded};
        return {'result': decoded};
      } catch (e) {
        throw GeminiException(
            message: 'Failed to parse audio transcription JSON: $e');
      }
    });
  }

  /// Generate text from an image using Gemini vision capabilities.
  /// Sends the image as base64 inline data and returns the text response.
  Future<String> generateTextFromImage({
    required String prompt,
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    _ensureConfigured();

    return _withRetry(() async {
      final base64Image = base64Encode(imageBytes);
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': AppConstants.geminiTemperature,
          'thinkingConfig': {
            'thinkingLevel': 'low',
          },
        },
      };

      return _post(AppConstants.geminiModel, body);
    });
  }

  /// Generate structured JSON from a text prompt + video file URI (e.g. YouTube URL).
  /// Gemini natively processes the video content.
  Future<Map<String, dynamic>> generateStructuredWithVideo({
    required String prompt,
    required String videoUri,
    String? mimeType,
  }) async {
    _ensureConfigured();

    return _withRetry(() async {
      final fileData = <String, dynamic>{
        'file_uri': videoUri,
      };
      if (mimeType != null) {
        fileData['mime_type'] = mimeType;
      }

      final body = {
        'contents': [
          {
            'parts': [
              {'file_data': fileData},
              {'text': prompt},
            ]
          }
        ],
        'generationConfig': {
          'temperature': AppConstants.geminiTemperature,
          'responseMimeType': 'application/json',
          'thinkingConfig': {
            'thinkingLevel': 'low',
          },
        },
      };

      final text = await _post(AppConstants.geminiModel, body);
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'segments': decoded};
        return {'result': decoded};
      } catch (e) {
        throw GeminiException(
            message: 'Failed to parse video transcription JSON: $e');
      }
    });
  }

  /// Send POST request to Gemini API and extract text from response.
  Future<String> _post(String model, Map<String, dynamic> body) async {
    final url = '$_baseUrl/$model:generateContent';

    final response = await _dio.post(
      url,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey!,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw GeminiException(
        message: 'Gemini API error: ${response.statusCode} ${response.data}',
      );
    }

    final text = _extractText(response.data as Map<String, dynamic>);
    if (text.isEmpty) {
      throw const GeminiException(message: 'Empty response from Gemini');
    }
    return text;
  }

  /// Extract answer text from Gemini response, skipping thinking parts.
  String _extractText(Map<String, dynamic> responseData) {
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) return '';

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';

    // Collect only non-thought parts.
    final buffer = StringBuffer();
    for (final part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap['thought'] == true) continue;
      final text = partMap['text'] as String?;
      if (text != null) buffer.write(text);
    }
    return buffer.toString();
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
          throw _toFriendlyException(e);
        }
        final delay = Duration(seconds: 1 << (attempt - 1)); // 1, 2, 4, 8, 16
        await Future.delayed(delay);
      }
    }
  }

  /// Convert low-level errors into user-friendly [GeminiException]s.
  GeminiException _toFriendlyException(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 429) {
        return const GeminiException(
          message: 'API 请求频率超限，请稍后再试',
          statusCode: 429,
        );
      }
      if (code != null && code >= 500) {
        return GeminiException(
          message: 'Gemini 服务暂时不可用 ($code)，请稍后再试',
          statusCode: code,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const GeminiException(message: '请求超时，请检查网络后重试');
      }
      if (error.type == DioExceptionType.connectionError) {
        return const GeminiException(message: '网络连接失败，请检查网络设置');
      }
    }
    if (error is TimeoutException) {
      return const GeminiException(message: '请求超时，请检查网络后重试');
    }
    return GeminiException(message: error.toString());
  }

  bool _isRetryable(Object error) {
    if (error is TimeoutException) return true;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) return true;
      if (statusCode != null && statusCode >= 500) return true;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return true;
      }
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('429') || msg.contains('rate limit')) return true;
    if (msg.contains('timeout') || msg.contains('timed out')) return true;
    return false;
  }
}
