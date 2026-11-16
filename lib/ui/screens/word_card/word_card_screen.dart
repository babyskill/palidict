import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/headword.dart';
import '../../../../data/models/meaning_vi.dart';
import '../../../../data/models/pronunciation.dart';
import '../../../../data/models/vi_gloss_provenance.dart';
import '../../../../data/models/word_card_data.dart';
import '../../../../data/repositories/dictionary_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/audio_player_service.dart';
import '../../../../services/recent_words_service.dart';
import '../inflected/inflected_results_screen.dart';
import 'widgets/construction_block.dart';
import 'widgets/example_block.dart';
import 'widgets/inflections_chip_list.dart';
import 'widgets/vi_compound_row.dart';

class WordCardScreen extends StatefulWidget {
  final String? lemmaClean;
  final int? headwordId;
  final VoidCallback? onNavigateToPacks;
  final bool automaticallyImplyLeading;
  final ValueChanged<String>? onSelectInflection;
  final AudioPlayerService? audioService;

  const WordCardScreen({
    super.key,
    this.lemmaClean,
    this.headwordId,
    this.onNavigateToPacks,
    this.automaticallyImplyLeading = true,
    this.onSelectInflection,
    this.audioService,
  });

  @override
  State<WordCardScreen> createState() => _WordCardScreenState();
}

class _WordCardScreenState extends State<WordCardScreen> {
  final DictionaryRepository _repository = DictionaryRepository();
  late final AudioPlayerService _audioService =
      widget.audioService ?? AudioPlayerService.instance;
  StreamSubscription<AudioEvent>? _audioSubscription;

