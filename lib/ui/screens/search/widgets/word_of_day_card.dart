import 'package:flutter/material.dart';
import '../../../../data/models/home_sections_data.dart';
import '../../../../l10n/app_localizations.dart';

class WordOfDayCard extends StatelessWidget {
  final HeadwordGroup word;
  final VoidCallback onTap;

  const WordOfDayCard({
    super.key,
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.homeWordOfDay,
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
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          word.cleanLemma,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (word.representativePos != null &&
                          word.representativePos!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            word.representativePos!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (word.resolvedGloss != null && word.resolvedGloss!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      word.resolvedGloss!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                  if (word.ebtCountClean != null && word.ebtCountClean!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.ebtCountTimes(word.ebtCountClean!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
