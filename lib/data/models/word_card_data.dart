import 'headword.dart';
import 'meaning_vi.dart';
import 'meaning_vi_sense.dart';
import 'pronunciation.dart';
import 'root_entry.dart';
import 'vi_gloss_provenance.dart';

/// Aggregated data required to render the Word Card screen.
class WordCardData {
  final String lemmaClean;
  final List<Headword> senses;
  final MeaningVi? meaningVi;
  final Map<int, MeaningViSense> viSenses;
  final RootEntry? root;
  final bool isCorePack;
  final ViGlossProvenance? viGlossProvenance;
  final List<ResolvedConstructionPart> constructionParts;
  final Pronunciation? pronunciation;

  const WordCardData({
    required this.lemmaClean,
    required this.senses,
    this.meaningVi,
    this.viSenses = const {},
    this.root,
    required this.isCorePack,
    this.viGlossProvenance,
    this.constructionParts = const [],
    this.pronunciation,
  });

  /// Primary headword entry (first sense).
  Headword? get primarySense => senses.isNotEmpty ? senses.first : null;

  /// Whether any Vietnamese gloss exists across entries or senses.
  bool get hasVietnameseGloss {
    if (viGlossProvenance != null) return true;
    if (meaningVi != null && meaningVi!.glossMain.trim().isNotEmpty) return true;
    return viSenses.values.any((s) => s.viGloss.trim().isNotEmpty);
  }

  /// Combined inflections from all senses (deduplicated).
  List<String> get allInflections {
    final set = <String>{};
    for (final sense in senses) {
      set.addAll(sense.inflectionsList);
    }
    final list = set.toList();
    list.sort();
    return list;
  }
}
