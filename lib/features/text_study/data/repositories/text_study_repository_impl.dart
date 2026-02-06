import '../../domain/entities/paragraph.dart';
import '../../domain/entities/study_text.dart';
import '../../domain/repositories/text_study_repository.dart';
import '../datasources/text_study_local_datasource.dart';
import '../models/paragraph_model.dart';
import '../models/study_text_model.dart';

class TextStudyRepositoryImpl implements TextStudyRepository {
  final TextStudyLocalDatasource _localDatasource;

  const TextStudyRepositoryImpl({
    required TextStudyLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<List<StudyText>> getAllStudyTexts() async {
    return _localDatasource.getAllStudyTexts();
  }

  @override
  Future<StudyText?> getStudyTextById(String id) async {
    final model = await _localDatasource.getStudyTextById(id);
    if (model == null) return null;

    final paragraphs = await _localDatasource.getParagraphsForText(id);
    return model.withParagraphs(paragraphs);
  }

  @override
  Future<void> saveStudyText(StudyText studyText) async {
    final model = StudyTextModel.fromEntity(studyText);
    await _localDatasource.insertStudyText(model);
  }

  @override
  Future<void> deleteStudyText(String id) async {
    await _localDatasource.deleteStudyText(id);
  }

  @override
  Future<void> saveParagraphs(List<Paragraph> paragraphs) async {
    final models =
        paragraphs.map((p) => ParagraphModel.fromEntity(p)).toList();
    await _localDatasource.insertParagraphs(models);
  }

  @override
  Future<List<Paragraph>> getParagraphsForText(String studyTextId) async {
    return _localDatasource.getParagraphsForText(studyTextId);
  }
}
