import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/vocabulary_local_datasource.dart';
import '../../data/repositories/vocabulary_repository_impl.dart';
import '../../domain/entities/review_schedule.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/usecases/calculate_next_review.dart';

// ──────────────── Core providers ────────────────

final vocabularyLocalDatasourceProvider =
    Provider<VocabularyLocalDatasource>((ref) {
  return VocabularyLocalDatasource();
});

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepositoryImpl(
    localDatasource: ref.watch(vocabularyLocalDatasourceProvider),
  );
});

final calculateNextReviewProvider = Provider<CalculateNextReview>((ref) {
  return CalculateNextReview();
});

// ──────────────── Vocabulary list ────────────────

/// Watches all vocabulary entries.
final vocabularyListProvider =
    AsyncNotifierProvider<VocabularyListNotifier, List<VocabularyEntry>>(
  VocabularyListNotifier.new,
);

class VocabularyListNotifier extends AsyncNotifier<List<VocabularyEntry>> {
  @override
  Future<List<VocabularyEntry>> build() async {
    final repo = ref.watch(vocabularyRepositoryProvider);
    return repo.getAllEntries();
  }

  Future<void> addEntry(VocabularyEntry entry) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    await repo.addEntry(entry);

    // Create initial review schedule for the new entry
    const uuid = Uuid();
    final schedule = ReviewSchedule(
      id: uuid.v4(),
      vocabularyEntryId: entry.id,
      nextReviewDate: DateTime.now(),
    );
    await repo.saveSchedule(schedule);

    ref.invalidateSelf();
  }

  Future<void> deleteEntry(String id) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    await repo.deleteEntry(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ──────────────── Due reviews ────────────────

/// Watches vocabulary entries that are due for review.
final dueReviewsProvider =
    AsyncNotifierProvider<DueReviewsNotifier, List<VocabularyEntry>>(
  DueReviewsNotifier.new,
);

class DueReviewsNotifier extends AsyncNotifier<List<VocabularyEntry>> {
  @override
  Future<List<VocabularyEntry>> build() async {
    final repo = ref.watch(vocabularyRepositoryProvider);
    return repo.getDueReviews(DateTime.now());
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ──────────────── Search ────────────────

/// A family provider that searches vocabulary entries by query string.
final vocabularySearchProvider =
    FutureProvider.family<List<VocabularyEntry>, String>((ref, query) async {
  final repo = ref.watch(vocabularyRepositoryProvider);
  if (query.trim().isEmpty) {
    return repo.getAllEntries();
  }
  return repo.searchEntries(query);
});

// ──────────────── Review session ────────────────

/// State for the current review session.
class ReviewSessionState {
  final List<VocabularyEntry> entries;
  final int currentIndex;
  final bool isRevealed;
  final bool isComplete;
  final Map<String, int> ratings; // entryId -> quality

  const ReviewSessionState({
    this.entries = const [],
    this.currentIndex = 0,
    this.isRevealed = false,
    this.isComplete = false,
    this.ratings = const {},
  });

  int get totalCount => entries.length;
  int get completedCount => ratings.length;
  VocabularyEntry? get currentEntry =>
      entries.isNotEmpty && currentIndex < entries.length
          ? entries[currentIndex]
          : null;

  ReviewSessionState copyWith({
    List<VocabularyEntry>? entries,
    int? currentIndex,
    bool? isRevealed,
    bool? isComplete,
    Map<String, int>? ratings,
  }) {
    return ReviewSessionState(
      entries: entries ?? this.entries,
      currentIndex: currentIndex ?? this.currentIndex,
      isRevealed: isRevealed ?? this.isRevealed,
      isComplete: isComplete ?? this.isComplete,
      ratings: ratings ?? this.ratings,
    );
  }
}

/// Manages the current review session state.
final reviewSessionProvider =
    NotifierProvider<ReviewSessionNotifier, ReviewSessionState>(
  ReviewSessionNotifier.new,
);

class ReviewSessionNotifier extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() {
    return const ReviewSessionState();
  }

  /// Start a new review session with the given entries.
  void startSession(List<VocabularyEntry> entries) {
    state = ReviewSessionState(entries: entries);
  }

  /// Reveal the back of the current flashcard.
  void reveal() {
    state = state.copyWith(isRevealed: true);
  }

  /// Rate the current entry and advance to the next one.
  Future<void> rateAndAdvance(int quality) async {
    final currentEntry = state.currentEntry;
    if (currentEntry == null) return;

    // Save the quality rating
    final newRatings = Map<String, int>.from(state.ratings);
    newRatings[currentEntry.id] = quality;

    // Update the review schedule
    final repo = ref.read(vocabularyRepositoryProvider);
    final calculator = ref.read(calculateNextReviewProvider);
    final existingSchedule =
        await repo.getScheduleForEntry(currentEntry.id);

    if (existingSchedule != null) {
      final updatedSchedule = calculator.call(
        quality: quality,
        currentSchedule: existingSchedule,
      );
      await repo.saveSchedule(updatedSchedule);
    }

    // Advance to next entry or complete the session
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.entries.length) {
      state = state.copyWith(
        ratings: newRatings,
        isComplete: true,
        isRevealed: false,
      );
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        ratings: newRatings,
        isRevealed: false,
      );
    }
  }

  /// Reset the session.
  void reset() {
    state = const ReviewSessionState();
  }
}
