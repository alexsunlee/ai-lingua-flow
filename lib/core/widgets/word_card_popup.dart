import 'package:flutter/material.dart';

/// Data model for word card display.
class WordCardData {
  final String word;
  final String? pronunciation;
  final String? translation;
  final String? explanation;
  final String? etymology;
  final List<String> examples;
  final List<String> synonyms;
  final bool isInVocabulary;

  const WordCardData({
    required this.word,
    this.pronunciation,
    this.translation,
    this.explanation,
    this.etymology,
    this.examples = const [],
    this.synonyms = const [],
    this.isInVocabulary = false,
  });
}

/// Shows a word card overlay with translation, pronunciation, etc.
class WordCardPopup extends StatelessWidget {
  final WordCardData data;
  final VoidCallback? onPlayTts;
  final VoidCallback? onAddToVocabulary;
  final VoidCallback? onClose;
  final bool isLoading;

  const WordCardPopup({
    super.key,
    required this.data,
    this.onPlayTts,
    this.onAddToVocabulary,
    this.onClose,
    this.isLoading = false,
  });

  /// Show as an overlay positioned near the tapped word.
  static void show(
    BuildContext context, {
    required Offset position,
    required WordCardData data,
    VoidCallback? onPlayTts,
    VoidCallback? onAddToVocabulary,
    bool isLoading = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _WordCardOverlay(
          position: position,
          data: data,
          isLoading: isLoading,
          onPlayTts: onPlayTts,
          onAddToVocabulary: onAddToVocabulary,
          onClose: () => entry.remove(),
        );
      },
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return _WordCardContent(
      data: data,
      isLoading: isLoading,
      onPlayTts: onPlayTts,
      onAddToVocabulary: onAddToVocabulary,
      onClose: onClose,
    );
  }
}

class _WordCardOverlay extends StatelessWidget {
  final Offset position;
  final WordCardData data;
  final bool isLoading;
  final VoidCallback? onPlayTts;
  final VoidCallback? onAddToVocabulary;
  final VoidCallback? onClose;

  const _WordCardOverlay({
    required this.position,
    required this.data,
    this.isLoading = false,
    this.onPlayTts,
    this.onAddToVocabulary,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss on tap outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.black12),
          ),
        ),
        Positioned(
          left: _clampX(context, position.dx),
          top: _clampY(context, position.dy),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: _WordCardContent(
                data: data,
                isLoading: isLoading,
                onPlayTts: onPlayTts,
                onAddToVocabulary: onAddToVocabulary,
                onClose: onClose,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _clampX(BuildContext context, double x) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (x - 160).clamp(8.0, screenWidth - 328);
  }

  double _clampY(BuildContext context, double y) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Show below tap point, or above if near bottom
    if (y + 300 > screenHeight) {
      return y - 280;
    }
    return y + 16;
  }
}

class _WordCardContent extends StatelessWidget {
  final WordCardData data;
  final bool isLoading;
  final VoidCallback? onPlayTts;
  final VoidCallback? onAddToVocabulary;
  final VoidCallback? onClose;

  const _WordCardContent({
    required this.data,
    this.isLoading = false,
    this.onPlayTts,
    this.onAddToVocabulary,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: word + TTS + close
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.word,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (onPlayTts != null)
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 20),
                        onPressed: onPlayTts,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                // Pronunciation
                if (data.pronunciation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.pronunciation!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                // Translation
                if (data.translation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.translation!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                // Explanation
                if (data.explanation != null) ...[
                  const SizedBox(height: 8),
                  Text(data.explanation!, style: theme.textTheme.bodyMedium),
                ],
                // Etymology
                if (data.etymology != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '词源: ${data.etymology!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                // Examples
                if (data.examples.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...data.examples.take(2).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $e',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                ],
                // Synonyms
                if (data.synonyms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: data.synonyms
                        .take(5)
                        .map(
                          (s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
                // Add to Vocabulary button
                if (onAddToVocabulary != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: data.isInVocabulary
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('已添加到生词本'),
                          )
                        : ElevatedButton.icon(
                            onPressed: onAddToVocabulary,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('添加到生词本'),
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}
