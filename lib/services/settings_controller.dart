import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform channel for managing the macOS window title.
class WindowTitleService {
  static const MethodChannel _channel =
      MethodChannel('org.giacngo.palidict/window');

  static const String viTitle = 'Từ điển Pāḷi - Việt - giacngo.org';
  static const String enTitle = 'Pāḷi Dictionary - giacngo.org';

  /// Updates the macOS window title according to the chosen locale.
  static Future<void> updateTitleForLocale(Locale locale) async {
    if (kIsWeb) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (!Platform.isMacOS) return;
      final title = locale.languageCode == 'en' ? enTitle : viTitle;
      await _channel.invokeMethod('setWindowTitle', {'title': title});
    } catch (e) {
      debugPrint('WindowTitleService notice: $e');
    }
  }
}

/// Controller that manages theme mode and locale settings.
///
/// Persists user preferences via [SharedPreferences] and notifies listeners
/// upon changes to trigger immediate UI updates across the entire application.
class SettingsController extends ChangeNotifier {
  static const String prefKeyThemeMode = 'settings_theme_mode';
  static const String prefKeyLanguageCode = 'settings_language_code';

  static SettingsController? _instance;
  static SettingsController get instance => _instance ??= SettingsController();

  @visibleForTesting
  static set instance(SettingsController controller) => _instance = controller;

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('vi');
  bool _isLoaded = false;

  SettingsController({SharedPreferences? prefs}) {
    _prefs = prefs;
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads persisted settings from SharedPreferences, defaulting to
  /// [ThemeMode.light] and Vietnamese locale on first run.
  Future<void> loadSettings({SharedPreferences? prefs}) async {
    if (prefs != null) {
      _prefs = prefs;
    }
    final sp = await _getPrefs();

    // Theme mode
    final themeStr = sp.getString(prefKeyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Locale
    final langStr = sp.getString(prefKeyLanguageCode);
    if (langStr == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('vi');
    }

    _isLoaded = true;
    notifyListeners();
    await WindowTitleService.updateTitleForLocale(_locale);
  }

  /// Updates the active [ThemeMode] and persists the change.
  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final sp = await _getPrefs();
    String val;
    switch (mode) {
      case ThemeMode.dark:
        val = 'dark';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
      case ThemeMode.light:
        val = 'light';
        break;
    }
    await sp.setString(prefKeyThemeMode, val);
  }

  /// Updates the active [Locale] and persists the change.
  Future<void> updateLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();

    final sp = await _getPrefs();
    await sp.setString(prefKeyLanguageCode, newLocale.languageCode);
    await WindowTitleService.updateTitleForLocale(_locale);
  }
}
