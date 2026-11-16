import 'package:flutter/material.dart';
import '../../../../data/models/headword.dart';
import '../../../../data/models/root_entry.dart';
import '../../../../l10n/app_localizations.dart';

class ConstructionBlock extends StatelessWidget {
  final Headword primarySense;
  final RootEntry? root;

  const ConstructionBlock({
    super.key,
    required this.primarySense,
    this.root,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasRoot = primarySense.rootKey != null && primarySense.rootKey!.isNotEmpty;
    final hasConstruction = primarySense.construction != null && primarySense.construction!.isNotEmpty;
    final hasPhonetic = primarySense.phonetic != null && primarySense.phonetic!.isNotEmpty;
    final hasSanskrit = primarySense.sanskrit != null && primarySense.sanskrit!.isNotEmpty;

    if (!hasRoot && !hasConstruction && !hasPhonetic && !hasSanskrit) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.grammarConstructionSection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (hasRoot) ...[
              _buildRow(
                label: l10n.rootLabel,
                content: primarySense.rootKey!,
                extra: root?.rootMeaning != null ? '(${root!.rootMeaning})' : null,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            if (hasConstruction) ...[
              _buildRow(
                label: l10n.constructionLabel,
                content: primarySense.construction!,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            if (hasPhonetic) ...[
              _buildRow(
                label: l10n.phoneticLabel,
                content: primarySense.phonetic!,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            if (hasSanskrit) ...[
              _buildRow(
                label: l10n.sanskritLabel,
                content: primarySense.sanskrit!,
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String content,
    String? extra,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: content,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (extra != null) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: extra,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
