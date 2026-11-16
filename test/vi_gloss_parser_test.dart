import 'package:flutter_test/flutter_test.dart';
import 'package:palidict/data/models/vi_gloss_parser.dart';

void main() {
  group('ViGlossParser Unit Tests', () {
    const dhammaGlossMain =
        'giáo lý,thiên nhiên,chân lý,chủ nghĩa,luân lý,hạnh kiểm tốt đẹp';
    const dhammaGlossFull =
        'giáo lý,thiên nhiên,chân lý,chủ nghĩa,luân lý,hạnh kiểm tốt đẹp '
        '--kathā [f] sự nói về đạo đức,luận đạo '
        '--kkhāna [nt] sự thuyết giáo lý '
        '--kathika [3] pháp sư,người thuyết pháp '
        '--kamma [nt] sự hành động hợp pháp,công việc tiến hành đúng theo luật lệ '
        '--karaka [m] cái phích hay vải lọc nước';

    test('parses real dhamma fixture with lead senses and compounds', () {
      final parsed = parseViGloss(dhammaGlossMain, dhammaGlossFull);

      // Lead senses count = 6
      expect(parsed.leadSenses.length, 6);
      expect(parsed.leadSenses, [
        'giáo lý',
        'thiên nhiên',
        'chân lý',
        'chủ nghĩa',
        'luân lý',
        'hạnh kiểm tốt đẹp',
      ]);
      expect(
        parsed.leadParagraph,
        'giáo lý, thiên nhiên, chân lý, chủ nghĩa, luân lý, hạnh kiểm tốt đẹp',
      );

      // Compounds parsed
      expect(parsed.hasCompounds, isTrue);
      expect(parsed.compounds.length, 5);

      // First compound: kathā [f]
      final c0 = parsed.compounds[0];
      expect(c0.lemma, 'kathā');
      expect(c0.pos, 'f');
      expect(c0.gloss, 'sự nói về đạo đức,luận đạo');
      expect(c0.normalizedGloss, 'sự nói về đạo đức, luận đạo');
      expect(c0.isStructured, isTrue);

      // Second compound: kkhāna [nt]
      final c1 = parsed.compounds[1];
      expect(c1.lemma, 'kkhāna');
      expect(c1.pos, 'nt');
      expect(c1.gloss, 'sự thuyết giáo lý');
      expect(c1.normalizedGloss, 'sự thuyết giáo lý');
      expect(c1.isStructured, isTrue);

      // Third compound: kathika [3]
      final c2 = parsed.compounds[2];
      expect(c2.lemma, 'kathika');
      expect(c2.pos, '3');
      expect(c2.gloss, 'pháp sư,người thuyết pháp');
      expect(c2.normalizedGloss, 'pháp sư, người thuyết pháp');
      expect(c2.isStructured, isTrue);

      // Fourth compound: kamma [nt]
      final c3 = parsed.compounds[3];
      expect(c3.lemma, 'kamma');
      expect(c3.pos, 'nt');
      expect(c3.gloss, 'sự hành động hợp pháp,công việc tiến hành đúng theo luật lệ');
      expect(
        c3.normalizedGloss,
        'sự hành động hợp pháp, công việc tiến hành đúng theo luật lệ',
      );
    });

    test('edge case: no compounds (gloss_full == gloss_main)', () {
      const gloss = 'hư không,mây khói';
      final parsed = parseViGloss(gloss, gloss);

      expect(parsed.leadSenses, ['hư không', 'mây khói']);
      expect(parsed.leadParagraph, 'hư không, mây khói');
      expect(parsed.compounds, isEmpty);
      expect(parsed.hasCompounds, isFalse);
    });

    test('edge case: null gloss_full returns no compounds', () {
      final parsed = parseViGloss('giáo lý', null);
      expect(parsed.leadSenses, ['giáo lý']);
      expect(parsed.compounds, isEmpty);
      expect(parsed.hasCompounds, isFalse);
    });

    test('edge case: empty gloss_main with compound tail', () {
      final parsed = parseViGloss('', '--kathā [f] sự nói về đạo đức');

      expect(parsed.leadSenses, isEmpty);
      expect(parsed.leadParagraph, '');
      expect(parsed.compounds.length, 1);
      expect(parsed.compounds[0].lemma, 'kathā');
      expect(parsed.compounds[0].pos, 'f');
      expect(parsed.compounds[0].gloss, 'sự nói về đạo đức');
      expect(parsed.compounds[0].isStructured, isTrue);
    });

    test('edge case: empty gloss_main and empty gloss_full', () {
      final parsed = parseViGloss('', '');
      expect(parsed.leadSenses, isEmpty);
      expect(parsed.leadParagraph, '');
      expect(parsed.compounds, isEmpty);
      expect(parsed.hasCompounds, isFalse);
    });

    test('edge case: malformed segment kept as plain row without crash', () {
      // Starts with bracket (no lemma token)
      final parsed = parseViGloss(
        'chùa chiền',
        'chùa chiền --[adj] thuộc về chùa chiền',
      );
      expect(parsed.leadSenses, ['chùa chiền']);
      expect(parsed.compounds.length, 1);
      final c0 = parsed.compounds[0];
      expect(c0.isStructured, isFalse);
      expect(c0.lemma, isNull);
      expect(c0.rawText, '[adj] thuộc về chùa chiền');

      // Unclosed bracket
      final parsed2 = parseViGloss('từ ngữ', 'từ ngữ --broken [unclosed');
      expect(parsed2.compounds.length, 1);
      expect(parsed2.compounds[0].isStructured, isFalse);
      expect(parsed2.compounds[0].rawText, 'broken [unclosed');
    });

    test('handles compound without pos and without gloss (inflection forms)', () {
      final parsed = parseViGloss('bị đè nén', 'bị đè nén --esi');
      expect(parsed.compounds.length, 1);
      final c0 = parsed.compounds[0];
      expect(c0.lemma, 'esi');
      expect(c0.pos, isNull);
      expect(c0.gloss, isNull);
      expect(c0.isStructured, isTrue);
    });

    test('handles compound without pos but with gloss', () {
      final parsed = parseViGloss(
        'khả năng',
        'khả năng --ṭā sự không thể được,không có khả năng',
      );
      expect(parsed.compounds.length, 1);
      final c0 = parsed.compounds[0];
      expect(c0.lemma, 'ṭā');
      expect(c0.pos, isNull);
      expect(c0.gloss, 'sự không thể được,không có khả năng');
      expect(c0.normalizedGloss, 'sự không thể được, không có khả năng');
      expect(c0.isStructured, isTrue);
    });

    test('handles tail starting with semicolon', () {
      final parsed = parseViGloss(
        'từ từ',
        'từ từ ; --bbena [ad] một cách từ từ --pubbaṭā [f] sự liên tiếp',
      );
      expect(parsed.compounds.length, 2);
      expect(parsed.compounds[0].lemma, 'bbena');
      expect(parsed.compounds[0].pos, 'ad');
      expect(parsed.compounds[0].gloss, 'một cách từ từ');
      expect(parsed.compounds[1].lemma, 'pubbaṭā');
      expect(parsed.compounds[1].pos, 'f');
      expect(parsed.compounds[1].gloss, 'sự liên tiếp');
    });

    test('normalizeCommaSpacing handles various comma patterns', () {
      expect(normalizeCommaSpacing('a,b,c'), 'a, b, c');
      expect(normalizeCommaSpacing('a, b, c'), 'a, b, c');
      expect(normalizeCommaSpacing('a,   b,  c'), 'a, b, c');
      expect(normalizeCommaSpacing('single'), 'single');
    });
  });

  group('ViGlossParser - Display Cleaning Rules (R1 to R6)', () {
    test('R1 Leading derivation drops lemma derivation parentheticals but keeps ordinary Vietnamese', () {
      // Lemma derivation
      expect(cleanBuuChonSegment('(hū+a) là,có,hiện tại'), 'là, có, hiện tại');
      // Cross-reference pattern (<abbrev> của <lemma>)
      expect(cleanBuuChonSegment('(pp của bhamati) sự lung lay'), 'sự lung lay');
      // Ordinary Vietnamese meaning parenthetical preserved
      expect(cleanBuuChonSegment('(ngữ pháp) ngữ căn...'), '(ngữ pháp) ngữ căn...');
      expect(cleanBuuChonSegment('(như chén, ly) vật để uống'), '(như chén, ly) vật để uống');
    });

    test('R2 Leading bracketed POS/gender tag drops [pos] from start', () {
      expect(cleanBuuChonSegment('[nt] cái tách, vật để uống'), 'cái tách, vật để uống');
      expect(cleanBuuChonSegment('[m] người nam'), 'người nam');
      expect(cleanBuuChonSegment('[adj] trong sạch, thanh tịnh'), 'trong sạch, thanh tịnh');
    });

    test('R3 Trailing verb-form lists cut from first bracketed verb form if meaning text precedes', () {
      expect(
        cleanBuuChonSegment('là, có, hiện tại [aor] ahosi [prp] honta [ptp] hotabba [inf] hotum'),
        'là, có, hiện tại',
      );
      // Segment with only verb form preserves text so as not to empty it
      expect(cleanBuuChonSegment('[aor] ahosi'), '[aor] ahosi');
    });

    test('R4 English leftovers drop fixed lead prefixes', () {
      expect(cleanBuuChonSegment('copulative particle và,với,vậy thì'), 'và, với, vậy thì');
      expect(cleanBuuChonSegment('dem pron cái đó (so nó)'), 'cái đó (so nó)');
    });

    test('R5 Parenthesis balance merges unbalanced segments across -- boundary', () {
      final parsed = parseViGloss(
        'dem pron cái đó (so nó; sā cô đó; taṃ cái đó',
        'dem pron cái đó (so nó; sā cô đó; taṃ cái đó --đây là vài biến thể của từ này)',
      );
      expect(
        parsed.leadParagraph,
        'cái đó (so nó; sā cô đó; taṃ cái đó — đây là vài biến thể của từ này)',
      );
      expect(parsed.compounds, isEmpty);
    });

    test('R6 Separator normalization standardizes commas and semicolons', () {
      expect(normalizeSeparators('a,b;c,d; e'), 'a, b; c, d; e');
      expect(
        cleanBuuChonSegment('[nt] cái tách,vật để uống (như chén,ly),cái bao,vỏ nhỏ'),
        'cái tách, vật để uống (như chén, ly), cái bao, vỏ nhỏ',
      );
    });

    test('Compound rows drop standalone POS abbreviation token after compound lemma', () {
      final parsed = parseViGloss(
        'tatāyati làm nghe tiếng tách tách [aor]',
        'tatāyati làm nghe tiếng tách tách [aor] --āyi prp taṭalaṭāyamāna',
      );
      expect(parsed.compounds.length, 1);
      final c0 = parsed.compounds[0];
      expect(c0.lemma, 'āyi');
      expect(c0.pos, isNull);
      expect(c0.gloss, 'taṭalaṭāyamāna');
      expect(c0.normalizedGloss, 'taṭalaṭāyamāna');
    });
  });

  group('ViGlossParser - Mandatory Fixtures from Brief', () {
    test('Fixture 1: hoti gloss_main cleans leading derivation and trailing verb forms', () {
      final parsed = parseViGloss(
        '(hū+a) là,có,hiện tại [aor] ahosi [prp] honta [ptp] hotabba [inf] hotum',
        null,
      );
      expect(parsed.leadParagraph, 'là, có, hiện tại');
    });

    test('Fixture 2: ca gloss_main cleans copulative particle English leftover', () {
      final parsed = parseViGloss(
        'copulative particle và,với,vậy thì',
        null,
      );
      expect(parsed.leadParagraph, 'và, với, vậy thì');
    });

    test('Fixture 3: ta gloss_full cleans dem pron and balances parenthesis into single segment', () {
      final parsed = parseViGloss(
        'dem pron cái đó (so nó; sā cô đó; taṃ cái đó',
        'dem pron cái đó (so nó; sā cô đó; taṃ cái đó --đây là vài biến thể của từ này)',
      );
      expect(
        parsed.leadParagraph,
        'cái đó (so nó; sā cô đó; taṃ cái đó — đây là vài biến thể của từ này)',
      );
      expect(parsed.compounds, isEmpty);
    });

    test('Fixture 4: kosaka gloss_main cleans [nt] and normalizes separators preserving nested parens', () {
      final parsed = parseViGloss(
        '[nt] cái tách,vật để uống (như chén,ly),cái bao,vỏ nhỏ',
        null,
      );
      expect(
        parsed.leadParagraph,
        'cái tách, vật để uống (như chén, ly), cái bao, vỏ nhỏ',
      );
    });

    test('Fixture 5: A gloss with no noise stays byte-identical', () {
      const cleanGloss = 'giáo lý, thiên nhiên, chân lý, chủ nghĩa';
      final parsed = parseViGloss(cleanGloss, null);
      expect(parsed.leadParagraph, cleanGloss);
    });
  });
}
