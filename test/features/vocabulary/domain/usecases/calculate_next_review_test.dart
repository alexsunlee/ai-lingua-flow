import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lingua_flow/features/vocabulary/domain/entities/review_schedule.dart';
import 'package:ai_lingua_flow/features/vocabulary/domain/usecases/calculate_next_review.dart';

void main() {
  late CalculateNextReview calculateNextReview;

  setUp(() {
    calculateNextReview = CalculateNextReview();
  });

  ReviewSchedule makeSchedule({
    int repetitionCount = 0,
    double easeFactor = 2.5,
    int intervalDays = 0,
  }) {
    return ReviewSchedule(
      id: 'test-schedule',
      vocabularyEntryId: 'test-entry',
      repetitionCount: repetitionCount,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      nextReviewDate: DateTime.now(),
    );
  }

  group('SM-2 Algorithm', () {
    test('quality < 3 resets repetition count to 0 and interval to 1', () {
      final schedule =
          makeSchedule(repetitionCount: 5, easeFactor: 2.5, intervalDays: 30);

      for (int q = 0; q < 3; q++) {
        final result =
            calculateNextReview.call(quality: q, currentSchedule: schedule);
        expect(result.repetitionCount, 0, reason: 'quality=$q should reset');
        expect(result.intervalDays, 1, reason: 'quality=$q should reset to 1');
      }
    });

    test('first successful review sets interval to 1', () {
      final schedule = makeSchedule(repetitionCount: 0);
      final result =
          calculateNextReview.call(quality: 4, currentSchedule: schedule);
      expect(result.repetitionCount, 1);
      expect(result.intervalDays, 1);
    });

    test('second successful review sets interval to 6', () {
      final schedule = makeSchedule(repetitionCount: 1, intervalDays: 1);
      final result =
          calculateNextReview.call(quality: 4, currentSchedule: schedule);
      expect(result.repetitionCount, 2);
      expect(result.intervalDays, 6);
    });

    test('subsequent reviews multiply interval by ease factor', () {
      final schedule =
          makeSchedule(repetitionCount: 2, easeFactor: 2.5, intervalDays: 6);
      final result =
          calculateNextReview.call(quality: 4, currentSchedule: schedule);
      expect(result.repetitionCount, 3);
      expect(result.intervalDays, 15); // 6 * 2.5 = 15
    });

    test('ease factor never goes below 1.3', () {
      final schedule = makeSchedule(easeFactor: 1.3);
      final result =
          calculateNextReview.call(quality: 3, currentSchedule: schedule);
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('perfect quality (5) increases ease factor', () {
      final schedule = makeSchedule(easeFactor: 2.5);
      final result =
          calculateNextReview.call(quality: 5, currentSchedule: schedule);
      expect(result.easeFactor, greaterThan(2.5));
    });

    test('quality 3 decreases ease factor', () {
      final schedule = makeSchedule(easeFactor: 2.5);
      final result =
          calculateNextReview.call(quality: 3, currentSchedule: schedule);
      expect(result.easeFactor, lessThan(2.5));
    });

    test('nextReviewDate is set correctly', () {
      final schedule = makeSchedule(repetitionCount: 1, intervalDays: 1);
      final result =
          calculateNextReview.call(quality: 4, currentSchedule: schedule);

      final now = DateTime.now();
      final expected = DateTime(now.year, now.month, now.day + 6);
      expect(result.nextReviewDate.year, expected.year);
      expect(result.nextReviewDate.month, expected.month);
      expect(result.nextReviewDate.day, expected.day);
    });

    test('lastQuality is saved', () {
      final schedule = makeSchedule();
      final result =
          calculateNextReview.call(quality: 4, currentSchedule: schedule);
      expect(result.lastQuality, 4);
    });

    test('lastReviewDate is set to now', () {
      final schedule = makeSchedule();
      final before = DateTime.now();
      final result =
          calculateNextReview.call(quality: 3, currentSchedule: schedule);
      final after = DateTime.now();

      expect(result.lastReviewDate, isNotNull);
      expect(
        result.lastReviewDate!.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        result.lastReviewDate!.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });
  });
}
