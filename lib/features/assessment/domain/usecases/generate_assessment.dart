import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/network/gemini_client.dart';
import '../entities/assessment_report.dart';
import '../entities/learning_activity.dart';
import '../repositories/assessment_repository.dart';

class GenerateAssessment {
  final AssessmentRepository _repository;
  final GeminiClient _geminiClient;

  const GenerateAssessment({
    required AssessmentRepository repository,
    required GeminiClient geminiClient,
  })  : _repository = repository,
        _geminiClient = geminiClient;

  /// Generate an assessment report for the period between [start] and [end].
  ///
  /// 1. Aggregates learning activities for the period.
  /// 2. Calculates summary metrics.
  /// 3. Sends a structured prompt to Gemini for evaluation.
  /// 4. Persists the resulting [AssessmentReport] to the database.
  /// 5. Returns the saved report.
  Future<AssessmentReport> call({
    required DateTime start,
    required DateTime end,
    String reportType = 'custom',
  }) async {
    // 1. Fetch activities for the period.
    final activities = await _repository.getActivities(
      start: start,
      end: end,
    );

    // 2. Aggregate metrics.
    final metrics = _aggregateMetrics(activities);

    // 3. Build the prompt.
    final prompt = _buildPrompt(
      metrics: metrics,
      start: start,
      end: end,
    );

    // 4. Call Gemini for assessment.
    final result = await _geminiClient.generateStructured(prompt: prompt);

    // 5. Parse the response.
    final overallScore = (result['overall_score'] as num?)?.toDouble();

    final dimensionsJson = <String, dynamic>{};
    if (result['dimensions'] is Map) {
      final dims = result['dimensions'] as Map<String, dynamic>;
      for (final key in ['reading', 'listening', 'speaking', 'vocabulary']) {
        dimensionsJson[key] = (dims[key] as num?)?.toDouble() ?? 0.0;
      }
    }

    final summaryText = result['summary'] as String?;

    final recommendations = <String>[];
    if (result['recommendations'] is List) {
      for (final item in result['recommendations'] as List) {
        recommendations.add(item.toString());
      }
    }

    // 6. Save the report.
    const uuid = Uuid();
    final report = AssessmentReport(
      id: uuid.v4(),
      reportType: reportType,
      periodStart: start,
      periodEnd: end,
      overallScore: overallScore,
      dimensionsJson: dimensionsJson,
      summaryText: summaryText,
      recommendations: recommendations,
      createdAt: DateTime.now(),
    );

    await _repository.saveReport(report);

    return report;
  }

  /// Aggregate raw activities into summary metrics.
  Map<String, dynamic> _aggregateMetrics(List<LearningActivity> activities) {
    int totalStudyTimeSeconds = 0;
    int totalWordsEncountered = 0;
    int totalNewWordsAdded = 0;
    int sessionsCompleted = activities.length;

    final typeCounts = <String, int>{};
    final typeDurations = <String, int>{};
    double difficultySum = 0;
    int difficultyCount = 0;

    for (final activity in activities) {
      totalStudyTimeSeconds += activity.durationSeconds;
      totalWordsEncountered += activity.wordsEncountered;
      totalNewWordsAdded += activity.newWordsAdded;

      typeCounts[activity.activityType] =
          (typeCounts[activity.activityType] ?? 0) + 1;
      typeDurations[activity.activityType] =
          (typeDurations[activity.activityType] ?? 0) +
              activity.durationSeconds;

      if (activity.contentDifficultyScore != null) {
        difficultySum += activity.contentDifficultyScore!;
        difficultyCount++;
      }
    }

    return {
      'total_study_time_seconds': totalStudyTimeSeconds,
      'total_study_time_minutes': (totalStudyTimeSeconds / 60).round(),
      'total_words_encountered': totalWordsEncountered,
      'total_new_words_added': totalNewWordsAdded,
      'sessions_completed': sessionsCompleted,
      'type_counts': typeCounts,
      'type_durations_seconds': typeDurations,
      'average_difficulty':
          difficultyCount > 0 ? difficultySum / difficultyCount : null,
    };
  }

  /// Build a structured prompt for Gemini assessment.
  String _buildPrompt({
    required Map<String, dynamic> metrics,
    required DateTime start,
    required DateTime end,
  }) {
    final metricsJson = jsonEncode(metrics);

    return '''
你是一位专业的英语学习评估顾问。请根据以下用户学习数据，生成一份详细的学习评估报告。

评估时间段: ${start.toIso8601String().substring(0, 10)} 至 ${end.toIso8601String().substring(0, 10)}

学习数据统计:
$metricsJson

请严格按照以下JSON格式返回评估结果:
{
  "overall_score": <0到100的整数，代表综合学习表现>,
  "dimensions": {
    "reading": <0到100的整数，阅读能力评分>,
    "listening": <0到100的整数，听力能力评分>,
    "speaking": <0到100的整数，口语能力评分>,
    "vocabulary": <0到100的整数，词汇能力评分>
  },
  "summary": "<用中文写的200-300字的学习总结叙述，包括学习表现的亮点和不足>",
  "recommendations": [
    "<用中文写的具体改进建议1>",
    "<用中文写的具体改进建议2>",
    "<用中文写的具体改进建议3>",
    "<用中文写的具体改进建议4>"
  ]
}

评分参考标准:
- text_study 活动影响 reading 和 vocabulary 维度
- video_study 活动影响 listening 和 reading 维度
- shadowing 活动影响 speaking 和 listening 维度
- vocabulary_review 和 dictation 活动影响 vocabulary 维度
- 学习时长、频率、新词数量等综合考虑
- 如果某个维度没有对应活动数据，给一个保守的估计分数（40-50）

请确保返回有效的JSON格式。
''';
  }
}
