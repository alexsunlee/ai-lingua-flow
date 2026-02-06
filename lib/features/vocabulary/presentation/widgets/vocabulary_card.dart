import 'package:flutter/material.dart';

import '../../domain/entities/vocabulary_entry.dart';

/// A reusable card widget for displaying a vocabulary entry in lists.
class VocabularyCard extends StatelessWidget {
  final VocabularyEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onPlayAudio;

  const VocabularyCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Word info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word
                    Text(
                      entry.word,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    // Pronunciation
                    if (entry.pronunciation != null &&
                        entry.pronunciation!.isNotEmpty)
                      Text(
                        entry.pronunciation!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Translation
                    if (entry.translation != null &&
                        entry.translation!.isNotEmpty)
                      Text(
                        entry.translation!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Source badge
                    if (entry.sourceType != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _sourceLabel(entry.sourceType!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Play audio button
              if (onPlayAudio != null)
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: colorScheme.primary,
                  ),
                  onPressed: onPlayAudio,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _sourceLabel(String sourceType) {
    switch (sourceType) {
      case 'text':
        return '文本';
      case 'video':
        return '视频';
      case 'manual':
        return '手动添加';
      default:
        return sourceType;
    }
  }
}
