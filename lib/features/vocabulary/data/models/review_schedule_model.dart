import '../../domain/entities/review_schedule.dart';

class ReviewScheduleModel extends ReviewSchedule {
  const ReviewScheduleModel({
    required super.id,
    required super.vocabularyEntryId,
    super.repetitionCount,
    super.easeFactor,
    super.intervalDays,
    required super.nextReviewDate,
    super.lastReviewDate,
    super.lastQuality,
  });

  /// Create a [ReviewScheduleModel] from a SQLite row map.
  factory ReviewScheduleModel.fromMap(Map<String, dynamic> map) {
    return ReviewScheduleModel(
      id: map['id'] as String,
      vocabularyEntryId: map['vocabulary_entry_id'] as String,
      repetitionCount: (map['repetition_count'] as int?) ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (map['interval_days'] as int?) ?? 0,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
      lastReviewDate: map['last_review_date'] != null
          ? DateTime.parse(map['last_review_date'] as String)
          : null,
      lastQuality: map['last_quality'] as int?,
    );
  }

  /// Create a [ReviewScheduleModel] from a domain entity.
  factory ReviewScheduleModel.fromEntity(ReviewSchedule schedule) {
    return ReviewScheduleModel(
      id: schedule.id,
      vocabularyEntryId: schedule.vocabularyEntryId,
      repetitionCount: schedule.repetitionCount,
      easeFactor: schedule.easeFactor,
      intervalDays: schedule.intervalDays,
      nextReviewDate: schedule.nextReviewDate,
      lastReviewDate: schedule.lastReviewDate,
      lastQuality: schedule.lastQuality,
    );
  }

  /// Convert to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vocabulary_entry_id': vocabularyEntryId,
      'repetition_count': repetitionCount,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'next_review_date': nextReviewDate.toIso8601String(),
      'last_review_date': lastReviewDate?.toIso8601String(),
      'last_quality': lastQuality,
    };
  }
}
