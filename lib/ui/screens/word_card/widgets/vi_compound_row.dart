import 'package:flutter/material.dart';
import '../../../../data/models/vi_gloss_parser.dart';

/// Renders a single Vietnamese compound sub-entry.
///
/// Features:
/// - Bold `–{lemma}` with dictionary-style leading single dash.
/// - Optional `[pos]` displayed as a small muted tag.
/// - Gloss text with commas normalized to have spacing.
/// - Gracefully renders unstructured segments as plain-text rows.
class ViCompoundRow extends StatelessWidget {
  final ViCompoundEntry compound;

  const ViCompoundRow({
    super.key,
    required this.compound,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!compound.isStructured) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SelectableText(
          compound.rawText,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
          ),
        ),
      );
    }

    final hasPos = compound.pos != null && compound.pos!.isNotEmpty;
    final hasGloss = compound.gloss != null && compound.gloss!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '–${compound.lemma}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (hasPos) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      compound.pos!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (hasGloss)
              TextSpan(
                text: (!hasPos ? ' — ' : '') + (compound.normalizedGloss ?? ''),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
