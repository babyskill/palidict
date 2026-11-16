/// Application constants
class AppConstants {
  AppConstants._();

  static const String appName = 'PaliDict';
  static const String appVersion = '1.0.0';

  // Desktop responsive layout constants
  static const double desktopBreakpoint = 900.0;
  static const double desktopMaxContentWidth = 880.0;

  // Bundled asset path for Lite pack
  static const String liteAssetPath = 'data/lite_final.db';

  // Filenames in app documents directory
  static const String liteDatabaseFileName = 'lite_final.db';
  static const String coreDatabaseFileName = 'core_final.db';
  static const String coreDownloadFileName = 'core_final.db.gz';

  // Default raw URLs for Core pack gz archive
  static const String defaultCorePackR2Url =
      'https://pub-7386c1f692c141a3827f6d1399e19e4e.r2.dev/packs/core_final.db.gz';
  static const String defaultCorePackUrl =
      'https://raw.githubusercontent.com/babyskill/suttacentral/main/core_final.db.gz';

  // Effective URLs with --dart-define support
  // Primary: Cloudflare R2 (overridable via --dart-define=PALIDICT_CORE_R2_URL=...)
  static const String corePackR2Url = String.fromEnvironment(
    'PALIDICT_CORE_R2_URL',
    defaultValue: defaultCorePackR2Url,
  );

  // Fallback: GitHub data repository (overridable via --dart-define=PALIDICT_CORE_GITHUB_URL=...)
  static const String corePackUrl = String.fromEnvironment(
    'PALIDICT_CORE_GITHUB_URL',
    defaultValue: defaultCorePackUrl,
  );

  // Sister app (Cùng Tu) landing & web app link
  static const String cungTuWebUrl = 'https://app.giacngo.org';

  // Author links and visible link texts
  static const String authorWebsiteUrl = 'https://giacngo.org';
  static const String authorFacebookUrl = 'https://www.facebook.com/kiinl';
  static const String authorWebsiteText = 'giacngo.org';
  static const String authorFacebookText = 'facebook.com/kiinl';
  static const String authorWebsiteLabel = 'Website';
  static const String authorFacebookLabel = 'Facebook';

  // Audio URL template (Male voice only)
  static String getAudioUrl(String lemmaClean) {
    final encoded = Uri.encodeComponent(lemmaClean);
    return 'https://dpdict.net/audio/$encoded?gender=male';
  }
}
