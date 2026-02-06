import '../entities/review_schedule.dart';
import '../entities/vocabulary_entry.dart';

abstract class VocabularyRepository {
  /// Retrieve all vocabulary entries, ordered by most recently created.
  Future<List<VocabularyEntry>> getAllEntries();

  /// Retrieve a single vocabulary entry by [id].
  Future<VocabularyEntry?> getEntryById(String id);

  /// Insert a new vocabulary entry.
  Future<void> addEntry(VocabularyEntry entry);

  /// Update an existing vocabulary entry.
  Future<void> updateEntry(VocabularyEntry entry);

  /// Delete a vocabulary entry by [id].
  Future<void> deleteEntry(String id);

  /// Search vocabulary entries whose word or translation matches [query].
  Future<List<VocabularyEntry>> searchEntries(String query);

  /// Get all vocabulary entries that are due for review on or before [date].
  Future<List<VocabularyEntry>> getDueReviews(DateTime date);

  /// Get the review schedule for a given vocabulary entry.
  Future<ReviewSchedule?> getScheduleForEntry(String vocabularyEntryId);

  /// Insert or update a review schedule.
  Future<void> saveSchedule(ReviewSchedule schedule);
}
