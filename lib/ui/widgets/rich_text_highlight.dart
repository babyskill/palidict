import 'package:flutter/material.dart';

/// Parses text containing `<b>...</b>` tags and displays it with highlighted bold styling.
class RichTextHighlight extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;

  const RichTextHighlight({
    super.key,
    required this.text,
    this.baseStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBase = baseStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
        ) ??
        const TextStyle(fontSize: 14, height: 1.5);

    final defaultHighlight = highlightStyle ??
        defaultBase.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        );

    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>', dotAll: true);
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultBase,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: defaultHighlight,
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultBase,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}
