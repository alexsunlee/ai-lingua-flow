import '../entities/paragraph.dart';
import '../entities/study_text.dart';

abstract class TextStudyRepository {
  /// Retrieve all study texts, ordered by most recently updated.
  Future<List<StudyText>> getAllStudyTexts();

  /// Retrieve a single study text by [id], with its paragraphs attached.
  Future<StudyText?> getStudyTextById(String id);

  /// Insert or update a study text.
  Future<void> saveStudyText(StudyText studyText);

  /// Delete a study text and its associated paragraphs.
  Future<void> deleteStudyText(String id);

  /// Insert or replace paragraphs for a given study text.
  Future<void> saveParagraphs(List<Paragraph> paragraphs);

  /// Retrieve all paragraphs belonging to the given [studyTextId].
  Future<List<Paragraph>> getParagraphsForText(String studyTextId);
}
