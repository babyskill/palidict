import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/data/models/search_result.dart';
import 'package:palidict/data/models/vi_gloss_provenance.dart';
import 'package:palidict/data/repositories/dictionary_repository.dart';
import 'fixtures/fixture_helper.dart';

void main() {
  late DictionaryRepository repository;
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await PackManager.instance.initialize(directDbPath: dbPath);
    repository = DictionaryRepository(packManager: PackManager.instance);
  });

  group('Lookup Resolution - 10 Sample Forms', () {
    test('Sample 1: bhikkhunaṃ → bhikkhu (49885)', () async {
      final entry = await repository.getLookupEntry('bhikkhunaṃ');
      expect(entry, isNotNull);
      expect(entry!.headwordIds, contains(49885));

      final headwords = await repository.getHeadwordsByIds(entry.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toList();
      expect(lemmas, contains('bhikkhu'));

      expect(entry.grammarSummary, contains('masc'));
    });

    test('Sample 1 (Velthuis): bhikkhuna.m resolves identically to bhikkhunaṃ', () async {
      final entry = await repository.getLookupEntry('bhikkhuna.m');
      expect(entry, isNotNull);
      expect(entry!.headwordIds, contains(49885));
    });

    test('Sample 2: dhamma senses = exactly 16 entries in headwords', () async {
      final data = await repository.getWordCardDataByLemma('dhamma');
      expect(data, isNotNull);
      expect(data!.senses.length, 16);
      expect(data.meaningVi, isNotNull);
      expect(data.meaningVi!.glossMain, contains('giáo lý'));
      expect(data.meaningVi!.source, 'buuchon1976');
    });

    test('Sample 3: dhammassa → dhamma', () async {
      final entry = await repository.getLookupEntry('dhammassa');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('dhamma'));
    });

    test('Sample 4: dhammena → dhamma', () async {
      final entry = await repository.getLookupEntry('dhammena');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('dhamma'));
    });

    test('Sample 5: buddhaṃ → buddha', () async {
      final entry = await repository.getLookupEntry('buddhaṃ');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('buddha'));
    });

    test('Sample 6: aniccā → anicca', () async {
      final entry = await repository.getLookupEntry('aniccā');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('anicca'));
    });

    test('Sample 7: dukkhassa → dukkha', () async {
      final entry = await repository.getLookupEntry('dukkhassa');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('dukkha'));
    });

    test('Sample 8: kammaṃ → kamma', () async {
      final entry = await repository.getLookupEntry('kammaṃ');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('kamma'));
    });

    test('Sample 9: nibbānaṃ → nibbāna', () async {
      final entry = await repository.getLookupEntry('nibbānaṃ');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('nibbāna'));
    });

    test('Sample 10: arahato → arahant', () async {
      final entry = await repository.getLookupEntry('arahato');
      expect(entry, isNotNull);
      final headwords = await repository.getHeadwordsByIds(entry!.headwordIds);
      final lemmas = headwords.map((h) => h.lemmaClean).toSet();
      expect(lemmas, contains('arahant'));
    });
  });

  group('Suggestions and Equivalence', () {
    test('searchSuggestions returns headwords first, then inflections', () async {
      final suggestions = await repository.searchSuggestions('dhamma');
      expect(suggestions, isNotEmpty);
      expect(suggestions.first.type, SearchResultType.headword);
      expect(suggestions.first.title, 'dhamma');

      final hasInflected = suggestions.any((s) => s.type == SearchResultType.inflected);
      expect(hasInflected, isTrue);
    });

    test('Velthuis and plain queries return matching suggestions', () async {
      final sPlain = await repository.searchSuggestions('dhamma');
      final sVelthuis = await repository.searchSuggestions('dhammaa');
      expect(sPlain, isNotEmpty);
      expect(sVelthuis, isNotEmpty);
      final plainTitles = sPlain.map((s) => s.title).toSet();
      final velthuisTitles = sVelthuis.map((s) => s.title).toSet();
      expect(plainTitles, contains('dhamma'));
      expect(plainTitles, contains('dhammā'));
      expect(velthuisTitles, contains('dhamma'));
      expect(velthuisTitles, contains('dhammā'));
    });
  });

  group('Tolerant Search - Diacritic-Free & Missing-Letter (Tier 3)', () {
    test('meta returns headwords metta/mettā in suggestions (tier 3), and tier 1/2 results (metaṃ, metanti) still come first', () async {
      final suggestions = await repository.searchSuggestions('meta');
      expect(suggestions, isNotEmpty);
      final titles = suggestions.map((s) => s.title).toList();

      // Tier 1/2 results must come first
      final idxMetam = titles.indexOf('metaṃ');
      final idxMetanti = titles.indexOf('metanti');
      final idxMetta = titles.indexOf('metta');
      final idxMettaa = titles.indexOf('mettā');

      expect(idxMetam, isNot(-1));
      expect(idxMetanti, isNot(-1));
      expect(idxMetta, isNot(-1));
      expect(idxMettaa, isNot(-1));

      expect(idxMetam, lessThan(idxMetta));
      expect(idxMetam, lessThan(idxMettaa));
      expect(idxMetanti, lessThan(idxMetta));
      expect(idxMetanti, lessThan(idxMettaa));

      final metta = suggestions.firstWhere((s) => s.title == 'metta');
      expect(metta.type, SearchResultType.headword);
      expect(metta.subtitle, isNotNull);

      final mettaa = suggestions.firstWhere((s) => s.title == 'mettā');
      expect(mettaa.type, SearchResultType.headword);
      expect(mettaa.subtitle, isNotNull);
    });

    test('budha returns buddha via tier 3', () async {
      final suggestions = await repository.searchSuggestions('budha');
      expect(suggestions, isNotEmpty);
      final titles = suggestions.map((s) => s.title).toList();
      expect(titles, contains('buddha'));
      final buddha = suggestions.firstWhere((s) => s.title == 'buddha');
      expect(buddha.type, SearchResultType.headword);
      expect(buddha.subtitle, contains('giác ngộ'));
    });

    test('Regression: tanha still returns taṇhā first (tier 1/2, NOT tier 3); metta still returns metta/mettā via tier 1/2; dhamma unchanged', () async {
      final sTanha = await repository.searchSuggestions('tanha');
      expect(sTanha, isNotEmpty);
      final tanhaTitles = sTanha.take(2).map((s) => s.title).toList();
      expect(tanhaTitles, contains('taṇhā'));
      expect(tanhaTitles, contains('taṇha'));
      expect(sTanha.first.type, SearchResultType.headword);

      final sMetta = await repository.searchSuggestions('metta');
      expect(sMetta, isNotEmpty);
      final mettaTitles = sMetta.take(2).map((s) => s.title).toList();
      expect(mettaTitles, contains('metta'));
      expect(mettaTitles, contains('mettā'));

      final sDhamma = await repository.searchSuggestions('dhamma');
      expect(sDhamma, isNotEmpty);
      expect(sDhamma.first.title, 'dhamma');
      expect(sDhamma.first.type, SearchResultType.headword);
    });

    test('A gibberish query (e.g. xyzqq) returns no tier-3 noise', () async {
      final suggestions = await repository.searchSuggestions('xyzqq');
      expect(suggestions, isEmpty);
    });

    test('Tier 3 never exceeds the result limit and never duplicates a tier 1/2 hit', () async {
      const customLimit = 5;
      final suggestions = await repository.searchSuggestions('meta', limit: customLimit);
      expect(suggestions.length, lessThanOrEqualTo(customLimit));

      final titles = suggestions.map((s) => s.title).toList();
      final uniqueTitles = titles.toSet();
      expect(titles.length, equals(uniqueTitles.length), reason: 'No duplicate titles should be returned');
    });
  });

  group('Deliverable 2 - Search Results Vietnamese Subtitle Precedence', () {
    test('a word with Buu Chon entry (taca) renders Vietnamese subtitle', () async {
      final suggestions = await repository.searchSuggestions('taca');
      expect(suggestions, isNotEmpty);
      final taca = suggestions.firstWhere((s) => s.title == 'taca');
      expect(taca.type, SearchResultType.headword);
      expect(taca.subtitle, contains('da, vỏ, da thú'));
    });

    test('a word with senses only (tañca) renders Vietnamese subtitle', () async {
      final suggestions = await repository.searchSuggestions('tañca');
      expect(suggestions, isNotEmpty);
      final tanca = suggestions.firstWhere((s) => s.title == 'tañca');
      expect(tanca.type, SearchResultType.headword);
      expect(tanca.subtitle, equals('và điều đó'));
    });

    test('a word with neither (tata on synthetic Lite fixture) still falls back to English meaning_1', () async {
      final fixturePath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixturePath);
      final fixtureRepo = DictionaryRepository(packManager: PackManager.instance);

      final suggestions = await fixtureRepo.searchSuggestions('tata');
      expect(suggestions, isNotEmpty);
      final tata = suggestions.firstWhere((s) => s.title == 'tata');
      expect(tata.type, SearchResultType.headword);
      expect(tata.subtitle, equals('spread out; extended; expanded'));

      await PackManager.instance.initialize(directDbPath: dbPath);
    });
  });

  group('Deliverable 4 - Buu Chon Exact Entry Join Verification', () {
    test('Lite entry join: 29426 (tata on synthetic fixture) has no gloss, 71483 (hoti 1) resolves Hoti tier 1', () async {
      final fixturePath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixturePath);
      final fixtureRepo = DictionaryRepository(packManager: PackManager.instance);

      // Entry 29426 ('tata') resolves NO Buu Chon gloss
      final tataGloss = await fixtureRepo.getMeaningViEntry(29426);
      expect(tataGloss, isNull);

      final tataCard = await fixtureRepo.getWordCardDataById(29426);
      expect(tataCard?.meaningVi, isNull);

      // Entry 71483 ('hoti 1') resolves lemma 'Hoti' at tier 1
      final hotiGloss = await fixtureRepo.getMeaningViEntry(71483);
      expect(hotiGloss, isNotNull);
      expect(hotiGloss!.lemma, 'Hoti');
      expect(hotiGloss.matchTier, 1);

      final hotiCard = await fixtureRepo.getWordCardDataById(71483);
      expect(hotiCard, isNotNull);
      expect(hotiCard!.meaningVi, isNotNull);
      expect(hotiCard.meaningVi!.lemma, 'Hoti');
      expect(hotiCard.meaningVi!.matchTier, 1);

      await PackManager.instance.initialize(directDbPath: dbPath);
    });

    test('Core pack entry join: 29307 and 29308 (taṭa) resolve lemma Taṭa, 29426 (tata) resolves tier 3 inherited', () async {
      final tempDir = await Directory.systemTemp.createTemp('palidict_core_test_');
      final coreDbFile = File(p.join(tempDir.path, 'core_final.db'));
      final gzBytes = File('data/core_final.db.gz').readAsBytesSync();
      final decompressed = gzip.decode(gzBytes);
      coreDbFile.writeAsBytesSync(decompressed);

      await PackManager.instance.initialize(directDbPath: coreDbFile.path);
      final coreRepo = DictionaryRepository(packManager: PackManager.instance);

      try {
        // Entry 29426 ('tata') in v3 Core resolves inherited gloss (tier 3), not Taṭa
        final tataGloss = await coreRepo.getMeaningViEntry(29426);
        expect(tataGloss, isNotNull);
        expect(tataGloss!.lemma, 'tata');
        expect(tataGloss.matchTier, 3);

        final tataCard = await coreRepo.getWordCardDataById(29426);
        expect(tataCard?.meaningVi, isNotNull);
        expect(tataCard!.meaningVi!.lemma, 'tata');
        expect(tataCard.meaningVi!.matchTier, 3);

        // Entries 29307 and 29308 ('taṭa') resolve Buu Chon gloss whose lemma is 'Taṭa'
        final tata1Gloss = await coreRepo.getMeaningViEntry(29307);
        expect(tata1Gloss, isNotNull);
        expect(tata1Gloss!.lemma, 'Taṭa');

        final tata2Gloss = await coreRepo.getMeaningViEntry(29308);
        expect(tata2Gloss, isNotNull);
        expect(tata2Gloss!.lemma, 'Taṭa');

        final tata1Card = await coreRepo.getWordCardDataById(29307);
        expect(tata1Card?.meaningVi, isNotNull);
        expect(tata1Card!.meaningVi!.lemma, 'Taṭa');

        final tata2Card = await coreRepo.getWordCardDataById(29308);
        expect(tata2Card?.meaningVi, isNotNull);
        expect(tata2Card!.meaningVi!.lemma, 'Taṭa');

        // Entry 71483 ('hoti 1') resolves lemma 'Hoti' at tier 1
        final hotiGloss = await coreRepo.getMeaningViEntry(71483);
        expect(hotiGloss, isNotNull);
        expect(hotiGloss!.lemma, 'Hoti');
        expect(hotiGloss.matchTier, 1);
      } finally {
        final liteDbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
        await PackManager.instance.initialize(directDbPath: liteDbPath);
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });

  group('Deliverable 4 - v4 Provenance & Construction Breakdown', () {
    test('tier-3 entry with base_lemma (agamāsi) has provenance populated', () async {
      final card = await repository.getWordCardDataByLemma('agamāsi');
      expect(card, isNotNull);
      expect(card!.viGlossProvenance, isNotNull);
      expect(card.viGlossProvenance!.matchTier, 3);
      expect(card.viGlossProvenance!.baseLemma, 'gacchati');
      expect(card.viGlossProvenance!.glossSource, 'buuchon');
    });

    test('tier-6 entry (tacas) has provenance populated', () async {
      final card = await repository.getWordCardDataByLemma('tacas');
      expect(card, isNotNull);
      expect(card!.viGlossProvenance, isNotNull);
      expect(card.viGlossProvenance!.matchTier, 6);
      expect(card.viGlossProvenance!.baseLemma, 'taca');
      expect(card.viGlossProvenance!.glossSource, 'buuchon');
    });

    test('phase2-draft senses entry (akasiralābhī) has provenance populated', () async {
      final card = await repository.getWordCardDataByLemma('akasiralābhī');
      expect(card, isNotNull);
      expect(card!.viGlossProvenance, isNotNull);
      expect(card.viGlossProvenance!.senseSource, 'phase2-draft');
    });

    test('compound with resolved parts (aṅgajāta) resolves construction breakdown', () async {
      final card = await repository.getWordCardDataByLemma('aṅgajāta');
      expect(card, isNotNull);
      expect(card!.constructionParts, isNotEmpty);
      final parts = card.constructionParts.map((p) => p.part).toList();
      expect(parts, contains('aṅga'));
      expect(parts, contains('jāta'));
      final angaPart = card.constructionParts.firstWhere((p) => p.part == 'aṅga');
      expect(angaPart.viGloss, contains('một bộ phận'));
    });

    test('compound without resolved parts (acirapakkanta) has empty construction breakdown', () async {
      final card = await repository.getWordCardDataByLemma('acirapakkanta');
      expect(card, isNotNull);
      expect(card!.constructionParts, isEmpty);
    });
  });

  group('Data Pack v6 - Curated Glosses Verification on Bundled Lite Pack', () {
    test('entry 53212 (mettā) resolves its display gloss as tâm từ; lòng từ ái from source curated', () async {
      final viGlosses = await repository.batchResolveDisplayGlosses([53212]);
      expect(viGlosses[53212], 'tâm từ; lòng từ ái');

      final card = await repository.getWordCardDataById(53212);
      expect(card, isNotNull);
      expect(card!.viGlossProvenance, isNotNull);
      expect(card.viGlossProvenance!.origin, ViGlossOrigin.senses);
      expect(card.viGlossProvenance!.senseSource, 'curated');
      expect(card.viGlossProvenance!.text, 'tâm từ; lòng từ ái');
    });

    test('entry 16449 (upekkhā) resolves tâm xả; sự quân bình của tâm from source curated', () async {
      final viGlosses = await repository.batchResolveDisplayGlosses([16449]);
      expect(viGlosses[16449], 'tâm xả; sự quân bình của tâm');

      final card = await repository.getWordCardDataById(16449);
      expect(card, isNotNull);
      expect(card!.viGlossProvenance, isNotNull);
      expect(card.viGlossProvenance!.origin, ViGlossOrigin.senses);
      expect(card.viGlossProvenance!.senseSource, 'curated');
      expect(card.viGlossProvenance!.text, 'tâm xả; sự quân bình của tâm');
    });
  });

  group('Data Pack v7 - Pronunciation Verification', () {
    test('entry 53212 (mettā) returns syllables met-tā, vi mết-tā, en met-tah', () async {
      final pronunciation = await repository.getPronunciation(53212);
      expect(pronunciation, isNotNull);
      expect(pronunciation!.syllables, 'met-tā');
      expect(pronunciation.vi, 'mết-tā');
      expect(pronunciation.en, 'met-tah');

      final card = await repository.getWordCardDataById(53212);
      expect(card, isNotNull);
      expect(card!.pronunciation, isNotNull);
      expect(card.pronunciation!.syllables, 'met-tā');
      expect(card.pronunciation!.vi, 'mết-tā');
      expect(card.pronunciation!.en, 'met-tah');
    });

    test('entry 16449 (upekkhā) returns syllables u-pek-khā, vi u-pếch-khā, en u-pek-khah', () async {
      final pronunciation = await repository.getPronunciation(16449);
      expect(pronunciation, isNotNull);
      expect(pronunciation!.syllables, 'u-pek-khā');
      expect(pronunciation.vi, 'u-pếch-khā');
      expect(pronunciation.en, 'u-pek-khah');

      final card = await repository.getWordCardDataById(16449);
      expect(card, isNotNull);
      expect(card!.pronunciation, isNotNull);
      expect(card.pronunciation!.syllables, 'u-pek-khā');
      expect(card.pronunciation!.vi, 'u-pếch-khā');
      expect(card.pronunciation!.en, 'u-pek-khah');
    });

    test('database WITHOUT pronunciation table returns null, no exception', () async {
      final fixtureDbPath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixtureDbPath);
      final fixtureRepo = DictionaryRepository(packManager: PackManager.instance);

      final pronunciation = await fixtureRepo.getPronunciation(29426);
      expect(pronunciation, isNull);

      final card = await fixtureRepo.getWordCardDataByLemma('tata');
      expect(card, isNotNull);
      expect(card!.pronunciation, isNull);

      // Restore active pack
      await PackManager.instance.initialize(directDbPath: dbPath);
    });
  });

  group('Language Separation - Batch Gloss Resolution & Construction Breakdown', () {
    test('batchResolveDisplayGlosses in English returns meaning_1, and in Vietnamese returns Vietnamese gloss (mettā 53212)', () async {
      // English resolution: returns English meaning_1, not 'tâm từ'
      final enGlosses = await repository.batchResolveDisplayGlosses([53212], locale: 'en');
      expect(enGlosses[53212], isNotNull);
      expect(enGlosses[53212], contains('goodwill'));
      expect(enGlosses[53212], isNot(contains('tâm từ')));

      // Vietnamese resolution: returns Vietnamese gloss as before
      final viGlosses = await repository.batchResolveDisplayGlosses([53212], locale: 'vi');
      expect(viGlosses[53212], 'tâm từ; lòng từ ái');

      // Default (meaningLocale = 'vi') returns Vietnamese
      final defaultGlosses = await repository.batchResolveDisplayGlosses([53212]);
      expect(defaultGlosses[53212], 'tâm từ; lòng từ ái');
    });

    test('batchResolveDisplayGlosses for upekkhā (16449) resolves English vs Vietnamese correctly', () async {
      final enGlosses = await repository.batchResolveDisplayGlosses([16449], locale: 'en');
      expect(enGlosses[16449], contains('equanimity'));
      expect(enGlosses[16449], isNot(contains('tâm xả')));

      final viGlosses = await repository.batchResolveDisplayGlosses([16449], locale: 'vi');
      expect(viGlosses[16449], 'tâm xả; sự quân bình của tâm');
    });

    test('construction breakdown resolves each component in English (meaning_1) and Vietnamese (viGloss)', () async {
      final card = await repository.getWordCardDataByLemma('aṅgajāta');
      expect(card, isNotNull);
      expect(card!.constructionParts, isNotEmpty);

      final angaPart = card.constructionParts.firstWhere((p) => p.part == 'aṅga');
      expect(angaPart.viGloss, contains('một bộ phận'));
      expect(angaPart.enGloss, contains('part of the body'));
      expect(angaPart.displayGloss('en'), contains('part of the body'));
      expect(angaPart.displayGloss('vi'), contains('một bộ phận'));
    });
  });
}
