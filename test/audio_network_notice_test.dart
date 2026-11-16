import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/data/repositories/dictionary_repository.dart';
import 'package:palidict/l10n/app_localizations.dart';
import 'package:palidict/services/audio_player_service.dart';
import 'package:palidict/ui/screens/word_card/word_card_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = p.join(Directory.current.path, 'data', 'lite_final.db');
    await PackManager.instance.initialize(directDbPath: dbPath);
    await DictionaryRepository().getGroupedHeadwordsPool();
  });

  Widget buildTestWidget({
    required AudioPlayerService audioService,
    Locale locale = const Locale('vi'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: WordCardScreen(
          lemmaClean: 'dhamma',
          audioService: audioService,
        ),
      ),
    );
  }

  Future<void> pumpWordCard(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  group('Audio Pronunciation Playback & Network Notices', () {
    testWidgets('1. Loading state appears on button tap, disables control, and clears on play', (tester) async {
      final completer = Completer<void>();
      final audioService = AudioPlayerService(
        customLoader: (_) => completer.future,
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      // Normal initial state
      expect(find.text('Nghe phát âm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap listen button
      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();

      // Loading state active: spinner visible, label switches to audioLoading
      expect(find.text('Đang tải âm thanh…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2)); // Button & AppBar icon

      // Verify button is disabled against double taps (onPressed is null)
      final outlinedBtn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Đang tải âm thanh…'), matching: find.byType(OutlinedButton)),
      );
      expect(outlinedBtn.onPressed, isNull);

      // Complete the playback start
      completer.complete();
      await tester.pump();

      // Loading clears, switches to playing state
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Đang phát...'), findsOneWidget);

      // Stop audio
      await audioService.stop();
      await tester.pump();

      // Back to normal idle state
      expect(find.text('Nghe phát âm'), findsOneWidget);
    });

    testWidgets('2. Slow network notice (> 4 s): shows audioSlowNetwork SnackBar once while loading continues', (tester) async {
      final completer = Completer<void>();
      final audioService = AudioPlayerService(
        slowThreshold: const Duration(seconds: 4),
        timeoutThreshold: const Duration(seconds: 12),
        customLoader: (_) => completer.future,
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      // Tap listen button
      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();

      // Before 4s: no slow network snackbar
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Kết nối mạng chậm, vẫn đang tải âm thanh…'), findsNothing);
      expect(find.text('Đang tải âm thanh…'), findsOneWidget);

      // At 4.5s (> 4s threshold): slow network snackbar renders
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Kết nối mạng chậm, vẫn đang tải âm thanh…'), findsOneWidget);
      // Loading continues
      expect(find.text('Đang tải âm thanh…'), findsOneWidget);

      // Later loader completes
      completer.complete();
      await tester.pump();

      // State switches to playing, loading clears
      expect(find.text('Đang phát...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('3. Failure notice on network error: shows audioPlayError SnackBar and restores control', (tester) async {
      final audioService = AudioPlayerService(
        customLoader: (_) async {
          throw Exception('SocketException: Connection refused (simulated offline)');
        },
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      // Tap listen button
      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();

      // Error snackbar renders
      expect(
        find.text('Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.'),
        findsOneWidget,
      );

      // No raw exception text anywhere
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.textContaining('Connection refused'), findsNothing);

      // Control restored to normal state
      expect(find.text('Nghe phát âm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final outlinedBtn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Nghe phát âm'), matching: find.byType(OutlinedButton)),
      );
      expect(outlinedBtn.onPressed, isNotNull);
    });

    testWidgets('4. Failure notice on timeout (> 12 s): cancels pending load, shows audioPlayError, no endless spinner', (tester) async {
      final hangingCompleter = Completer<void>();
      final audioService = AudioPlayerService(
        slowThreshold: const Duration(seconds: 4),
        timeoutThreshold: const Duration(seconds: 12),
        customLoader: (_) => hangingCompleter.future,
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();

      // At 4.5s: slow network notice
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Kết nối mạng chậm, vẫn đang tải âm thanh…'), findsOneWidget);

      // Advance past 12s timeout threshold (to 13s total)
      await tester.pump(const Duration(seconds: 8));

      // Error snackbar replaces slow snackbar
      expect(
        find.text('Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.'),
        findsOneWidget,
      );

      // Restored to normal state, endless spinner eliminated
      expect(find.text('Nghe phát âm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final outlinedBtn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Nghe phát âm'), matching: find.byType(OutlinedButton)),
      );
      expect(outlinedBtn.onPressed, isNotNull);
    });

    testWidgets('5. Retry after failure succeeds normally and resets state', (tester) async {
      int attempts = 0;
      final audioService = AudioPlayerService(
        customLoader: (_) async {
          attempts++;
          if (attempts == 1) {
            throw Exception('Initial failure');
          }
          // Second attempt succeeds immediately
        },
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      // First attempt fails
      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();
      expect(
        find.text('Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Nghe phát âm'), findsOneWidget);

      // Retry (second attempt)
      await tester.tap(find.text('Nghe phát âm'));
      await tester.pump();

      // State is playing on retry success
      expect(attempts, 2);
      expect(find.text('Đang phát...'), findsOneWidget);
    });

    testWidgets('6. AppBar speaker icon has identical loading, disabled, and error behavior', (tester) async {
      final audioService = AudioPlayerService(
        customLoader: (_) async {
          throw Exception('AppBar network error');
        },
      );

      await pumpWordCard(tester, buildTestWidget(audioService: audioService));

      // Find AppBar icon button
      final iconFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Nghe phát âm',
      );
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      // Error snackbar renders
      expect(
        find.text('Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('7. English locale renders correct localized notices', (tester) async {
      final completer = Completer<void>();
      final audioService = AudioPlayerService(
        slowThreshold: const Duration(seconds: 4),
        timeoutThreshold: const Duration(seconds: 12),
        customLoader: (_) => completer.future,
      );

      await pumpWordCard(
        tester,
        buildTestWidget(audioService: audioService, locale: const Locale('en')),
      );

      expect(find.text('Listen'), findsOneWidget);

      await tester.tap(find.text('Listen'));
      await tester.pump();

      // Loading state label in English
      expect(find.text('Loading audio…'), findsOneWidget);

      // Slow network notice in English
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Slow connection, still loading audio…'), findsOneWidget);

      // Timeout failure in English
      await tester.pump(const Duration(seconds: 8));
      expect(
        find.text('Could not play the audio. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Listen'), findsOneWidget);
    });
  });
}
