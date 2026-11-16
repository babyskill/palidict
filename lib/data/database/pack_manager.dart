import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import 'asset_pack_service.dart';
import 'pack_manifest.dart';

enum PackStatus {
  idle,
  downloading,
  extracting,
  installed,
  error,
}

enum PackErrorKind {
  http,
  verificationMismatch,
  network,
  deleteFailed,
  sideloadFailed,
  other,
}

abstract class PackError {
  PackErrorKind get kind;
  int? get statusCode;
}

class PackHttpException extends HttpException implements PackError {
  @override
  final int statusCode;
  @override
  PackErrorKind get kind => PackErrorKind.http;

  PackHttpException(this.statusCode, [String? message])
      : super(message ?? 'Download failed (HTTP $statusCode)');
}

class PackVerificationException extends StateError implements PackError {
  @override
  final int? statusCode = null;
  @override
  PackErrorKind get kind => PackErrorKind.verificationMismatch;

  PackVerificationException(super.message);
}

class PackNetworkException extends StateError implements PackError {
  @override
  final int? statusCode = null;
  @override
  PackErrorKind get kind => PackErrorKind.network;

  PackNetworkException(super.message);
}

class PackErrorDetails {
  final PackErrorKind kind;
  final int? statusCode;
  final String? technicalMessage;

  const PackErrorDetails({
    required this.kind,
    this.statusCode,
    this.technicalMessage,
  });

  String toLocalizedMessage(AppLocalizations l10n) {
    switch (kind) {
      case PackErrorKind.http:
        return l10n.packErrorHttp(statusCode ?? 0);
      case PackErrorKind.verificationMismatch:
        return l10n.packErrorVerification;
      case PackErrorKind.network:
      case PackErrorKind.other:
        return l10n.packErrorNetwork;
      case PackErrorKind.deleteFailed:
        return l10n.packErrorDelete;
      case PackErrorKind.sideloadFailed:
        return l10n.packErrorSideload;
    }
  }

  static PackErrorDetails fromException(Object e) {
    if (e is PackError) {
      return PackErrorDetails(
        kind: e.kind,
        statusCode: e.statusCode,
        technicalMessage: e.toString(),
      );
    }
    if (e is HttpException) {
      final match = RegExp(r'HTTP (\d+)').firstMatch(e.message);
      final code = match != null ? int.tryParse(match.group(1)!) : null;
      return PackErrorDetails(
        kind: PackErrorKind.http,
        statusCode: code,
        technicalMessage: e.message,
      );
    }
    if (e is StateError) {
      final msg = e.message;
      if (msg.contains('mismatch') || msg.contains('corrupted') || msg.contains('size')) {
        return PackErrorDetails(
          kind: PackErrorKind.verificationMismatch,
          technicalMessage: msg,
        );
      }
    }
    if (e is SocketException || e is TimeoutException || e is http.ClientException) {
      return PackErrorDetails(
        kind: PackErrorKind.network,
        technicalMessage: e.toString(),
      );
    }
    return PackErrorDetails(
      kind: PackErrorKind.other,
      technicalMessage: e.toString(),
    );
  }
}

/// Manages data pack files (Lite and Core packs) and their SQLite connections.
class PackManager extends ChangeNotifier {
  static final PackManager instance = PackManager._internal();
  PackManager._internal();

  Database? _activeDatabase;
  String? _activeDbDir;
  bool _isCoreActive = false;
  PackStatus _coreStatus = PackStatus.idle;
  double _downloadProgress = 0.0;
  String? _statusMessage;
  PackErrorDetails? _lastError;
  http.Client? _downloadClient;
  http.Client? clientOverride;
  AssetPackService assetPackService = const AssetPackService();

  bool get isCoreActive => _isCoreActive;
  bool get isInitialized => _activeDatabase != null && _activeDatabase!.isOpen;
  PackStatus get coreStatus => _coreStatus;
  double get downloadProgress => _downloadProgress;
  String? get statusMessage => _statusMessage;
  PackErrorDetails? get lastError => _lastError;

  Database get database {
    if (_activeDatabase == null) {
      throw StateError('Database has not been initialized. Call initialize() first.');
    }
    return _activeDatabase!;
  }

