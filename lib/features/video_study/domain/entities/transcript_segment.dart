class TranscriptSegment {
  final String id;
  final String videoResourceId;
  final int segmentIndex;
  final int startMs;
  final int endMs;
  final String originalText;
  final String? translatedText;

  const TranscriptSegment({
    required this.id,
    required this.videoResourceId,
    required this.segmentIndex,
    required this.startMs,
    required this.endMs,
    required this.originalText,
    this.translatedText,
  });

  TranscriptSegment copyWith({
    String? id,
    String? videoResourceId,
    int? segmentIndex,
    int? startMs,
    int? endMs,
    String? originalText,
    String? translatedText,
  }) {
    return TranscriptSegment(
      id: id ?? this.id,
      videoResourceId: videoResourceId ?? this.videoResourceId,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
    );
  }
}
