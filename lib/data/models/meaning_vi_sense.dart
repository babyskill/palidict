/// Represents a row from `meaning_vi_senses` (new draft translation).
class MeaningViSense {
  final int entryId;
  final String viGloss;
  final String source;

  const MeaningViSense({
    required this.entryId,
    required this.viGloss,
    required this.source,
  });

  factory MeaningViSense.fromMap(Map<String, dynamic> map) {
    return MeaningViSense(
      entryId: (map['entry_id'] as num).toInt(),
      viGloss: map['vi_gloss'] as String? ?? '',
      source: map['source'] as String? ?? 'phase1-draft',
    );
  }
}
