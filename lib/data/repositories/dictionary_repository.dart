import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/normalization/pali_normalization.dart';
import '../../services/recent_words_service.dart';
import '../database/pack_manager.dart';
import '../models/headword.dart';
import '../models/home_sections_data.dart';
import '../models/lookup_entry.dart';
import '../models/meaning_vi.dart';
import '../models/meaning_vi_sense.dart';
import '../models/pronunciation.dart';
import '../models/root_entry.dart';
import '../models/search_result.dart';
import '../models/vi_gloss_parser.dart';
import '../models/vi_gloss_provenance.dart';
import '../models/word_card_data.dart';

/// Standard Pāḷi alphabetical order for the Alphabet Index.
const List<String> paliAlphabetOrder = [
  'a', 'ā', 'i', 'ī', 'u', 'ū', 'e', 'o', 'ṃ',
  'k', 'g', 'ṅ', 'c', 'j', 'ñ', 'ṭ', 'ḍ', 'ṇ',
  't', 'd', 'n', 'p', 'b', 'm', 'y', 'r', 'l',
  'ḷ', 'v', 's', 'h',
];

/// Repository interface for dictionary data access.
///
/// Abstracted behind `meaningLocale` (default 'vi') so future language glosses
/// (meaning_en, etc.) can be plugged in without changing queries.
class DictionaryRepository {
  final PackManager packManager;
  final String meaningLocale;

  DictionaryRepository({
    PackManager? packManager,
    this.meaningLocale = 'vi',
  }) : packManager = packManager ?? PackManager.instance;

  Database get _db => packManager.database;

  String get _meaningEntriesTable => 'meaning_${meaningLocale}_entries';
  String get _meaningSensesTable => 'meaning_${meaningLocale}_senses';

