import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileStorageService {
  Directory? _appDir;
  Directory? _audioDir;
  Directory? _recordingsDir;
  Directory? _ttsCacheDir;

  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
    _audioDir = Directory(p.join(_appDir!.path, 'audio'));
    _recordingsDir = Directory(p.join(_appDir!.path, 'recordings'));
    _ttsCacheDir = Directory(p.join(_appDir!.path, 'tts_cache'));

    await _audioDir!.create(recursive: true);
    await _recordingsDir!.create(recursive: true);
    await _ttsCacheDir!.create(recursive: true);
  }

  Directory get appDir {
    if (_appDir == null) throw StateError('FileStorageService not initialized');
    return _appDir!;
  }

  Directory get audioDir => _audioDir!;
  Directory get recordingsDir => _recordingsDir!;
  Directory get ttsCacheDir => _ttsCacheDir!;

  String audioFilePath(String filename) => p.join(_audioDir!.path, filename);

  String recordingFilePath(String filename) =>
      p.join(_recordingsDir!.path, filename);

  String ttsCacheFilePath(String filename) =>
      p.join(_ttsCacheDir!.path, filename);

  Future<void> clearTtsCache() async {
    if (_ttsCacheDir != null && await _ttsCacheDir!.exists()) {
      await _ttsCacheDir!.delete(recursive: true);
      await _ttsCacheDir!.create(recursive: true);
    }
  }

  Future<File> saveAudioFile(String filename, List<int> bytes) async {
    final file = File(audioFilePath(filename));
    return file.writeAsBytes(bytes);
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}
