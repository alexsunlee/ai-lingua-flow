import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileStorageService {
  Directory? _appDir;
  Directory? _audioDir;
  Directory? _recordingsDir;

  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
    _audioDir = Directory(p.join(_appDir!.path, 'audio'));
    _recordingsDir = Directory(p.join(_appDir!.path, 'recordings'));

    await _audioDir!.create(recursive: true);
    await _recordingsDir!.create(recursive: true);
  }

  Directory get appDir {
    if (_appDir == null) throw StateError('FileStorageService not initialized');
    return _appDir!;
  }

  Directory get audioDir => _audioDir!;
  Directory get recordingsDir => _recordingsDir!;

  String audioFilePath(String filename) => p.join(_audioDir!.path, filename);

  String recordingFilePath(String filename) =>
      p.join(_recordingsDir!.path, filename);

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
