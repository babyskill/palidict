import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:palidict/main.dart';
import 'package:palidict/services/settings_controller.dart';
import 'package:palidict/ui/screens/about/about_screen.dart';
import 'package:palidict/ui/screens/packs/packs_screen.dart';
import 'package:palidict/ui/screens/word_card/word_card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 300),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('pumpUntil timed out after $timeout');
    }
    await tester.pump(step);
  }
  await tester.pump(step);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots flow', (WidgetTester tester) async {
    // Before screenshots on iOS, convertFlutterSurfaceToImage() once per testWidgets,
    // then repump after convert.
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 500));

    const device = String.fromEnvironment('DEVICE', defaultValue: 'iphone');

    for (final lang in ['en', 'vi']) {
      final prefix = '$device-$lang';

      // 1. Language control via real SharedPreferences
      final sp = await SharedPreferences.getInstance();
      await sp.setString('settings_language_code', lang);
      await SettingsController.instance.loadSettings(prefs: sp);

      // Clean state before pumping PaliDictApp
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        PaliDictApp(
          key: ValueKey('app_$lang'),
          settingsController: SettingsController.instance,
          initialTab: 0,
        ),
      );

      // a. Settle until the home screen list appears (pump in a loop up to 15s)
      await pumpUntil(
        tester,
        () => find.byKey(const ValueKey('home_sections_list')).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 15),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('$prefix-1-home');

      // b. Tap the search TextField, enterText 'metta', pump in a loop until a result row for 'mettā' is visible (up to 10s)
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.tap(searchField);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(searchField, 'metta');
      await tester.pump(const Duration(milliseconds: 300));

      await pumpUntil(
        tester,
        () => find.textContaining('mettā').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('$prefix-2-results');

      // c. Tap the result row whose headword is 'mettā' (find by text containing 'mettā' in the results list). Settle.
      final mettaTile = find.widgetWithText(ListTile, 'mettā');
      if (mettaTile.evaluate().isNotEmpty) {
        await tester.tap(mettaTile.first);
      } else {
        final mettaText = find.textContaining('mettā');
        await tester.tap(mettaText.first);
      }
      await tester.pump(const Duration(milliseconds: 300));

      // Settle on WordCardScreen
      await pumpUntil(
        tester,
        () =>
            find.byType(WordCardScreen).evaluate().isNotEmpty &&
            find.descendant(of: find.byType(WordCardScreen), matching: find.byType(CircularProgressIndicator)).evaluate().isEmpty,
        timeout: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('$prefix-3-word-metta');

      // d. Go back (tap the back button in the app bar), then tap the 'Data Packs' (en) / 'Gói dữ liệu' (vi) bottom-nav tab. Settle.
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await pumpUntil(
          tester,
          () => find.byType(WordCardScreen).evaluate().isEmpty,
          timeout: const Duration(seconds: 5),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }

      final packsLabel = lang == 'en' ? 'Data Packs' : 'Gói dữ liệu';
      final packsFinder = find.text(packsLabel);
      if (packsFinder.evaluate().isNotEmpty) {
        await tester.tap(packsFinder.first);
      } else {
        await tester.tap(find.byIcon(Icons.inventory_2_outlined).first);
      }
      await tester.pump(const Duration(milliseconds: 300));

      await pumpUntil(
        tester,
        () => find.byType(PacksScreen).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('$prefix-4-packs');

      // e. Tap the 'About' (en) / 'Giới thiệu' (vi) tab. Settle.
      final aboutLabel = lang == 'en' ? 'About' : 'Giới thiệu';
      final aboutFinder = find.text(aboutLabel);
      if (aboutFinder.evaluate().isNotEmpty) {
        await tester.tap(aboutFinder.first);
      } else {
        await tester.tap(find.byIcon(Icons.info_outline).first);
      }
      await tester.pump(const Duration(milliseconds: 300));

      await pumpUntil(
        tester,
        () => find.byType(AboutScreen).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('$prefix-5-about');
    }
  });
}
