class ShadowingSession {
  final String id;
  final String sourceType; // 'text' or 'video'
  final String sourceId;
  final String sentenceText;
  final int sentenceIndex;
  final String? recordingFilePath;
  final String? recognizedText;
  final double? pronunciationScore;
  final Map<String, dynamic>? feedbackJson;
  final DateTime createdAt;

  const ShadowingSession({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.sentenceText,
    this.sentenceIndex = 0,
    this.recordingFilePath,
    this.recognizedText,
    this.pronunciationScore,
    this.feedbackJson,
    required this.createdAt,
  });

  ShadowingSession copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    String? sentenceText,
    int? sentenceIndex,
    String? recordingFilePath,
    String? recognizedText,
    double? pronunciationScore,
    Map<String, dynamic>? feedbackJson,
    DateTime? createdAt,
  }) {
    return ShadowingSession(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sentenceText: sentenceText ?? this.sentenceText,
      sentenceIndex: sentenceIndex ?? this.sentenceIndex,
      recordingFilePath: recordingFilePath ?? this.recordingFilePath,
      recognizedText: recognizedText ?? this.recognizedText,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      feedbackJson: feedbackJson ?? this.feedbackJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
