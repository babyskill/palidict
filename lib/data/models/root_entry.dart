/// Represents a row from the `roots` table.
class RootEntry {
  final String root;
  final String? rootMeaning;
  final String? rootSign;
  final String? rootGroup;
  final String? sanskritRoot;
  final String? sanskritRootMeaning;

  const RootEntry({
    required this.root,
    this.rootMeaning,
    this.rootSign,
    this.rootGroup,
    this.sanskritRoot,
    this.sanskritRootMeaning,
  });

  factory RootEntry.fromMap(Map<String, dynamic> map) {
    return RootEntry(
      root: map['root'] as String? ?? '',
      rootMeaning: map['root_meaning'] as String?,
      rootSign: map['root_sign'] as String?,
      rootGroup: map['root_group'] as String?,
      sanskritRoot: map['sanskrit_root'] as String?,
      sanskritRootMeaning: map['sanskrit_root_meaning'] as String?,
    );
  }
}
