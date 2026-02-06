import 'package:flutter_tts/flutter_tts.dart';

import '../core/constants/app_constants.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _initialized = true;
  }

  /// Speak text using flutter_tts.
  /// Short text (≤3 words) always uses local TTS.
  /// Longer text uses local TTS by default.
  Future<void> speak(String text) async {
    await init();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Whether the text is short enough to always use local TTS.
  bool isShortText(String text) {
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    return wordCount <= AppConstants.ttsShortTextMaxWords;
  }

  Future<void> setLanguage(String language) async {
    await init();
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    await init();
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
