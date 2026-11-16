import 'dart:convert';

/// Represents a row from the `lookup` table.
class LookupEntry {
  final String lookupKey;
  final List<int> headwordIds;
  final String? deconstructor;
  final List<List<dynamic>> grammarEntries;

  const LookupEntry({
    required this.lookupKey,
    required this.headwordIds,
    this.deconstructor,
    this.grammarEntries = const [],
  });

  /// Returns a formatted summary of grammar notes.
  String get grammarSummary {
    if (grammarEntries.isEmpty) return '';
    final notes = <String>{};
    for (final entry in grammarEntries) {
      if (entry.length >= 3 && entry[2] != null) {
        notes.add(entry[2].toString());
      } else if (entry.isNotEmpty) {
        notes.add(entry.map((e) => e.toString()).join(' '));
      }
    }
    return notes.join('; ');
  }

  factory LookupEntry.fromMap(Map<String, dynamic> map) {
    final rawKey = map['lookup_key'] as String? ?? '';
    final rawHeadwords = map['headwords'] as String?;
    final rawGrammar = map['grammar'] as String?;

    List<int> headwordsList = [];
    if (rawHeadwords != null && rawHeadwords.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHeadwords);
        if (decoded is List) {
          headwordsList = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    List<List<dynamic>> grammarList = [];
    if (rawGrammar != null && rawGrammar.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawGrammar);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is List) {
              grammarList.add(item);
            }
          }
        }
      } catch (_) {}
    }

    return LookupEntry(
      lookupKey: rawKey,
      headwordIds: headwordsList,
      deconstructor: map['deconstructor'] as String?,
      grammarEntries: grammarList,
    );
  }
}
