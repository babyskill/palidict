enum SearchResultType {
  headword,
  inflected,
}

/// A search suggestion or result item.
class SearchResult {
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? grammar;
  final int? headwordId;
  final String? lemmaClean;
  final String? lookupKey;
  final List<int> targetHeadwordIds;

  const SearchResult({
    required this.type,
    required this.title,
    this.subtitle,
    this.grammar,
    this.headwordId,
    this.lemmaClean,
    this.lookupKey,
    this.targetHeadwordIds = const [],
  });

  SearchResult copyWith({
    SearchResultType? type,
    String? title,
    String? subtitle,
    String? grammar,
    int? headwordId,
    String? lemmaClean,
    String? lookupKey,
    List<int>? targetHeadwordIds,
  }) {
    return SearchResult(
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      grammar: grammar ?? this.grammar,
      headwordId: headwordId ?? this.headwordId,
      lemmaClean: lemmaClean ?? this.lemmaClean,
      lookupKey: lookupKey ?? this.lookupKey,
      targetHeadwordIds: targetHeadwordIds ?? this.targetHeadwordIds,
    );
  }
}
