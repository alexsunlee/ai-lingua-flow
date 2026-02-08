import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants/app_constants.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/gemini_client.dart';
import '../core/storage/file_storage_service.dart';
import 'tts_service.dart';

/// TTS service that uses Gemini TTS API for natural speech with caching,
/// falling back to system TTS (flutter_tts) when offline or unconfigured.
class GeminiTtsService {
  final GeminiClient _geminiClient;
  final FileStorageService _fileStorageService;
  final ConnectivityService _connectivityService;
  final TtsService _fallbackTts;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _voiceName = AppConstants.geminiTtsDefaultVoice;

  GeminiTtsService({
    required GeminiClient geminiClient,
    required FileStorageService fileStorageService,
    required ConnectivityService connectivityService,
    required TtsService fallbackTts,
  })  : _geminiClient = geminiClient,
        _fileStorageService = fileStorageService,
        _connectivityService = connectivityService,
        _fallbackTts = fallbackTts;

  /// Expose the audio player for external position/duration/state monitoring.
  AudioPlayer get audioPlayer => _audioPlayer;

  /// Ensure audio for [text] is cached. Returns the WAV file path on success,
  /// or null if Gemini TTS is unavailable (caller should fallback to system TTS).
  Future<String?> ensureCached(String text) async {
    try {
      final cacheKey = '${_stableHash(text)}_$_voiceName';
      final cachePath = _fileStorageService.ttsCacheFilePath('$cacheKey.wav');
      final cacheFile = File(cachePath);

      if (await cacheFile.exists()) return cachePath;

      if (!_geminiClient.isConfigured || !_connectivityService.isOnline) {
        return null;
      }

      final pcmBytes = await _geminiClient.generateAudio(
        text: text,
        voiceName: _voiceName,
      );
      final wavBytes = _buildWav(pcmBytes);
      await cacheFile.writeAsBytes(wavBytes);
      return cachePath;
    } catch (e) {
      debugPrint('Gemini TTS ensureCached failed: $e');
      return null;
    }
  }

  /// Play a cached WAV file at the given [path].
  Future<void> playFile(String path, {double speed = 1.0}) async {
    await _audioPlayer.setFilePath(path);
    await _audioPlayer.setSpeed(speed);
    await _audioPlayer.play();
  }

  /// Speak text using Gemini TTS with caching. Falls back to system TTS
  /// when offline, unconfigured, or on error.
  Future<void> speak(String text, {double playbackSpeed = 1.0}) async {
    final path = await ensureCached(text);
    if (path == null) {
      await _fallbackTts.speak(text);
      return;
    }
    try {
      await playFile(path, speed: playbackSpeed);
    } catch (e) {
      debugPrint('Playback failed, falling back to system TTS: $e');
      await _fallbackTts.speak(text);
    }
  }

  void setVoice(String name) {
    _voiceName = name;
  }

  String get currentVoice => _voiceName;

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> clearCache() async {
    await _fileStorageService.clearTtsCache();
  }

  Future<void> dispose() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  /// Stable hash for cache keys using SHA-256 truncated to 16 hex chars.
  String _stableHash(String input) {
    final bytes = utf8.encode(input);
    // Simple FNV-1a 64-bit hash — deterministic across runs
    var hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Build a complete WAV file from raw PCM data.
  /// Format: 24kHz, 16-bit, mono (matches Gemini TTS output).
  Uint8List _buildWav(Uint8List pcmData) {
    final pcmLength = pcmData.length;
    final fileLength = pcmLength + 36; // total - 8 bytes for RIFF header
    final sampleRate = AppConstants.geminiTtsSampleRate;
    final bitsPerSample = AppConstants.geminiTtsBitsPerSample;
    final channels = AppConstants.geminiTtsChannels;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileLength, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, pcmLength, Endian.little);

    final wav = Uint8List(44 + pcmLength);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + pcmLength, pcmData);
    return wav;
  }
}
