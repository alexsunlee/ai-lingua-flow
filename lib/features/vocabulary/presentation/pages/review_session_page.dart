import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection.dart';
import '../../../../services/tts_service.dart';
import '../providers/vocabulary_providers.dart';

/// Quality rating labels in Chinese, mapped to SM-2 quality values 0-5.
const _qualityLabels = <int, String>{
  0: '完全忘记',
  1: '严重错误',
  2: '有错误',
  3: '困难',
  4: '犹豫',
  5: '完美',
};

/// Flashcard review session page.
class ReviewSessionPage extends ConsumerWidget {
  const ReviewSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(reviewSessionProvider);

    // If session is complete, show summary
    if (sessionState.isComplete) {
      return _CompletionSummary(sessionState: sessionState);
    }

    // If no entries, show empty state
    if (sessionState.entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('复习')),
        body: const Center(child: Text('没有待复习的单词')),
      );
    }

    final currentEntry = sessionState.currentEntry;
    if (currentEntry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('复习')),
        body: const Center(child: Text('复习已完成')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('复习'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(reviewSessionProvider.notifier).reset();
            context.go('/vocabulary');
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${sessionState.currentIndex + 1} / ${sessionState.totalCount}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (sessionState.currentIndex + 1) /
                          sessionState.totalCount,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Flashcard
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!sessionState.isRevealed) {
                    ref.read(reviewSessionProvider.notifier).reveal();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TTS play button
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            final tts = getIt<TtsService>();
                            tts.speak(currentEntry.word);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Word
                        Text(
                          currentEntry.word,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Pronunciation
                        if (currentEntry.pronunciation != null &&
                            currentEntry.pronunciation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentEntry.pronunciation!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],

                        // Revealed section
                        if (sessionState.isRevealed) ...[
                          const SizedBox(height: 24),
                          Divider(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.1)),
                          const SizedBox(height: 16),

                          // Translation
                          if (currentEntry.translation != null &&
                              currentEntry.translation!.isNotEmpty)
                            Text(
                              currentEntry.translation!,
                              style: theme.textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),

                          // Explanation
                          if (currentEntry.explanation != null &&
                              currentEntry.explanation!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              currentEntry.explanation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          // Example sentence
                          if (currentEntry.exampleSentences.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              currentEntry.exampleSentences.first,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 32),
                          Text(
                            '点击卡片查看释义',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quality rating buttons (only shown when revealed)
            if (sessionState.isRevealed)
              _QualityRatingBar(
                onRate: (quality) {
                  ref
                      .read(reviewSessionProvider.notifier)
                      .rateAndAdvance(quality);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bar of quality rating buttons (0-5).
class _QualityRatingBar extends StatelessWidget {
  final void Function(int quality) onRate;

  const _QualityRatingBar({required this.onRate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '回忆质量评分',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(6, (index) {
              final color = Color.lerp(
                colorScheme.error,
                colorScheme.secondary,
                index / 5,
              )!;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _RatingButton(
                    quality: index,
                    label: _qualityLabels[index]!,
                    color: color,
                    onTap: () => onRate(index),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final int quality;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.quality,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$quality',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Completion summary screen shown when all cards have been reviewed.
class _CompletionSummary extends ConsumerWidget {
  final ReviewSessionState sessionState;

  const _CompletionSummary({required this.sessionState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate statistics
    final totalCount = sessionState.totalCount;
    final ratings = sessionState.ratings.values.toList();
    final avgQuality =
        ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
    final perfectCount = ratings.where((q) => q >= 4).length;
    final failedCount = ratings.where((q) => q < 3).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('复习完成'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(reviewSessionProvider.notifier).reset();
            ref.read(dueReviewsProvider.notifier).refresh();
            ref.read(vocabularyListProvider.notifier).refresh();
            context.go('/vocabulary');
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                '复习完成!',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),

              // Statistics
              _StatRow(
                label: '总复习单词',
                value: '$totalCount',
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: '平均评分',
                value: avgQuality.toStringAsFixed(1),
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: '掌握良好 (4-5)',
                value: '$perfectCount',
                valueColor: colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: '需要加强 (0-2)',
                value: '$failedCount',
                valueColor:
                    failedCount > 0 ? colorScheme.error : colorScheme.secondary,
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  ref.read(reviewSessionProvider.notifier).reset();
                  ref.read(dueReviewsProvider.notifier).refresh();
                  ref.read(vocabularyListProvider.notifier).refresh();
                  context.go('/vocabulary');
                },
                child: const Text('返回生词本'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
