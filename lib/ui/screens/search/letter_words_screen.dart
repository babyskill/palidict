import 'package:flutter/material.dart';
import '../../../data/models/home_sections_data.dart';
import '../../../data/repositories/dictionary_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Full screen used on mobile navigation when tapping a letter from Alphabet Index.
class LetterWordsScreen extends StatelessWidget {
  final String letter;
  final ValueChanged<LetterHeadwordRow> onSelectWord;

  const LetterWordsScreen({
    super.key,
    required this.letter,
    required this.onSelectWord,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.letterListTitle(letter)),
        elevation: 0,
      ),
      body: LetterWordsView(
        letter: letter,
        onSelectWord: onSelectWord,
        showHeader: false,
      ),
    );
  }
}

/// Lazy list view of headwords starting with [letter].
///
/// Used both in [LetterWordsScreen] on mobile and in the master left pane on desktop.
class LetterWordsView extends StatefulWidget {
  final String letter;
  final ValueChanged<LetterHeadwordRow> onSelectWord;
  final VoidCallback? onBack;
  final bool showHeader;

  const LetterWordsView({
    super.key,
    required this.letter,
    required this.onSelectWord,
    this.onBack,
    this.showHeader = false,
  });

  @override
  State<LetterWordsView> createState() => _LetterWordsViewState();
}

class _LetterWordsViewState extends State<LetterWordsView> {
  final DictionaryRepository _repository = DictionaryRepository();
  List<LetterHeadwordRow> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void didUpdateWidget(covariant LetterWordsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) {
      _loadWords();
    }
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    final words = await _repository.getHeadwordsByLetter(widget.letter);
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Column(
        children: [
          if (widget.showHeader) _buildHeader(l10n, theme),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (widget.showHeader) _buildHeader(l10n, theme),
        Expanded(
          child: _words.isEmpty
              ? Center(
                  child: Text(
                    l10n.searchNoResults,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final item = _words[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 2.0,
                      ),
                      leading: item.pos != null && item.pos!.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.pos!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : const SizedBox(width: 24),
                      title: Text(
                        item.lemma1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: Colors.grey,
                      ),
                      onTap: () => widget.onSelectWord(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.letterListTitle(widget.letter),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_words.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
