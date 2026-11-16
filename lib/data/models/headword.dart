import 'package:intl/intl.dart';
import '../../core/normalization/pali_normalization.dart';

/// Represents a headword entry from table `headwords`.
class Headword {
  final int id;
  final String lemma1;
  final String? lemma2;
  final String? pos;
  final String? grammar;
  final String? meaning1;
  final String? meaningLit;
  final String? meaning2;
  final String? rootKey;
  final String? rootSign;
  final String? construction;
  final String? phonetic;
  final String? source1;
  final String? sutta1;
  final String? example1;
  final String? antonym;
  final String? synonym;
  final String? ebtCount;

  // Extended columns available in Core pack
  final String? sanskrit;
  final String? inflections;
  final String? derivedFrom;
  final String? rootBase;
  final String? familyRoot;
  final String? familyWord;
  final String? notes;

  const Headword({
    required this.id,
    required this.lemma1,
    this.lemma2,
    this.pos,
    this.grammar,
    this.meaning1,
    this.meaningLit,
    this.meaning2,
    this.rootKey,
    this.rootSign,
    this.construction,
    this.phonetic,
    this.source1,
    this.sutta1,
    this.example1,
    this.antonym,
    this.synonym,
    this.ebtCount,
    this.sanskrit,
    this.inflections,
    this.derivedFrom,
    this.rootBase,
    this.familyRoot,
    this.familyWord,
    this.notes,
  });

  /// Lemma without sense numbering suffix (e.g. 'dhamma 1.03' -> 'dhamma').
  String get lemmaClean => PaliNormalization.cleanLemma(lemma1);

  /// Cleaned EBT frequency number without surrounding quotes.
  String? get ebtCountClean => ebtCount?.replaceAll("'", "").trim();

  /// Formatted EBT frequency with vi-VN thousands separator (e.g. 12.582).
  String? get ebtCountFormatted {
    final clean = ebtCountClean;
    if (clean == null || clean.isEmpty) return null;
    final n = int.tryParse(clean);
    if (n == null) return clean;
    return NumberFormat.decimalPattern('vi_VN').format(n);
  }

  /// True if the entry represents a compound word.
  bool get isCompound {
    final g = (grammar ?? '').toLowerCase();
    final p = (pos ?? '').toLowerCase();
    final regex = RegExp(r'\bcomps?\b|\bcompound\b');
    return regex.hasMatch(g) || regex.hasMatch(p);
  }

  /// List of inflections split by comma (from Core pack).
  List<String> get inflectionsList {
    if (inflections == null || inflections!.trim().isEmpty) {
      return const [];
    }
    return inflections!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory Headword.fromMap(Map<String, dynamic> map) {
    return Headword(
      id: map['id'] as int,
      lemma1: map['lemma_1'] as String? ?? '',
      lemma2: map['lemma_2'] as String?,
      pos: map['pos'] as String?,
      grammar: map['grammar'] as String?,
      meaning1: map['meaning_1'] as String?,
      meaningLit: map['meaning_lit'] as String?,
      meaning2: map['meaning_2'] as String?,
      rootKey: map['root_key'] as String?,
      rootSign: map['root_sign'] as String?,
      construction: map['construction'] as String?,
      phonetic: map['phonetic'] as String?,
      source1: map['source_1'] as String?,
      sutta1: map['sutta_1'] as String?,
      example1: map['example_1'] as String?,
      antonym: map['antonym'] as String?,
      synonym: map['synonym'] as String?,
      ebtCount: map['ebt_count']?.toString(),
      sanskrit: map['sanskrit'] as String?,
      inflections: map['inflections'] as String?,
      derivedFrom: map['derived_from'] as String?,
      rootBase: map['root_base'] as String?,
      familyRoot: map['family_root'] as String?,
      familyWord: map['family_word'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
