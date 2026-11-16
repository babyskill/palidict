import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/core/constants/app_constants.dart';
import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/l10n/app_localizations.dart';
import 'package:palidict/main.dart';
import 'package:palidict/ui/screens/about/about_screen.dart';
import 'package:palidict/ui/screens/word_card/widgets/vi_compound_row.dart';
import 'package:palidict/data/repositories/dictionary_repository.dart';
import 'package:palidict/ui/screens/word_card/word_card_screen.dart';
import 'package:palidict/services/recent_words_service.dart';
import 'package:palidict/ui/screens/packs/packs_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/fixture_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await PackManager.instance.initialize(directDbPath: dbPath);
    await DictionaryRepository().getGroupedHeadwordsPool();
    await DictionaryRepository().getAlphabetIndex();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecentWordsService.instance = RecentWordsService();
  });

  testWidgets('App renders navigation bar and search bar in Vietnamese', (tester) async {
    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pump();

    // Verify app title & all 4 navigation items in Vietnamese
    expect(find.text('Từ điển Pāḷi - Việt'), findsOneWidget);
    expect(find.text('Tra cứu'), findsOneWidget);
    expect(find.text('Gói dữ liệu'), findsOneWidget);
    expect(find.text('Giới thiệu'), findsOneWidget);
    expect(find.text('Cùng Tu'), findsWidgets); // Nav label and possible references

    // Verify search text field
    expect(find.byType(TextField), findsOneWidget);

    // Switch to Packs tab
    await tester.tap(find.text('Gói dữ liệu'));
    await tester.pump();
    expect(find.text('Gói Tinh gọn (Lite pack)'), findsOneWidget);

    // Switch to About tab
    await tester.tap(find.text('Giới thiệu'));
    await tester.pump();
    expect(find.text('Digital Pali Dictionary (DPD)'), findsOneWidget);

    // Switch to Cùng Tu tab
    await tester.tap(find.text('Cùng Tu').first);
    await tester.pump();
    expect(find.text('Ứng dụng Cùng Tu'), findsOneWidget);
  });

  testWidgets('Cung Tu tab renders title, features, and primary action', (tester) async {
    // Assert cungTuWebUrl constant
    expect(AppConstants.cungTuWebUrl, 'https://app.giacngo.org');

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pump();

    // Tap on Cùng Tu navigation tab
    await tester.tap(find.text('Cùng Tu').first);
    await tester.pump();

    // Verify header and title
    expect(find.text('Ứng dụng Cùng Tu'), findsOneWidget);
    expect(find.text('Nghe Kinh Phật — Nghe & Đọc Trọn 5 Bộ Kinh Nikāya'), findsOneWidget);
    expect(find.text('Hệ sinh thái Giác Ngộ'), findsOneWidget);

    // Verify description
    expect(
      find.text(
        'Cùng Tu là ứng dụng nghe và đọc Kinh Phật Nikāya: hơn 750 bài kinh với 388 giờ giọng đọc miền Nam, đọc song ngữ Pāḷi–Việt theo bản dịch của HT Thích Minh Châu. Cùng Tu và từ điển này cùng thuộc một dự án cộng đồng phi thương mại.',
      ),
      findsOneWidget,
    );

    // Verify 4 feature bullets
    expect(
      find.text('Nghe trọn 5 bộ Kinh Nikāya — hơn 750 bài, 388 giờ giọng đọc miền Nam'),
      findsOneWidget,
    );
    expect(
      find.text('Đọc song ngữ Pāḷi–Việt — bản dịch HT Thích Minh Châu'),
      findsOneWidget,
    );
    expect(find.text('Tải về nghe offline, không cần mạng'), findsOneWidget);
    expect(find.text('Hoàn toàn miễn phí, không quảng cáo'), findsOneWidget);

    // Scroll down to reveal cross-reference note and action button
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    // Verify cross reference note (unchanged)
    expect(find.text('Đồng hành tu học'), findsOneWidget);
    expect(
      find.text('Tra nghĩa tại đây để hiểu rõ hơn các bài tụng kinh và bài học Pāḷi trong Cùng Tu. Hai ứng dụng hoạt động độc lập và không đồng bộ dữ liệu với nhau — chỉ cùng chung một dự án cộng đồng.'),
      findsOneWidget,
    );

    // Verify primary action button
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    expect(find.text('Tìm hiểu & tải app Cùng Tu'), findsOneWidget);

    // Verify old strings do not appear
    expect(find.text('Sắp có mặt trên App Store'), findsNothing);
    expect(find.text('Mở trên Google Play'), findsNothing);
    expect(find.text('Mở trên App Store'), findsNothing);
  });

  testWidgets('Cung Tu tab shows single web action button across platforms including iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
      await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
      await tester.pump();

      await tester.tap(find.text('Cùng Tu').first);
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      // Single primary CTA button is shown on iOS
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.text('Tìm hiểu & tải app Cùng Tu'), findsOneWidget);

      // Old iOS coming-soon notice and old store buttons do not appear
      expect(find.text('Sắp có mặt trên App Store'), findsNothing);
      expect(find.text('Mở trên Google Play'), findsNothing);
      expect(find.text('Mở trên App Store'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Desktop layout (1280x800) renders NavigationRail, master-detail panes, and updates word card on suggestion selection', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    // 1. NavigationRail is shown on desktop, bottom NavigationBar is NOT
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // 2. Both master–detail panes are visible:
    // Left pane has search field and Home v2 sections
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Từ của ngày'), findsOneWidget);
    expect(find.text('Hay gặp trong kinh'), findsOneWidget);

    // Right pane has the empty-state hint before any selection
    expect(
      find.text('Chọn một từ ở cột bên trái hoặc nhập từ để tra cứu'),
      findsOneWidget,
    );

    // 3. Enter search query to display suggestions
    await tester.enterText(find.byType(TextField), 'dhamma');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Suggestions list appears in left pane
    expect(find.byType(ListTile), findsWidgets);

    // 4. Select a suggestion - fills the right pane without route push
    await tester.tap(find.widgetWithText(ListTile, 'dhamma').first);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Right pane now displays the word card with Vietnamese meaning & audio button
    expect(find.text('HT Bửu Chơn (1976)'), findsOneWidget);
    expect(find.text('Chọn một từ ở cột bên trái hoặc nhập từ để tra cứu'), findsNothing);

    // Left pane search field and NavigationRail are STILL visible (master-detail layout)
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 5. Test Escape key clears search field
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Từ của ngày'), findsOneWidget);

    // 6. Test Enter key opens top suggestion
    await tester.enterText(find.byType(TextField), 'bhikkhu');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(find.text('HT Bửu Chơn (1976)'), findsOneWidget);

    // 7. Verify all other tabs render with no overflow at 1280x800
    // Packs tab
    await tester.tap(find.text('Gói dữ liệu'));
    await tester.pumpAndSettle();
    expect(find.text('Gói Tinh gọn (Lite pack)'), findsOneWidget);

    // About tab
    await tester.tap(find.text('Giới thiệu'));
    await tester.pumpAndSettle();
    expect(find.text('Digital Pali Dictionary (DPD)'), findsOneWidget);

    // Cùng Tu tab
    await tester.tap(find.text('Cùng Tu').first);
    await tester.pumpAndSettle();
    expect(find.text('Ứng dụng Cùng Tu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop layout at 1920x1080 renders all tabs with no overflow', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Chọn một từ ở cột bên trái hoặc nhập từ để tra cứu'), findsOneWidget);

    // Test Packs tab
    await tester.tap(find.text('Gói dữ liệu'));
    await tester.pumpAndSettle();
    expect(find.text('Gói Tinh gọn (Lite pack)'), findsOneWidget);

    // Test About tab
    await tester.tap(find.text('Giới thiệu'));
    await tester.pumpAndSettle();
    expect(find.text('Digital Pali Dictionary (DPD)'), findsOneWidget);

    // Test Cùng Tu tab
    await tester.tap(find.text('Cùng Tu').first);
    await tester.pumpAndSettle();
    expect(find.text('Ứng dụng Cùng Tu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dhamma word card shows Vietnamese lead paragraph once and renders compounds as separate rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'dhamma')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 1. Vietnamese meaning section header & source badge
    expect(find.text('Nghĩa tiếng Việt'), findsOneWidget);
    expect(find.text('HT Bửu Chơn (1976)'), findsOneWidget);

    // 2. Lead senses paragraph is displayed once only (joined with ', ')
    const expectedLeadParagraph =
        'giáo lý, thiên nhiên, chân lý, chủ nghĩa, luân lý, hạnh kiểm tốt đẹp';
    expect(find.text(expectedLeadParagraph), findsOneWidget);

    // 3. The old raw crammed blob with '--kathā' inline in gloss_full is NOT present
    expect(find.textContaining('giáo lý,thiên nhiên'), findsNothing);

    // 4. Compounds are rendered as separate ViCompoundRow widgets
    expect(find.byType(ViCompoundRow), findsWidgets);

    // Verify first compound entries
    expect(find.textContaining('–kathā'), findsOneWidget);
    expect(find.text('f'), findsWidgets);
    expect(find.textContaining('sự nói về đạo đức'), findsOneWidget);

    expect(find.textContaining('–kkhāna'), findsOneWidget);
    expect(find.text('nt'), findsWidgets);
    expect(find.textContaining('sự thuyết giáo lý'), findsOneWidget);

    expect(find.textContaining('–kathika'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.textContaining('pháp sư, người thuyết pháp'), findsOneWidget);
  });

  testWidgets('Word card without compounds (adhamma) shows only lead paragraph and no compound rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'adhamma')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Lead paragraph shown once
    expect(find.text('hạ tiện, thấp hèn, bực trung, bần cùng'), findsOneWidget);

    // No compound rows rendered
    expect(find.byType(ViCompoundRow), findsNothing);
  });

  testWidgets('Word card: entry with no Vietnamese gloss (tata) renders framed English block with heading + pending note', (tester) async {
    final prodDbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    addTearDown(() async {
      await PackManager.instance.initialize(directDbPath: prodDbPath);
    });
    await tester.runAsync(() async {
      final fixturePath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixturePath);
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'tata')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 1. Vietnamese meaning section card is NOT shown
    expect(find.text('Nghĩa tiếng Việt'), findsNothing);

    // 2. Framed English meaning block
    expect(find.text('Nghĩa tiếng Anh (DPD)'), findsOneWidget);
    expect(find.text('spread out; extended; expanded'), findsOneWidget);
    expect(find.text('Nghĩa tiếng Việt đang được bổ sung.'), findsOneWidget);

    await tester.runAsync(() async {
      await PackManager.instance.initialize(directDbPath: prodDbPath);
    });
  });

  testWidgets('Word card: compound with resolved parts (aṅgajāta) renders construction breakdown, and acirapakkanta does not', (tester) async {
    // 1. Compound whose parts resolve (aṅgajāta)
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'aṅgajāta')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('Nghĩa theo cấu tạo', skipOffstage: false), findsOneWidget);
    expect(find.text('aṅga', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('một bộ phận', skipOffstage: false), findsOneWidget);
    expect(find.text('jāta', skipOffstage: false), findsOneWidget);

    // 2. Compound whose parts do not resolve to Vietnamese (acirapakkanta)
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'acirapakkanta')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('Nghĩa theo cấu tạo'), findsNothing);
  });

  testWidgets('Word card: tier-3 entry (agamāsi) shows inheritedFrom and sourceBuuChon labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'agamāsi')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text("Kế thừa từ 'gacchati'"), findsOneWidget);
    expect(find.text('HT Bửu Chơn (1976)'), findsOneWidget);
  });

  testWidgets('About screen renders Author card with author name, intro, and links', (tester) async {
    // Assert author URL & text constants
    expect(AppConstants.authorWebsiteUrl, 'https://giacngo.org');
    expect(AppConstants.authorFacebookUrl, 'https://www.facebook.com/kiinl');
    expect(AppConstants.authorWebsiteText, 'giacngo.org');
    expect(AppConstants.authorFacebookText, 'facebook.com/kiinl');

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial card is rendered
    expect(find.text('Digital Pali Dictionary (DPD)'), findsOneWidget);

    // Scroll to reveal the author card at the end of the list
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // 1. Author card title
    expect(find.text('Tác giả'), findsOneWidget);

    // 2. Author intro containing Kiên Lê
    expect(find.textContaining('Kiên Lê'), findsOneWidget);
    expect(
      find.text('Ứng dụng do Kiên Lê phát triển, một thiện pháp hỗ trợ cộng đồng tu học.'),
      findsOneWidget,
    );

    // 3. Link rows: labels and visible link texts
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('giacngo.org'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('facebook.com/kiinl'), findsOneWidget);

    // 4. Icon person_outline is present on the card
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('About screen renders English appTitle and aboutAppSubtitle in en locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pāḷi Dictionary'), findsOneWidget);
    expect(find.text('Offline Pāḷi Dictionary'), findsOneWidget);
  });

  testWidgets('Home v2: sections render when query is empty (Word of the Day card, Frequent rows, letter tiles)', (tester) async {
    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    // 1. Word of the Day section header & card
    expect(find.text('Từ của ngày'), findsOneWidget);

    // 2. Frequent in the Discourses section header
    expect(find.text('Hay gặp trong kinh'), findsOneWidget);

    // 3. Scroll down until Alphabet Index is visible
    final scrollable = tester.state<ScrollableState>(find.descendant(
      of: find.byKey(const ValueKey('home_sections_list')),
      matching: find.byType(Scrollable),
    ));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(find.text('Mục lục chữ cái'), findsOneWidget);
    // Letter tiles exist
    expect(find.byKey(const ValueKey('letter_tile_a')), findsOneWidget);
    expect(find.byKey(const ValueKey('letter_tile_k')), findsOneWidget);
  });

  testWidgets('Home v2: tapping a Frequent row opens its word card', (tester) async {
    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    // Find first tile in the Frequent section
    expect(find.text('Hay gặp trong kinh'), findsOneWidget);
    final frequentTile = find.byType(ListTile).first;
    await tester.tap(frequentTile);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // WordCardScreen is open
    expect(find.byType(WordCardScreen), findsOneWidget);
  });

  testWidgets('Home v2: tapping a letter lists words and tapping one opens its card', (tester) async {
    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    // Scroll until Alphabet section is visible
    final scrollable = tester.state<ScrollableState>(find.descendant(
      of: find.byKey(const ValueKey('home_sections_list')),
      matching: find.byType(Scrollable),
    ));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final letterTile = find.byKey(const ValueKey('letter_tile_a'));
    await tester.ensureVisible(letterTile);
    await tester.pumpAndSettle();

    // Tap letter tile 'a'
    await tester.tap(letterTile);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Screen title shows words starting with 'a'
    expect(find.text('Từ bắt đầu bằng "a"'), findsOneWidget);

    // Tap first word row in the letter list
    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // WordCardScreen is open
    expect(find.byType(WordCardScreen), findsOneWidget);
  });

  testWidgets('Home v2: after opening a word and returning, Recent shows it', (tester) async {
    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.pumpWidget(PaliDictApp(overrideDbPath: dbPath));
    await tester.pumpAndSettle();

    // Initially Recent section is not shown (empty)
    expect(find.text('Gần đây'), findsNothing);

    // Search and open 'dhamma'
    await tester.enterText(find.byType(TextField), 'dhamma');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    await tester.tap(find.widgetWithText(ListTile, 'dhamma').first);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.byType(WordCardScreen), findsOneWidget);

    // Return to Search / Home
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Clear search text field
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // Scroll down to find Recent section
    final scrollable = tester.state<ScrollableState>(find.descendant(
      of: find.byKey(const ValueKey('home_sections_list')),
      matching: find.byType(Scrollable),
    ));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    // Recent section is now visible and contains dhamma
    expect(find.text('Gần đây'), findsOneWidget);
    expect(find.textContaining('dhamma'), findsWidgets);
  });

  testWidgets('Search suggestions display Vietnamese subtitle for Buu Chon (taca) and senses (tañca), fallback English for tata', (tester) async {
    final prodDbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    addTearDown(() async {
      await PackManager.instance.initialize(directDbPath: prodDbPath);
    });
    late String fixturePath;
    await tester.runAsync(() async {
      fixturePath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixturePath);
    });
    await tester.pumpWidget(PaliDictApp(overrideDbPath: fixturePath));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 1. Search 'taca' -> subtitle contains Vietnamese 'da, vỏ, da thú'
    await tester.enterText(find.byType(TextField), 'taca');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'taca'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'taca'),
        matching: find.textContaining('da, vỏ, da thú'),
      ),
      findsOneWidget,
    );

    // 2. Search 'tañca' -> subtitle contains Vietnamese 'và điều đó'
    await tester.enterText(find.byType(TextField), 'tañca');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'tañca'), findsOneWidget);
    expect(find.text('và điều đó'), findsOneWidget);

    // 3. Search 'tata' -> subtitle falls back to English 'spread out; extended; expanded'
    await tester.enterText(find.byType(TextField), 'tata');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'tata'), findsOneWidget);
    expect(find.text('spread out; extended; expanded'), findsOneWidget);

    await tester.runAsync(() async {
      await PackManager.instance.initialize(directDbPath: prodDbPath);
    });
  });

  testWidgets('Word-card Vietnamese header with two long badges at Size(360, 800), text scale 1.0 and 1.3 completes with no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    // 1. Scale 1.0
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'abhibhuyya')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nghĩa tiếng Việt', skipOffstage: false), findsOneWidget);
    expect(find.text("Kế thừa từ 'abhibhavati'", skipOffstage: false), findsOneWidget);

    // 2. Scale 1.3
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'abhibhuyya')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nghĩa tiếng Việt', skipOffstage: false), findsOneWidget);
    expect(find.text("Kế thừa từ 'abhibhavati'", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Packs Lite card header at Size(360, 800), text scale 1.3 completes with no overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: PacksScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Gói Tinh gọn (Lite pack)'), findsOneWidget);
    expect(find.textContaining('Bundled'), findsOneWidget);
  });

  testWidgets('Word card with reading in Vietnamese locale shows label, syllable split, vi reading, and note', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'mettā')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Cách đọc'), findsOneWidget);
    expect(find.text('met-tā'), findsOneWidget);
    expect(find.text('mết-tā'), findsOneWidget);
    expect(
      find.text('Cách đọc gần đúng. Dấu ngang (ā, ī, ū) nghĩa là đọc kéo dài. Nghe phát âm để có âm chuẩn.'),
      findsOneWidget,
    );
  });

  testWidgets('Word card with reading in English locale shows label, syllable split, en reading, and note', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'mettā')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Pronunciation'), findsOneWidget);
    expect(find.text('met-tā'), findsOneWidget);
    expect(find.text('met-tah'), findsOneWidget);
    expect(
      find.text('Approximate reading. A long mark (ā, ī, ū) means hold the vowel longer. Listen to the audio for the exact sound.'),
      findsOneWidget,
    );
  });

  testWidgets('Word card without reading shows no pronunciation block', (tester) async {
    final defaultDbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.runAsync(() async {
      final fixtureDbPath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixtureDbPath);
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'tata')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Cách đọc'), findsNothing);
    expect(find.text('Pronunciation'), findsNothing);
    expect(find.byIcon(Icons.record_voice_over_outlined), findsNothing);

    // Restore active pack
    await tester.runAsync(() async {
      await PackManager.instance.initialize(directDbPath: defaultDbPath);
    });
  });

  testWidgets('Language separation: word card in English locale shows NO Vietnamese text', (tester) async {
    // 1. Test mettā in English locale: no Vietnamese meaning card, senses show meaning_1
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'mettā')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Vietnamese meaning card and compounds are NOT shown
    expect(find.text('Vietnamese Meaning', skipOffstage: false), findsNothing);
    expect(find.text('Nghĩa tiếng Việt', skipOffstage: false), findsNothing);
    expect(find.text('HT Bửu Chơn (1976)', skipOffstage: false), findsNothing);
    expect(find.text('tâm từ; lòng từ ái', skipOffstage: false), findsNothing);
    expect(find.byType(ViCompoundRow), findsNothing);

    // Senses card shows English only: meaning_1
    expect(find.text('Senses (1)', skipOffstage: false), findsOneWidget);
    expect(find.text('goodwill (towards); friendliness (to); benevolence (for)', skipOffstage: false), findsOneWidget);

    // No pending note or Vietnamese string leaked
    expect(find.text('Vietnamese meaning is being added.', skipOffstage: false), findsNothing);
    expect(find.text('Nghĩa tiếng Việt đang được bổ sung.', skipOffstage: false), findsNothing);

    // 2. Test word with meaning_lit (akata) in English locale: shows meaning_1 + meaning_lit
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'akata')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Vietnamese Meaning', skipOffstage: false), findsNothing);
    expect(find.text('Nghĩa tiếng Việt', skipOffstage: false), findsNothing);
    expect(find.text('lit. not done', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Language separation: word card in Vietnamese locale keeps Vietnamese meaning card present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'mettā')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Vietnamese Meaning card IS present
    expect(find.text('Nghĩa tiếng Việt', skipOffstage: false), findsOneWidget);
    expect(find.text('tâm từ; lòng từ ái', skipOffstage: false), findsWidgets);

    // Senses section present with Vietnamese sense + English meaning_1
    expect(find.text('Các nét nghĩa (1)', skipOffstage: false), findsOneWidget);
    expect(find.text('goodwill (towards); friendliness (to); benevolence (for)', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Language separation: word without Vietnamese gloss (tata) shows English meaning only in EN, framed pending in VI', (tester) async {
    final defaultDbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await tester.runAsync(() async {
      final fixtureDbPath = await TestFixtureHelper.getOrCreateNoGlossFixture();
      await PackManager.instance.initialize(directDbPath: fixtureDbPath);
    });

    // In English locale: shows English meaning directly without pending note
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: WordCardScreen(lemmaClean: 'tata')),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Vietnamese Meaning'), findsNothing);
    expect(find.text('Nghĩa tiếng Việt'), findsNothing);
    expect(find.text('spread out; extended; expanded'), findsOneWidget);
    expect(find.text('Vietnamese meaning is being added.'), findsNothing);
    expect(find.text('Nghĩa tiếng Việt đang được bổ sung.'), findsNothing);
    expect(find.text('English meaning (DPD)'), findsNothing);

    // Restore active pack
    await tester.runAsync(() async {
      await PackManager.instance.initialize(directDbPath: defaultDbPath);
    });
  });
}
