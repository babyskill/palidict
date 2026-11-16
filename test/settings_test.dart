import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palidict/core/theme/app_theme.dart';
import 'package:palidict/l10n/app_localizations.dart';
import 'package:palidict/services/settings_controller.dart';
import 'package:palidict/ui/screens/search/search_screen.dart';
import 'package:palidict/ui/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults are Light theme and Vietnamese locale', () async {
      final controller = SettingsController();
      await controller.loadSettings();

      expect(controller.themeMode, equals(ThemeMode.light));
      expect(controller.locale, equals(const Locale('vi')));
      expect(controller.isLoaded, isTrue);
    });

    test('choosing Dark persists and a fresh controller restores Dark', () async {
      SharedPreferences.setMockInitialValues({});
      final controller1 = SettingsController();
      await controller1.loadSettings();

      bool notified = false;
      controller1.addListener(() {
        notified = true;
      });

      await controller1.updateThemeMode(ThemeMode.dark);
      expect(controller1.themeMode, equals(ThemeMode.dark));
      expect(notified, isTrue);

      // Verify persistence in SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsController.prefKeyThemeMode), equals('dark'));

      // Fresh controller restoring the value
      final controller2 = SettingsController(prefs: prefs);
      await controller2.loadSettings();
      expect(controller2.themeMode, equals(ThemeMode.dark));
    });

    test('choosing English persists and restores', () async {
      SharedPreferences.setMockInitialValues({});
      final controller1 = SettingsController();
      await controller1.loadSettings();

      await controller1.updateLocale(const Locale('en'));
      expect(controller1.locale, equals(const Locale('en')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsController.prefKeyLanguageCode), equals('en'));

      final controller2 = SettingsController(prefs: prefs);
      await controller2.loadSettings();
      expect(controller2.locale, equals(const Locale('en')));
    });

    test('themeMode mapping (system -> ThemeMode.system, light -> ThemeMode.light)', () async {
      SharedPreferences.setMockInitialValues({
        SettingsController.prefKeyThemeMode: 'system',
      });
      final controller = SettingsController();
      await controller.loadSettings();
      expect(controller.themeMode, equals(ThemeMode.system));

      await controller.updateThemeMode(ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsController.prefKeyThemeMode), equals('light'));

      // Unknown string fallback
      await prefs.setString(SettingsController.prefKeyThemeMode, 'unknown_val');
      final fallbackController = SettingsController(prefs: prefs);
      await fallbackController.loadSettings();
      expect(fallbackController.themeMode, equals(ThemeMode.light));
    });

    test('locale mapping fallback to vi for unknown string', () async {
      SharedPreferences.setMockInitialValues({
        SettingsController.prefKeyLanguageCode: 'fr',
      });
      final controller = SettingsController();
      await controller.loadSettings();
      expect(controller.locale, equals(const Locale('vi')));
    });

    test('English and Vietnamese appTitle and window title match specifications', () {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nVi = lookupAppLocalizations(const Locale('vi'));

      expect(l10nEn.appTitle, equals('Pāḷi Dictionary'));
      expect(l10nEn.aboutAppSubtitle, equals('Offline Pāḷi Dictionary'));
      expect(WindowTitleService.enTitle, equals('Pāḷi Dictionary - giacngo.org'));

      expect(l10nVi.appTitle, equals('Từ điển Pāḷi - Việt'));
      expect(l10nVi.aboutAppSubtitle, equals('Từ điển Pāḷi - Việt ngoại tuyến'));
      expect(WindowTitleService.viTitle, equals('Từ điển Pāḷi - Việt - giacngo.org'));
    });
  });

  group('SettingsScreen Widget Tests', () {
    late SettingsController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = SettingsController();
    });

    Widget buildTestApp({required Locale locale, required SettingsController ctrl}) {
      return MaterialApp(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ctrl.themeMode,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(controller: ctrl),
      );
    }

    testWidgets('renders both sections with all radio options in Vietnamese', (tester) async {
      await controller.loadSettings();
      await tester.pumpWidget(buildTestApp(locale: const Locale('vi'), ctrl: controller));
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('Cài đặt'), findsOneWidget);

      // Section 1: Appearance
      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
      expect(find.text('Theo hệ thống'), findsOneWidget);

      // Section 2: Language
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('renders both sections with all radio options in English', (tester) async {
      await controller.loadSettings();
      await controller.updateLocale(const Locale('en'));
      await tester.pumpWidget(buildTestApp(locale: const Locale('en'), ctrl: controller));
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('Settings'), findsOneWidget);

      // Section 1: Appearance
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);

      // Section 2: Language
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Vietnamese'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('tapping dark theme radio updates controller immediately', (tester) async {
      await controller.loadSettings();
      await tester.pumpWidget(buildTestApp(locale: const Locale('vi'), ctrl: controller));
      await tester.pumpAndSettle();

      expect(controller.themeMode, equals(ThemeMode.light));

      // Tap "Tối"
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('tapping English language radio updates controller immediately', (tester) async {
      await controller.loadSettings();
      await tester.pumpWidget(buildTestApp(locale: const Locale('vi'), ctrl: controller));
      await tester.pumpAndSettle();

      expect(controller.locale, equals(const Locale('vi')));

      // Tap "English"
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(controller.locale, equals(const Locale('en')));
    });
  });

  group('SearchScreen Settings Gear Integration', () {
    testWidgets('gear icon exists on search screen and opens SettingsScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController();
      await controller.loadSettings();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchScreen(),
      ));
      await tester.pump();

      // Find the settings icon
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);

      // Tap settings icon
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Settings screen should be open
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Back on search screen
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
