import 'package:flutter/material.dart';
import '../../../../data/models/headword.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/rich_text_highlight.dart';

class ExampleBlock extends StatelessWidget {
  final Headword primarySense;

  const ExampleBlock({
    super.key,
    required this.primarySense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final example = primarySense.example1;
    if (example == null || example.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final source = primarySense.source1;
    final sutta = primarySense.sutta1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.exampleSection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (source != null && source.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      source,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            RichTextHighlight(
              text: example,
              baseStyle: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (sutta != null && sutta.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${l10n.suttaLabel}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    sutta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
