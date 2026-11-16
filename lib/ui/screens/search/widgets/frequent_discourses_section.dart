import 'package:flutter/material.dart';
import '../../../../data/models/home_sections_data.dart';
import '../../../../l10n/app_localizations.dart';

class FrequentDiscoursesSection extends StatelessWidget {
  final List<HeadwordGroup> groups;
  final ValueChanged<HeadwordGroup> onSelect;

  const FrequentDiscoursesSection({
    super.key,
    required this.groups,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_stories_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.homeFrequentTitle,
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
              for (int i = 0; i < groups.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                _buildRow(context, groups[i], theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, HeadwordGroup item, ThemeData theme) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Row(
        children: [
          Text(
            item.cleanLemma,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          if (item.representativePos != null &&
              item.representativePos!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.representativePos!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: item.resolvedGloss != null && item.resolvedGloss!.isNotEmpty
          ? Text(
              item.resolvedGloss!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
      onTap: () => onSelect(item),
    );
  }
}
