import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/gemini_client.dart';
import '../../../../injection.dart';
import '../../data/datasources/assessment_local_datasource.dart';
import '../../data/repositories/assessment_repository_impl.dart';
import '../../domain/entities/assessment_report.dart';

import '../../domain/repositories/assessment_repository.dart';
import '../../domain/usecases/generate_assessment.dart';

final _assessmentDatasourceProvider = Provider<AssessmentLocalDatasource>(
  (ref) => AssessmentLocalDatasource(),
);

final _assessmentRepositoryProvider = Provider<AssessmentRepository>(
  (ref) => AssessmentRepositoryImpl(localDatasource: ref.read(_assessmentDatasourceProvider)),
);

/// Aggregated learning stats for the dashboard.
final learningStatsProvider = FutureProvider<LearningStats>((ref) async {
  final repo = ref.read(_assessmentRepositoryProvider);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final activities = await repo.getActivities(start: weekAgo, end: now);

  int totalSeconds = 0;
  int totalWords = 0;
  int sessions = activities.length;

  for (final a in activities) {
    totalSeconds += a.durationSeconds;
    totalWords += a.newWordsAdded;
  }

  return LearningStats(
    totalStudyMinutes: totalSeconds ~/ 60,
    wordsLearned: totalWords,
    sessionsCompleted: sessions,
  );
});

/// List of assessment reports.
final assessmentReportsProvider =
    FutureProvider<List<AssessmentReport>>((ref) async {
  final repo = ref.read(_assessmentRepositoryProvider);
  return repo.getReports();
});

/// Generate a new assessment report.
final generateAssessmentProvider = Provider<GenerateAssessment>((ref) {
  return GenerateAssessment(
    repository: ref.read(_assessmentRepositoryProvider),
    geminiClient: getIt<GeminiClient>(),
  );
});

class LearningStats {
  final int totalStudyMinutes;
  final int wordsLearned;
  final int sessionsCompleted;

  const LearningStats({
    required this.totalStudyMinutes,
    required this.wordsLearned,
    required this.sessionsCompleted,
  });
}
