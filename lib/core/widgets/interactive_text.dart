import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/text_parser.dart';

typedef WordTapCallback = void Function(String word, Offset globalPosition);

/// Renders text with per-word tap targets.
/// Each word is tappable and fires [onWordTap] with the word and position.
class InteractiveText extends StatefulWidget {
  final String text;
  final WordTapCallback? onWordTap;
  final TextStyle? style;
  final TextStyle? wordStyle;
  final Set<String> highlightedWords;
  final Color highlightColor;
  final TextAlign textAlign;

  const InteractiveText({
    super.key,
    required this.text,
    this.onWordTap,
    this.style,
    this.wordStyle,
    this.highlightedWords = const {},
    this.highlightColor = const Color(0xFFFFE082),
    this.textAlign = TextAlign.start,
  });

  @override
  State<InteractiveText> createState() => _InteractiveTextState();
}

class _InteractiveTextState extends State<InteractiveText> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose old recognizers
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final tokens = TextParser.tokenize(widget.text);
    final defaultStyle = widget.style ??
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16, height: 1.6);

    final spans = <InlineSpan>[];

    for (final token in tokens) {
      if (token.isWord && widget.onWordTap != null) {
        final recognizer = TapGestureRecognizer()
          ..onTapUp = (details) {
            widget.onWordTap!(token.text, details.globalPosition);
          };
        _recognizers.add(recognizer);

        final isHighlighted = widget.highlightedWords
            .contains(token.text.toLowerCase());

        spans.add(TextSpan(
          text: token.text,
          style: (widget.wordStyle ?? defaultStyle).copyWith(
            backgroundColor: isHighlighted ? widget.highlightColor : null,
          ),
          recognizer: recognizer,
        ));
      } else {
        spans.add(TextSpan(
          text: token.text,
          style: defaultStyle,
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: widget.textAlign,
    );
  }
}
