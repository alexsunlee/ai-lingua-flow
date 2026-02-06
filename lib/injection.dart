import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/network/gemini_client.dart';
import 'core/storage/file_storage_service.dart';
import 'services/audio_service.dart';
import 'services/dictionary_service.dart';
import 'services/tts_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<GeminiClient>(() => GeminiClient());
  getIt.registerLazySingleton<FileStorageService>(() => FileStorageService());
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Services
  getIt.registerLazySingleton<TtsService>(() => TtsService());
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<DictionaryService>(
    () => DictionaryService(
      geminiClient: getIt<GeminiClient>(),
      dio: getIt<Dio>(),
    ),
  );

  // Initialize file storage
  await getIt<FileStorageService>().init();
}
