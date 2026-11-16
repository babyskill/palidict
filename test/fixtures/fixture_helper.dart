import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestFixtureHelper {
  static String? _cachedFixturePath;

  static Future<String> getOrCreateNoGlossFixture() async {
    if (_cachedFixturePath != null && File(_cachedFixturePath!).existsSync()) {
      return _cachedFixturePath!;
    }

    final tempDir = Directory.systemTemp.createTempSync('palidict_fixture_');
    final dbPath = p.join(tempDir.path, 'lite_fixture.db');

    final db = await databaseFactoryFfi.openDatabase(dbPath);

    await db.execute('''
      CREATE TABLE headwords ("id" INTEGER PRIMARY KEY, "lemma_1" TEXT, "lemma_2" TEXT, "pos" TEXT, "grammar" TEXT, "meaning_1" TEXT, "meaning_lit" TEXT, "meaning_2" TEXT, "root_key" TEXT, "root_sign" TEXT, "construction" TEXT, "phonetic" TEXT, "source_1" TEXT, "sutta_1" TEXT, "example_1" TEXT, "antonym" TEXT, "synonym" TEXT, "ebt_count" TEXT);
    ''');
    await db.execute('''
      CREATE TABLE lookup (lookup_key TEXT, headwords TEXT, deconstructor TEXT, grammar TEXT);
    ''');
    await db.execute('''
      CREATE TABLE roots ("root" TEXT, "root_in_comps" TEXT, "root_has_verb" TEXT, "root_group" TEXT, "root_sign" TEXT, "root_meaning" TEXT, "sanskrit_root" TEXT, "sanskrit_root_meaning" TEXT, "sanskrit_root_class" TEXT, "root_example" TEXT, "dhatupatha_num" TEXT, "dhatupatha_root" TEXT, "dhatupatha_pali" TEXT, "dhatupatha_english" TEXT, "dhatumanjusa_num" TEXT, "dhatumanjusa_root" TEXT, "dhatumanjusa_pali" TEXT, "dhatumanjusa_english" TEXT, "dhatumala_root" TEXT, "dhatumala_pali" TEXT, "dhatumala_english" TEXT, "panini_root" TEXT, "panini_sanskrit" TEXT, "panini_english" TEXT, "note" TEXT, "matrix_test" TEXT, "root_info" TEXT, "root_matrix" TEXT, "created_at" TEXT, "updated_at" TEXT);
    ''');
    await db.execute('''
      CREATE TABLE meaning_vi (lemma_key TEXT PRIMARY KEY, lemma TEXT, pos TEXT, gloss_main TEXT, gloss_full TEXT, source TEXT);
    ''');
    await db.execute('''
      CREATE TABLE meaning_vi_senses (entry_id INTEGER PRIMARY KEY, vi_gloss TEXT, source TEXT);
    ''');
    await db.execute('''
      CREATE TABLE meaning_vi_entries (
        entry_id INTEGER PRIMARY KEY, lemma TEXT, gloss_main TEXT,
        gloss_full TEXT, source TEXT, match_tier INTEGER,
        base_lemma TEXT, base_entry_id INTEGER, gloss_source TEXT);
    ''');

    // Insert synthetic entries
    // 1. tata (id 29426) - No Vietnamese gloss in entries or senses -> falls back to English meaning_1
    await db.insert('headwords', {
      'id': 29426,
      'lemma_1': 'tata',
      'pos': 'adj',
      'meaning_1': 'spread out; extended; expanded',
      'ebt_count': '0',
    });
    await db.insert('lookup', {
      'lookup_key': 'tata',
      'headwords': '29426',
      'grammar': 'adj',
    });

    // 2. hoti 1 (id 71483) - Has tier 1 Buu Chon entry
    await db.insert('headwords', {
      'id': 71483,
      'lemma_1': 'hoti 1',
      'pos': 'verb',
      'meaning_1': 'is, exists',
      'ebt_count': '0',
    });
    await db.insert('lookup', {
      'lookup_key': 'hoti',
      'headwords': '71483',
      'grammar': 'verb',
    });
    await db.insert('meaning_vi_entries', {
      'entry_id': 71483,
      'lemma': 'Hoti',
      'gloss_main': 'là, có',
      'gloss_full': 'là, có',
      'source': 'buuchon1976',
      'match_tier': 1,
      'gloss_source': 'buuchon1976',
    });

    // 3. taca (id 29236) - Has tier 1 Buu Chon entry
    await db.insert('headwords', {
      'id': 29236,
      'lemma_1': 'taca 1',
      'pos': 'masc',
      'meaning_1': 'skin; bark',
      'ebt_count': '0',
    });
    await db.insert('lookup', {
      'lookup_key': 'taca',
      'headwords': '29236',
      'grammar': 'masc',
    });
    await db.insert('meaning_vi_entries', {
      'entry_id': 29236,
      'lemma': 'taca',
      'gloss_main': 'da, vỏ, da thú',
      'gloss_full': 'da, vỏ, da thú',
      'source': 'buuchon1976',
      'match_tier': 1,
      'gloss_source': 'buuchon1976',
    });

    // 4. tañca (id 29402) - Has senses row
    await db.insert('headwords', {
      'id': 29402,
      'lemma_1': 'tañca',
      'pos': 'pron',
      'meaning_1': 'and that',
      'ebt_count': '0',
    });
    await db.insert('lookup', {
      'lookup_key': 'tañca',
      'headwords': '29402',
      'grammar': 'pron',
    });
    await db.insert('meaning_vi_senses', {
      'entry_id': 29402,
      'vi_gloss': 'và điều đó',
      'source': 'phase1-draft',
    });

    await db.close();
    _cachedFixturePath = dbPath;
    return dbPath;
  }
}
