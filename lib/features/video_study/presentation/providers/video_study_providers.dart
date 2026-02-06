import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/gemini_client.dart';
import '../../../../core/storage/file_storage_service.dart';
import '../../../../injection.dart';
import '../../data/datasources/video_study_local_datasource.dart';
import '../../data/datasources/youtube_datasource.dart';
import '../../data/repositories/video_study_repository_impl.dart';
import '../../domain/entities/video_resource.dart';
import '../../domain/repositories/video_study_repository.dart';
import '../../domain/usecases/process_video.dart';

// ---------------------------------------------------------------------------
// Datasources
// ---------------------------------------------------------------------------

final videoStudyLocalDatasourceProvider =
    Provider<VideoStudyLocalDatasource>((ref) {
  return VideoStudyLocalDatasource();
});

final youtubeDatasourceProvider = Provider<YouTubeDatasource>((ref) {
  return YouTubeDatasource(
    geminiClient: getIt<GeminiClient>(),
    fileStorageService: getIt<FileStorageService>(),
  );
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final videoStudyRepositoryProvider = Provider<VideoStudyRepository>((ref) {
  return VideoStudyRepositoryImpl(
    localDatasource: ref.watch(videoStudyLocalDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Use cases
// ---------------------------------------------------------------------------

final processVideoUseCaseProvider = Provider<ProcessVideo>((ref) {
  return ProcessVideo(
    youtubeDatasource: ref.watch(youtubeDatasourceProvider),
    localDatasource: ref.watch(videoStudyLocalDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// UI state providers
// ---------------------------------------------------------------------------

/// Provider for the list of all video resources.
final videoResourcesListProvider =
    AutoDisposeFutureProvider<List<VideoResource>>((ref) async {
  final repository = ref.watch(videoStudyRepositoryProvider);
  return repository.getAllVideoResources();
});

/// Provider for a single video resource detail (with segments).
final videoResourceDetailProvider =
    AutoDisposeFutureProvider.family<VideoResource?, String>(
        (ref, videoResourceId) async {
  final repository = ref.watch(videoStudyRepositoryProvider);
  return repository.getVideoResourceById(videoResourceId);
});
