import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart-side interface for Google Play Asset Delivery (Android).
/// Falls back safely to null on non-Android or in non-Play builds.
class AssetPackService {
  static const MethodChannel _channel = MethodChannel('palidict/asset_packs');

  final MethodChannel channel;

  const AssetPackService({MethodChannel? channel})
      : channel = channel ?? _channel;

  /// Attempts to fetch and locate the `core_pack` asset via Play Asset Delivery.
  /// Returns the absolute path to the installed `core_final.db` if successful,
  /// or `null` if unavailable (non-Android, dev/sideload build, or Play fetch failed).
  Future<String?> fetchCorePack({void Function(double progress)? onProgress}) async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final dynamic result = await channel.invokeMethod('fetchCorePack');
      if (result is String && result.isNotEmpty) {
        final dbFile = File(result);
        if (dbFile.existsSync()) {
          return dbFile.path;
        }
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('AssetPackService platform exception: ${e.message}');
      return null;
    } on MissingPluginException {
      debugPrint('AssetPackService: MethodChannel palidict/asset_packs not implemented.');
      return null;
    } catch (e) {
      debugPrint('AssetPackService unexpected error: $e');
      return null;
    }
  }
}
