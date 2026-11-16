import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:palidict/data/database/pack_manager.dart';
import 'package:palidict/data/database/pack_manifest.dart';

void main() {
  late Directory tempDir;
  late Uint8List realCoreGzBytes;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final realGzFile = File('data/core_final.db.gz');
    expect(realGzFile.existsSync(), isTrue,
        reason: 'data/core_final.db.gz must exist locally to serve as test fixture');
    realCoreGzBytes = realGzFile.readAsBytesSync();
    expect(realCoreGzBytes.length, PackManifest.coreExpectedDownloadBytes);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('palidict_pack_manager_test_');
    await PackManager.instance.initialize(overrideDbDir: tempDir.path);
  });

  tearDown(() async {
    try {
      await PackManager.instance.deleteCorePack();
    } catch (_) {}
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('PackManager - Download & Verification Flow', () {
    test('(a) a download with wrong byte count is rejected', () async {
      final mockClient = MockClient((request) async {
        // Return 100 bytes (far shorter than expected 30,619,188 bytes)
        return http.Response.bytes(Uint8List(100), 200);
      });

      await expectLater(
        PackManager.instance.downloadCorePack(
          urls: ['http://source.test/corrupted_len.gz'],
          client: mockClient,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Byte count mismatch'),
        )),
      );

      expect(PackManager.instance.isCoreActive, isFalse);
      expect(PackManager.instance.coreStatus, PackStatus.error);
      expect(PackManager.instance.lastError?.kind, PackErrorKind.verificationMismatch);
    });

    test('(b) a download with wrong sha256 is rejected', () async {
      final mockClient = MockClient((request) async {
        // Correct byte length, but corrupted content (all zeroes)
        final badBytes = Uint8List(PackManifest.coreExpectedDownloadBytes);
        return http.Response.bytes(badBytes, 200);
      });

      await expectLater(
        PackManager.instance.downloadCorePack(
          urls: ['http://source.test/corrupted_sha.gz'],
          client: mockClient,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('SHA-256 checksum mismatch'),
        )),
      );

      expect(PackManager.instance.isCoreActive, isFalse);
      expect(PackManager.instance.coreStatus, PackStatus.error);
      expect(PackManager.instance.lastError?.kind, PackErrorKind.verificationMismatch);
    });

    test('(c) an HTTP error surfaces its status code', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      await expectLater(
        PackManager.instance.downloadCorePack(
          urls: ['http://source.test/missing.gz'],
          client: mockClient,
        ),
        throwsA(isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('Download failed (HTTP 404)'),
        )),
      );

      expect(PackManager.instance.coreStatus, PackStatus.error);
      expect(PackManager.instance.statusMessage, contains('HTTP 404'));
      expect(PackManager.instance.lastError?.kind, PackErrorKind.http);
      expect(PackManager.instance.lastError?.statusCode, 404);
    });
  });

  group('PackManager - Multi-Source Failover (Addendum 1 & 2)', () {
    test('first source returns 404 -> second source is used and install succeeds', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'http://r2.test/core.gz') {
          return http.Response('Not Found on R2', 404);
        }
        if (request.url.toString() == 'http://github.test/core.gz') {
          return http.Response.bytes(realCoreGzBytes, 200);
        }
        return http.Response('Bad Request', 400);
      });

      await PackManager.instance.downloadCorePack(
        urls: [
          'http://r2.test/core.gz',
          'http://github.test/core.gz',
        ],
        client: mockClient,
      );

      expect(PackManager.instance.isCoreActive, isTrue);
      expect(PackManager.instance.coreStatus, PackStatus.installed);
      expect(PackManager.instance.statusMessage, isNull);

      // Verify active core file on disk
      final coreFile = File(p.join(tempDir.path, PackManifest.coreInstalledFileName));
      expect(coreFile.existsSync(), isTrue);
      expect(coreFile.lengthSync(), PackManifest.coreExpectedBytes);
    });

    test('first source serves corrupted bytes (sha mismatch) -> second source is used', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'http://r2.test/core.gz') {
          // Correct length, bad sha
          final badBytes = Uint8List(PackManifest.coreExpectedDownloadBytes);
          return http.Response.bytes(badBytes, 200);
        }
        if (request.url.toString() == 'http://github.test/core.gz') {
          return http.Response.bytes(realCoreGzBytes, 200);
        }
        return http.Response('Bad Request', 400);
      });

      await PackManager.instance.downloadCorePack(
        urls: [
          'http://r2.test/core.gz',
          'http://github.test/core.gz',
        ],
        client: mockClient,
      );

      expect(PackManager.instance.isCoreActive, isTrue);
      expect(PackManager.instance.coreStatus, PackStatus.installed);
    });

    test('all sources fail -> error surfaces with the last status code', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'http://source1.test/core.gz') {
          return http.Response('Server error', 502);
        }
        return http.Response('Not found', 404);
      });

      await expectLater(
        PackManager.instance.downloadCorePack(
          urls: [
            'http://source1.test/core.gz',
            'http://source2.test/core.gz',
          ],
          client: mockClient,
        ),
        throwsA(isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('Download failed (HTTP 404)'),
        )),
      );

      expect(PackManager.instance.isCoreActive, isFalse);
      expect(PackManager.instance.coreStatus, PackStatus.error);
    });

    test('(d) a correct gz fixture installs and reports the pack as installed', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(realCoreGzBytes, 200);
      });

      await PackManager.instance.downloadCorePack(
        urls: ['http://primary.test/core.gz'],
        client: mockClient,
      );

      expect(PackManager.instance.isCoreActive, isTrue);
      expect(PackManager.instance.coreStatus, PackStatus.installed);

      final storage = await PackManager.instance.getStorageInfo();
      expect(storage['core'], PackManifest.core.formattedInstalledSize);
    });
  });

  group('PackManager - Sideload Local Verification', () {
    test('sideloading wrong byte count .gz is rejected', () async {
      final corruptGz = File(p.join(tempDir.path, 'bad_size.gz'));
      corruptGz.writeAsBytesSync(Uint8List(50));

      expect(
        () => PackManager.instance.sideloadCorePack(corruptGz.path),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('File size mismatch'),
        )),
      );
    });

    test('sideloading wrong sha256 .gz is rejected', () async {
      final corruptGz = File(p.join(tempDir.path, 'bad_sha.gz'));
      corruptGz.writeAsBytesSync(Uint8List(PackManifest.coreExpectedDownloadBytes));

      expect(
        () => PackManager.instance.sideloadCorePack(corruptGz.path),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('SHA-256 checksum mismatch'),
        )),
      );
    });

    test('sideloading correct gz fixture installs cleanly', () async {
      await PackManager.instance.sideloadCorePack('data/core_final.db.gz');

      expect(PackManager.instance.isCoreActive, isTrue);
      expect(PackManager.instance.coreStatus, PackStatus.installed);

      final storage = await PackManager.instance.getStorageInfo();
      expect(storage['core'], PackManifest.core.formattedInstalledSize);
    });
  });

  group('PackManager - Installed Pack Validation & Refresh (Deliverable 3)', () {
    test('a stale installed Lite (wrong sha / missing meaning_vi_entries) is replaced by the bundled asset on init', () async {
      final customDir = await Directory.systemTemp.createTemp('stale_lite_test_');
      try {
        final liteFile = File(p.join(customDir.path, PackManifest.liteInstalledFileName));
        // Create a stale sqlite database missing meaning_vi_entries
        final db = await openDatabase(liteFile.path);
        await db.execute('CREATE TABLE headwords (id INTEGER PRIMARY KEY, lemma_1 TEXT)');
        await db.execute('CREATE TABLE lookup (lookup_key TEXT)');
        await db.execute('CREATE TABLE roots (root TEXT)');
        await db.execute('CREATE TABLE meaning_vi (lemma_key TEXT)');
        await db.execute('CREATE TABLE meaning_vi_senses (entry_id INTEGER)');
        await db.close();

        expect(liteFile.existsSync(), isTrue);

        await PackManager.instance.initialize(overrideDbDir: customDir.path);

        // Verify it was replaced by bundled asset
        expect(liteFile.lengthSync(), PackManifest.liteExpectedBytes);
        final digest = await sha256.bind(liteFile.openRead()).first;
        expect(digest.toString().toLowerCase(), PackManifest.liteSha256.toLowerCase());

        // Verify table meaning_vi_entries now exists in the active database
        final tables = await PackManager.instance.database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='meaning_vi_entries'",
        );
        expect(tables.isNotEmpty, isTrue);
      } finally {
        if (customDir.existsSync()) {
          try {
            customDir.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    });

    test('a current installed Lite (sha matches manifest) is NOT recopied', () async {
      final customDir = await Directory.systemTemp.createTemp('current_lite_test_');
      try {
        // Initialize once to populate valid lite_final.db
        await PackManager.instance.initialize(overrideDbDir: customDir.path);
        final liteFile = File(p.join(customDir.path, PackManifest.liteInstalledFileName));
        expect(liteFile.existsSync(), isTrue);
        expect(liteFile.lengthSync(), PackManifest.liteExpectedBytes);

        // Set modification time to the past
        final pastTime = DateTime.now().subtract(const Duration(hours: 48));
        liteFile.setLastModifiedSync(pastTime);
        final recordedMtime = liteFile.lastModifiedSync();

        // Initialize again with the same directory
        await PackManager.instance.initialize(overrideDbDir: customDir.path);

        // Assert file was NOT recopied or overwritten (timestamp untouched)
        expect(liteFile.lastModifiedSync(), equals(recordedMtime));
      } finally {
        if (customDir.existsSync()) {
          try {
            customDir.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    });

    test('a stale-schema installed Core is invalidated (treated as not installed)', () async {
      final customDir = await Directory.systemTemp.createTemp('stale_core_test_');
      try {
        final coreFile = File(p.join(customDir.path, PackManifest.coreInstalledFileName));
        // Create a stale sqlite database lacking meaning_vi_entries
        final db = await openDatabase(coreFile.path);
        await db.execute('CREATE TABLE headwords (id INTEGER PRIMARY KEY, lemma_1 TEXT)');
        await db.execute('CREATE TABLE lookup (lookup_key TEXT)');
        await db.execute('CREATE TABLE roots (root TEXT)');
        await db.execute('CREATE TABLE meaning_vi (lemma_key TEXT)');
        await db.execute('CREATE TABLE meaning_vi_senses (entry_id INTEGER)');
        await db.close();

        expect(coreFile.existsSync(), isTrue);

        // Initialize PackManager with this directory
        await PackManager.instance.initialize(overrideDbDir: customDir.path);

        // Assert Core was invalidated:
        // 1. Core file was deleted from disk
        expect(coreFile.existsSync(), isFalse);
        // 2. isCoreActive is false
        expect(PackManager.instance.isCoreActive, isFalse);
        // 3. coreStatus is idle (treated as not installed)
        expect(PackManager.instance.coreStatus, PackStatus.idle);
        // 4. Active database is Lite
        final storage = await PackManager.instance.getStorageInfo();
        expect(storage['core'], '0 MB');
      } finally {
        if (customDir.existsSync()) {
          try {
            customDir.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    });
  });
}
