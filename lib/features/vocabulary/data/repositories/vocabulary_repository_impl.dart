import '../../domain/entities/review_schedule.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/vocabulary_local_datasource.dart';
import '../models/review_schedule_model.dart';
import '../models/vocabulary_entry_model.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabularyLocalDatasource _localDatasource;

  VocabularyRepositoryImpl({
    required VocabularyLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<List<VocabularyEntry>> getAllEntries() {
    return _localDatasource.getAllEntries();
  }

  @override
  Future<VocabularyEntry?> getEntryById(String id) {
    return _localDatasource.getEntryById(id);
  }

  @override
  Future<void> addEntry(VocabularyEntry entry) {
    final model = VocabularyEntryModel.fromEntity(entry);
    return _localDatasource.insertEntry(model);
  }

  @override
  Future<void> updateEntry(VocabularyEntry entry) {
    final model = VocabularyEntryModel.fromEntity(entry);
    return _localDatasource.updateEntry(model);
  }

  @override
  Future<void> deleteEntry(String id) {
    return _localDatasource.deleteEntry(id);
  }

  @override
  Future<List<VocabularyEntry>> searchEntries(String query) {
    return _localDatasource.searchEntries(query);
  }

  @override
  Future<List<VocabularyEntry>> getDueReviews(DateTime date) {
    return _localDatasource.getDueReviews(date);
  }

  @override
  Future<ReviewSchedule?> getScheduleForEntry(String vocabularyEntryId) {
    return _localDatasource.getScheduleForEntry(vocabularyEntryId);
  }

  @override
  Future<void> saveSchedule(ReviewSchedule schedule) {
    final model = ReviewScheduleModel.fromEntity(schedule);
    return _localDatasource.saveSchedule(model);
  }
}
