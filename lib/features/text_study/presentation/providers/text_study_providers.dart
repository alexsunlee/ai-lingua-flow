import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/gemini_client.dart';
import '../../../../core/widgets/word_card_popup.dart';
import '../../../../injection.dart';
import '../../../vocabulary/domain/entities/vocabulary_entry.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../data/datasources/text_study_local_datasource.dart';
import '../../data/repositories/text_study_repository_impl.dart';
import '../../domain/entities/study_text.dart';
import '../../domain/repositories/text_study_repository.dart';
import '../../domain/usecases/analyze_text.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final _textStudyLocalDatasourceProvider =
    Provider<TextStudyLocalDatasource>((ref) {
  return TextStudyLocalDatasource();
});

final _textStudyRepositoryProvider = Provider<TextStudyRepository>((ref) {
  return TextStudyRepositoryImpl(
    localDatasource: ref.watch(_textStudyLocalDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

/// Provides the [AnalyzeText] use case, ready to call.
final analyzeTextUseCaseProvider = Provider<AnalyzeText>((ref) {
  return AnalyzeText(
    repository: ref.watch(_textStudyRepositoryProvider),
    geminiClient: getIt<GeminiClient>(),
  );
});

// ---------------------------------------------------------------------------
// Study texts list (AsyncNotifier)
// ---------------------------------------------------------------------------

final studyTextsListProvider =
    AsyncNotifierProvider<StudyTextsListNotifier, List<StudyText>>(
  StudyTextsListNotifier.new,
);

class StudyTextsListNotifier extends AsyncNotifier<List<StudyText>> {
  @override
  Future<List<StudyText>> build() async {
    final repository = ref.watch(_textStudyRepositoryProvider);
    return repository.getAllStudyTexts();
  }

  /// Reload the list from the database.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(_textStudyRepositoryProvider);
      return repository.getAllStudyTexts();
    });
  }

  /// Delete a study text and refresh the list.
  Future<void> delete(String id) async {
    final repository = ref.read(_textStudyRepositoryProvider);
    await repository.deleteStudyText(id);
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Single study text detail (family provider)
// ---------------------------------------------------------------------------

/// Watches a single [StudyText] (with paragraphs) by its [id].
final studyTextDetailProvider =
    FutureProvider.family<StudyText?, String>((ref, id) async {
  final repository = ref.watch(_textStudyRepositoryProvider);
  return repository.getStudyTextById(id);
});

// ---------------------------------------------------------------------------
// Add word to vocabulary helper
// ---------------------------------------------------------------------------

/// Returns a callback that persists a [WordCardData] via the vocabulary
/// repository, which also creates an initial SM-2 review schedule.
final addToVocabularyProvider =
    Provider<Future<void> Function(WordCardData)>((ref) {
  return (WordCardData data) async {
    const uuid = Uuid();
    final entry = VocabularyEntry(
      id: uuid.v4(),
      word: data.word,
      pronunciation: data.pronunciation,
      translation: data.translation,
      explanation: data.explanation,
      etymology: data.etymology,
      exampleSentences: data.examples,
      synonyms: data.synonyms,
      sourceType: 'text_study',
      createdAt: DateTime.now(),
    );
    await ref.read(vocabularyListProvider.notifier).addEntry(entry);
  };
});
