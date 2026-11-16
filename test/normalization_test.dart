import 'package:flutter_test/flutter_test.dart';
import 'package:palidict/core/normalization/pali_normalization.dart';

void main() {
  group('PaliNormalization - Velthuis to Unicode', () {
    test('converts long vowels', () {
      expect(PaliNormalization.velthuisToUnicode('dhammaa'), 'dhammā');
      expect(PaliNormalization.velthuisToUnicode('aasiivo'), 'āsīvo');
      expect(PaliNormalization.velthuisToUnicode('bhuumi'), 'bhūmi');
    });

    test('converts retroflex and nasal consonants', () {
      expect(PaliNormalization.velthuisToUnicode('bhikkhuna.m'), 'bhikkhunaṃ');
      expect(PaliNormalization.velthuisToUnicode('ka"nha'), 'kaṅha');
      expect(PaliNormalization.velthuisToUnicode('pa~n~naa'), 'paññā');
      expect(PaliNormalization.velthuisToUnicode('ti.t.thati'), 'tiṭṭhati');
      expect(PaliNormalization.velthuisToUnicode('a.d.dha'), 'aḍḍha');
      expect(PaliNormalization.velthuisToUnicode('.naa.na'), 'ṇāṇa');
      expect(PaliNormalization.velthuisToUnicode('ve.lu'), 'veḷu');
    });
  });

  group('PaliNormalization - ASCII Fold', () {
    test('folds Pali diacritics to lowercase ASCII', () {
      expect(PaliNormalization.asciiFold('dhammā'), 'dhamma');
      expect(PaliNormalization.asciiFold('ānanda'), 'ananda');
      expect(PaliNormalization.asciiFold('bhikkhunaṃ'), 'bhikkhunam');
      expect(PaliNormalization.asciiFold('saṅgha'), 'sangha');
      expect(PaliNormalization.asciiFold('paññā'), 'panna');
      expect(PaliNormalization.asciiFold('ṭhāna'), 'thana');
      expect(PaliNormalization.asciiFold('aḍḍha'), 'addha');
      expect(PaliNormalization.asciiFold('veḷu'), 'velu');
    });

    test('removes whitespace during fold', () {
      expect(PaliNormalization.asciiFold('  dhamma  1.03 '), 'dhamma1.03');
    });

    test('folds combining characters correctly', () {
      // 'a' followed by combining macron U+0304
      const combinedA = 'a\u0304nanda';
      expect(PaliNormalization.asciiFold(combinedA), 'ananda');
    });
  });

  group('PaliNormalization - Equivalence Classes', () {
    test('plain, diacritic, and Velthuis forms are equivalent', () {
      // dhamma
      expect(PaliNormalization.areEquivalent('dhammā', 'dhamma'), isTrue);
      expect(PaliNormalization.areEquivalent('dhammaa', 'dhammā'), isTrue);
      expect(PaliNormalization.areEquivalent('dhammaa', 'dhamma'), isTrue);

      // bhikkhunaṃ
      expect(PaliNormalization.areEquivalent('bhikkhunaṃ', 'bhikkhunam'), isTrue);
      expect(PaliNormalization.areEquivalent('bhikkhuna.m', 'bhikkhunaṃ'), isTrue);

      // ānanda
      expect(PaliNormalization.areEquivalent('ānanda', 'ananda'), isTrue);
      expect(PaliNormalization.areEquivalent('aananda', 'ānanda'), isTrue);

      // paññā
      expect(PaliNormalization.areEquivalent('paññā', 'panna'), isTrue);
      expect(PaliNormalization.areEquivalent('pa~n~naa', 'paññā'), isTrue);
    });
  });

  group('PaliNormalization - cleanLemma', () {
    test('removes trailing sense numbers', () {
      expect(PaliNormalization.cleanLemma('dhamma 1.03'), 'dhamma');
      expect(PaliNormalization.cleanLemma('dhamma 2.1'), 'dhamma');
      expect(PaliNormalization.cleanLemma('a 1.1'), 'a');
      expect(PaliNormalization.cleanLemma('abbhuta 1'), 'abbhuta');
      expect(PaliNormalization.cleanLemma('bhikkhu'), 'bhikkhu');
      expect(PaliNormalization.cleanLemma('aṅguttara 1'), 'aṅguttara');
    });
  });

  group('PaliNormalization - Glob Patterns', () {
    test('generates prefix pattern', () {
      expect(
        PaliNormalization.toGlobPrefixPattern('dhamma'),
        '[dḍ]h[aā][mṃ][mṃ][aā]*',
      );
    });

    test('generates exact pattern', () {
      expect(
        PaliNormalization.toGlobExactPattern('ananda'),
        '[aā][nṇñṅ][aā][nṇñṅ][dḍ][aā]',
      );
    });
  });

  group('PaliNormalization - Squeeze Folded', () {
    test('collapses runs of consecutive identical characters', () {
      expect(PaliNormalization.squeezeFolded('metta'), 'meta');
      expect(PaliNormalization.squeezeFolded('buddha'), 'budha');
      expect(PaliNormalization.squeezeFolded('aaabbbccc'), 'abc');
      expect(PaliNormalization.squeezeFolded(''), '');
      expect(PaliNormalization.squeezeFolded('a'), 'a');
    });
  });

  group('PaliNormalization - Levenshtein Distance', () {
    test('computes correct edit distance', () {
      expect(PaliNormalization.levenshtein('kitten', 'sitting'), 3);
      expect(PaliNormalization.levenshtein('metta', 'meta'), 1);
      expect(PaliNormalization.levenshtein('budha', 'buddha'), 1);
      expect(PaliNormalization.levenshtein('same', 'same'), 0);
      expect(PaliNormalization.levenshtein('', 'pali'), 4);
      expect(PaliNormalization.levenshtein('pali', ''), 4);
    });
  });
}
