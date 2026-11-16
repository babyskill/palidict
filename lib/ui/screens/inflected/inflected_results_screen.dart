import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/headword.dart';
import '../../../data/models/lookup_entry.dart';
import '../../../data/repositories/dictionary_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../word_card/word_card_screen.dart';

/// Screen displaying the results of an inflected-form lookup.
///
/// Lists the corresponding headwords pointed to by `lookup.lookup_key`,
/// along with the grammar notes from `lookup.grammar`.
class InflectedResultsScreen extends StatefulWidget {
  final String lookupKey;
  final VoidCallback? onNavigateToPacks;
  final bool automaticallyImplyLeading;
  final void Function(int headwordId, String lemmaClean)? onSelectHeadword;

  const InflectedResultsScreen({
    super.key,
    required this.lookupKey,
    this.onNavigateToPacks,
    this.automaticallyImplyLeading = true,
    this.onSelectHeadword,
  });

  @override
  State<InflectedResultsScreen> createState() => _InflectedResultsScreenState();
}

class _InflectedResultsScreenState extends State<InflectedResultsScreen> {
  final DictionaryRepository _repository = DictionaryRepository();

  LookupEntry? _entry;
  List<Headword> _headwords = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant InflectedResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lookupKey != widget.lookupKey) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entry = await _repository.getLookupEntry(widget.lookupKey);
      List<Headword> headwords = [];
      if (entry != null && entry.headwordIds.isNotEmpty) {
        headwords = await _repository.getHeadwordsByIds(entry.headwordIds);
      }

      if (mounted) {
        setState(() {
          _entry = entry;
          _headwords = headwords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        title: Text(widget.lookupKey),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.desktopMaxContentWidth),
          child: _buildBody(context, l10n, theme),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.errorOccurred(_error!),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (_entry == null || _headwords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.searchNoResults,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final entry = _entry!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // Overview Card
        Card(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final isDark = theme.brightness == Brightness.dark;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.inflectedBadgeDarkBg
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.typeInflected,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.inflectedBadgeDarkText
                                  : Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.lookupKey,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (entry.grammarSummary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.grammarLabel}: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.grammarSummary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Headwords Prompt
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Text(
            l10n.inflectedHeadwordsPrompt(_headwords.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // List of Headword Cards
        ..._headwords.map((headword) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.onSelectHeadword != null) {
                  widget.onSelectHeadword!(headword.id, headword.lemmaClean);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WordCardScreen(
                        lemmaClean: headword.lemmaClean,
                        headwordId: headword.id,
                        onNavigateToPacks: widget.onNavigateToPacks,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                headword.lemmaClean,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (headword.pos != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    headword.pos!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (headword.meaning1 != null && headword.meaning1!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              headword.meaning1!,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