  /// Initializes sqflite FFI if on desktop / test, and opens the active database.
  Future<void> initialize({String? overrideDbDir, String? directDbPath}) async {
    _lastError = null;
    _statusMessage = null;
    if (kIsWeb) {
      throw UnsupportedError('Web SQLite is not supported in this offline build.');
    }

    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (directDbPath != null) {
      _activeDbDir = p.dirname(directDbPath);
      await _openDatabaseFile(directDbPath);
      final packName = p.basename(directDbPath).contains('core')
          ? PackManifest.coreId
          : PackManifest.liteId;
      await verifyRequiredTables(_activeDatabase!, packName: packName);
      return;
    }

    final dbDir = overrideDbDir ?? await _getAppDatabaseDirectory();
    _activeDbDir = dbDir;
    final litePath = p.join(dbDir, PackManifest.liteInstalledFileName);
    final corePath = p.join(dbDir, PackManifest.coreInstalledFileName);
    final liteFile = File(litePath);
    final coreFile = File(corePath);

    // 1. Ensure installed Lite pack matches manifest (size and sha256)
    await _ensureValidLitePack(liteFile);

    // 2. Validate installed Core pack (if present)
    bool isCoreValid = false;
    if (coreFile.existsSync()) {
      isCoreValid = await _validateAndCheckCorePack(coreFile);
    }

    // 3. Open the active database
    if (isCoreValid) {
      await _openDatabaseFile(corePath);
      _isCoreActive = true;
      _coreStatus = PackStatus.installed;
    } else {
      await _openDatabaseFile(litePath);
      _isCoreActive = false;
      _coreStatus = PackStatus.idle;
    }

    // 4. Schema self-check on the active database
    final activePackName = _isCoreActive ? PackManifest.coreId : PackManifest.liteId;
    final missing = await verifyRequiredTables(_activeDatabase!, packName: activePackName);
    if (missing.isNotEmpty) {
      if (!_isCoreActive) {
        // Lite pack copy has missing tables -> refresh from bundled asset and reopen
        debugPrint('Lite pack missing required tables: $missing. Refreshing from bundled asset...');
        await _activeDatabase?.close();
        _activeDatabase = null;
        await _copyLiteAssetToFile(liteFile);
        await _openDatabaseFile(litePath);
        await verifyRequiredTables(_activeDatabase!, packName: PackManifest.liteId);
      } else {
        // Core pack has missing tables -> invalidate, delete, and fallback to Lite
        debugPrint('Core pack missing required tables: $missing. Invalidation triggered.');
        await _activeDatabase?.close();
        _activeDatabase = null;
        if (coreFile.existsSync()) {
          coreFile.deleteSync();
        }
        _isCoreActive = false;
        _coreStatus = PackStatus.idle;
        await _openDatabaseFile(litePath);
        await verifyRequiredTables(_activeDatabase!, packName: PackManifest.liteId);
      }
    }

    notifyListeners();
  }

  static const List<String> requiredTables = [
    'headwords',
    'lookup',
    'roots',
    'meaning_vi_entries',
    'meaning_vi_senses',
  ];

  /// Checks that all required tables exist in [db] and logs missing tables with [packName].
  /// Returns the list of missing table names (empty if all exist).
  Future<List<String>> verifyRequiredTables(Database db, {required String packName}) async {
    final rows = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final existingTables = rows.map((r) => r['name'] as String).toSet();
    final missingTables = <String>[];
    for (final table in requiredTables) {
      if (!existingTables.contains(table)) {
        missingTables.add(table);
        debugPrint('Pack $packName is missing required table: $table');
      }
    }
    return missingTables;
  }

