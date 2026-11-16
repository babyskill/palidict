library;

import '../../core/normalization/pali_normalization.dart';

/// Models for Home v2 sections: Word of the Day, Frequent in Discourses,
/// Alphabet Index, and Recent Words.

/// Represents a grouped headword (used by Word of the Day and Frequent in Discourses).
class HeadwordGroup {
  final String cleanLemma;
  final int score;
  final int representativeId;
  final String representativeLemma1;
  final String? representativePos;
  final String? representativeMeaning1;
  final String? ebtCount;
  final String? resolvedGloss;

  const HeadwordGroup({
    required this.cleanLemma,
    required this.score,
    required this.representativeId,
    required this.representativeLemma1,
    this.representativePos,
    this.representativeMeaning1,
    this.ebtCount,
    this.resolvedGloss,
  });

  /// Cleaned EBT frequency number without surrounding quotes.
  String? get ebtCountClean => ebtCount?.replaceAll("'", "").trim();

  HeadwordGroup copyWith({String? resolvedGloss}) {
    return HeadwordGroup(
      cleanLemma: cleanLemma,
      score: score,
      representativeId: representativeId,
      representativeLemma1: representativeLemma1,
      representativePos: representativePos,
      representativeMeaning1: representativeMeaning1,
      ebtCount: ebtCount,
      resolvedGloss: resolvedGloss ?? this.resolvedGloss,
    );
  }
}

/// Represents a letter tile in the Alphabet Index.
class LetterCount {
  final String letter;
  final int count;

  const LetterCount({
    required this.letter,
    required this.count,
  });
}

/// Represents a lightweight headword row in the Alphabet letter list.
class LetterHeadwordRow {
  final int id;
  final String lemma1;
  final String? pos;

  const LetterHeadwordRow({
    required this.id,
    required this.lemma1,
    this.pos,
  });
}

/// Represents a stored item in Recent Words.
class RecentWordItem {
  final int id;
  final String lemma1;

  const RecentWordItem({
    required this.id,
    required this.lemma1,
  });

  /// Lemma without sense suffix (e.g. 'tacas 1' -> 'tacas').
  String get cleanLemma => PaliNormalization.cleanLemma(lemma1);

  Map<String, dynamic> toJson() => {
    'id': id,
    'lemma_1': lemma1,
  };

  factory RecentWordItem.fromJson(Map<String, dynamic> json) => RecentWordItem(
    id: (json['id'] as num).toInt(),
    lemma1: json['lemma_1'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentWordItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lemma1 == other.lemma1;

  @override
  int get hashCode => Object.hash(id, lemma1);
}
