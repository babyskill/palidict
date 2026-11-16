/// Represents a row from the `pronunciation` table.
class Pronunciation {
  final int entryId;
  final String syllables;
  final String vi;
  final String en;

  const Pronunciation({
    required this.entryId,
    required this.syllables,
    required this.vi,
    required this.en,
  });

  factory Pronunciation.fromMap(Map<String, dynamic> map) {
    return Pronunciation(
      entryId: (map['entry_id'] as num).toInt(),
      syllables: map['syllables'] as String? ?? '',
      vi: map['vi'] as String? ?? '',
      en: map['en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entry_id': entryId,
      'syllables': syllables,
      'vi': vi,
      'en': en,
    };
  }

  @override
  String toString() => 'Pronunciation(entryId: $entryId, syllables: $syllables, vi: $vi, en: $en)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pronunciation &&
          runtimeType == other.runtimeType &&
          entryId == other.entryId &&
          syllables == other.syllables &&
          vi == other.vi &&
          en == other.en;

  @override
  int get hashCode => Object.hash(entryId, syllables, vi, en);
}