  WordCardData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _audioService.addListener(_onAudioStateChange);
    _audioSubscription = _audioService.eventStream.listen(_onAudioEvent);
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioService.removeListener(_onAudioStateChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WordCardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headwordId != widget.headwordId ||
        oldWidget.lemmaClean != widget.lemmaClean) {
      _loadData();
    }
  }

  void _onAudioStateChange() {
    if (mounted) setState(() {});
  }

  void _onAudioEvent(AudioEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (event == AudioEvent.slowNetwork) {
      _showSnackBar(l10n.audioSlowNetwork);
    } else if (event == AudioEvent.error) {
      _showSnackBar(l10n.audioPlayError);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      WordCardData? data;
      if (widget.headwordId != null) {
        data = await _repository.getWordCardDataById(widget.headwordId!);
      } else if (widget.lemmaClean != null) {
        data = await _repository.getWordCardDataByLemma(widget.lemmaClean!);
      }

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });

        if (data != null && data.primarySense != null) {
          unawaited(RecentWordsService.instance.recordWord(
            id: data.primarySense!.id,
            lemma1: data.primarySense!.lemma1,
          ));
        }
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _data == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.desktopMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _error != null
                    ? l10n.errorOccurred(_error!)
                    : l10n.searchNoResults,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final data = _data!;
    final primary = data.primarySense;
    final lemma = data.lemmaClean;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final bool isLoadingAudio = _audioService.state == AudioState.loading &&
        _audioService.currentLemma == lemma;
    final bool isPlayingAudio = _audioService.state == AudioState.playing &&
        _audioService.currentLemma == lemma;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        title: Text(lemma),
        actions: [
          IconButton(
            tooltip: isLoadingAudio
                ? l10n.audioLoading
                : (isPlayingAudio ? l10n.audioPlaying : l10n.listenAudio),
            onPressed: isLoadingAudio
                ? null
                : () {
                    _audioService.playAudio(lemma);
                  },
            icon: _buildAudioIcon(theme),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.desktopMaxContentWidth),
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // 1. Header Card (Lemma, POS, Grammar, Audio, EBT)
                _buildHeaderCard(context, data, primary),
                const SizedBox(height: 12),

                // Pronunciation Block (under header, above meanings)
                if (data.pronunciation != null) ...[
                  _buildPronunciationCard(context, data.pronunciation!),
                  const SizedBox(height: 12),
                ],

                // 2. Vietnamese Meaning FIRST (HT Buu Chon 1976 / Inherited)
                // Hidden entirely in English UI
                if (!isEn && data.meaningVi != null) ...[
                  _buildVietnameseGlossCard(
                    context,
                    data.meaningVi!,
                    provenance: data.viGlossProvenance,
                  ),
                  const SizedBox(height: 12),
                ],

                // 3. Senses List (English meaning + draft Vietnamese senses)
                _buildSensesCard(context, data),
                const SizedBox(height: 12),

                // 4. Construction Breakdown (presentation A)
                if (isEn
                    ? data.constructionParts.any((p) => p.enGloss != null && p.enGloss!.isNotEmpty)
                    : data.constructionParts.any((p) => p.viGloss.isNotEmpty)) ...[
                  _buildConstructionBreakdownCard(context, data),
                  const SizedBox(height: 12),
                ],

                // 5. Grammar & Construction Block
                if (primary != null) ...[
                  ConstructionBlock(
                    primarySense: primary,
                    root: data.root,
                  ),
                  const SizedBox(height: 12),
                ],

                // 5. Example Block with <b> highlight
                if (primary != null && primary.example1 != null) ...[
                  ExampleBlock(primarySense: primary),
                  const SizedBox(height: 12),
                ],

                // 6. Inflections Block
                InflectionsChipList(
                  inflections: data.allInflections,
                  isCorePack: data.isCorePack,
                  onGoToPacks: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    widget.onNavigateToPacks?.call();
                  },
                  onSelectInflection: (inflectedForm) {
                    if (widget.onSelectInflection != null) {
                      widget.onSelectInflection!(inflectedForm);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InflectedResultsScreen(
                            lookupKey: inflectedForm,
                            onNavigateToPacks: widget.onNavigateToPacks,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioIcon(ThemeData theme) {
    if (_audioService.state == AudioState.loading &&
        _audioService.currentLemma == _data?.lemmaClean) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }
    if (_audioService.state == AudioState.playing &&
        _audioService.currentLemma == _data?.lemmaClean) {
      return Icon(Icons.volume_up, color: theme.colorScheme.primary);
    }
    return const Icon(Icons.volume_up_outlined);
  }

  Widget _buildHeaderCard(BuildContext context, WordCardData data, Headword? primary) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasGrammar = primary?.grammar != null && primary!.grammar!.trim().isNotEmpty;
    final hasPos = primary?.pos != null && primary!.pos!.trim().isNotEmpty;
    final bool isLoadingAudio = _audioService.state == AudioState.loading &&
        _audioService.currentLemma == data.lemmaClean;
    final bool isPlayingAudio = _audioService.state == AudioState.playing &&
        _audioService.currentLemma == data.lemmaClean;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    data.lemmaClean,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Audio listen button
                OutlinedButton.icon(
                  onPressed: isLoadingAudio
                      ? null
                      : () {
                          _audioService.playAudio(data.lemmaClean);
                        },
                  icon: _buildAudioIcon(theme),
                  label: Text(
                    isLoadingAudio
                        ? l10n.audioLoading
                        : (isPlayingAudio
                            ? l10n.audioPlaying
                            : l10n.listenAudio),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            if (hasPos || hasGrammar) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (!hasGrammar && hasPos)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        primary.pos!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasGrammar)
                    Text(
                      primary.grammar!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ],
            // EBT frequency
            if (primary?.ebtCountClean != null && primary!.ebtCountClean!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.ebtCountTimes(primary.ebtCountFormatted ?? primary.ebtCountClean!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildPronunciationCard(BuildContext context, Pronunciation pronunciation) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final reading = isEn
        ? (pronunciation.en.isNotEmpty ? pronunciation.en : pronunciation.vi)
        : (pronunciation.vi.isNotEmpty ? pronunciation.vi : pronunciation.en);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.pronunciationTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pronunciation.syllables,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pronunciationNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVietnameseGlossCard(
    BuildContext context,
    MeaningVi meaningVi, {
    ViGlossProvenance? provenance,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parsed = meaningVi.parsed;

    final labels = provenance?.getLabels(l10n) ??
        ViGlossProvenance.fromEntry(
          text: meaningVi.glossMain,
          matchTier: meaningVi.matchTier,
          baseLemma: meaningVi.baseLemma,
          baseEntryId: meaningVi.baseEntryId,
          glossSource: meaningVi.glossSource,
        ).getLabels(l10n);

    return Card(
      elevation: 0,
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
                Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.vietnameseMeaningSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (labels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: labels.map((label) {
                  final isDark = theme.brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.provenanceBadgeDarkBg
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                      border: isDark
                          ? Border.all(
                              color: const Color(0xFFE2A169).withValues(alpha: 0.4),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.provenanceBadgeDarkText
                            : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 18),
            if (provenance != null &&
                provenance.origin == ViGlossOrigin.senses &&
                provenance.text.isNotEmpty)
              SelectableText(
                provenance.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              )
            else if (parsed.leadParagraph.isNotEmpty)
              SelectableText(
                parsed.leadParagraph,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              )
            else if (meaningVi.glossMain.isNotEmpty)
              SelectableText(
                meaningVi.glossMain,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            if (parsed.hasCompounds) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...parsed.compounds.map(
                (compound) => ViCompoundRow(compound: compound),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensesCard(BuildContext context, WordCardData data) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_numbered, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.sensesSection} (${data.senses.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.senses.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final sense = data.senses[index];
                final viSense = data.viSenses[sense.id];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sense number & POS
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (sense.lemma1 != data.lemmaClean) ...[
                          const SizedBox(width: 8),
                          Text(
                            sense.lemma1,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Vietnamese gloss from meaning_vi_senses (ONLY in Vietnamese UI)
                    if (!isEn && viSense != null && viSense.viGloss.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  viSense.source == 'curated'
                                      ? l10n.sourceCurated
                                      : l10n.sourceNewTranslation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              viSense.viGloss,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // English meaning_1
                    if (sense.meaning1 != null && sense.meaning1!.isNotEmpty) ...[
                      if (isEn || data.hasVietnameseGloss)
                        SelectableText(
                          sense.meaning1!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.englishMeaningTitle,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                sense.meaning1!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.viMeaningPending,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    // Literal meaning if present
                    if (sense.meaningLit != null && sense.meaningLit!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        'lit. ${sense.meaningLit!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstructionBreakdownCard(BuildContext context, WordCardData data) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final parts = isEn
        ? data.constructionParts.where((p) => p.enGloss != null && p.enGloss!.isNotEmpty).toList()
        : data.constructionParts.where((p) => p.viGloss.isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.constructionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...parts.map((part) {
              final gloss = isEn ? part.enGloss! : part.viGloss;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.part,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '—',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        gloss,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
