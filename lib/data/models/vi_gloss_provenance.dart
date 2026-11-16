import '../../l10n/app_localizations.dart';

/// Origin table of the Vietnamese gloss.
enum ViGlossOrigin {
  senses,
  entries,
}

/// Structured provenance and label resolution for Vietnamese glosses on the Word Card.
class ViGlossProvenance {
  final ViGlossOrigin origin;
  final String text;

  // From meaning_vi_senses
  final String? senseSource; // 'phase1-draft' | 'phase2-draft'

  // From meaning_vi_entries
  final int? matchTier;
  final String? baseLemma;
  final int? baseEntryId;
  final String? glossSource; // 'buuchon' | 'senses'

  const ViGlossProvenance({
    required this.origin,
    required this.text,
    this.senseSource,
    this.matchTier,
    this.baseLemma,
    this.baseEntryId,
    this.glossSource,
  });

  /// Factory for glosses originating from `meaning_vi_senses`.
  factory ViGlossProvenance.fromSense({
    required String text,
    required String source,
  }) {
    return ViGlossProvenance(
      origin: ViGlossOrigin.senses,
      text: text,
      senseSource: source,
    );
  }

  /// Factory for glosses originating from `meaning_vi_entries`.
  factory ViGlossProvenance.fromEntry({
    required String text,
    int? matchTier,
    String? baseLemma,
    int? baseEntryId,
    String? glossSource,
  }) {
    return ViGlossProvenance(
      origin: ViGlossOrigin.entries,
      text: text,
      matchTier: matchTier,
      baseLemma: baseLemma,
      baseEntryId: baseEntryId,
      glossSource: glossSource,
    );
  }

  /// Resolves presentation labels per Part 3 specification:
  /// - Gloss from senses (either draft source): show the SAME draft label (l10n.sourceNewTranslation)
  /// - Gloss from entries with match_tier 1, 2 or 4: show the existing Bửu Chơn source label (l10n.sourceBuuChon)
  /// - Gloss from entries with match_tier 3, 5 or 6 (inherited): show an inheritance label PLUS
  ///   the label of the underlying gloss source:
  ///     - if base_lemma != null: l10n.inheritedFrom(base_lemma)
  ///     - if base_lemma == null: l10n.inheritedGeneric
  ///     - plus: Bửu Chơn label when gloss_source = 'buuchon', draft label when gloss_source = 'senses'
  List<String> getLabels(AppLocalizations l10n) {
    if (origin == ViGlossOrigin.senses) {
      if (senseSource == 'curated') {
        return [l10n.sourceCurated];
      }
      return [l10n.sourceNewTranslation];
    }

    final tier = matchTier ?? 1;
    if (tier == 1 || tier == 2 || tier == 4) {
      return [l10n.sourceBuuChon];
    }

    if (tier == 3 || tier == 5 || tier == 6) {
      final List<String> labels = [];
      if (baseLemma != null && baseLemma!.trim().isNotEmpty) {
        labels.add(l10n.inheritedFrom(baseLemma!.trim()));
      } else {
        labels.add(l10n.inheritedGeneric);
      }

      if (glossSource == 'senses') {
        labels.add(l10n.sourceNewTranslation);
      } else {
        labels.add(l10n.sourceBuuChon);
      }
      return labels;
    }

    return [l10n.sourceBuuChon];
  }
}

/// Represents one component of a compound word resolved to its language gloss.
class ResolvedConstructionPart {
  final String part;
  final String viGloss;
  final String? enGloss;

  const ResolvedConstructionPart({
    required this.part,
    this.viGloss = '',
    this.enGloss,
  });

  String displayGloss([String locale = 'vi']) {
    if (locale == 'en') {
      return (enGloss != null && enGloss!.isNotEmpty) ? enGloss! : viGloss;
    }
    return viGloss.isNotEmpty ? viGloss : (enGloss ?? '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedConstructionPart &&
          runtimeType == other.runtimeType &&
          part == other.part &&
          viGloss == other.viGloss &&
          enGloss == other.enGloss;

  @override
  int get hashCode => Object.hash(part, viGloss, enGloss);

  @override
  String toString() => 'ResolvedConstructionPart($part: vi=$viGloss, en=$enGloss)';
}
