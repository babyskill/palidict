import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Application title
  ///
  /// In vi, this message translates to:
  /// **'Từ điển Pāḷi - Việt'**
  String get appTitle;

  /// Navigation item for lookup
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu'**
  String get navLookup;

  /// Navigation item for data packs
  ///
  /// In vi, this message translates to:
  /// **'Gói dữ liệu'**
  String get navPacks;

  /// Navigation item for about screen
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get navAbout;

  /// Navigation item for Cùng Tu companion app
  ///
  /// In vi, this message translates to:
  /// **'Cùng Tu'**
  String get navCungTu;

  /// Search input placeholder
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ cần tra (dhammā…)'**
  String get searchHint;

  /// Prompt when search input is empty
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ Pāḷi để bắt đầu tra cứu'**
  String get searchEmptyPrompt;

  /// Empty state prompt for master-detail right pane on desktop
  ///
  /// In vi, this message translates to:
  /// **'Chọn một từ ở cột bên trái hoặc nhập từ để tra cứu'**
  String get desktopDetailEmptyPrompt;

  /// Message when no words match
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy từ phù hợp'**
  String get searchNoResults;

  /// Search results counter
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =0{Không có kết quả} =1{1 kết quả} other{{count} kết quả}}'**
  String searchResultsCount(int count);

  /// Tooltip for clear search button
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearch;

  /// Label for headword suggestion type
  ///
  /// In vi, this message translates to:
  /// **'Mục từ'**
  String get typeHeadword;

  /// Label for inflected suggestion type
  ///
  /// In vi, this message translates to:
  /// **'Dạng biến cách'**
  String get typeInflected;

  /// Title for inflected forms view
  ///
  /// In vi, this message translates to:
  /// **'Dạng biến cách: {key}'**
  String inflectedTitle(String key);

  /// Header for headwords matching an inflected form
  ///
  /// In vi, this message translates to:
  /// **'Các mục từ tương ứng ({count}):'**
  String inflectedHeadwordsPrompt(int count);

  /// Label for grammar note
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp'**
  String get grammarLabel;

  /// Section header for Vietnamese meaning
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa tiếng Việt'**
  String get vietnameseMeaningSection;

  /// Source citation for Buu Chon dictionary
  ///
  /// In vi, this message translates to:
  /// **'HT Bửu Chơn (1976)'**
  String get sourceBuuChon;

  /// Source tag for new translation under review
  ///
  /// In vi, this message translates to:
  /// **'Bản dịch mới — đang hiệu đính'**
  String get sourceNewTranslation;

  /// Source tag for curated terminology correction
  ///
  /// In vi, this message translates to:
  /// **'Đã hiệu đính'**
  String get sourceCurated;

  /// Section header for multiple word senses
  ///
  /// In vi, this message translates to:
  /// **'Các nét nghĩa'**
  String get sensesSection;

  /// Section header for English meaning
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa tiếng Anh'**
  String get englishMeaningSection;

  /// Section header for grammar and construction block
  ///
  /// In vi, this message translates to:
  /// **'Ngữ pháp & Cấu tạo từ'**
  String get grammarConstructionSection;

  /// Label for root key
  ///
  /// In vi, this message translates to:
  /// **'Căn từ'**
  String get rootLabel;

  /// Label for root meaning
  ///
  /// In vi, this message translates to:
  /// **'Ý nghĩa căn'**
  String get rootMeaningLabel;

  /// Label for word construction
  ///
  /// In vi, this message translates to:
  /// **'Cấu tạo'**
  String get constructionLabel;

  /// Label for phonetic changes
  ///
  /// In vi, this message translates to:
  /// **'Biến âm'**
  String get phoneticLabel;

  /// Label for Sanskrit equivalent
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Phạn (Sanskrit)'**
  String get sanskritLabel;

  /// Section header for example block
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ kinh văn'**
  String get exampleSection;

  /// Label for source reference
  ///
  /// In vi, this message translates to:
  /// **'Nguồn'**
  String get sourceLabel;

  /// Label for sutta reference
  ///
  /// In vi, this message translates to:
  /// **'Kinh văn'**
  String get suttaLabel;

  /// Label for EBT occurrence count
  ///
  /// In vi, this message translates to:
  /// **'Tần suất EBT'**
  String get ebtCountLabel;

  /// Description of EBT count
  ///
  /// In vi, this message translates to:
  /// **'{count} lần xuất hiện trong kinh điển sơ thời'**
  String ebtCountTimes(String count);

  /// Section header for inflections
  ///
  /// In vi, this message translates to:
  /// **'Bảng biến cách'**
  String get inflectionsSection;

  /// Notice on Lite pack that inflections require Core pack
  ///
  /// In vi, this message translates to:
  /// **'Bảng biến cách chi tiết khả dụng trong gói Đầy đủ (Core pack). Vui lòng vào mục Gói dữ liệu để tải về.'**
  String get inflectionsLiteNote;

  /// Button to navigate to packs screen
  ///
  /// In vi, this message translates to:
  /// **'Đến Gói dữ liệu'**
  String get goToPacks;

  /// Button to play male pronunciation audio
  ///
  /// In vi, this message translates to:
  /// **'Nghe phát âm'**
  String get listenAudio;

  /// State when audio is playing
  ///
  /// In vi, this message translates to:
  /// **'Đang phát...'**
  String get audioPlaying;

  /// Error message when audio playback fails
  ///
  /// In vi, this message translates to:
  /// **'Không thể phát âm thanh'**
  String get audioError;

  /// Trạng thái đang tải âm thanh
  ///
  /// In vi, this message translates to:
  /// **'Đang tải âm thanh…'**
  String get audioLoading;

  /// Thông báo khi kết nối mạng chậm và đang tải âm thanh
  ///
  /// In vi, this message translates to:
  /// **'Kết nối mạng chậm, vẫn đang tải âm thanh…'**
  String get audioSlowNetwork;

  /// Thông báo lỗi khi không phát được âm thanh
  ///
  /// In vi, this message translates to:
  /// **'Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.'**
  String get audioPlayError;

  /// Active data pack name banner
  ///
  /// In vi, this message translates to:
  /// **'Gói đang kích hoạt: {packName}'**
  String activePack(String packName);

  /// Title of Lite pack
  ///
  /// In vi, this message translates to:
  /// **'Gói Tinh gọn (Lite pack)'**
  String get packLiteTitle;

  /// Description of Lite pack
  ///
  /// In vi, this message translates to:
  /// **'5.000 mục từ thông dụng, 48.727 dạng biến cách, toàn bộ nghĩa tiếng Việt. Tích hợp sẵn trong ứng dụng, tra cứu ngoại tuyến ngay lập tức.'**
  String get packLiteDesc;

  /// Title of Core pack
  ///
  /// In vi, this message translates to:
  /// **'Gói Đầy đủ (Core pack)'**
  String get packCoreTitle;

  /// Description of Core pack
  ///
  /// In vi, this message translates to:
  /// **'64.138 mục từ, 367.748 dạng biến cách, bảng biến cách chi tiết, tương đương Phạn ngữ và thông tin gốc từ mở rộng.'**
  String get packCoreDesc;

  /// Pack status installed
  ///
  /// In vi, this message translates to:
  /// **'Đã cài đặt & đang sử dụng'**
  String get statusInstalled;

  /// Pack status not installed
  ///
  /// In vi, this message translates to:
  /// **'Chưa cài đặt'**
  String get statusNotInstalled;

  /// Pack status downloading
  ///
  /// In vi, this message translates to:
  /// **'Đang tải về: {percent}%'**
  String statusDownloading(int percent);

  /// Pack status extracting
  ///
  /// In vi, this message translates to:
  /// **'Đang giải nén và kiểm tra dữ liệu...'**
  String get statusExtracting;

  /// Storage used indicator
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng bộ nhớ: {size}'**
  String storageUsed(String size);

  /// Button to download Core pack
  ///
  /// In vi, this message translates to:
  /// **'Tải gói Đầy đủ (Core)'**
  String get btnDownloadCore;

  /// Cancel button
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get btnCancel;

  /// Button to delete Core pack
  ///
  /// In vi, this message translates to:
  /// **'Xóa gói Đầy đủ'**
  String get btnDeleteCore;

  /// Button to side-load Core pack from file
  ///
  /// In vi, this message translates to:
  /// **'Nạp gói từ tệp tin thiết bị'**
  String get btnSideload;

  /// Prompt for local path
  ///
  /// In vi, this message translates to:
  /// **'Nhập đường dẫn tệp core_final.db hoặc core_final.db.gz trên máy:'**
  String get sideloadPrompt;

  /// Success notification for sideload
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp và kích hoạt gói Core thành công!'**
  String get sideloadSuccess;

  /// Dialog title for deletion confirmation
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa gói Đầy đủ?'**
  String get deleteConfirmTitle;

  /// Dialog message for deletion confirmation
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng sẽ xóa tệp dữ liệu Core và quay về sử dụng gói Tinh gọn (Lite) tích hợp sẵn.'**
  String get deleteConfirmMessage;

  /// Confirm deletion button
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get btnConfirmDelete;

  /// About screen title
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu ứng dụng'**
  String get aboutTitle;

  /// App subtitle on about screen
  ///
  /// In vi, this message translates to:
  /// **'Từ điển Pāḷi - Việt ngoại tuyến'**
  String get aboutAppSubtitle;

  /// App version string
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}'**
  String appVersion(String version);

  /// Attribution section header
  ///
  /// In vi, this message translates to:
  /// **'Bản quyền & Nguồn dữ liệu'**
  String get attributionTitle;

  /// DPD attribution text
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu từ điển gốc từ Digital Pali Dictionary (DPD) do Tỳ-khưu Bodhirasa biên soạn, phát hành dưới giấy phép Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).'**
  String get dpdAttribution;

  /// Buu Chon dictionary attribution
  ///
  /// In vi, this message translates to:
  /// **'Lớp dịch nghĩa tiếng Việt chính yếu trích từ Từ điển Pāḷi - Việt của Cố Hòa thượng Bửu Chơn (xuất bản năm 1976), kết hợp cùng các bản dịch đối chiếu mới đang trong tiến trình hiệu đính.'**
  String get buuChonAttribution;

  /// Author card title on about screen
  ///
  /// In vi, this message translates to:
  /// **'Tác giả'**
  String get aboutAuthorTitle;

  /// Author card introduction text on about screen
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng do Kiên Lê phát triển, một thiện pháp hỗ trợ cộng đồng tu học.'**
  String get aboutAuthorIntro;

  /// Close button label
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// Back button label
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// Loading indicator label
  ///
  /// In vi, this message translates to:
  /// **'Đang tải dữ liệu...'**
  String get loading;

  /// Generic error display
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi: {error}'**
  String errorOccurred(String error);

  /// AppBar title for Cùng Tu companion screen
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng Cùng Tu'**
  String get cungTuScreenTitle;

  /// Title of the companion app
  ///
  /// In vi, this message translates to:
  /// **'Cùng Tu'**
  String get cungTuAppTitle;

  /// Tagline for Cùng Tu app
  ///
  /// In vi, this message translates to:
  /// **'Nghe Kinh Phật — Nghe & Đọc Trọn 5 Bộ Kinh Nikāya'**
  String get cungTuTagline;

  /// Badge indicating companion community project
  ///
  /// In vi, this message translates to:
  /// **'Hệ sinh thái Giác Ngộ'**
  String get cungTuBadge;

  /// Short description of Cùng Tu
  ///
  /// In vi, this message translates to:
  /// **'Cùng Tu là ứng dụng nghe và đọc Kinh Phật Nikāya: hơn 750 bài kinh với 388 giờ giọng đọc miền Nam, đọc song ngữ Pāḷi–Việt theo bản dịch của HT Thích Minh Châu. Cùng Tu và từ điển này cùng thuộc một dự án cộng đồng phi thương mại.'**
  String get cungTuDescription;

  /// Section header for Cùng Tu features
  ///
  /// In vi, this message translates to:
  /// **'Tính năng nổi bật'**
  String get cungTuFeaturesTitle;

  /// Feature bullet for 5 Nikaya collections with audio
  ///
  /// In vi, this message translates to:
  /// **'Nghe trọn 5 bộ Kinh Nikāya — hơn 750 bài, 388 giờ giọng đọc miền Nam'**
  String get cungTuFeatureNikaya;

  /// Feature bullet for bilingual reading
  ///
  /// In vi, this message translates to:
  /// **'Đọc song ngữ Pāḷi–Việt — bản dịch HT Thích Minh Châu'**
  String get cungTuFeatureBilingual;

  /// Feature bullet for offline listening
  ///
  /// In vi, this message translates to:
  /// **'Tải về nghe offline, không cần mạng'**
  String get cungTuFeatureOffline;

  /// Feature bullet for free and ad-free experience
  ///
  /// In vi, this message translates to:
  /// **'Hoàn toàn miễn phí, không quảng cáo'**
  String get cungTuFeatureFree;

  /// Section header for cross-reference note
  ///
  /// In vi, this message translates to:
  /// **'Đồng hành tu học'**
  String get cungTuCrossReferenceTitle;

  /// Cross-reference note explaining connection to dictionary
  ///
  /// In vi, this message translates to:
  /// **'Tra nghĩa tại đây để hiểu rõ hơn các bài tụng kinh và bài học Pāḷi trong Cùng Tu. Hai ứng dụng hoạt động độc lập và không đồng bộ dữ liệu với nhau — chỉ cùng chung một dự án cộng đồng.'**
  String get cungTuCrossReference;

  /// Button to open Cùng Tu web landing page and app
  ///
  /// In vi, this message translates to:
  /// **'Tìm hiểu & tải app Cùng Tu'**
  String get cungTuOpenWeb;

  /// Snackbar message when web link fails to launch
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở liên kết'**
  String get cungTuLaunchError;

  /// Error message when download returns HTTP error code
  ///
  /// In vi, this message translates to:
  /// **'Tải về thất bại (HTTP {statusCode})'**
  String downloadFailedHttp(int statusCode);

  /// Error message when all download sources fail
  ///
  /// In vi, this message translates to:
  /// **'Tải về thất bại từ tất cả các nguồn (HTTP {statusCode})'**
  String downloadFailedAllSources(int statusCode);

  /// Error message for size mismatch
  ///
  /// In vi, this message translates to:
  /// **'Kích thước tệp không khớp (kỳ vọng {expected} bytes, thực tế {actual} bytes)'**
  String verificationFailedSize(int expected, int actual);

  /// Error message for sha256 mismatch
  ///
  /// In vi, this message translates to:
  /// **'Mã kiểm tra (SHA-256) không khớp'**
  String get verificationFailedSha256;

  /// Error message for db size mismatch
  ///
  /// In vi, this message translates to:
  /// **'Kích thước cơ sở dữ liệu không khớp (kỳ vọng {expected} bytes, thực tế {actual} bytes)'**
  String verificationFailedDbSize(int expected, int actual);

  /// Download size label
  ///
  /// In vi, this message translates to:
  /// **'Tải về: {size}'**
  String downloadSize(String size);

  /// Installed size label
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt: {size}'**
  String installedSize(String size);

  /// Word of the Day section header
  ///
  /// In vi, this message translates to:
  /// **'Từ của ngày'**
  String get homeWordOfDay;

  /// Frequent in the Discourses section header
  ///
  /// In vi, this message translates to:
  /// **'Hay gặp trong kinh'**
  String get homeFrequentTitle;

  /// Alphabet Index section header
  ///
  /// In vi, this message translates to:
  /// **'Mục lục chữ cái'**
  String get homeAlphabetTitle;

  /// Recent words section header
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get homeRecentTitle;

  /// Screen/section title for words starting with a specific letter
  ///
  /// In vi, this message translates to:
  /// **'Từ bắt đầu bằng \"{letter}\"'**
  String letterListTitle(String letter);

  /// Label indicating Vietnamese gloss was inherited from base lemma
  ///
  /// In vi, this message translates to:
  /// **'Kế thừa từ \'{base}\''**
  String inheritedFrom(String base);

  /// Label indicating Vietnamese gloss was inherited from a base word without specified lemma
  ///
  /// In vi, this message translates to:
  /// **'Kế thừa từ từ gốc'**
  String get inheritedGeneric;

  /// Title for English meaning section when no Vietnamese meaning exists
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa tiếng Anh (DPD)'**
  String get englishMeaningTitle;

  /// Note indicating Vietnamese meaning is pending
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa tiếng Việt đang được bổ sung.'**
  String get viMeaningPending;

  /// Title for compound word construction meaning section
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa theo cấu tạo'**
  String get constructionTitle;

  /// Status chip label for pack in error state
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get statusError;

  /// Error message when pack download fails with HTTP status code
  ///
  /// In vi, this message translates to:
  /// **'Không tải được gói (mã lỗi {code}). Kiểm tra kết nối mạng rồi thử lại.'**
  String packErrorHttp(int code);

  /// Error message when downloaded pack size or checksum does not match expected manifest
  ///
  /// In vi, this message translates to:
  /// **'Tệp gói tải về không khớp dữ liệu gốc. Vui lòng thử lại.'**
  String get packErrorVerification;

  /// Error message when pack download fails due to network, timeout, or general download error
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi tải gói. Kiểm tra kết nối mạng rồi thử lại.'**
  String get packErrorNetwork;

  /// Error message when deleting data pack fails
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi xóa gói dữ liệu. Vui lòng thử lại.'**
  String get packErrorDelete;

  /// Error message when loading data pack from local device file fails
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi nạp gói dữ liệu. Vui lòng thử lại.'**
  String get packErrorSideload;

  /// Error message when sideloaded pack file fails verification
  ///
  /// In vi, this message translates to:
  /// **'Tệp gói nạp vào không khớp dữ liệu gốc. Vui lòng thử lại.'**
  String get packErrorSideloadMismatch;

  /// Title for settings screen and icon tooltip
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// Section header for appearance settings
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsAppearance;

  /// Light theme option
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// Dark theme option
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

  /// System default theme option
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsThemeSystem;

  /// Section header for language settings
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// Vietnamese language option
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get settingsLanguageVi;

  /// English language option
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// Title for pronunciation section
  ///
  /// In vi, this message translates to:
  /// **'Cách đọc'**
  String get pronunciationTitle;

  /// Footnote explaining approximate pronunciation conventions
  ///
  /// In vi, this message translates to:
  /// **'Cách đọc gần đúng. Dấu ngang (ā, ī, ū) nghĩa là đọc kéo dài. Nghe phát âm để có âm chuẩn.'**
  String get pronunciationNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
