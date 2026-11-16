import '../../core/constants/app_constants.dart';

/// Resolves effective Core pack download URLs, supporting --dart-define and testing overrides.
class PackUrlResolver {
  final String? overrideR2Url;
  final String? overrideGithubUrl;

  const PackUrlResolver({
    this.overrideR2Url,
    this.overrideGithubUrl,
  });

  /// Resolves ordered download sources: R2 primary, GitHub fallback.
  List<String> resolveCoreUrls({
    String? r2Url,
    String? githubUrl,
  }) {
    final effectiveR2 = r2Url ?? overrideR2Url ?? AppConstants.corePackR2Url;
    final effectiveGithub = githubUrl ?? overrideGithubUrl ?? AppConstants.corePackUrl;
    return [effectiveR2, effectiveGithub];
  }
}

/// Descriptor for a PaliDict database pack (Lite bundled or Core downloadable).
class PackManifestEntry {
  final String id;
  final String installedFileName;
  final int expectedBytes;
  final String? downloadFileName;
  final int? expectedDownloadBytes;
  final String? downloadSha256;
  final String? androidAssetPackName;
  final List<String> downloadUrls;
  final bool isBundled;

  const PackManifestEntry({
    required this.id,
    required this.installedFileName,
    required this.expectedBytes,
    this.downloadFileName,
    this.expectedDownloadBytes,
    this.downloadSha256,
    this.androidAssetPackName,
    this.downloadUrls = const [],
    this.isBundled = false,
  });

  /// Formatted installed file size (e.g. "118.4 MB" or "11.6 MB").
  String get formattedInstalledSize => PackManifest.formatBytes(expectedBytes);

  /// Formatted download archive size (e.g. "29.2 MB").
  String? get formattedDownloadSize =>
      expectedDownloadBytes != null ? PackManifest.formatBytes(expectedDownloadBytes!) : null;
}

/// Single source of truth for all PaliDict pack definitions, expected sizes,
/// checksums, and download endpoints.
class PackManifest {
  PackManifest._();

  // Core pack measured facts
  static const String coreId = 'core';
  static const String coreInstalledFileName = 'core_final.db';
  static const int coreExpectedBytes = 133558272;
  static const String coreSha256 =
      '76219ded47202581720d87ee79f1712829a79b98f9e5e50ef1f1fc2d32da068e';
  static const String coreDownloadFileName = 'core_final.db.gz';
  static const int coreExpectedDownloadBytes = 32867017;
  static const String coreDownloadSha256 =
      '6a473b81ee8126c411dbc07deedccca00301520b687c6ca96a9dc592696b2178';
  static const String coreAndroidAssetPackName = 'core_pack';

  // Lite pack measured facts (bundled base)
  static const String liteId = 'lite';
  static const String liteInstalledFileName = 'lite_final.db';
  static const int liteExpectedBytes = 14966784;
  static const String liteSha256 =
      'c5cf41b96ffb9f89c6163a29d604032775c4e4a5fbf301b8dfb56ec21207d31c';

  static PackUrlResolver urlResolver = const PackUrlResolver();

  static List<String> get effectiveCoreDownloadUrls =>
      urlResolver.resolveCoreUrls();

  /// Core pack manifest entry
  static PackManifestEntry get core => PackManifestEntry(
    id: coreId,
    installedFileName: coreInstalledFileName,
    expectedBytes: coreExpectedBytes,
    downloadFileName: coreDownloadFileName,
    expectedDownloadBytes: coreExpectedDownloadBytes,
    downloadSha256: coreDownloadSha256,
    androidAssetPackName: coreAndroidAssetPackName,
    downloadUrls: effectiveCoreDownloadUrls,
    isBundled: false,
  );

  /// Lite pack manifest entry (pre-bundled)
  static const PackManifestEntry lite = PackManifestEntry(
    id: liteId,
    installedFileName: liteInstalledFileName,
    expectedBytes: liteExpectedBytes,
    downloadSha256: liteSha256,
    isBundled: true,
  );

  static List<PackManifestEntry> get allPacks => [lite, core];

  /// Utility to format byte sizes cleanly into B, KB, or MB.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