  Future<String> _computeFileSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  Future<void> _ensureValidLitePack(File liteFile) async {
    if (!liteFile.existsSync()) {
      await _copyLiteAssetToFile(liteFile);
      return;
    }

    final size = liteFile.lengthSync();
    if (size != PackManifest.liteExpectedBytes) {
      debugPrint(
        'Installed Lite pack size mismatch ($size != ${PackManifest.liteExpectedBytes}). Refreshing from bundled asset...',
      );
      await _copyLiteAssetToFile(liteFile);
      return;
    }

    final fileSha = await _computeFileSha256(liteFile);
    if (fileSha != PackManifest.liteSha256.toLowerCase()) {
      debugPrint(
        'Installed Lite pack SHA-256 mismatch ($fileSha != ${PackManifest.liteSha256}). Refreshing from bundled asset...',
      );
      await _copyLiteAssetToFile(liteFile);
      return;
    }
  }

  Future<bool> _validateAndCheckCorePack(File coreFile) async {
    if (!coreFile.existsSync()) return false;

    final size = coreFile.lengthSync();
    if (size != PackManifest.coreExpectedBytes) {
      debugPrint(
        'Installed Core pack size mismatch ($size != ${PackManifest.coreExpectedBytes}). Invaliding and deleting stale core file.',
      );
      coreFile.deleteSync();
      return false;
    }

    final fileSha = await _computeFileSha256(coreFile);
    if (fileSha != PackManifest.coreSha256.toLowerCase()) {
      debugPrint(
        'Installed Core pack SHA-256 mismatch ($fileSha != ${PackManifest.coreSha256}). Invaliding and deleting stale core file.',
      );
      coreFile.deleteSync();
      return false;
    }

    Database? testDb;
    try {
      testDb = await openDatabase(coreFile.path, readOnly: true);
      final missing = await verifyRequiredTables(testDb, packName: PackManifest.coreId);
      if (missing.isNotEmpty) {
        debugPrint(
          'Installed Core pack lacks required tables: $missing. Invaliding and deleting stale core file.',
        );
        await testDb.close();
        testDb = null;
        if (coreFile.existsSync()) coreFile.deleteSync();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error inspecting installed Core pack: $e. Deleting stale core file.');
      if (testDb != null && testDb.isOpen) {
        await testDb.close();
      }
      if (coreFile.existsSync()) coreFile.deleteSync();
      return false;
    } finally {
      if (testDb != null && testDb.isOpen) {
        await testDb.close();
      }
    }
  }

  Future<void> _openDatabaseFile(String path) async {
    if (_activeDatabase != null && _activeDatabase!.isOpen) {
      await _activeDatabase!.close();
    }

    _activeDatabase = await openDatabase(
      path,
      readOnly: true,
      singleInstance: true,
    );
  }

  Future<String> _getAppDatabaseDirectory() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final path = p.join(docDir.path, 'palidict_data');
      final dir = Directory(path);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return path;
    } catch (_) {
      // Fallback for tests or environments without path_provider
      final fallbackDir = Directory(p.join(Directory.current.path, 'data_store'));
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      return fallbackDir.path;
    }
  }

  Future<void> _copyLiteAssetToFile(File destination) async {
    if (_activeDatabase != null && _activeDatabase!.isOpen) {
      await _activeDatabase!.close();
      _activeDatabase = null;
    }

    destination.parent.createSync(recursive: true);
    final tempFile = File('${destination.path}.tmp');
    if (tempFile.existsSync()) tempFile.deleteSync();

    try {
      final data = await rootBundle.load(AppConstants.liteAssetPath);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await tempFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      // If rootBundle fails (e.g. In unit tests), try copying from local data/
      final localAsset = File(AppConstants.liteAssetPath);
      if (localAsset.existsSync()) {
        await localAsset.copy(tempFile.path);
      } else {
        if (tempFile.existsSync()) tempFile.deleteSync();
        rethrow;
      }
    }

    if (destination.existsSync()) {
      destination.deleteSync();
    }
    await tempFile.rename(destination.path);
  }

  /// Downloads the Core pack (.db.gz) using the Cùng Tu dual mechanism:
  /// 1. Android Play Asset Delivery (if available)
  /// 2. Multi-source network download: Cloudflare R2 primary, GitHub fallback.
  Future<void> downloadCorePack({List<String>? urls, String? url, http.Client? client}) async {
    if (_coreStatus == PackStatus.downloading || _coreStatus == PackStatus.extracting) {
      return;
    }

    _coreStatus = PackStatus.downloading;
    _downloadProgress = 0.0;
    _statusMessage = null;
    _lastError = null;
    notifyListeners();

    final dbDir = _activeDbDir ?? await _getAppDatabaseDirectory();
    final corePath = p.join(dbDir, PackManifest.coreInstalledFileName);

    // Step 1: On Android, attempt Play Asset Delivery first
    try {
      final assetPath = await assetPackService.fetchCorePack(
        onProgress: (p) {
          _downloadProgress = p;
          notifyListeners();
        },
      );
      if (assetPath != null) {
        final padFile = File(assetPath);
        if (padFile.existsSync() && padFile.lengthSync() == PackManifest.coreExpectedBytes) {
          _coreStatus = PackStatus.extracting;
          notifyListeners();

          await padFile.copy(corePath);
          await _verifyAndSwitchToCore(corePath);
          _coreStatus = PackStatus.installed;
          _isCoreActive = true;
          _statusMessage = null;
          _lastError = null;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Play Asset Delivery check bypassed: $e');
    }

    // Step 2: Multi-source download (R2 primary, GitHub fallback)
    final sources = urls ?? (url != null ? [url] : PackManifest.core.downloadUrls);
    final gzPath = p.join(dbDir, PackManifest.coreDownloadFileName);
    final gzTempFile = File('$gzPath.tmp');

    int? lastHttpStatus;
    String? lastFailureReason;
    bool hasMismatch = false;
    bool downloadSuccess = false;

    final httpClient = client ?? clientOverride ?? http.Client();
    _downloadClient = httpClient;

    try {
      for (final currentUrl in sources) {
        if (gzTempFile.existsSync()) {
          gzTempFile.deleteSync();
        }

        IOSink? gzSink;
        try {
          final request = http.Request('GET', Uri.parse(currentUrl));
          final response = await httpClient.send(request);

          if (response.statusCode != 200) {
            lastHttpStatus = response.statusCode;
            lastFailureReason = 'HTTP ${response.statusCode}';
            continue;
          }

          final contentLength = response.contentLength ?? PackManifest.coreExpectedDownloadBytes;
          int received = 0;
          gzSink = gzTempFile.openWrite();

          await for (final chunk in response.stream) {
            gzSink.add(chunk);
            received += chunk.length;
            if (contentLength > 0) {
              _downloadProgress = (received / contentLength).clamp(0.0, 1.0);
              notifyListeners();
            }
          }

          await gzSink.flush();
          await gzSink.close();
          gzSink = null;

          // Verify download byte count
          final downloadedBytes = gzTempFile.lengthSync();
          if (downloadedBytes != PackManifest.coreExpectedDownloadBytes) {
            hasMismatch = true;
            lastFailureReason =
                'Byte count mismatch: expected ${PackManifest.coreExpectedDownloadBytes}, got $downloadedBytes';
            if (gzTempFile.existsSync()) gzTempFile.deleteSync();
            continue;
          }

          // Verify SHA-256 checksum
          final digest = await sha256.bind(gzTempFile.openRead()).first;
          final checksum = digest.toString().toLowerCase();
          if (checksum != PackManifest.coreDownloadSha256.toLowerCase()) {
            hasMismatch = true;
            lastFailureReason =
                'SHA-256 checksum mismatch: expected ${PackManifest.coreDownloadSha256}, got $checksum';
            if (gzTempFile.existsSync()) gzTempFile.deleteSync();
            continue;
          }

          // Extraction phase
          _coreStatus = PackStatus.extracting;
          notifyListeners();

          await _decompressAndActivate(gzTempFile, corePath);
          downloadSuccess = true;
          _lastError = null;
          _statusMessage = null;
          break;
        } catch (e) {
          if (gzSink != null) {
            try {
              await gzSink.close();
            } catch (_) {}
          }
          if (gzTempFile.existsSync()) {
            gzTempFile.deleteSync();
          }
          if (e is StateError && (e.message.contains('mismatch') || e.message.contains('size'))) {
            hasMismatch = true;
          }
          lastFailureReason = e.toString();
        }
      }

      if (!downloadSuccess) {
        if (lastHttpStatus != null) {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.http,
            statusCode: lastHttpStatus,
            technicalMessage: 'Download failed (HTTP $lastHttpStatus)',
          );
          throw PackHttpException(lastHttpStatus);
        } else if (hasMismatch) {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.verificationMismatch,
            technicalMessage: lastFailureReason,
          );
          throw PackVerificationException(lastFailureReason ?? 'Verification mismatch');
        } else {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.network,
            technicalMessage: lastFailureReason,
          );
          throw PackNetworkException(lastFailureReason ?? 'Download failed from all sources');
        }
      } else {
        _lastError = null;
        _statusMessage = null;
      }
    } catch (e) {
      if (gzTempFile.existsSync()) {
        gzTempFile.deleteSync();
      }
      _coreStatus = PackStatus.error;
      _statusMessage = e is HttpException ? e.message : e.toString();
      _lastError ??= PackErrorDetails.fromException(e);
      notifyListeners();
      rethrow;
    } finally {
      if (client == null && clientOverride == null) {
        _downloadClient?.close();
      }
      _downloadClient = null;
    }
  }

  /// Cancels an in-flight Core pack download.
  void cancelDownload() {
    _downloadClient?.close();
    _downloadClient = null;
    _coreStatus = PackStatus.idle;
    _downloadProgress = 0.0;
    _statusMessage = null;
    _lastError = null;
    notifyListeners();
  }

  /// Sideloads a Core pack file (either .db or .db.gz) from a local path.
  /// Strictly verifies file sizes and checksum against PackManifest.
  Future<void> sideloadCorePack(String filePath) async {
    _lastError = null;
    final sourceFile = File(filePath);
    if (!sourceFile.existsSync()) {
      _coreStatus = PackStatus.error;
      _lastError = PackErrorDetails(
        kind: PackErrorKind.sideloadFailed,
        technicalMessage: 'File not found: $filePath',
      );
      notifyListeners();
      throw FileSystemException('File not found', filePath);
    }

    final dbDir = _activeDbDir ?? await _getAppDatabaseDirectory();
    final corePath = p.join(dbDir, PackManifest.coreInstalledFileName);

    try {
      if (filePath.endsWith('.gz')) {
        final fileSize = sourceFile.lengthSync();
        if (fileSize != PackManifest.coreExpectedDownloadBytes) {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.verificationMismatch,
            technicalMessage:
                'File size mismatch: expected ${PackManifest.coreExpectedDownloadBytes} bytes, got $fileSize bytes',
          );
          throw PackVerificationException(
            'File size mismatch: expected ${PackManifest.coreExpectedDownloadBytes} bytes, got $fileSize bytes',
          );
        }

        final digest = await sha256.bind(sourceFile.openRead()).first;
        final checksum = digest.toString().toLowerCase();
        if (checksum != PackManifest.coreDownloadSha256.toLowerCase()) {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.verificationMismatch,
            technicalMessage:
                'SHA-256 checksum mismatch: expected ${PackManifest.coreDownloadSha256}, got $checksum',
          );
          throw PackVerificationException(
            'SHA-256 checksum mismatch: expected ${PackManifest.coreDownloadSha256}, got $checksum',
          );
        }

        _coreStatus = PackStatus.extracting;
        notifyListeners();
        await _decompressAndActivate(sourceFile, corePath);
      } else {
        final fileSize = sourceFile.lengthSync();
        if (fileSize != PackManifest.coreExpectedBytes) {
          _lastError = PackErrorDetails(
            kind: PackErrorKind.verificationMismatch,
            technicalMessage:
                'File size mismatch: expected ${PackManifest.coreExpectedBytes} bytes, got $fileSize bytes',
          );
          throw PackVerificationException(
            'File size mismatch: expected ${PackManifest.coreExpectedBytes} bytes, got $fileSize bytes',
          );
        }

        final tempPath = '$corePath.tmp';
        final tempFile = File(tempPath);
        if (tempFile.existsSync()) tempFile.deleteSync();

        await sourceFile.copy(tempPath);
        await _verifyAndSwitchToCore(tempPath);

        final coreFile = File(corePath);
        if (coreFile.existsSync()) coreFile.deleteSync();
        await tempFile.rename(corePath);

        await _openDatabaseFile(corePath);
        _isCoreActive = true;
        _coreStatus = PackStatus.installed;
        _lastError = null;
        _statusMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _coreStatus = PackStatus.error;
      _statusMessage = e.toString();
      _lastError ??= PackErrorDetails.fromException(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _decompressAndActivate(File gzFile, String targetPath) async {
    final tempPath = '$targetPath.tmp';
    final tempFile = File(tempPath);
    if (tempFile.existsSync()) tempFile.deleteSync();

    final input = gzFile.openRead();
    final output = tempFile.openWrite();

    await input.transform(gzip.decoder).pipe(output);
    await output.flush();
    await output.close();

    // Verify uncompressed byte count against manifest
    final decompressedBytes = tempFile.lengthSync();
    if (decompressedBytes != PackManifest.coreExpectedBytes) {
      if (tempFile.existsSync()) tempFile.deleteSync();
      throw StateError(
        'Database size mismatch: expected ${PackManifest.coreExpectedBytes} bytes, got $decompressedBytes bytes',
      );
    }

    // Verify temp database contents
    await _verifyAndSwitchToCore(tempPath);

    // Atomically replace target
    final coreFile = File(targetPath);
    if (coreFile.existsSync()) coreFile.deleteSync();
    await tempFile.rename(targetPath);

    // Clean up gz download if it was a temporary download file
    if (gzFile.existsSync() && gzFile.path.endsWith('.tmp')) {
      gzFile.deleteSync();
    }

    // Reopen database with final core path
    await _openDatabaseFile(targetPath);
    _isCoreActive = true;
    _coreStatus = PackStatus.installed;
    notifyListeners();
  }

  Future<void> _verifyAndSwitchToCore(String dbPath) async {
    final testDb = await openDatabase(dbPath, readOnly: true);
    try {
      final missing = await verifyRequiredTables(testDb, packName: PackManifest.coreId);
      if (missing.isNotEmpty) {
        throw StateError('Invalid Core database: missing required tables ($missing)');
      }
      final result = await testDb.rawQuery('SELECT count(*) as count FROM headwords');
      final count = Sqflite.firstIntValue(result) ?? 0;
      if (count < 5000) {
        throw StateError('Invalid Core database: headwords count too low ($count)');
      }
    } finally {
      await testDb.close();
    }
  }

  /// Deletes the Core pack and falls back to the bundled Lite pack.
  Future<void> deleteCorePack() async {
    try {
      final dbDir = _activeDbDir ?? await _getAppDatabaseDirectory();
      final corePath = p.join(dbDir, PackManifest.coreInstalledFileName);
      final coreFile = File(corePath);

      if (_activeDatabase != null && _activeDatabase!.isOpen) {
        await _activeDatabase!.close();
        _activeDatabase = null;
      }

      if (coreFile.existsSync()) {
        coreFile.deleteSync();
      }

      final litePath = p.join(dbDir, PackManifest.liteInstalledFileName);
      final liteFile = File(litePath);
      await _ensureValidLitePack(liteFile);
      await _openDatabaseFile(litePath);
      await verifyRequiredTables(_activeDatabase!, packName: PackManifest.liteId);

      _isCoreActive = false;
      _coreStatus = PackStatus.idle;
      _downloadProgress = 0.0;
      _statusMessage = null;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = PackErrorDetails(
        kind: PackErrorKind.deleteFailed,
        technicalMessage: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Returns storage usage details for Lite and Core packs.
  Future<Map<String, String>> getStorageInfo() async {
    final dbDir = _activeDbDir ?? await _getAppDatabaseDirectory();
    final liteFile = File(p.join(dbDir, PackManifest.liteInstalledFileName));
    final coreFile = File(p.join(dbDir, PackManifest.coreInstalledFileName));

    return {
      'lite': liteFile.existsSync()
          ? PackManifest.formatBytes(liteFile.lengthSync())
          : PackManifest.lite.formattedInstalledSize,
      'core': coreFile.existsSync()
          ? PackManifest.formatBytes(coreFile.lengthSync())
          : '0 MB',
    };
  }
}
