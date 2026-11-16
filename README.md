# Pāḷi Dictionary — Từ điển Pāḷi–Việt

A free, offline Pāḷi dictionary app built on the [Digital Pāḷi Dictionary (DPD)](https://github.com/digitalpalidictionary/dpd-db), with Vietnamese glosses, pronunciation guides and audio. Built with Flutter for Android, iOS, macOS, Windows and Linux.

> Tra cứu Pāḷi ngoại tuyến: hơn 64.000 mục từ, nghĩa tiếng Việt, hướng dẫn phát âm và âm thanh. Miễn phí, không quảng cáo, không thu thập dữ liệu.

## Download

- **Desktop (macOS / Windows) and Android APK:** see the [Releases](https://github.com/babyskill/palidict/releases) page — macOS `.dmg` (signed & notarized) and a Windows installer.
- **Google Play:** closed testing in progress.
- **App Store / TestFlight:** in preparation.

## Features

- **64,138 entries** in the full Core pack; a 5,000-entry Lite pack is bundled so the app works offline immediately
- **Vietnamese glosses** layered on DPD's English data, with a growing set of curated corrections ("Đã hiệu đính")
- **Pronunciation guides** in Vietnamese and English reading conventions; audio streamed from DPD (dpdict.net), male voice
- Browse by **Word of the day**, **Common in the suttas**, **A–Z index**, and recent lookups — search is there when you need it
- Vietnamese / English interface, light & dark themes
- No account, no ads, no tracking. Everything is stored on your device; the network is used only to download the Core pack and stream pronunciation audio

## Build from source

Requirements: Flutter 3.47+ (Dart 3.13+).

```bash
flutter pub get
flutter run -d macos        # or: windows, linux, android, ios
flutter build macos --release
flutter build windows --release
```

The Lite database (`data/lite_final.db`) is bundled as an asset so a fresh
clone builds and runs. The full Core pack is downloaded in-app from the
project's data mirrors (Cloudflare R2 primary, GitHub fallback in the
[babyskill/suttacentral](https://github.com/babyskill/suttacentral) repo).

A Windows installer script for Inno Setup lives in `windows/installer/`,
and `.github/workflows/` contains the Windows build pipeline used for
releases.

## Data & licensing — please read

- **App source code:** MIT License — see [LICENSE](LICENSE).
- **Dictionary data:** derived from DPD and distributed under
  **CC BY-NC-SA 4.0**. The databases in `data/` and the downloadable Core
  pack are **not** covered by the MIT license — see [NOTICE.md](NOTICE.md).
- **Vietnamese gloss layer:** draws on the Pāḷi–Vietnamese dictionary of
  Bửu Chơn, plus glosses translated and curated by this project.
- **Audio:** streamed from dpdict.net (DPD project); not redistributed here.

## Credits

- [Digital Pāḷi Dictionary](https://github.com/digitalpalidictionary/dpd-db) by Bhikkhu Bodhirasa and contributors — the foundation of this app.
- Developed by **Kiên Lê** as a Dhamma offering in support of the practice community — [app.giacngo.org](https://app.giacngo.org).

---

## Giới thiệu (Tiếng Việt)

**Từ điển Pāḷi - Việt** là ứng dụng tra cứu Pāḷi ngoại tuyến, xây dựng trên
nền dữ liệu Digital Pāḷi Dictionary (DPD):

- Gói Đầy đủ (Core) gồm **64.138 mục từ**; gói Lite 5.000 mục được đóng gói
  sẵn trong app để dùng ngay khi không có mạng.
- Lớp nghĩa tiếng Việt dựa trên tự điển Pāḷi–Việt của **Bửu Chơn**, kèm phần
  dịch và hiệu đính bổ sung của dự án (đánh dấu "Đã hiệu đính").
- Hướng dẫn phát âm theo quy ước đọc tiếng Việt và tiếng Anh; âm thanh phát
  âm (giọng nam) phát trực tiếp từ máy chủ DPD.
- Màn hình chính dẫn bằng chạm: Từ của ngày, Hay gặp trong kinh, Mục lục
  chữ cái, Tra gần đây.
- Ứng dụng không tài khoản, không quảng cáo, không theo dõi; dữ liệu chỉ
  lưu trên máy của bạn.

Mã nguồn ứng dụng theo giấy phép MIT; dữ liệu từ điển theo CC BY-NC-SA 4.0
của dự án DPD — chi tiết trong [NOTICE.md](NOTICE.md).
