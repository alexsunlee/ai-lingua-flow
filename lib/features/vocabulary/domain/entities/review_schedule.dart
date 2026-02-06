class ReviewSchedule {
  final String id;
  final String vocabularyEntryId;
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime nextReviewDate;
  final DateTime? lastReviewDate;
  final int? lastQuality;

  const ReviewSchedule({
    required this.id,
    required this.vocabularyEntryId,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    required this.nextReviewDate,
    this.lastReviewDate,
    this.lastQuality,
  });
}
