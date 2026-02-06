import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../entities/review_schedule.dart';

/// Implements the SM-2 spaced repetition algorithm.
///
/// Takes a quality rating (0-5) and the current [ReviewSchedule],
/// and returns a new [ReviewSchedule] with updated interval, repetition
/// count, ease factor, and next review date.
class CalculateNextReview {
  /// Calculate the next review schedule based on the SM-2 algorithm.
  ///
  /// [quality] must be between 0 and 5 inclusive:
  ///   0 - Complete blackout
  ///   1 - Incorrect; correct answer remembered after reveal
  ///   2 - Incorrect; correct answer seemed easy to recall
  ///   3 - Correct with serious difficulty
  ///   4 - Correct after hesitation
  ///   5 - Perfect response
  ReviewSchedule call({
    required int quality,
    required ReviewSchedule currentSchedule,
  }) {
    assert(quality >= 0 && quality <= 5, 'Quality must be between 0 and 5');

    int newRepetition;
    int newInterval;
    double newEaseFactor;

    if (quality < 3) {
      // Failed recall: reset to beginning
      newRepetition = 0;
      newInterval = AppConstants.sm2FirstInterval;
      newEaseFactor = currentSchedule.easeFactor;
    } else {
      // Successful recall: progress interval
      newRepetition = currentSchedule.repetitionCount + 1;

      if (currentSchedule.repetitionCount == 0) {
        newInterval = AppConstants.sm2FirstInterval;
      } else if (currentSchedule.repetitionCount == 1) {
        newInterval = AppConstants.sm2SecondInterval;
      } else {
        newInterval =
            (currentSchedule.intervalDays * currentSchedule.easeFactor).round();
      }

      // Update ease factor using SM-2 formula
      newEaseFactor = currentSchedule.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      newEaseFactor = max(AppConstants.sm2MinEaseFactor, newEaseFactor);
    }

    final now = DateTime.now();
    final nextReviewDate = DateTime(
      now.year,
      now.month,
      now.day + newInterval,
    );

    return ReviewSchedule(
      id: currentSchedule.id,
      vocabularyEntryId: currentSchedule.vocabularyEntryId,
      repetitionCount: newRepetition,
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      nextReviewDate: nextReviewDate,
      lastReviewDate: now,
      lastQuality: quality,
    );
  }
}
