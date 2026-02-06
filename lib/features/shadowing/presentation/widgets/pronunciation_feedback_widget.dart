import 'package:flutter/material.dart';

/// Displays word-by-word color-coded pronunciation comparison.
/// Green = correct, Red = wrong, Yellow = close match.
class PronunciationFeedbackWidget extends StatelessWidget {
  final String referenceText;
  final String recognizedText;

  const PronunciationFeedbackWidget({
    super.key,
    required this.referenceText,
    required this.recognizedText,
  });

  @override
  Widget build(BuildContext context) {
    final refWords = referenceText.toLowerCase().split(RegExp(r'\s+'));
    final recWords = recognizedText.toLowerCase().split(RegExp(r'\s+'));
    final displayWords = referenceText.split(RegExp(r'\s+'));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(displayWords.length, (i) {
        final refWord =
            i < refWords.length ? _cleanWord(refWords[i]) : '';
        final recWord =
            i < recWords.length ? _cleanWord(recWords[i]) : '';

        Color color;
        if (refWord == recWord) {
          color = Colors.green;
        } else if (_isSimilar(refWord, recWord)) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            displayWords[i],
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }),
    );
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Simple similarity check: >60% character overlap.
  bool _isSimilar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    final longer = a.length >= b.length ? a : b;
    final shorter = a.length < b.length ? a : b;
    int matches = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }
    return matches / longer.length > 0.6;
  }
}

extension _ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
