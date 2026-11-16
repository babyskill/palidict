// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Từ điển Pāḷi - Việt';

  @override
  String get navLookup => 'Tra cứu';

  @override
  String get navPacks => 'Gói dữ liệu';

  @override
  String get navAbout => 'Giới thiệu';

  @override
  String get navCungTu => 'Cùng Tu';

  @override
  String get searchHint => 'Nhập từ cần tra (dhammā…)';

  @override
  String get searchEmptyPrompt => 'Nhập từ Pāḷi để bắt đầu tra cứu';

  @override
  String get desktopDetailEmptyPrompt =>
      'Chọn một từ ở cột bên trái hoặc nhập từ để tra cứu';

  @override
  String get searchNoResults => 'Không tìm thấy từ phù hợp';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả',
      one: '1 kết quả',
      zero: 'Không có kết quả',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get typeHeadword => 'Mục từ';

  @override
  String get typeInflected => 'Dạng biến cách';

  @override
  String inflectedTitle(String key) {
    return 'Dạng biến cách: $key';
  }

  @override
  String inflectedHeadwordsPrompt(int count) {
    return 'Các mục từ tương ứng ($count):';
  }

  @override
  String get grammarLabel => 'Ngữ pháp';

  @override
  String get vietnameseMeaningSection => 'Nghĩa tiếng Việt';

  @override
  String get sourceBuuChon => 'HT Bửu Chơn (1976)';

  @override
  String get sourceNewTranslation => 'Bản dịch mới — đang hiệu đính';

  @override
  String get sourceCurated => 'Đã hiệu đính';

  @override
  String get sensesSection => 'Các nét nghĩa';

  @override
  String get englishMeaningSection => 'Nghĩa tiếng Anh';

  @override
  String get grammarConstructionSection => 'Ngữ pháp & Cấu tạo từ';

  @override
  String get rootLabel => 'Căn từ';

  @override
  String get rootMeaningLabel => 'Ý nghĩa căn';

  @override
  String get constructionLabel => 'Cấu tạo';

  @override
  String get phoneticLabel => 'Biến âm';

  @override
  String get sanskritLabel => 'Tiếng Phạn (Sanskrit)';

  @override
  String get exampleSection => 'Ví dụ kinh văn';

  @override
  String get sourceLabel => 'Nguồn';

  @override
  String get suttaLabel => 'Kinh văn';

  @override
  String get ebtCountLabel => 'Tần suất EBT';

  @override
  String ebtCountTimes(String count) {
    return '$count lần xuất hiện trong kinh điển sơ thời';
  }

  @override
  String get inflectionsSection => 'Bảng biến cách';

  @override
  String get inflectionsLiteNote =>
      'Bảng biến cách chi tiết khả dụng trong gói Đầy đủ (Core pack). Vui lòng vào mục Gói dữ liệu để tải về.';

  @override
  String get goToPacks => 'Đến Gói dữ liệu';

  @override
  String get listenAudio => 'Nghe phát âm';

  @override
  String get audioPlaying => 'Đang phát...';

  @override
  String get audioError => 'Không thể phát âm thanh';

  @override
  String get audioLoading => 'Đang tải âm thanh…';

  @override
  String get audioSlowNetwork => 'Kết nối mạng chậm, vẫn đang tải âm thanh…';

  @override
  String get audioPlayError =>
      'Không phát được âm thanh. Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String activePack(String packName) {
    return 'Gói đang kích hoạt: $packName';
  }

  @override
  String get packLiteTitle => 'Gói Tinh gọn (Lite pack)';

  @override
  String get packLiteDesc =>
      '5.000 mục từ thông dụng, 48.727 dạng biến cách, toàn bộ nghĩa tiếng Việt. Tích hợp sẵn trong ứng dụng, tra cứu ngoại tuyến ngay lập tức.';

  @override
  String get packCoreTitle => 'Gói Đầy đủ (Core pack)';

  @override
  String get packCoreDesc =>
      '64.138 mục từ, 367.748 dạng biến cách, bảng biến cách chi tiết, tương đương Phạn ngữ và thông tin gốc từ mở rộng.';

  @override
  String get statusInstalled => 'Đã cài đặt & đang sử dụng';

  @override
  String get statusNotInstalled => 'Chưa cài đặt';

  @override
  String statusDownloading(int percent) {
    return 'Đang tải về: $percent%';
  }

  @override
  String get statusExtracting => 'Đang giải nén và kiểm tra dữ liệu...';

  @override
  String storageUsed(String size) {
    return 'Dung lượng bộ nhớ: $size';
  }

  @override
  String get btnDownloadCore => 'Tải gói Đầy đủ (Core)';

  @override
  String get btnCancel => 'Hủy';

  @override
  String get btnDeleteCore => 'Xóa gói Đầy đủ';

  @override
  String get btnSideload => 'Nạp gói từ tệp tin thiết bị';

  @override
  String get sideloadPrompt =>
      'Nhập đường dẫn tệp core_final.db hoặc core_final.db.gz trên máy:';

  @override
  String get sideloadSuccess => 'Đã nạp và kích hoạt gói Core thành công!';

  @override
  String get deleteConfirmTitle => 'Xác nhận xóa gói Đầy đủ?';

  @override
  String get deleteConfirmMessage =>
      'Ứng dụng sẽ xóa tệp dữ liệu Core và quay về sử dụng gói Tinh gọn (Lite) tích hợp sẵn.';

  @override
  String get btnConfirmDelete => 'Xác nhận xóa';

  @override
  String get aboutTitle => 'Giới thiệu ứng dụng';

  @override
  String get aboutAppSubtitle => 'Từ điển Pāḷi - Việt ngoại tuyến';

  @override
  String appVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get attributionTitle => 'Bản quyền & Nguồn dữ liệu';

  @override
  String get dpdAttribution =>
      'Dữ liệu từ điển gốc từ Digital Pali Dictionary (DPD) do Tỳ-khưu Bodhirasa biên soạn, phát hành dưới giấy phép Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).';

  @override
  String get buuChonAttribution =>
      'Lớp dịch nghĩa tiếng Việt chính yếu trích từ Từ điển Pāḷi - Việt của Cố Hòa thượng Bửu Chơn (xuất bản năm 1976), kết hợp cùng các bản dịch đối chiếu mới đang trong tiến trình hiệu đính.';

  @override
  String get aboutAuthorTitle => 'Tác giả';

  @override
  String get aboutAuthorIntro =>
      'Ứng dụng do Kiên Lê phát triển, một thiện pháp hỗ trợ cộng đồng tu học.';

  @override
  String get close => 'Đóng';

  @override
  String get back => 'Quay lại';

  @override
  String get loading => 'Đang tải dữ liệu...';

  @override
  String errorOccurred(String error) {
    return 'Đã xảy ra lỗi: $error';
  }

  @override
  String get cungTuScreenTitle => 'Ứng dụng Cùng Tu';

  @override
  String get cungTuAppTitle => 'Cùng Tu';

  @override
  String get cungTuTagline =>
      'Nghe Kinh Phật — Nghe & Đọc Trọn 5 Bộ Kinh Nikāya';

  @override
  String get cungTuBadge => 'Hệ sinh thái Giác Ngộ';

  @override
  String get cungTuDescription =>
      'Cùng Tu là ứng dụng nghe và đọc Kinh Phật Nikāya: hơn 750 bài kinh với 388 giờ giọng đọc miền Nam, đọc song ngữ Pāḷi–Việt theo bản dịch của HT Thích Minh Châu. Cùng Tu và từ điển này cùng thuộc một dự án cộng đồng phi thương mại.';

  @override
  String get cungTuFeaturesTitle => 'Tính năng nổi bật';

  @override
  String get cungTuFeatureNikaya =>
      'Nghe trọn 5 bộ Kinh Nikāya — hơn 750 bài, 388 giờ giọng đọc miền Nam';

  @override
  String get cungTuFeatureBilingual =>
      'Đọc song ngữ Pāḷi–Việt — bản dịch HT Thích Minh Châu';

  @override
  String get cungTuFeatureOffline => 'Tải về nghe offline, không cần mạng';

  @override
  String get cungTuFeatureFree => 'Hoàn toàn miễn phí, không quảng cáo';

  @override
  String get cungTuCrossReferenceTitle => 'Đồng hành tu học';

  @override
  String get cungTuCrossReference =>
      'Tra nghĩa tại đây để hiểu rõ hơn các bài tụng kinh và bài học Pāḷi trong Cùng Tu. Hai ứng dụng hoạt động độc lập và không đồng bộ dữ liệu với nhau — chỉ cùng chung một dự án cộng đồng.';

  @override
  String get cungTuOpenWeb => 'Tìm hiểu & tải app Cùng Tu';

  @override
  String get cungTuLaunchError => 'Không thể mở liên kết';

  @override
  String downloadFailedHttp(int statusCode) {
    return 'Tải về thất bại (HTTP $statusCode)';
  }

  @override
  String downloadFailedAllSources(int statusCode) {
    return 'Tải về thất bại từ tất cả các nguồn (HTTP $statusCode)';
  }

  @override
  String verificationFailedSize(int expected, int actual) {
    return 'Kích thước tệp không khớp (kỳ vọng $expected bytes, thực tế $actual bytes)';
  }

  @override
  String get verificationFailedSha256 => 'Mã kiểm tra (SHA-256) không khớp';

  @override
  String verificationFailedDbSize(int expected, int actual) {
    return 'Kích thước cơ sở dữ liệu không khớp (kỳ vọng $expected bytes, thực tế $actual bytes)';
  }

  @override
  String downloadSize(String size) {
    return 'Tải về: $size';
  }

  @override
  String installedSize(String size) {
    return 'Cài đặt: $size';
  }

  @override
  String get homeWordOfDay => 'Từ của ngày';

  @override
  String get homeFrequentTitle => 'Hay gặp trong kinh';

  @override
  String get homeAlphabetTitle => 'Mục lục chữ cái';

  @override
  String get homeRecentTitle => 'Gần đây';

  @override
  String letterListTitle(String letter) {
    return 'Từ bắt đầu bằng \"$letter\"';
  }

  @override
  String inheritedFrom(String base) {
    return 'Kế thừa từ \'$base\'';
  }

  @override
  String get inheritedGeneric => 'Kế thừa từ từ gốc';

  @override
  String get englishMeaningTitle => 'Nghĩa tiếng Anh (DPD)';

  @override
  String get viMeaningPending => 'Nghĩa tiếng Việt đang được bổ sung.';

  @override
  String get constructionTitle => 'Nghĩa theo cấu tạo';

  @override
  String get statusError => 'Lỗi';

  @override
  String packErrorHttp(int code) {
    return 'Không tải được gói (mã lỗi $code). Kiểm tra kết nối mạng rồi thử lại.';
  }

  @override
  String get packErrorVerification =>
      'Tệp gói tải về không khớp dữ liệu gốc. Vui lòng thử lại.';

  @override
  String get packErrorNetwork =>
      'Đã xảy ra lỗi khi tải gói. Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String get packErrorDelete =>
      'Đã xảy ra lỗi khi xóa gói dữ liệu. Vui lòng thử lại.';

  @override
  String get packErrorSideload =>
      'Đã xảy ra lỗi khi nạp gói dữ liệu. Vui lòng thử lại.';

  @override
  String get packErrorSideloadMismatch =>
      'Tệp gói nạp vào không khớp dữ liệu gốc. Vui lòng thử lại.';

  @override
  String get settings => 'Cài đặt';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageVi => 'Tiếng Việt';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get pronunciationTitle => 'Cách đọc';

  @override
  String get pronunciationNote =>
      'Cách đọc gần đúng. Dấu ngang (ā, ī, ū) nghĩa là đọc kéo dài. Nghe phát âm để có âm chuẩn.';
}
