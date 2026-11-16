import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/home_sections_data.dart';

/// App-private storage manager for recently viewed headwords.
///
/// Stores a JSON list, newest first, of `{id, lemma_1}`, deduplicated by `id`,
/// capped at 20. Survives app restarts and pack switches.
class RecentWordsService extends ChangeNotifier {
  static const String prefKey = 'recent_words_history';

  static RecentWordsService? _instance;
  static RecentWordsService get instance => _instance ??= RecentWordsService();

  @visibleForTesting
  static set instance(RecentWordsService service) => _instance = service;

  SharedPreferences? _prefs;
  List<RecentWordItem>? _cachedWords;

  RecentWordsService({SharedPreferences? prefs}) {
    _prefs = prefs;
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Retrieves the list of recent words (newest first).
  Future<List<RecentWordItem>> getRecentWords() async {
    if (_cachedWords != null) {
      return List.unmodifiable(_cachedWords!);
    }

    final prefs = await _getPrefs();
    final rawJson = prefs.getString(prefKey);
    if (rawJson == null || rawJson.isEmpty) {
      _cachedWords = [];
      return const [];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        _cachedWords = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => RecentWordItem.fromJson(m))
            .where((w) => w.lemma1.isNotEmpty)
            .toList();
      } else {
        _cachedWords = [];
      }
    } catch (_) {
      _cachedWords = [];
    }

    return List.unmodifiable(_cachedWords!);
  }

  /// Records a viewed headword: newest first, deduplicated by `id`, capped at 20.
  Future<void> recordWord({required int id, required String lemma1}) async {
    if (lemma1.trim().isEmpty) return;

    final current = (await getRecentWords()).toList();
    current.removeWhere((item) => item.id == id);
    current.insert(0, RecentWordItem(id: id, lemma1: lemma1));

    final capped = current.take(20).toList();
    _cachedWords = capped;

    final prefs = await _getPrefs();
    await prefs.setString(
      prefKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );

    notifyListeners();
  }

  /// Removes a word by `id` from the recent history.
  Future<void> removeWord(int id) async {
    final current = (await getRecentWords()).toList();
    final initialLength = current.length;
    current.removeWhere((item) => item.id == id);

    if (current.length != initialLength) {
      _cachedWords = current;
      final prefs = await _getPrefs();
      await prefs.setString(
        prefKey,
        jsonEncode(current.map((e) => e.toJson()).toList()),
      );
      notifyListeners();
    }
  }

  /// Clears the recent history (used in tests / debug).
  Future<void> clear() async {
    _cachedWords = [];
    final prefs = await _getPrefs();
    await prefs.remove(prefKey);
    notifyListeners();
  }
}
