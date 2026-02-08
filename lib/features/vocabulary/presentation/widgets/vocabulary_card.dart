import 'package:flutter/material.dart';

import '../../domain/entities/vocabulary_entry.dart';

/// A reusable card widget for displaying a vocabulary entry in lists.
/// Tapping the card toggles an expanded view with explanation, etymology,
/// example sentences, and synonyms.
class VocabularyCard extends StatefulWidget {
  final VocabularyEntry entry;
  final VoidCallback? onPlayAudio;

  const VocabularyCard({
    super.key,
    required this.entry,
    this.onPlayAudio,
  });

  @override
  State<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<VocabularyCard> {
  bool _isExpanded = false;

  bool get _hasExpandedContent {
    final e = widget.entry;
    return (e.explanation != null && e.explanation!.isNotEmpty) ||
        (e.etymology != null && e.etymology!.isNotEmpty) ||
        e.exampleSentences.isNotEmpty ||
        e.synonyms.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entry = widget.entry;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: _hasExpandedContent
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsed header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.word,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        if (entry.pronunciation != null &&
                            entry.pronunciation!.isNotEmpty)
                          Text(
                            entry.pronunciation!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (entry.translation != null &&
                            entry.translation!.isNotEmpty)
                          Text(
                            entry.translation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (entry.sourceType != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.1),
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
                  if (widget.onPlayAudio != null)
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: colorScheme.primary,
                      ),
                      onPressed: widget.onPlayAudio,
                    ),
                  // Expand/collapse chevron
                  if (_hasExpandedContent)
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              // Expanded details
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(theme, colorScheme),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, ColorScheme colorScheme) {
    final entry = widget.entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        // Explanation
        if (entry.explanation != null && entry.explanation!.isNotEmpty) ...[
          Text(
            '释义',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(entry.explanation!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        // Etymology
        if (entry.etymology != null && entry.etymology!.isNotEmpty) ...[
          Text(
            '词源',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.etymology!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Example sentences
        if (entry.exampleSentences.isNotEmpty) ...[
          Text(
            '例句',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...entry.exampleSentences.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $e',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Synonyms
        if (entry.synonyms.isNotEmpty) ...[
          Text(
            '近义词',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: entry.synonyms
                .map(
                  (s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  String _sourceLabel(String sourceType) {
    switch (sourceType) {
      case 'text':
      case 'text_study':
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
