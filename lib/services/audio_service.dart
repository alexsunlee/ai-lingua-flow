import 'package:just_audio/just_audio.dart';

/// Wrapper around just_audio for playback.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  Future<void> setFilePath(String path) async {
    await _player.setFilePath(path);
  }

  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Play a specific segment (start to end).
  Future<void> playSegment(Duration start, Duration end) async {
    await _player.seek(start);
    await _player.play();

    // Listen for end of segment
    _player.positionStream.listen((pos) {
      if (pos >= end && _player.playing) {
        _player.pause();
        _player.seek(start);
      }
    });
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
