import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class InflectionsChipList extends StatefulWidget {
  final List<String> inflections;
  final bool isCorePack;
  final VoidCallback? onGoToPacks;
  final ValueChanged<String>? onSelectInflection;

  const InflectionsChipList({
    super.key,
    required this.inflections,
    required this.isCorePack,
    this.onGoToPacks,
    this.onSelectInflection,
  });

  @override
  State<InflectionsChipList> createState() => _InflectionsChipListState();
}

class _InflectionsChipListState extends State<InflectionsChipList> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (!widget.isCorePack) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_chart_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.inflectionsSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inflectionsLiteNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: widget.onGoToPacks,
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: Text(l10n.goToPacks),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.inflections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.inflectionsSection} (${widget.inflections.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.inflections.map((inflection) {
                  return ActionChip(
                    label: Text(inflection),
                    onPressed: () {
                      widget.onSelectInflection?.call(inflection);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
