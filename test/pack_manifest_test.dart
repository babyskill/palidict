import 'package:flutter_test/flutter_test.dart';
import 'package:palidict/core/constants/app_constants.dart';
import 'package:palidict/data/database/pack_manifest.dart';

void main() {
  group('PackManifest - Measured Facts & Constants', () {
    test('Core pack constants equal exact measured values from brief', () {
      expect(PackManifest.coreId, 'core');
      expect(PackManifest.coreInstalledFileName, 'core_final.db');
      expect(PackManifest.coreExpectedBytes, 133558272);
      expect(PackManifest.coreSha256, '76219ded47202581720d87ee79f1712829a79b98f9e5e50ef1f1fc2d32da068e');
      expect(PackManifest.coreDownloadFileName, 'core_final.db.gz');
      expect(PackManifest.coreExpectedDownloadBytes, 32867017);
      expect(
        PackManifest.coreDownloadSha256,
        '6a473b81ee8126c411dbc07deedccca00301520b687c6ca96a9dc592696b2178',
      );
      expect(PackManifest.coreAndroidAssetPackName, 'core_pack');

      final core = PackManifest.core;
      expect(core.id, 'core');
      expect(core.installedFileName, 'core_final.db');
      expect(core.expectedBytes, 133558272);
      expect(core.downloadFileName, 'core_final.db.gz');
      expect(core.expectedDownloadBytes, 32867017);
      expect(
        core.downloadSha256,
        '6a473b81ee8126c411dbc07deedccca00301520b687c6ca96a9dc592696b2178',
      );
      expect(core.androidAssetPackName, 'core_pack');
      expect(core.isBundled, isFalse);
    });

    test('Lite pack constants equal exact measured values from brief', () {
      expect(PackManifest.liteId, 'lite');
      expect(PackManifest.liteInstalledFileName, 'lite_final.db');
      expect(PackManifest.liteExpectedBytes, 14966784);
      expect(
        PackManifest.liteSha256,
        'c5cf41b96ffb9f89c6163a29d604032775c4e4a5fbf301b8dfb56ec21207d31c',
      );

      final lite = PackManifest.lite;
      expect(lite.id, 'lite');
      expect(lite.installedFileName, 'lite_final.db');
      expect(lite.expectedBytes, 14966784);
      expect(lite.downloadFileName, isNull);
      expect(lite.expectedDownloadBytes, isNull);
      expect(lite.isBundled, isTrue);
    });

    test('formatBytes utility formats B, KB, and MB correctly', () {
      expect(PackManifest.formatBytes(500), '500 B');
      expect(PackManifest.formatBytes(2048), '2.0 KB');
      expect(PackManifest.formatBytes(14966784), '14.3 MB');
      expect(PackManifest.formatBytes(133558272), '127.4 MB');
      expect(PackManifest.formatBytes(32867017), '31.3 MB');
    });

    test('allPacks lists lite and core packs', () {
      final packs = PackManifest.allPacks;
      expect(packs.length, 2);
      expect(packs[0].id, 'lite');
      expect(packs[1].id, 'core');
    });
  });

  group('PackUrlResolver - Addendum 1 & 2 Overrides', () {
    test('default resolution orders Cloudflare R2 first and GitHub fallback second', () {
      const resolver = PackUrlResolver();
      final urls = resolver.resolveCoreUrls();
      expect(urls.length, 2);
      expect(urls[0], AppConstants.corePackR2Url);
      expect(
        urls[0],
        'https://pub-7386c1f692c141a3827f6d1399e19e4e.r2.dev/packs/core_final.db.gz',
      );
      expect(urls[1], AppConstants.corePackUrl);
      expect(
        urls[1],
        'https://raw.githubusercontent.com/babyskill/suttacentral/main/core_final.db.gz',
      );
      expect(urls[0], contains('r2.dev'));
      expect(urls[1], contains('raw.githubusercontent.com'));
    });

    test('PackUrlResolver honors injected R2 override in primary position', () {
      const customR2 = 'http://127.0.0.1:8799/packs/core_final.db.gz';
      const resolver = PackUrlResolver(overrideR2Url: customR2);
      final urls = resolver.resolveCoreUrls();
      expect(urls[0], customR2);
      expect(urls[1], AppConstants.corePackUrl);
    });

    test('PackUrlResolver honors injected GitHub override in fallback position', () {
      const customGithub = 'http://127.0.0.1:8799/github/core_final.db.gz';
      const resolver = PackUrlResolver(overrideGithubUrl: customGithub);
      final urls = resolver.resolveCoreUrls();
      expect(urls[0], AppConstants.corePackR2Url);
      expect(urls[1], customGithub);
    });

    test('PackUrlResolver honors both overrides simultaneously', () {
      const customR2 = 'http://127.0.0.1:8799/primary.gz';
      const customGithub = 'http://127.0.0.1:8799/fallback.gz';
      const resolver = PackUrlResolver(
        overrideR2Url: customR2,
        overrideGithubUrl: customGithub,
      );
      final urls = resolver.resolveCoreUrls();
      expect(urls, [customR2, customGithub]);
    });
  });
}
