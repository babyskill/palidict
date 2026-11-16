import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/data/models/home_sections_data.dart';
import 'package:palidict/data/repositories/dictionary_repository.dart';
import 'package:palidict/services/recent_words_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await PackManager.instance.initialize(directDbPath: dbPath);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RecentWordsService.instance.clear();
  });

  group('RecentWordsService Unit Tests', () {
    test('records words newest first, capped at 20, deduplicated by id', () async {
      final service = RecentWordsService.instance;

      // Add 25 items
      for (int i = 1; i <= 25; i++) {
        await service.recordWord(id: i, lemma1: 'lemma $i');
      }

      var recent = await service.getRecentWords();
      expect(recent.length, 20);
      expect(recent.first.id, 25);
      expect(recent.first.lemma1, 'lemma 25');
      expect(recent.last.id, 6); // items 1-5 pushed out

      // Re-add an existing item (id: 10)
      await service.recordWord(id: 10, lemma1: 'lemma 10 updated');
      recent = await service.getRecentWords();
      expect(recent.length, 20);
      expect(recent.first.id, 10);
      expect(recent.first.lemma1, 'lemma 10 updated');

      // Remove an item
      await service.removeWord(10);
      recent = await service.getRecentWords();
      expect(recent.length, 19);
      expect(recent.any((r) => r.id == 10), isFalse);
    });
  });

  group('DictionaryRepository - Home v2 Queries', () {
    final repo = DictionaryRepository();

    test('getGroupedHeadwordsPool returns top 365 scored groups with resolved glosses', () async {
      final pool = await repo.getGroupedHeadwordsPool(limit: 365);
      expect(pool.length, 365);

      // Verify ordering: score DESC, tie-break cleanLemma ASC
      for (int i = 0; i < pool.length - 1; i++) {
        final a = pool[i];
        final b = pool[i + 1];
        if (a.score != b.score) {
          expect(a.score, greaterThan(b.score));
        } else {
          expect(a.cleanLemma.compareTo(b.cleanLemma), lessThanOrEqualTo(0));
        }
      }

      // Verify lead item has cleanLemma, representative id, and resolved gloss
      final top = pool.first;
      expect(top.cleanLemma.isNotEmpty, isTrue);
      expect(top.representativeId, greaterThan(0));
      expect(top.score, greaterThan(0));
      expect(top.resolvedGloss, isNotNull);
    });

    test('getWordOfTheDay is deterministic by calendar day', () async {
      final word1 = await repo.getWordOfTheDay(forDate: DateTime(2026, 11, 14));
      final word2 = await repo.getWordOfTheDay(forDate: DateTime(2026, 11, 14));
      final wordNextDay = await repo.getWordOfTheDay(forDate: DateTime(2026, 11, 15));

      expect(word1, isNotNull);
      expect(word2, isNotNull);
      expect(wordNextDay, isNotNull);

      // Same date returns identical word
      expect(word1!.cleanLemma, word2!.cleanLemma);
      expect(word1.representativeId, word2.representativeId);

      // Different date returns different word
      expect(word1.cleanLemma != wordNextDay!.cleanLemma, isTrue);
    });

    test('getFrequentInDiscourses returns top 24 grouped rows', () async {
      final frequent = await repo.getFrequentInDiscourses(limit: 24);
      expect(frequent.length, 24);

      for (int i = 0; i < frequent.length - 1; i++) {
        expect(frequent[i].score, greaterThanOrEqualTo(frequent[i + 1].score));
      }
    });

    test('getAlphabetIndex follows standard Pali order and counts', () async {
      final alphabet = await repo.getAlphabetIndex();
      expect(alphabet.isNotEmpty, isTrue);

      final letters = alphabet.map((a) => a.letter).toList();

      // Per brief measured data facts: Lite pack has no ū/ḍ/ṇ/ḷ/ṅ/ṃ-initial headwords
      expect(letters.contains('ū'), isFalse);
      expect(letters.contains('ḍ'), isFalse);
      expect(letters.contains('ṇ'), isFalse);
      expect(letters.contains('ḷ'), isFalse);
      expect(letters.contains('ṅ'), isFalse);
      expect(letters.contains('ṃ'), isFalse);

      // Present letters must be in exact Pali ordering
      final expectedPaliOrder = [
        'a', 'ā', 'i', 'ī', 'u', 'e', 'o',
        'k', 'g', 'c', 'j', 'ñ', 'ṭ',
        't', 'd', 'n', 'p', 'b', 'm', 'y', 'r', 'l',
        'v', 's', 'h',
      ];
      expect(letters, expectedPaliOrder);

      // All counts are positive
      for (final item in alphabet) {
        expect(item.count, greaterThan(0));
      }
    });

    test('getHeadwordsByLetter returns lightweight rows ordered by lemma_1', () async {
      final rows = await repo.getHeadwordsByLetter('k');
      expect(rows.length, 330); // 330 k-words in Lite pack

      for (final r in rows) {
        expect(r.lemma1.startsWith('k'), isTrue);
      }

      // Check ordering
      for (int i = 0; i < rows.length - 1; i++) {
        expect(rows[i].lemma1.compareTo(rows[i + 1].lemma1), lessThanOrEqualTo(0));
      }
    });

    test('resolveRecentWord resolves by id, falls back to lemma_1, removes if absent', () async {
      // 1. Resolve by valid id
      final resolved = await repo.resolveRecentWord(
        const RecentWordItem(id: 49885, lemma1: 'bhikkhu'),
      );
      expect(resolved, isNotNull);
      expect(resolved!.lemmaClean, 'bhikkhu');

      // 2. Resolve with invalid id but valid lemma_1 (fallback to exact lemma match)
      final resolvedFallback = await repo.resolveRecentWord(
        const RecentWordItem(id: 9999999, lemma1: 'bhikkhu'),
      );
      expect(resolvedFallback, isNotNull);
      expect(resolvedFallback!.lemmaClean, 'bhikkhu');

      // 3. Resolve completely absent word -> removes from storage and returns null
      await RecentWordsService.instance.recordWord(id: 888888, lemma1: 'nonexistentword123');
      expect((await RecentWordsService.instance.getRecentWords()).any((r) => r.id == 888888), isTrue);

      final absent = await repo.resolveRecentWord(
        const RecentWordItem(id: 888888, lemma1: 'nonexistentword123'),
      );
      expect(absent, isNull);
      expect((await RecentWordsService.instance.getRecentWords()).any((r) => r.id == 888888), isFalse);
    });
  });
}
