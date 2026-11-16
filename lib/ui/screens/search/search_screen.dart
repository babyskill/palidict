import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/normalization/pali_normalization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pack_manager.dart';
import '../../../data/models/home_sections_data.dart';
import '../../../data/models/search_result.dart';
import '../../../data/repositories/dictionary_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/recent_words_service.dart';
import '../../../services/settings_controller.dart';
import '../inflected/inflected_results_screen.dart';
import '../settings/settings_screen.dart';
import '../word_card/word_card_screen.dart';
import 'letter_words_screen.dart';
import 'widgets/alphabet_index_section.dart';
import 'widgets/frequent_discourses_section.dart';
import 'widgets/recent_words_section.dart';
import 'widgets/word_of_day_card.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPacks;
  final FocusNode? focusNode;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.onNavigateToPacks,
    this.focusNode,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final DictionaryRepository _repository = DictionaryRepository();
  FocusNode? _internalFocusNode;
  Timer? _debounceTimer;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  List<SearchResult> _suggestions = [];
  bool _isLoading = false;
  String _currentQuery = '';
  SearchResult? _selectedResult;

  // Home v2 state
  HeadwordGroup? _wordOfDay;
  List<HeadwordGroup> _frequentWords = [];
  List<LetterCount> _alphabetIndex = [];
  List<RecentWordItem> _recentWords = [];
  bool _isLoadingHome = true;
  String? _selectedLetter;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _selectedResult = SearchResult(
        title: widget.initialQuery!,
        type: SearchResultType.headword,
        lemmaClean: widget.initialQuery!,
      );
    }
    _controller.addListener(_onSearchChanged);
    _loadHomeSections();
    RecentWordsService.instance.addListener(_onRecentWordsChanged);
    PackManager.instance.addListener(_onPackChanged);
    SettingsController.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _loadHomeSections(SettingsController.instance.locale.languageCode);
    if (_currentQuery.trim().isNotEmpty) {
      _currentQuery = ''; // Reset current query so _onSearchChanged triggers search
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _internalFocusNode?.dispose();
    RecentWordsService.instance.removeListener(_onRecentWordsChanged);
    PackManager.instance.removeListener(_onPackChanged);
    SettingsController.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadHomeSections([String? locale]) async {
    setState(() {
      _isLoadingHome = true;
    });

    try {
      final effectiveLocale = locale ?? SettingsController.instance.locale.languageCode;
      final wordOfDay = await _repository.getWordOfTheDay(locale: effectiveLocale);
      final frequent = await _repository.getFrequentInDiscourses(locale: effectiveLocale);
      final alphabet = await _repository.getAlphabetIndex();
      final recent = await RecentWordsService.instance.getRecentWords();

      if (mounted) {
        setState(() {
          _wordOfDay = wordOfDay;
          _frequentWords = frequent;
          _alphabetIndex = alphabet;
          _recentWords = recent;
          _isLoadingHome = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHome = false;
        });
      }
    }
  }

  void _onRecentWordsChanged() {
    _loadRecentWords();
  }

  Future<void> _loadRecentWords() async {
    final recent = await RecentWordsService.instance.getRecentWords();
    if (mounted) {
      setState(() {
        _recentWords = recent;
      });
    }
  }

  void _onPackChanged() {
    _selectedLetter = null;
    _loadHomeSections();
  }

  void _onSearchChanged() {
    final query = _controller.text.trim();
    if (query == _currentQuery) return;

    _currentQuery = query;
    _debounceTimer?.cancel();

    if (query.isNotEmpty) {
      _selectedLetter = null;
    }

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      setState(() {
        _isLoading = true;
      });

      final locale = SettingsController.instance.locale.languageCode;
      final results = await _repository.searchSuggestions(query, locale: locale);

      if (mounted && _currentQuery == query) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleSubmit(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final isDesktop = MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;

    if (isDesktop) {
      // 1. If we already have suggestions, open top suggestion in right pane
      if (_suggestions.isNotEmpty) {
        _openSuggestion(_suggestions.first, isDesktop: true);
        return;
      }

      // 2. If suggestions list is currently empty, fetch suggestions
      setState(() {
        _isLoading = true;
      });
      final locale = SettingsController.instance.locale.languageCode;
      final results = await _repository.searchSuggestions(trimmed, locale: locale);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });

        if (results.isNotEmpty) {
          _openSuggestion(results.first, isDesktop: true);
          return;
        }

        // 3. If no suggestions returned, check if direct inflected or headword match
        final lookupEntry = await _repository.getLookupEntry(trimmed);
        if (lookupEntry != null && mounted) {
          _openSuggestion(
            SearchResult(
              title: lookupEntry.lookupKey,
              type: SearchResultType.inflected,
              lookupKey: lookupEntry.lookupKey,
              grammar: lookupEntry.grammarSummary,
            ),
            isDesktop: true,
          );
          return;
        }

        final wordData = await _repository.getWordCardDataByLemma(trimmed);
        if (wordData != null && mounted) {
          _openSuggestion(
            SearchResult(
              title: wordData.lemmaClean,
              type: SearchResultType.headword,
              lemmaClean: wordData.lemmaClean,
              headwordId: wordData.primarySense?.id,
            ),
            isDesktop: true,
          );
          return;
        }
      }
      return;
    }

    // Mobile flow:
    // Check if query exactly matches an inflected lookup key
    final lookupEntry = await _repository.getLookupEntry(trimmed);
    if (lookupEntry != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InflectedResultsScreen(
            lookupKey: lookupEntry.lookupKey,
            onNavigateToPacks: widget.onNavigateToPacks,
          ),
        ),
      );
      return;
    }

    // Check if query matches a headword
    final wordData = await _repository.getWordCardDataByLemma(trimmed);
    if (wordData != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordCardScreen(
            lemmaClean: wordData.lemmaClean,
            onNavigateToPacks: widget.onNavigateToPacks,
          ),
        ),
      );
      return;
    }

    // Otherwise if we have suggestions, open the first suggestion
    if (_suggestions.isNotEmpty && mounted) {
      _openSuggestion(_suggestions.first, isDesktop: false);
    }
  }

  void _openSuggestion(SearchResult item, {required bool isDesktop}) {
    if (isDesktop) {
      setState(() {
        _selectedResult = item;
      });
      return;
    }

    if (item.type == SearchResultType.headword) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordCardScreen(
            lemmaClean: item.lemmaClean ?? item.title,
            headwordId: item.headwordId,
            onNavigateToPacks: widget.onNavigateToPacks,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InflectedResultsScreen(
            lookupKey: item.lookupKey ?? item.title,
            onNavigateToPacks: widget.onNavigateToPacks,
          ),
        ),
      );
    }
  }

  void _openHeadwordEntry({
    required int? id,
    required String lemmaClean,
    String? lemma1,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      setState(() {
        _selectedResult = SearchResult(
          type: SearchResultType.headword,
          title: lemmaClean,
          lemmaClean: lemmaClean,
          headwordId: id,
        );
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordCardScreen(
            lemmaClean: lemmaClean,
            headwordId: id,
            onNavigateToPacks: widget.onNavigateToPacks,
          ),
        ),
      );
    }
  }

  Future<void> _handleRecentSelected(RecentWordItem item, {required bool isDesktop}) async {
    final wordData = await _repository.resolveRecentWord(item);
    if (!mounted) return;

    if (wordData != null) {
      _openHeadwordEntry(
        id: wordData.primarySense?.id ?? item.id,
        lemmaClean: wordData.lemmaClean,
        lemma1: item.lemma1,
        isDesktop: isDesktop,
      );
    } else {
      _loadRecentWords();
    }
  }

  void _handleLetterSelected(String letter, {required bool isDesktop}) {
    if (isDesktop) {
      setState(() {
        _selectedLetter = letter;
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LetterWordsScreen(
            letter: letter,
            onSelectWord: (row) {
              _openHeadwordEntry(
                id: row.id,
                lemmaClean: PaliNormalization.cleanLemma(row.lemma1),
                lemma1: row.lemma1,
                isDesktop: false,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;

    final searchInputBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _controller,
        focusNode: _effectiveFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: _handleSubmit,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: l10n.clearSearch,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _selectedLetter = null;
                    _effectiveFocusNode.requestFocus();
                  },
                )
              : null,
        ),
      ),
    );

    final progressBar = _isLoading
        ? const LinearProgressIndicator(minHeight: 2)
        : const SizedBox(height: 2);

    final resultsList = _buildResultsArea(context, l10n, theme, isDesktop: isDesktop);

    if (isDesktop) {
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _controller.clear();
            _selectedLetter = null;
            _effectiveFocusNode.requestFocus();
          },
        },
        child: Row(
          children: [
            // Left pane (~380 px)
            SizedBox(
              width: 380,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(l10n.appTitle),
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: l10n.settings,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    searchInputBar,
                    progressBar,
                    Expanded(child: resultsList),
                  ],
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Right pane: detail view or empty state hint
            Expanded(
              child: _buildRightPane(context, l10n, theme),
            ),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _controller.clear();
          _selectedLetter = null;
          _effectiveFocusNode.requestFocus();
        },
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settings,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            searchInputBar,
            progressBar,
            Expanded(child: resultsList),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPane(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    if (_selectedResult == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: const SizedBox.shrink(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.desktopDetailEmptyPrompt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _selectedResult!;
    if (item.type == SearchResultType.headword) {
      return WordCardScreen(
        key: ValueKey('desktop_word_${item.headwordId}_${item.lemmaClean ?? item.title}'),
        lemmaClean: item.lemmaClean ?? item.title,
        headwordId: item.headwordId,
        onNavigateToPacks: widget.onNavigateToPacks,
        automaticallyImplyLeading: false,
        onSelectInflection: (inflectedForm) {
          setState(() {
            _selectedResult = SearchResult(
              title: inflectedForm,
              type: SearchResultType.inflected,
              lookupKey: inflectedForm,
            );
          });
        },
      );
    } else {
      return InflectedResultsScreen(
        key: ValueKey('desktop_inflected_${item.lookupKey ?? item.title}'),
        lookupKey: item.lookupKey ?? item.title,
        onNavigateToPacks: widget.onNavigateToPacks,
        automaticallyImplyLeading: false,
        onSelectHeadword: (headwordId, lemmaClean) {
          setState(() {
            _selectedResult = SearchResult(
              title: lemmaClean,
              type: SearchResultType.headword,
              lemmaClean: lemmaClean,
              headwordId: headwordId,
            );
          });
        },
      );
    }
  }

  Widget _buildResultsArea(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required bool isDesktop,
  }) {
    // 1. Home v2: Empty search query renders the 4 tappable sections
    if (_currentQuery.isEmpty) {
      // Desktop letter view inside master left pane
      if (isDesktop && _selectedLetter != null) {
        return LetterWordsView(
          letter: _selectedLetter!,
          showHeader: true,
          onBack: () {
            setState(() {
              _selectedLetter = null;
            });
          },
          onSelectWord: (row) {
            _openHeadwordEntry(
              id: row.id,
              lemmaClean: PaliNormalization.cleanLemma(row.lemma1),
              lemma1: row.lemma1,
              isDesktop: true,
            );
          },
        );
      }

      if (_isLoadingHome && _wordOfDay == null && _frequentWords.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        key: const ValueKey('home_sections_list'),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // 1. Word of the Day
          if (_wordOfDay != null) ...[
            WordOfDayCard(
              word: _wordOfDay!,
              onTap: () => _openHeadwordEntry(
                id: _wordOfDay!.representativeId,
                lemmaClean: _wordOfDay!.cleanLemma,
                lemma1: _wordOfDay!.representativeLemma1,
                isDesktop: isDesktop,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. Frequent in the Discourses
          if (_frequentWords.isNotEmpty) ...[
            FrequentDiscoursesSection(
              groups: _frequentWords,
              onSelect: (group) => _openHeadwordEntry(
                id: group.representativeId,
                lemmaClean: group.cleanLemma,
                lemma1: group.representativeLemma1,
                isDesktop: isDesktop,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Alphabet Index
          if (_alphabetIndex.isNotEmpty) ...[
            AlphabetIndexSection(
              letters: _alphabetIndex,
              onSelectLetter: (letter) => _handleLetterSelected(letter, isDesktop: isDesktop),
            ),
          ],

          // 4. Recent (only when non-empty)
          if (_recentWords.isNotEmpty) ...[
            const SizedBox(height: 20),
            RecentWordsSection(
              recentWords: _recentWords,
              onSelect: (item) => _handleRecentSelected(item, isDesktop: isDesktop),
            ),
          ],
          const SizedBox(height: 24),
        ],
      );
    }

    // 2. Typing query: Suggestions list or no results
    if (_suggestions.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.searchNoResults,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final item = _suggestions[index];
        final isHeadword = item.type == SearchResultType.headword;
        final isSelected = isDesktop &&
            _selectedResult != null &&
            _selectedResult!.title == item.title &&
            _selectedResult!.type == item.type;

        return ListTile(
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHeadword
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : (theme.brightness == Brightness.dark
                      ? AppTheme.inflectedBadgeDarkBg
                      : AppTheme.inflectedBadgeBg),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isHeadword ? l10n.typeHeadword : l10n.typeInflected,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isHeadword
                    ? theme.colorScheme.primary
                    : (theme.brightness == Brightness.dark
                        ? AppTheme.inflectedBadgeDarkText
                        : AppTheme.inflectedBadgeText),
              ),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isHeadword ? theme.colorScheme.primary : null,
            ),
          ),
          subtitle: item.subtitle != null || item.grammar != null
              ? Text(
                  item.subtitle ?? item.grammar ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () => _openSuggestion(item, isDesktop: isDesktop),
        );
      },
    );
  }
}
