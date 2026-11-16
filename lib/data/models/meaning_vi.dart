import 'vi_gloss_parser.dart';

/// Represents a row from the `meaning_vi_entries` table (HT Buu Chon 1976 exact join).
class MeaningVi {
  final int? entryId;
  final String? lemmaKey;
  final String lemma;
  final String? pos;
  final String glossMain;
  final String? glossFull;
  final String source;
  final int? matchTier;
  final String? baseLemma;
  final int? baseEntryId;
  final String? glossSource;

  const MeaningVi({
    this.entryId,
    this.lemmaKey,
    required this.lemma,
    this.pos,
    required this.glossMain,
    this.glossFull,
    required this.source,
    this.matchTier,
    this.baseLemma,
    this.baseEntryId,
    this.glossSource,
  });

  /// Structured parsing of the lead senses and compound sub-entries.
  ParsedViGloss get parsed => parseViGloss(glossMain, glossFull);

  factory MeaningVi.fromMap(Map<String, dynamic> map) {
    return MeaningVi(
      entryId: map['entry_id'] as int?,
      lemmaKey: map['lemma_key'] as String?,
      lemma: map['lemma'] as String? ?? '',
      pos: map['pos'] as String?,
      glossMain: map['gloss_main'] as String? ?? '',
      glossFull: map['gloss_full'] as String?,
      source: map['source'] as String? ?? 'buuchon1976',
      matchTier: map['match_tier'] as int?,
      baseLemma: map['base_lemma'] as String?,
      baseEntryId: map['base_entry_id'] as int?,
      glossSource: map['gloss_source'] as String?,
    );
  }
}