  /// Searches for matching suggestions: headwords first, then inflected lookup forms.
  Future<List<SearchResult>> searchSuggestions(
    String query, {
    int limit = 40,
    String? locale,
  }) async {
    final effectiveLocale = locale ?? meaningLocale;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final unicodeQuery = PaliNormalization.velthuisToUnicode(trimmed);
    final globPrefix = PaliNormalization.toGlobPrefixPattern(trimmed);
    final globExact = PaliNormalization.toGlobExactPattern(trimmed);

    final results = <SearchResult>[];
    final seenHeadwordLemmas = <String>{};
    final seenLookupKeys = <String>{};

    // 1. Search Headwords (Exact & Prefix)
    // Order: exact matches first, then prefix matches, sorted by lemma_1
    final headwordsSql = '''
      SELECT id, lemma_1, pos, meaning_1
      FROM headwords
      WHERE lemma_1 GLOB ? OR lemma_1 LIKE ?
      ORDER BY 
        CASE 
          WHEN lemma_1 = ? OR lemma_1 LIKE ? THEN 0
          WHEN lemma_1 GLOB ? THEN 1
          WHEN lemma_1 GLOB ? THEN 2
          ELSE 3 
        END,
        id ASC
      LIMIT ?
    ''';

    final headwordRows = await _db.rawQuery(headwordsSql, [
      globPrefix,
      '$unicodeQuery%',
      trimmed,
      '$trimmed %',
      globExact,
      '$globExact *',
      limit,
    ]);

    for (final row in headwordRows) {
      final lemma1 = row['lemma_1'] as String? ?? '';
      final lemmaClean = PaliNormalization.cleanLemma(lemma1);

      if (seenHeadwordLemmas.contains(lemmaClean)) {
        continue;
      }
      seenHeadwordLemmas.add(lemmaClean);

      results.add(SearchResult(
        type: SearchResultType.headword,
        title: lemmaClean,
        subtitle: row['meaning_1'] as String?,
        grammar: row['pos'] as String?,
        headwordId: row['id'] as int,
        lemmaClean: lemmaClean,
      ));

      if (results.length >= limit) {
        break;
      }
    }

    // 2. Search Inflected forms via `lookup`
    final remainingLimit = limit - results.length;
    if (remainingLimit > 0) {
      final lookupSql = '''
        SELECT lookup_key, headwords, grammar
        FROM lookup
        WHERE lookup_key GLOB ? OR lookup_key LIKE ?
        ORDER BY
          CASE WHEN lookup_key = ? OR lookup_key = ? THEN 0 ELSE 1 END,
          lookup_key ASC
        LIMIT ?
      ''';

      final lookupRows = await _db.rawQuery(lookupSql, [
        globPrefix,
        '$unicodeQuery%',
        unicodeQuery,
        trimmed,
        remainingLimit,
      ]);

      for (final row in lookupRows) {
        final key = row['lookup_key'] as String? ?? '';

        // If this lookup key is already covered by a headword with the exact same name, skip
        if (seenHeadwordLemmas.contains(key)) {
          continue;
        }

        final rawHeadwords = row['headwords'] as String?;
        final rawGrammar = row['grammar'] as String?;

        List<int> headwordIds = [];
        if (rawHeadwords != null && rawHeadwords.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawHeadwords);
            if (decoded is List) {
              headwordIds = decoded.map((e) => (e as num).toInt()).toList();
            }
          } catch (_) {}
        }

        String grammarNote = '';
        if (rawGrammar != null && rawGrammar.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawGrammar);
            if (decoded is List && decoded.isNotEmpty) {
              final notes = <String>{};
              for (final item in decoded) {
                if (item is List && item.length >= 3 && item[2] != null) {
                  notes.add(item[2].toString());
                }
              }
              grammarNote = notes.join('; ');
            }
          } catch (_) {}
        }

        results.add(SearchResult(
          type: SearchResultType.inflected,
          title: key,
          grammar: grammarNote.isNotEmpty ? grammarNote : null,
          lookupKey: key,
          targetHeadwordIds: headwordIds,
        ));
        seenLookupKeys.add(key);

        if (results.length >= limit) {
          break;
        }
      }
    }

    // 3. Fallback approximate folded matching (Tier 3)
    final remainingAfterTier2 = limit - results.length;
    final foldedQuery = PaliNormalization.asciiFold(trimmed);
    if (remainingAfterTier2 > 0 && foldedQuery.length >= 3) {
      final squeezedQuery = PaliNormalization.squeezeFolded(foldedQuery);
      final prefix2 = foldedQuery.substring(0, 2);
      final globPrefix2 = PaliNormalization.toGlobPrefixPattern(prefix2);

      // Candidate fetch: headwords + lookup keys capped at 400 rows per table
      final tier3HeadwordsSql = '''
        SELECT id, lemma_1, pos, meaning_1, ebt_count
        FROM headwords
        WHERE lemma_1 GLOB ?
        LIMIT 400
      ''';
      final tier3LookupSql = '''
        SELECT lookup_key, headwords, grammar
        FROM lookup
        WHERE lookup_key GLOB ?
        LIMIT 400
      ''';

      final candidateHeadwordRows = await _db.rawQuery(tier3HeadwordsSql, [globPrefix2]);
      final candidateLookupRows = await _db.rawQuery(tier3LookupSql, [globPrefix2]);

      final candidates = <_Tier3Candidate>[];

      // Process headwords candidates
      for (final row in candidateHeadwordRows) {
        final lemma1 = row['lemma_1'] as String? ?? '';
        final lemmaClean = PaliNormalization.cleanLemma(lemma1);
        if (lemmaClean.isEmpty) continue;
        if (seenHeadwordLemmas.contains(lemmaClean)) continue;

        final foldedCandidate = PaliNormalization.asciiFold(lemmaClean);
        final squeezedCandidate = PaliNormalization.squeezeFolded(foldedCandidate);

        final matchGroup = _matchTier3Group(
          foldedCandidate: foldedCandidate,
          squeezedCandidate: squeezedCandidate,
          foldedQuery: foldedQuery,
          squeezedQuery: squeezedQuery,
        );

        if (matchGroup != null) {
          final rawEbt = row['ebt_count'];
          final int ebtCount;
          if (rawEbt is int) {
            ebtCount = rawEbt;
          } else if (rawEbt is String) {
            ebtCount = int.tryParse(rawEbt) ?? 0;
          } else {
            ebtCount = 0;
          }

          final searchResult = SearchResult(
            type: SearchResultType.headword,
            title: lemmaClean,
            subtitle: row['meaning_1'] as String?,
            grammar: row['pos'] as String?,
            headwordId: row['id'] as int,
            lemmaClean: lemmaClean,
          );

          candidates.add(_Tier3Candidate(
            matchGroup: matchGroup,
            isHeadword: true,
            ebtCount: ebtCount,
            sortKey: lemmaClean,
            headwordId: row['id'] as int,
            result: searchResult,
          ));
        }
      }

      // Process lookup candidates
      for (final row in candidateLookupRows) {
        final key = row['lookup_key'] as String? ?? '';
        if (key.isEmpty) continue;
        if (seenHeadwordLemmas.contains(key) || seenLookupKeys.contains(key)) continue;

        final foldedCandidate = PaliNormalization.asciiFold(key);
        final squeezedCandidate = PaliNormalization.squeezeFolded(foldedCandidate);

        final matchGroup = _matchTier3Group(
          foldedCandidate: foldedCandidate,
          squeezedCandidate: squeezedCandidate,
          foldedQuery: foldedQuery,
          squeezedQuery: squeezedQuery,
        );

        if (matchGroup != null) {
          final rawHeadwords = row['headwords'] as String?;
          final rawGrammar = row['grammar'] as String?;

          List<int> headwordIds = [];
          if (rawHeadwords != null && rawHeadwords.isNotEmpty) {
            try {
              final decoded = jsonDecode(rawHeadwords);
              if (decoded is List) {
                headwordIds = decoded.map((e) => (e as num).toInt()).toList();
              }
            } catch (_) {}
          }

          String grammarNote = '';
          if (rawGrammar != null && rawGrammar.isNotEmpty) {
            try {
              final decoded = jsonDecode(rawGrammar);
              if (decoded is List && decoded.isNotEmpty) {
                final notes = <String>{};
                for (final item in decoded) {
                  if (item is List && item.length >= 3 && item[2] != null) {
                    notes.add(item[2].toString());
                  }
                }
                grammarNote = notes.join('; ');
              }
            } catch (_) {}
          }

          final searchResult = SearchResult(
            type: SearchResultType.inflected,
            title: key,
            grammar: grammarNote.isNotEmpty ? grammarNote : null,
            lookupKey: key,
            targetHeadwordIds: headwordIds,
          );

          candidates.add(_Tier3Candidate(
            matchGroup: matchGroup,
            isHeadword: false,
            ebtCount: 0,
            sortKey: key,
            headwordId: null,
            result: searchResult,
          ));
        }
      }

      // Rank accepted candidates:
      // (a) before (b) before (c);
      // within a group: headwords before lookup forms,
      // then higher ebt_count first for headwords (descending),
      // then alphabetical.
      candidates.sort((a, b) {
        if (a.matchGroup != b.matchGroup) {
          return a.matchGroup.compareTo(b.matchGroup);
        }
        if (a.isHeadword != b.isHeadword) {
          return a.isHeadword ? -1 : 1;
        }
        if (a.isHeadword && a.ebtCount != b.ebtCount) {
          return b.ebtCount.compareTo(a.ebtCount);
        }
        final alphaCmp = a.sortKey.compareTo(b.sortKey);
        if (alphaCmp != 0) return alphaCmp;
        if (a.headwordId != null && b.headwordId != null) {
          return a.headwordId!.compareTo(b.headwordId!);
        }
        return 0;
      });

      // Add to results respecting limits and deduplication
      for (final candidate in candidates) {
        if (results.length >= limit) break;
        if (candidate.isHeadword) {
          if (seenHeadwordLemmas.contains(candidate.sortKey) ||
              seenLookupKeys.contains(candidate.sortKey)) {
            continue;
          }
          seenHeadwordLemmas.add(candidate.sortKey);
          results.add(candidate.result);
        } else {
          if (seenHeadwordLemmas.contains(candidate.sortKey) ||
              seenLookupKeys.contains(candidate.sortKey)) {
            continue;
          }
          seenLookupKeys.add(candidate.sortKey);
          results.add(candidate.result);
        }
      }
    }

    // Batch resolve display glosses for headword results preserving display priority:
    // In English: headwords meaning_1
    // In Vietnamese: 1. meaning_vi_senses, 2. meaning_vi_entries parsed, 3. meaning_1 (already set)
    final headwordResults = results.where((r) => r.headwordId != null).toList();
    if (headwordResults.isNotEmpty) {
      final ids = headwordResults.map((r) => r.headwordId!).toList();
      final displayGlosses = await batchResolveDisplayGlosses(ids, locale: effectiveLocale);
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        if (r.headwordId != null && displayGlosses.containsKey(r.headwordId!)) {
          final g = displayGlosses[r.headwordId!];
          if (g != null && g.isNotEmpty) {
            results[i] = r.copyWith(subtitle: g);
          }
        }
      }
    }

    return results;
  }

  /// Resolves an exact lookup entry for an inflected form.
  Future<LookupEntry?> getLookupEntry(String lookupKey) async {
    final trimmed = lookupKey.trim();
    if (trimmed.isEmpty) return null;

    final unicodeKey = PaliNormalization.velthuisToUnicode(trimmed);

    // Try exact Unicode key first
    var rows = await _db.rawQuery(
      'SELECT lookup_key, headwords, deconstructor, grammar FROM lookup WHERE lookup_key = ? LIMIT 1',
      [unicodeKey],
    );

    // If not found, try raw key
    if (rows.isEmpty && unicodeKey != trimmed) {
      rows = await _db.rawQuery(
        'SELECT lookup_key, headwords, deconstructor, grammar FROM lookup WHERE lookup_key = ? LIMIT 1',
        [trimmed],
      );
    }

    // If still not found, try GLOB exact pattern
    if (rows.isEmpty) {
      final globExact = PaliNormalization.toGlobExactPattern(trimmed);
      rows = await _db.rawQuery(
        'SELECT lookup_key, headwords, deconstructor, grammar FROM lookup WHERE lookup_key GLOB ? LIMIT 1',
        [globExact],
      );
    }

    if (rows.isEmpty) return null;
    return LookupEntry.fromMap(rows.first);
  }

  /// Retrieves a list of headwords by their integer IDs.
  Future<List<Headword>> getHeadwordsByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.rawQuery(
      'SELECT * FROM headwords WHERE id IN ($placeholders) ORDER BY id ASC',
      ids,
    );

    return rows.map((r) => Headword.fromMap(r)).toList();
  }

  /// Loads aggregated WordCardData by clean lemma string.
  Future<WordCardData?> getWordCardDataByLemma(String lemmaClean, {int? preferredEntryId}) async {
    final clean = lemmaClean.trim();
    if (clean.isEmpty) return null;

    final globExact = PaliNormalization.toGlobExactPattern(clean);

    // Query all senses matching lemma_clean
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM headwords 
      WHERE lemma_1 GLOB ? OR lemma_1 GLOB ? OR lemma_1 = ?
      ORDER BY id ASC
      ''',
      [globExact, '$globExact *', clean],
    );

    // Filter by cleanLemma: exact string match first, fallback to folded equivalence
    final allHeadwords = rows.map((r) => Headword.fromMap(r)).toList();
    var senses = allHeadwords
        .where((h) => h.lemmaClean.toLowerCase() == clean.toLowerCase())
        .toList();

    if (senses.isEmpty) {
      senses = allHeadwords
          .where((h) => PaliNormalization.areEquivalent(h.lemmaClean, clean))
          .toList();
    }

    if (senses.isEmpty) return null;

    // Load Vietnamese gloss from meaning_vi_entries BY entry_id
    MeaningVi? meaningVi;
    try {
      final senseIds = senses.map((s) => s.id).toList();
      if (senseIds.isNotEmpty) {
        final placeholders = List.filled(senseIds.length, '?').join(',');
        final orderClause = preferredEntryId != null
            ? 'CASE WHEN entry_id = $preferredEntryId THEN 0 ELSE 1 END, match_tier ASC, entry_id ASC'
            : 'match_tier ASC, entry_id ASC';
        final viRows = await _db.rawQuery(
          'SELECT * FROM $_meaningEntriesTable WHERE entry_id IN ($placeholders) ORDER BY $orderClause LIMIT 1',
          senseIds,
        );
        if (viRows.isNotEmpty) {
          meaningVi = MeaningVi.fromMap(viRows.first);
        }
      }
    } catch (e) {
      debugPrint('Error querying $_meaningEntriesTable: $e');
    }

    // Load sense-level Vietnamese glosses from meaning_vi_senses
    final Map<int, MeaningViSense> viSenses = {};
    try {
      final senseIds = senses.map((s) => s.id).toList();
      if (senseIds.isNotEmpty) {
        final placeholders = List.filled(senseIds.length, '?').join(',');
        final viSenseRows = await _db.rawQuery(
          'SELECT * FROM $_meaningSensesTable WHERE entry_id IN ($placeholders)',
          senseIds,
        );
        for (final row in viSenseRows) {
          final entry = MeaningViSense.fromMap(row);
          viSenses[entry.entryId] = entry;
        }
      }
    } catch (e) {
      debugPrint('Error querying $_meaningSensesTable: $e');
    }

    // Load root entry if primary sense has root_key
    RootEntry? root;
    final primaryRootKey = senses.first.rootKey;
    if (primaryRootKey != null && primaryRootKey.isNotEmpty) {
      try {
        final rootRows = await _db.rawQuery(
          'SELECT * FROM roots WHERE root = ? LIMIT 1',
          [primaryRootKey],
        );
        if (rootRows.isNotEmpty) {
          root = RootEntry.fromMap(rootRows.first);
        }
      } catch (_) {}
    }

    // Compute chosen Vietnamese gloss provenance (priority: senses first, then entries)
    final primarySense = preferredEntryId != null
        ? senses.firstWhere((s) => s.id == preferredEntryId, orElse: () => senses.first)
        : senses.first;

    ViGlossProvenance? viGlossProvenance;
    final senseGloss = viSenses[primarySense.id] ??
        (viSenses.isNotEmpty ? viSenses.values.first : null);
    if (senseGloss != null && senseGloss.viGloss.trim().isNotEmpty) {
      viGlossProvenance = ViGlossProvenance.fromSense(
        text: senseGloss.viGloss.trim(),
        source: senseGloss.source,
      );
    } else if (meaningVi != null &&
        (meaningVi.parsed.leadParagraph.isNotEmpty || meaningVi.glossMain.isNotEmpty)) {
      final text = meaningVi.parsed.leadParagraph.isNotEmpty
          ? meaningVi.parsed.leadParagraph
          : meaningVi.glossMain;
      viGlossProvenance = ViGlossProvenance.fromEntry(
        text: text,
        matchTier: meaningVi.matchTier,
        baseLemma: meaningVi.baseLemma,
        baseEntryId: meaningVi.baseEntryId,
        glossSource: meaningVi.glossSource,
      );
    }

    // Resolve construction breakdown if compound and construction non-empty
    List<ResolvedConstructionPart> constructionParts = const [];
    if (primarySense.isCompound &&
        primarySense.construction != null &&
        primarySense.construction!.trim().isNotEmpty) {
      constructionParts = await resolveConstructionBreakdown(primarySense.construction!);
    }

    // Load pronunciation for primary sense
    Pronunciation? pronunciation;
    try {
      pronunciation = await getPronunciation(primarySense.id);
    } catch (_) {
      pronunciation = null;
    }

    return WordCardData(
      lemmaClean: senses.first.lemmaClean,
      senses: senses,
      meaningVi: meaningVi,
      viSenses: viSenses,
      root: root,
      isCorePack: packManager.isCoreActive,
      viGlossProvenance: viGlossProvenance,
      constructionParts: constructionParts,
      pronunciation: pronunciation,
    );
  }

  /// Looks up pronunciation for a headword entry ID against the active pack database.
  ///
  /// Returns null if no pronunciation exists or if the pronunciation table is missing (older pack).
  /// Never throws an exception.
  Future<Pronunciation?> getPronunciation(int entryId) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT * FROM pronunciation WHERE entry_id = ? LIMIT 1',
        [entryId],
      );
      if (rows.isNotEmpty) {
        return Pronunciation.fromMap(rows.first);
      }
      return null;
    } catch (e) {
      // Table missing or other DB query issue; safely return null
      return null;
    }
  }

  /// Alias for getPronunciation.
  Future<Pronunciation?> getPronunciationByEntryId(int entryId) => getPronunciation(entryId);

  /// Resolves the construction breakdown for compound words per Part 5:
  /// Resolves compound construction components to language glosses:
  /// - Split construction on ' + '. Drop parts starting with '√' and parts of length <= 1.
  /// - For each part, resolve through lookup table to headword IDs, and get display glosses:
  ///   English: headwords meaning_1
  ///   Vietnamese: meaning_vi_senses -> meaning_vi_entries parsed
  /// - Resolves both languages when available so word card can display in either UI language.
  Future<List<ResolvedConstructionPart>> resolveConstructionBreakdown(String construction) async {
    final firstLine = construction.split('\n').first;
    final parts = firstLine.split(' + ');
    final candidateParts = <String>[];
    for (final raw in parts) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('√') || trimmed.length <= 1) continue;
      candidateParts.add(trimmed);
    }
    if (candidateParts.isEmpty) return const [];

    final resolved = <ResolvedConstructionPart>[];
    for (final part in candidateParts) {
      final lookupEntry = await getLookupEntry(part);
      if (lookupEntry == null || lookupEntry.headwordIds.isEmpty) continue;

      String? viGloss;
      for (final hid in lookupEntry.headwordIds) {
        // 1. meaning_vi_senses first
        try {
          final sRows = await _db.rawQuery(
            'SELECT vi_gloss FROM $_meaningSensesTable WHERE entry_id = ? LIMIT 1',
            [hid],
          );
          if (sRows.isNotEmpty) {
            final g = sRows.first['vi_gloss'] as String? ?? '';
            if (g.trim().isNotEmpty) {
              viGloss = g.trim();
              break;
            }
          }
        } catch (_) {}

        // 2. meaning_vi_entries second
        try {
          final eRows = await _db.rawQuery(
            'SELECT gloss_main, gloss_full FROM $_meaningEntriesTable WHERE entry_id = ? LIMIT 1',
            [hid],
          );
          if (eRows.isNotEmpty) {
            final gm = eRows.first['gloss_main'] as String? ?? '';
            final gf = eRows.first['gloss_full'] as String?;
            final parsed = parseViGloss(gm, gf);
            final text = parsed.leadParagraph.isNotEmpty ? parsed.leadParagraph : gm;
            if (text.trim().isNotEmpty) {
              viGloss = text.trim();
              break;
            }
          }
        } catch (_) {}
      }

      String? enGloss;
      for (final hid in lookupEntry.headwordIds) {
        try {
          final hRows = await _db.rawQuery(
            'SELECT meaning_1 FROM headwords WHERE id = ? LIMIT 1',
            [hid],
          );
          if (hRows.isNotEmpty) {
            final m = hRows.first['meaning_1'] as String? ?? '';
            if (m.trim().isNotEmpty) {
              enGloss = m.trim();
              break;
            }
          }
        } catch (_) {}
      }

      if ((viGloss != null && viGloss.isNotEmpty) ||
          (enGloss != null && enGloss.isNotEmpty)) {
        resolved.add(ResolvedConstructionPart(
          part: part,
          viGloss: viGloss ?? '',
          enGloss: enGloss,
        ));
      }
    }

    return resolved;
  }

  /// Loads aggregated WordCardData by a specific headword ID.
  Future<WordCardData?> getWordCardDataById(int headwordId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM headwords WHERE id = ? LIMIT 1',
      [headwordId],
    );

    if (rows.isEmpty) return null;
    final headword = Headword.fromMap(rows.first);
    return getWordCardDataByLemma(headword.lemmaClean, preferredEntryId: headwordId);
  }

  /// Resolves the Buu Chon gloss row from meaning_vi_entries for a specific headword entry_id.
  Future<MeaningVi?> getMeaningViEntry(int entryId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM $_meaningEntriesTable WHERE entry_id = ? LIMIT 1',
      [entryId],
    );
    if (rows.isEmpty) return null;
    return MeaningVi.fromMap(rows.first);
  }

  /// Batch-resolves display glosses for headword entry IDs preserving precedence:
  /// In English:
  /// - DPD headwords meaning_1
  /// In Vietnamese:
  /// 1. Draft senses (meaning_vi_senses) first
  /// 2. HT Bửu Chơn (meaning_vi_entries) second
  Future<Map<int, String>> batchResolveDisplayGlosses(
    List<int> entryIds, {
    String? locale,
  }) async {
    if (entryIds.isEmpty) return const {};
    final effectiveLocale = locale ?? meaningLocale;

    if (effectiveLocale == 'en') {
      final Map<int, String> resolved = {};
      try {
        final placeholders = List.filled(entryIds.length, '?').join(',');
        final rows = await _db.rawQuery(
          'SELECT id, meaning_1 FROM headwords WHERE id IN ($placeholders)',
          entryIds,
        );
        for (final row in rows) {
          final id = row['id'] as int? ?? 0;
          final m1 = row['meaning_1'] as String? ?? '';
          if (m1.trim().isNotEmpty) {
            resolved[id] = m1.trim();
          }
        }
      } catch (_) {}
      return resolved;
    }

    final Map<int, String> resolved = {};

    // 1. Draft senses (meaning_vi_senses) first
    try {
      final placeholders = List.filled(entryIds.length, '?').join(',');
      final senseRows = await _db.rawQuery(
        'SELECT entry_id, vi_gloss FROM $_meaningSensesTable WHERE entry_id IN ($placeholders)',
        entryIds,
      );
      for (final row in senseRows) {
        final entryId = row['entry_id'] as int? ?? 0;
        final viGloss = row['vi_gloss'] as String? ?? '';
        if (viGloss.isNotEmpty) {
          resolved[entryId] = viGloss;
        }
      }
    } catch (_) {}

    // 2. HT Bửu Chơn (meaning_vi_entries) for missing IDs
    final missingIds = entryIds.where((id) => !resolved.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      try {
        final placeholders = List.filled(missingIds.length, '?').join(',');
        final viRows = await _db.rawQuery(
          'SELECT entry_id, gloss_main, gloss_full FROM $_meaningEntriesTable WHERE entry_id IN ($placeholders)',
          missingIds,
        );
        for (final row in viRows) {
          final entryId = row['entry_id'] as int? ?? 0;
          final glossMain = row['gloss_main'] as String? ?? '';
          final glossFull = row['gloss_full'] as String?;
          final parsed = parseViGloss(glossMain, glossFull);
          final lead = parsed.leadParagraph.isNotEmpty ? parsed.leadParagraph : glossMain;
          if (lead.isNotEmpty) {
            resolved[entryId] = lead;
          }
        }
      } catch (_) {}
    }

    return resolved;
  }

  // ==========================================
  // Home v2: Selection-First Data Queries
  // ==========================================

  static String? _cachedDbPath;
  static String? _cachedPoolLocale;
  static List<HeadwordGroup>? _cachedPool;
  static List<LetterCount>? _cachedAlphabetIndex;

  /// Retrieves grouped base lemmas of the active pack sorted by score DESC,
  /// tie-break cleaned lemma ASC, with resolved display glosses.
  Future<List<HeadwordGroup>> getGroupedHeadwordsPool({
    int limit = 365,
    String? locale,
  }) async {
    final effectiveLocale = locale ?? meaningLocale;
    final currentDbPath = _db.path;
    if (_cachedPool != null &&
        _cachedDbPath == currentDbPath &&
        _cachedPoolLocale == effectiveLocale) {
      return _cachedPool!;
    }

    final rows = await _db.rawQuery('''
      SELECT id, lemma_1, pos, meaning_1, ebt_count
      FROM headwords
      WHERE ebt_count IS NOT NULL AND ebt_count != ''
      ORDER BY CAST(ebt_count AS INTEGER) DESC, id ASC
      LIMIT 4000
    ''');

    final groupsMap = <String, HeadwordGroup>{};
    for (final row in rows) {
      final lemma1 = row['lemma_1'] as String? ?? '';
      final clean = PaliNormalization.cleanLemma(lemma1);
      final rawEbt = row['ebt_count']?.toString() ?? '';
      final score = int.tryParse(rawEbt.replaceAll("'", "").trim()) ?? 0;

      if (!groupsMap.containsKey(clean)) {
        groupsMap[clean] = HeadwordGroup(
          cleanLemma: clean,
          score: score,
          representativeId: row['id'] as int,
          representativeLemma1: lemma1,
          representativePos: row['pos'] as String?,
          representativeMeaning1: row['meaning_1'] as String?,
          ebtCount: rawEbt,
        );
      }
    }

    final sortedGroups = groupsMap.values.toList();
    sortedGroups.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.cleanLemma.compareTo(b.cleanLemma);
    });

    final pool = sortedGroups.take(limit).toList();

    // Batch resolve glosses preserving precedence:
    // In English: headwords meaning_1
    // In Vietnamese:
    // 1. Draft senses (meaning_vi_senses) first
    // 2. HT Bửu Chơn (meaning_vi_entries) second
    final repIds = pool.map((g) => g.representativeId).toList();
    final displayGlosses = await batchResolveDisplayGlosses(repIds, locale: effectiveLocale);

    // 3. Assemble resolved gloss for each group in pool (fallback to meaning_1)
    final resolvedPool = pool.map((group) {
      final gloss = displayGlosses[group.representativeId] ?? group.representativeMeaning1;
      return group.copyWith(resolvedGloss: gloss);
    }).toList();

    _cachedDbPath = currentDbPath;
    _cachedPoolLocale = effectiveLocale;
    _cachedPool = resolvedPool;
    return resolvedPool;
  }

  /// Word of the Day: picks index = (days since epoch) mod pool size (top 365).
  Future<HeadwordGroup?> getWordOfTheDay({DateTime? forDate, String? locale}) async {
    final pool = await getGroupedHeadwordsPool(limit: 365, locale: locale);
    if (pool.isEmpty) return null;

    final date = forDate ?? DateTime.now();
    final localEpochDays = DateTime(date.year, date.month, date.day)
        .difference(DateTime(1970, 1, 1))
        .inDays;
    final index = ((localEpochDays % pool.length) + pool.length) % pool.length;
    return pool[index];
  }

  /// Frequent in Discourses: top 24 grouped lemmas by EBT score.
  Future<List<HeadwordGroup>> getFrequentInDiscourses({int limit = 24, String? locale}) async {
    final pool = await getGroupedHeadwordsPool(limit: 365, locale: locale);
    return pool.take(limit).toList();
  }

  /// Alphabet Index: initial letters present in the active pack, in standard Pāḷi order.
  Future<List<LetterCount>> getAlphabetIndex() async {
    final currentDbPath = _db.path;
    if (_cachedAlphabetIndex != null && _cachedDbPath == currentDbPath) {
      return _cachedAlphabetIndex!;
    }

    final rows = await _db.rawQuery(
      'SELECT substr(lemma_1, 1, 1) as letter, count(*) as count FROM headwords GROUP BY letter',
    );

    final map = <String, int>{};
    for (final row in rows) {
      final letter = row['letter'] as String? ?? '';
      final count = (row['count'] as num?)?.toInt() ?? 0;
      if (letter.isNotEmpty && count > 0) {
        map[letter] = count;
      }
    }

    final result = <LetterCount>[];
    for (final letter in paliAlphabetOrder) {
      if (map.containsKey(letter)) {
        result.add(LetterCount(letter: letter, count: map[letter]!));
        map.remove(letter);
      }
    }

    // Any characters not in standard Pali order sort alphabetically after
    final remaining = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in remaining) {
      result.add(LetterCount(letter: entry.key, count: entry.value));
    }

    _cachedAlphabetIndex = result;
    _cachedDbPath = currentDbPath;
    return result;
  }

  /// Retrieves lightweight rows for all headwords starting with [letter].
  Future<List<LetterHeadwordRow>> getHeadwordsByLetter(String letter) async {
    final rows = await _db.rawQuery(
      'SELECT id, lemma_1, pos FROM headwords WHERE lemma_1 GLOB ? ORDER BY lemma_1 ASC',
      ['$letter*'],
    );

    return rows.map((r) => LetterHeadwordRow(
      id: r['id'] as int,
      lemma1: r['lemma_1'] as String? ?? '',
      pos: r['pos'] as String?,
    )).toList();
  }

  /// Resolves a RecentWordItem in the active pack: by id first; if absent, by exact
  /// lemma_1 match; if still absent, removes item from storage and returns null.
  Future<WordCardData?> resolveRecentWord(RecentWordItem item) async {
    // 1. Try by id first
    final dataById = await getWordCardDataById(item.id);
    if (dataById != null) {
      return dataById;
    }

    // 2. If absent, search active pack by exact lemma_1 match
    final rows = await _db.rawQuery(
      'SELECT id, lemma_1 FROM headwords WHERE lemma_1 = ? LIMIT 1',
      [item.lemma1],
    );
    if (rows.isNotEmpty) {
      final matchedId = rows.first['id'] as int;
      final dataByLemma = await getWordCardDataById(matchedId);
      if (dataByLemma != null) {
        // Update stored item with newly matched id
        await RecentWordsService.instance.recordWord(
          id: matchedId,
          lemma1: item.lemma1,
        );
        return dataByLemma;
      }
    }

    // 3. Still absent -> remove that item from storage
    await RecentWordsService.instance.removeWord(item.id);
    return null;
  }

  static int? _matchTier3Group({
    required String foldedCandidate,
    required String squeezedCandidate,
    required String foldedQuery,
    required String squeezedQuery,
  }) {
    if (squeezedCandidate == squeezedQuery) {
      return 0; // (a)
    }
    if (squeezedCandidate.startsWith(squeezedQuery)) {
      return 1; // (b)
    }
    final qLen = foldedQuery.length;
    if (qLen >= 4) {
      final maxDist = qLen >= 7 ? 2 : 1;
      final dist = PaliNormalization.levenshtein(foldedCandidate, foldedQuery);
      if (dist <= maxDist) {
        return 2; // (c)
      }
    }
    return null;
  }
}

class _Tier3Candidate {
  final int matchGroup;
  final bool isHeadword;
  final int ebtCount;
  final String sortKey;
  final int? headwordId;
  final SearchResult result;

  const _Tier3Candidate({
    required this.matchGroup,
    required this.isHeadword,
    required this.ebtCount,
    required this.sortKey,
    required this.headwordId,
    required this.result,
  });
}

