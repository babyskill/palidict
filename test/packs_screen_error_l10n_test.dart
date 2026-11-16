import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/data/database/pack_manifest.dart';
import 'package:palidict/l10n/app_localizations.dart';
import 'package:palidict/ui/screens/packs/packs_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('packs_screen_error_test_');
    await PackManager.instance.initialize(overrideDbDir: tempDir.path);
  });

  tearDown(() async {
    PackManager.instance.clientOverride = null;
    try {
      await PackManager.instance.deleteCorePack();
    } catch (_) {}
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Widget buildTestableApp({Locale locale = const Locale('vi')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PacksScreen(),
    );
  }

  group('PacksScreen Error Localization (Vietnamese)', () {
    testWidgets('simulated HTTP 404 renders Vietnamese error strings and "Lỗi" chip with no raw English', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      // Find and tap the download Core button
      final downloadBtn = find.widgetWithText(FilledButton, 'Tải gói Đầy đủ (Core)');
      expect(downloadBtn, findsOneWidget);

      await tester.tap(downloadBtn);
      // Wait for async download to finish
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (PackManager.instance.coreStatus == PackStatus.error) break;
      }
      await tester.pumpAndSettle();

      // 1. Status chip must show "Lỗi" (not "Error" or "Chưa cài đặt")
      final errorChip = find.text('Lỗi');
      expect(errorChip, findsOneWidget, reason: 'Status chip should display localized "Lỗi"');
      expect(find.text('Error'), findsNothing, reason: 'Raw English "Error" chip must not be shown');

      // 2. Expected localized message
      const expectedMessage = 'Không tải được gói (mã lỗi 404). Kiểm tra kết nối mạng rồi thử lại.';

      // Inline error box and top snackbar banner should display expected message
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));

      // 3. Must NOT contain "Download failed" anywhere in the widget tree
      expect(find.textContaining('Download failed'), findsNothing);
      expect(find.textContaining('HTTP 404'), findsNothing);
    });

    testWidgets('simulated size-mismatch failure renders Vietnamese error string with no raw English', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(Uint8List(100), 200);
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Tải gói Đầy đủ (Core)');
      expect(downloadBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(downloadBtn);
        while (PackManager.instance.coreStatus == PackStatus.downloading) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      // 1. Status chip must show "Lỗi"
      expect(find.text('Lỗi'), findsOneWidget);
      expect(find.text('Error'), findsNothing);

      // 2. Expected localized message
      const expectedMessage = 'Tệp gói tải về không khớp dữ liệu gốc. Vui lòng thử lại.';
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));

      // 3. Must NOT contain "Download failed", "SHA-256", or "checksum mismatch"
      expect(find.textContaining('Download failed'), findsNothing);
      expect(find.textContaining('mismatch'), findsNothing);
    });

    testWidgets('simulated sha256-mismatch failure renders Vietnamese error string with no raw English', (tester) async {
      final mockClient = MockClient((request) async {
        final badBytes = Uint8List(PackManifest.coreExpectedDownloadBytes);
        return http.Response.bytes(badBytes, 200);
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Tải gói Đầy đủ (Core)');
      expect(downloadBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(downloadBtn);
        while (PackManager.instance.coreStatus == PackStatus.downloading) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      // 1. Status chip must show "Lỗi"
      expect(find.text('Lỗi'), findsOneWidget);
      expect(find.text('Error'), findsNothing);

      // 2. Expected localized message
      const expectedMessage = 'Tệp gói tải về không khớp dữ liệu gốc. Vui lòng thử lại.';
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));

      // 3. Must NOT contain "Download failed", "SHA-256", or "checksum mismatch"
      expect(find.textContaining('Download failed'), findsNothing);
      expect(find.textContaining('SHA-256'), findsNothing);
      expect(find.textContaining('mismatch'), findsNothing);
    });

    testWidgets('simulated network/timeout failure renders general network Vietnamese message', (tester) async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Network unreachable');
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('vi')));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Tải gói Đầy đủ (Core)');
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // 1. Status chip
      expect(find.text('Lỗi'), findsOneWidget);

      // 2. Localized network message
      const expectedMessage = 'Đã xảy ra lỗi khi tải gói. Kiểm tra kết nối mạng rồi thử lại.';
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));

      // 3. No raw technical string
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.textContaining('Network unreachable'), findsNothing);
    });
  });

  group('PacksScreen Error Localization (English)', () {
    testWidgets('simulated HTTP 404 renders English error strings and "Error" chip', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Download Core Pack');
      expect(downloadBtn, findsOneWidget);

      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // Status chip
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Lỗi'), findsNothing);

      // Localized message
      const expectedMessage = 'Could not download the pack (error 404). Check your connection and try again.';
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));
      expect(find.textContaining('Download failed (HTTP 404)'), findsNothing);
    });

    testWidgets('simulated size-mismatch renders English mismatch message', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(Uint8List(100), 200);
      });
      PackManager.instance.clientOverride = mockClient;

      await tester.pumpWidget(buildTestableApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(FilledButton, 'Download Core Pack');
      await tester.runAsync(() async {
        await tester.tap(downloadBtn);
        while (PackManager.instance.coreStatus == PackStatus.downloading) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      const expectedMessage = 'The downloaded pack does not match the original data. Please try again.';
      expect(find.text(expectedMessage), findsAtLeastNWidgets(1));
    });
  });
}
