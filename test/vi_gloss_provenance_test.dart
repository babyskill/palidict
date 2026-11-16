import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:palidict/data/models/vi_gloss_provenance.dart';
import 'package:palidict/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10nVi;
  late AppLocalizations l10nEn;

  setUpAll(() {
    l10nVi = lookupAppLocalizations(const Locale('vi'));
    l10nEn = lookupAppLocalizations(const Locale('en'));
  });

  group('Part 3 & 7 - ViGlossProvenance Labels', () {
    test('(a) label choice for a tier-3 entry with base_lemma', () {
      final prov = ViGlossProvenance.fromEntry(
        text: 'đi, dời đi',
        matchTier: 3,
        baseLemma: 'gacchati',
        glossSource: 'buuchon',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Kế thừa từ 'gacchati'", "HT Bửu Chơn (1976)"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["Inherited from 'gacchati'", "HT Buu Chon (1976)"]));
    });

    test('(a-variant) label choice for a tier-3 entry without base_lemma (generic inheritance)', () {
      final prov = ViGlossProvenance.fromEntry(
        text: 'từ aṭṭha',
        matchTier: 3,
        baseLemma: null,
        glossSource: 'buuchon',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Kế thừa từ từ gốc", "HT Bửu Chơn (1976)"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["Inherited from the base word", "HT Buu Chon (1976)"]));
    });

    test('(a-variant) label choice for inherited entry with gloss_source = senses', () {
      final prov = ViGlossProvenance.fromEntry(
        text: 'đã nghe',
        matchTier: 5,
        baseLemma: 'assosi',
        glossSource: 'senses',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Kế thừa từ 'assosi'", "Bản dịch mới — đang hiệu đính"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["Inherited from 'assosi'", "New translation — under review"]));
    });

    test('(b) label choice for a tier-6 entry', () {
      final prov = ViGlossProvenance.fromEntry(
        text: 'da, vỏ, da thú',
        matchTier: 6,
        baseLemma: 'taca',
        glossSource: 'buuchon',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Kế thừa từ 'taca'", "HT Bửu Chơn (1976)"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["Inherited from 'taca'", "HT Buu Chon (1976)"]));
    });

    test('curated senses show the curated label', () {
      final prov = ViGlossProvenance.fromSense(
        text: 'tâm từ; lòng từ ái',
        source: 'curated',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Đã hiệu đính"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["Reviewed"]));
    });

    test('(c) phase2-draft senses show the draft label', () {
      final prov = ViGlossProvenance.fromSense(
        text: 'người đạt được không khó khăn',
        source: 'phase2-draft',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Bản dịch mới — đang hiệu đính"]));

      final labelsEn = prov.getLabels(l10nEn);
      expect(labelsEn, equals(["New translation — under review"]));
    });

    test('phase1-draft senses also show the draft label', () {
      final prov = ViGlossProvenance.fromSense(
        text: 'và điều đó',
        source: 'phase1-draft',
      );

      final labelsVi = prov.getLabels(l10nVi);
      expect(labelsVi, equals(["Bản dịch mới — đang hiệu đính"]));
    });

    test('entries with match_tier 1, 2, or 4 show existing Buu Chon label exactly as today', () {
      for (final tier in [1, 2, 4]) {
        final prov = ViGlossProvenance.fromEntry(
          text: 'giáo lý',
          matchTier: tier,
          glossSource: 'buuchon',
        );

        final labelsVi = prov.getLabels(l10nVi);
        expect(labelsVi, equals(["HT Bửu Chơn (1976)"]));

        final labelsEn = prov.getLabels(l10nEn);
        expect(labelsEn, equals(["HT Buu Chon (1976)"]));
      }
    });
  });
}
