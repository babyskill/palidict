import 'levenshtein.dart';

/// Normalization utilities for Pali search and dictionary lookup.
///
/// Follows DATA_SPEC.md:
/// - Velthuis transliteration: aa, ii, uu, .t, .d, .n, "n, ~n, .m, .l
/// - ASCII fold: lowercase, strip combining marks (Mn), remove whitespace
/// - Lemma cleaning: strip sense numbers from `lemma_1` (e.g. "dhamma 1.03" -> "dhamma")
class PaliNormalization {
  PaliNormalization._();

  /// Converts a Velthuis transliterated string to Unicode Pali characters.
  ///
  /// Examples:
  /// - 'dhammaa' -> 'dhammā'
  /// - 'bhikkhuna.m' -> 'bhikkhunaṃ'
  /// - 'ka"nhaa' -> 'kaṅhā'
  /// - 'pa~n~naa' -> 'paññā'
  /// - 'ti.t.thati' -> 'tiṭṭhati'
  static String velthuisToUnicode(String input) {
    if (input.isEmpty) return '';

    String s = input;

    // Convert Velthuis consonant & vowel pairs
    // Handle uppercase / lowercase pairs
    s = s.replaceAll('"n', 'ṅ');
    s = s.replaceAll('"N', 'Ṅ');
    s = s.replaceAll('~n', 'ñ');
    s = s.replaceAll('~N', 'Ñ');
    s = s.replaceAll('.m', 'ṃ');
    s = s.replaceAll('.M', 'Ṃ');
    s = s.replaceAll('.t', 'ṭ');
    s = s.replaceAll('.T', 'Ṭ');
    s = s.replaceAll('.d', 'ḍ');
    s = s.replaceAll('.D', 'Ḍ');
    s = s.replaceAll('.n', 'ṇ');
    s = s.replaceAll('.N', 'Ṇ');
    s = s.replaceAll('.l', 'ḷ');
    s = s.replaceAll('.L', 'Ḷ');

    // Long vowels
    s = s.replaceAll('aa', 'ā');
    s = s.replaceAll('AA', 'Ā');
    s = s.replaceAll('Aa', 'Ā');
    s = s.replaceAll('ii', 'ī');
    s = s.replaceAll('II', 'Ī');
    s = s.replaceAll('Ii', 'Ī');
    s = s.replaceAll('uu', 'ū');
    s = s.replaceAll('UU', 'Ū');
    s = s.replaceAll('Uu', 'Ū');

    return s;
  }

  /// Folds Unicode Pali characters to ASCII lowercase, stripping combining marks and spaces.
  ///
  /// Matches `meaning_vi.lemma_key`.
  /// Examples:
  /// - 'dhammā' -> 'dhamma'
  /// - 'ānanda' -> 'ananda'
  /// - 'bhikkhunaṃ' -> 'bhikkhunam'
  /// - 'saṅgha' -> 'sangha'
  /// - 'paññā' -> 'panna'
  /// - 'ṭhāna' -> 'thana'
  /// - 'aṅguttara 1' -> 'anguttara1' (if not pre-cleaned)
  static String asciiFold(String input) {
    if (input.isEmpty) return '';

    // Convert Velthuis if present first
    String s = velthuisToUnicode(input).toLowerCase();

    // Remove all whitespace
    s = s.replaceAll(RegExp(r'\s+'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      switch (char) {
        case 'ā':
        case 'a':
          buffer.write('a');
          break;
        case 'ī':
        case 'i':
          buffer.write('i');
          break;
        case 'ū':
        case 'u':
          buffer.write('u');
          break;
        case 'ṭ':
        case 't':
          buffer.write('t');
          break;
        case 'ḍ':
        case 'd':
          buffer.write('d');
          break;
        case 'ṇ':
        case 'ṅ':
        case 'ñ':
        case 'n':
          buffer.write('n');
          break;
        case 'ḷ':
        case 'l':
          buffer.write('l');
          break;
        case 'ṃ':
        case 'm':
          buffer.write('m');
          break;
        default:
          // Check if char is a Unicode combining mark (0x0300 - 0x036F)
          final codeUnit = char.codeUnitAt(0);
          if (codeUnit >= 0x0300 && codeUnit <= 0x036F) {
            // strip combining mark
            continue;
          }
          buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Cleans `lemma_1` to `lemma_clean` by removing trailing sense number suffixes.
  ///
  /// Examples:
  /// - 'dhamma 1.03' -> 'dhamma'
  /// - 'dhamma 2.1' -> 'dhamma'
  /// - 'a 1.1' -> 'a'
  /// - 'abbhuta 1' -> 'abbhuta'
  /// - 'bhikkhu' -> 'bhikkhu'
  static String cleanLemma(String lemma1) {
    return lemma1.replaceFirst(RegExp(r'\s+\d+(\.\d+)*$'), '').trim();
  }

  /// Builds a SQLite GLOB pattern from an ASCII or Unicode search term.
  ///
  /// Matches both plain and diacritic variants.
  /// Example: 'dhamma' -> '[dḍ][h][aā][mṃ][mṃ][aā]*'
  static String toGlobPrefixPattern(String input) {
    final clean = asciiFold(input);
    if (clean.isEmpty) return '*';

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      switch (char) {
        case 'a':
          buffer.write('[aā]');
          break;
        case 'i':
          buffer.write('[iī]');
          break;
        case 'u':
          buffer.write('[uū]');
          break;
        case 't':
          buffer.write('[tṭ]');
          break;
        case 'd':
          buffer.write('[dḍ]');
          break;
        case 'n':
          buffer.write('[nṇñṅ]');
          break;
        case 'l':
          buffer.write('[lḷ]');
          break;
        case 'm':
          buffer.write('[mṃ]');
          break;
        default:
          buffer.write(char);
      }
    }
    buffer.write('*');
    return buffer.toString();
  }

  /// Builds a SQLite GLOB pattern for exact match on lemma_clean.
  ///
  /// Example: 'dhamma' -> '[dḍ][h][aā][mṃ][mṃ][aā]'
  static String toGlobExactPattern(String input) {
    final clean = asciiFold(input);
    if (clean.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      switch (char) {
        case 'a':
          buffer.write('[aā]');
          break;
        case 'i':
          buffer.write('[iī]');
          break;
        case 'u':
          buffer.write('[uū]');
          break;
        case 't':
          buffer.write('[tṭ]');
          break;
        case 'd':
          buffer.write('[dḍ]');
          break;
        case 'n':
          buffer.write('[nṇñṅ]');
          break;
        case 'l':
          buffer.write('[lḷ]');
          break;
        case 'm':
          buffer.write('[mṃ]');
          break;
        default:
          buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Checks if two query representations belong to the same Pali equivalence class.
  static bool areEquivalent(String q1, String q2) {
    return asciiFold(q1) == asciiFold(q2);
  }

  /// Collapses runs of the same consecutive character into a single character.
  ///
  /// Examples:
  /// - 'metta' -> 'meta'
  /// - 'buddha' -> 'budha'
  static String squeezeFolded(String input) {
    if (input.isEmpty) return '';
    final buffer = StringBuffer();
    int? lastCodeUnit;
    for (int i = 0; i < input.length; i++) {
      final codeUnit = input.codeUnitAt(i);
      if (codeUnit != lastCodeUnit) {
        buffer.writeCharCode(codeUnit);
        lastCodeUnit = codeUnit;
      }
    }
    return buffer.toString();
  }

  /// Computes the Levenshtein edit distance between two strings.
  static int levenshtein(String s1, String s2) {
    return levenshteinDistance(s1, s2);
  }
}
