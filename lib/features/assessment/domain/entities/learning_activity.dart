class LearningActivity {
  final String id;
  final String activityType; // 'text_study', 'video_study', 'shadowing', 'vocabulary_review', 'dictation'
  final String? sourceId;
  final int durationSeconds;
  final int wordsEncountered;
  final int newWordsAdded;
  final double? contentDifficultyScore;
  final Map<String, dynamic>? metadataJson;
  final DateTime createdAt;

  const LearningActivity({
    required this.id,
    required this.activityType,
    this.sourceId,
    this.durationSeconds = 0,
    this.wordsEncountered = 0,
    this.newWordsAdded = 0,
    this.contentDifficultyScore,
    this.metadataJson,
    required this.createdAt,
  });
}
