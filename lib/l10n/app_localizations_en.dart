// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pāḷi Dictionary';

  @override
  String get navLookup => 'Lookup';

  @override
  String get navPacks => 'Data Packs';

  @override
  String get navAbout => 'About';

  @override
  String get navCungTu => 'Cùng Tu';

  @override
  String get searchHint => 'Search word (dhammā…)';

  @override
  String get searchEmptyPrompt => 'Enter a Pali word to start lookup';

  @override
  String get desktopDetailEmptyPrompt =>
      'Select a word from the left pane or enter a word to look up';

  @override
  String get searchNoResults => 'No matching words found';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get typeHeadword => 'Headword';

  @override
  String get typeInflected => 'Inflected form';

  @override
  String inflectedTitle(String key) {
    return 'Inflected form: $key';
  }

  @override
  String inflectedHeadwordsPrompt(int count) {
    return 'Corresponding headwords ($count):';
  }

  @override
  String get grammarLabel => 'Grammar';

  @override
  String get vietnameseMeaningSection => 'Vietnamese Meaning';

  @override
  String get sourceBuuChon => 'HT Buu Chon (1976)';

  @override
  String get sourceNewTranslation => 'New translation — under review';

  @override
  String get sourceCurated => 'Reviewed';

  @override
  String get sensesSection => 'Senses';

  @override
  String get englishMeaningSection => 'English Meaning';

  @override
  String get grammarConstructionSection => 'Grammar & Construction';

  @override
  String get rootLabel => 'Root';

  @override
  String get rootMeaningLabel => 'Root Meaning';

  @override
  String get constructionLabel => 'Construction';

  @override
  String get phoneticLabel => 'Phonetic';

  @override
  String get sanskritLabel => 'Sanskrit';

  @override
  String get exampleSection => 'Textual Example';

  @override
  String get sourceLabel => 'Source';

  @override
  String get suttaLabel => 'Sutta';

  @override
  String get ebtCountLabel => 'EBT Frequency';

  @override
  String ebtCountTimes(String count) {
    return '$count occurrences in Early Buddhist Texts';
  }

  @override
  String get inflectionsSection => 'Inflections';

  @override
  String get inflectionsLiteNote =>
      'Full inflection tables are available in the Core pack. Please visit the Data Packs screen to download.';

  @override
  String get goToPacks => 'Go to Data Packs';

  @override
  String get listenAudio => 'Listen';

  @override
  String get audioPlaying => 'Playing...';

  @override
  String get audioError => 'Unable to play audio';

  @override
  String get audioLoading => 'Loading audio…';

  @override
  String get audioSlowNetwork => 'Slow connection, still loading audio…';

  @override
  String get audioPlayError =>
      'Could not play the audio. Check your connection and try again.';

  @override
  String activePack(String packName) {
    return 'Active Pack: $packName';
  }

  @override
  String get packLiteTitle => 'Lite Pack';

  @override
  String get packLiteDesc =>
      '5,000 common headwords, 48,727 inflections, complete Vietnamese gloss layer. Pre-bundled, fully offline.';

  @override
  String get packCoreTitle => 'Core Pack';

  @override
  String get packCoreDesc =>
      '64,138 headwords, 367,748 inflections, full inflection tables, Sanskrit cognates, and extended root data.';

  @override
  String get statusInstalled => 'Installed & Active';

  @override
  String get statusNotInstalled => 'Not Installed';

  @override
  String statusDownloading(int percent) {
    return 'Downloading: $percent%';
  }

  @override
  String get statusExtracting => 'Extracting and verifying data...';

  @override
  String storageUsed(String size) {
    return 'Storage used: $size';
  }

  @override
  String get btnDownloadCore => 'Download Core Pack';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDeleteCore => 'Delete Core Pack';

  @override
  String get btnSideload => 'Side-load from local file';

  @override
  String get sideloadPrompt =>
      'Enter local path to core_final.db or core_final.db.gz:';

  @override
  String get sideloadSuccess =>
      'Core pack successfully installed and activated!';

  @override
  String get deleteConfirmTitle => 'Delete Core Pack?';

  @override
  String get deleteConfirmMessage =>
      'The app will delete the Core database file and revert to the bundled Lite pack.';

  @override
  String get btnConfirmDelete => 'Confirm Delete';

  @override
  String get aboutTitle => 'About PaliDict';

  @override
  String get aboutAppSubtitle => 'Offline Pāḷi Dictionary';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get attributionTitle => 'Attribution & Data Sources';

  @override
  String get dpdAttribution =>
      'Underlying dictionary data from Digital Pali Dictionary (DPD) by Bhikkhu Bodhirasa, licensed under CC BY-NC-SA 4.0 International.';

  @override
  String get buuChonAttribution =>
      'Primary Vietnamese gloss layer sourced from Venerable Buu Chon\'s Pali-Vietnamese Dictionary (1976), supplemented by newly drafted translations under review.';

  @override
  String get aboutAuthorTitle => 'Author';

  @override
  String get aboutAuthorIntro =>
      'Developed by Kiên Lê, a Dhamma offering in support of the practice community.';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading data...';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get cungTuScreenTitle => 'Cùng Tu Companion App';

  @override
  String get cungTuAppTitle => 'Cùng Tu';

  @override
  String get cungTuTagline =>
      'Listen to the discourses — read & hear the complete five Nikāya collections';

  @override
  String get cungTuBadge => 'Giac Ngo ecosystem';

  @override
  String get cungTuDescription =>
      'Cùng Tu is an app for listening to and reading the Nikāya discourses: 750+ suttas with 388 hours of Southern Vietnamese narration, and bilingual Pāḷi–Vietnamese reading in Ven. Thích Minh Châu\'s translation. Cùng Tu and this dictionary belong to the same non-commercial community project.';

  @override
  String get cungTuFeaturesTitle => 'Key Features';

  @override
  String get cungTuFeatureNikaya =>
      'The complete five Nikāya collections — 750+ discourses, 388 hours of narration';

  @override
  String get cungTuFeatureBilingual =>
      'Bilingual Pāḷi–Vietnamese reading — Ven. Thích Minh Châu\'s translation';

  @override
  String get cungTuFeatureOffline => 'Download suttas and listen offline';

  @override
  String get cungTuFeatureFree => 'Completely free, no ads';

  @override
  String get cungTuCrossReferenceTitle => 'A study companion';

  @override
  String get cungTuCrossReference =>
      'Look words up here to better understand the chants and Pāḷi lessons in Cùng Tu. The two apps work independently and do not sync data with each other — they simply share the same community project.';

  @override
  String get cungTuOpenWeb => 'Learn more & get Cùng Tu';

  @override
  String get cungTuLaunchError => 'Could not open the link';

  @override
  String downloadFailedHttp(int statusCode) {
    return 'Download failed (HTTP $statusCode)';
  }

  @override
  String downloadFailedAllSources(int statusCode) {
    return 'Download failed from all sources (HTTP $statusCode)';
  }

  @override
  String verificationFailedSize(int expected, int actual) {
    return 'File size mismatch (expected $expected bytes, got $actual bytes)';
  }

  @override
  String get verificationFailedSha256 =>
      'Checksum (SHA-256) verification failed';

  @override
  String verificationFailedDbSize(int expected, int actual) {
    return 'Database size mismatch (expected $expected bytes, got $actual bytes)';
  }

  @override
  String downloadSize(String size) {
    return 'Download: $size';
  }

  @override
  String installedSize(String size) {
    return 'Installed: $size';
  }

  @override
  String get homeWordOfDay => 'Word of the day';

  @override
  String get homeFrequentTitle => 'Frequent in the discourses';

  @override
  String get homeAlphabetTitle => 'Browse by letter';

  @override
  String get homeRecentTitle => 'Recent';

  @override
  String letterListTitle(String letter) {
    return 'Words starting with \"$letter\"';
  }

  @override
  String inheritedFrom(String base) {
    return 'Inherited from \'$base\'';
  }

  @override
  String get inheritedGeneric => 'Inherited from the base word';

  @override
  String get englishMeaningTitle => 'English meaning (DPD)';

  @override
  String get viMeaningPending => 'Vietnamese meaning is being added.';

  @override
  String get constructionTitle => 'Meaning by components';

  @override
  String get statusError => 'Error';

  @override
  String packErrorHttp(int code) {
    return 'Could not download the pack (error $code). Check your connection and try again.';
  }

  @override
  String get packErrorVerification =>
      'The downloaded pack does not match the original data. Please try again.';

  @override
  String get packErrorNetwork =>
      'Something went wrong while downloading the pack. Check your connection and try again.';

  @override
  String get packErrorDelete =>
      'Could not delete the data pack. Please try again.';

  @override
  String get packErrorSideload =>
      'Could not load the data pack. Please try again.';

  @override
  String get packErrorSideloadMismatch =>
      'The selected pack file does not match the original data. Please try again.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageVi => 'Vietnamese';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get pronunciationTitle => 'Pronunciation';

  @override
  String get pronunciationNote =>
      'Approximate reading. A long mark (ā, ī, ū) means hold the vowel longer. Listen to the audio for the exact sound.';
}
