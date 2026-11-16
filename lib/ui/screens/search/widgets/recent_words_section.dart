import 'package:flutter/material.dart';
import '../../../../data/models/home_sections_data.dart';
import '../../../../l10n/app_localizations.dart';

class RecentWordsSection extends StatelessWidget {
  final List<RecentWordItem> recentWords;
  final ValueChanged<RecentWordItem> onSelect;

  const RecentWordsSection({
    super.key,
    required this.recentWords,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (recentWords.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.homeRecentTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < recentWords.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Icon(
                    Icons.history_outlined,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  title: Text(
                    recentWords[i].cleanLemma,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
                  onTap: () => onSelect(recentWords[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
