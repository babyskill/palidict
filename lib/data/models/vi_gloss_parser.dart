library;

/// Pure Dart parser for Vietnamese dictionary glosses (HT Buu Chon 1976).
///
/// Converts comma-delimited `gloss_main` and compound-chained `gloss_full`
/// into structured lead senses and compound entries, applying display-level
/// cleaning rules (R1 to R6 and compound row cleaning).

const Set<String> grammarAbbrevs = {
  'pp',
  'prp',
  'aor',
  'ptp',
  'inf',
  'abs',
  'caus',
  'desid',
  'fut',
  'opt',
  'imp',
  'sg',
  'pl',
  'masc',
  'fem',
  'nt',
};

const Set<String> posGenderTags = {
  'nt',
  'm',
  'f',
  'masc',
  'fem',
  'adj',
  'ind',
  'conj',
  'pron',
  'num',
  'adv',
  'prep',
  'interj',
  'root',
};

const Set<String> verbFormTags = {
  'aor',
  'prp',
  'ptp',
  'inf',
  'abs',
  'fut',
  'opt',
  'imp',
  'pp',
};

/// Normalizes comma spacing: converts ',' followed by optional whitespace into ', '.
String normalizeCommaSpacing(String text) {
  return text.replaceAll(RegExp(r',\s*'), ', ');
}

/// Normalizes comma and semicolon spacing (R6).
String normalizeSeparators(String text) {
  var s = text.replaceAll(RegExp(r',\s*'), ', ');
  s = s.replaceAll(RegExp(r';\s*'), '; ');
  return s.trim();
}

const String _vietnameseDiacritics =
    'àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ'
    'ÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴĐ';

/// Checks if content inside parentheses is purely a grammatical derivation (R1).
bool _isDerivationParenthetical(String inside) {
  final trimmed = inside.trim();
  if (trimmed.isEmpty) return false;

  // Pattern: (<abbrev> của <lemma>), e.g. "pp của bhamati"
  final abbrevPattern = grammarAbbrevs.join('|');
  final crossRefRegex = RegExp(
    '^($abbrevPattern)\\s+của\\s+[a-zA-ZāīūṃṅñṭḍṇḷĀĪŪṂṄÑṬḌṆḶ\\d\\s\\.\\-]+(?:\\s+[a-zA-ZāīūṃṅñṭḍṇḷĀĪŪṂṄÑṬḌṆḶ\\d\\s\\.\\-]+)*\$',
    caseSensitive: false,
  );
  if (crossRefRegex.hasMatch(trimmed)) {
    return true;
  }

  // If it contains Vietnamese-specific tone marks or accents, it contains ordinary Vietnamese words
  for (var i = 0; i < trimmed.length; i++) {
    if (_vietnameseDiacritics.contains(trimmed[i])) {
      return false;
    }
  }

  // Tokenize by derivation operators and separators
  final tokens = trimmed
      .split(RegExp(r'[+\-√*,\/;=\s]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.isEmpty) return false;

  final paliLemmaRegex = RegExp(r'^[a-zA-ZāīūṃṅñṭḍṇḷĀĪŪṂṄÑṬḌṆḶ\d\.\-]+$');

  for (final t in tokens) {
    final lower = t.toLowerCase();
    if (grammarAbbrevs.contains(lower)) continue;
    if (int.tryParse(t) != null) continue;
    if (paliLemmaRegex.hasMatch(t)) continue;
    return false;
  }

  return true;
}

/// R4: Drops leading English leftovers ('copulative particle', 'dem pron').
String stripLeadingEnglishLeftovers(String text) {
  var s = text.trim();
  final lower = s.toLowerCase();
  if (lower.startsWith('copulative particle')) {
    s = s.substring('copulative particle'.length).trim();
  } else if (lower.startsWith('dem pron')) {
    s = s.substring('dem pron'.length).trim();
  }
  return s;
}

/// R2: Drops a bracketed tag at the very start of a segment when it is a POS/gender tag.
String stripLeadingPosTag(String text) {
  var s = text.trim();
  if (s.startsWith('[')) {
    final closeIdx = s.indexOf(']');
    if (closeIdx != -1) {
      final tag = s.substring(1, closeIdx).trim().toLowerCase();
      if (posGenderTags.contains(tag)) {
        s = s.substring(closeIdx + 1).trim();
      }
    }
  }
  return s;
}

/// R1: Drops leading derivation parenthetical.
String stripLeadingDerivation(String text) {
  var s = text.trim();
  if (s.startsWith('(')) {
    final closeIdx = s.indexOf(')');
    if (closeIdx != -1) {
      final inside = s.substring(1, closeIdx);
      if (_isDerivationParenthetical(inside)) {
        s = s.substring(closeIdx + 1).trim();
        while (s.startsWith(',') || s.startsWith(';')) {
          s = s.substring(1).trim();
        }
      }
    }
  }
  return s;
}

/// R3: Cuts trailing verb-form lists from the first bracketed verb-form tag,
/// but ONLY when non-empty meaning text remains before it in the segment.
String stripTrailingVerbForms(String text) {
  final verbPattern = verbFormTags.join('|');
  final match = RegExp('\\[($verbPattern)\\]', caseSensitive: false).firstMatch(text);
  if (match != null) {
    final before = text.substring(0, match.start).trim();
    if (before.isNotEmpty) {
      return before;
    }
  }
  return text;
}

/// Cleans a Buu Chon gloss segment applying rules R4, R2, R1, R3, R6.
String cleanBuuChonSegment(String text) {
  var s = text.trim();
  if (s.isEmpty) return s;

  // R4 English leftovers
  s = stripLeadingEnglishLeftovers(s);

  // R2 Leading bracketed POS/gender tag
  s = stripLeadingPosTag(s);

  // R1 Leading derivation parenthetical
  s = stripLeadingDerivation(s);

  // R3 Trailing verb-form lists
  s = stripTrailingVerbForms(s);

  // R6 Separators
  s = normalizeSeparators(s);

  return s;
}

/// Counts occurrences of [char] in [text].
int _countChar(String text, String char) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == char) count++;
  }
  return count;
}

/// Splits senses by commas while keeping nested parenthetical clauses intact.
List<String> splitSensesPreservingParentheses(String text) {
  final result = <String>[];
  var depth = 0;
  final current = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '(') {
      depth++;
      current.write(char);
    } else if (char == ')') {
      if (depth > 0) depth--;
      current.write(char);
    } else if (char == ',' && depth == 0) {
      final s = current.toString().trim();
      if (s.isNotEmpty) result.add(s);
      current.clear();
    } else {
      current.write(char);
    }
  }

  final s = current.toString().trim();
  if (s.isNotEmpty) result.add(s);

  return result;
}

/// A parsed compound sub-entry from `gloss_full`.
class ViCompoundEntry {
  /// The lemma token of the compound, e.g. 'kathā'. Null if unstructured.
  final String? lemma;

  /// Optional part-of-speech in brackets, e.g. 'f', 'nt', '3'. Null if none.
  final String? pos;

  /// The raw trimmed gloss of the compound, e.g. 'sự nói về đạo đức,luận đạo'.
  final String? gloss;

  /// Full segment string as fallback / preservation.
  final String rawText;

  const ViCompoundEntry({
    this.lemma,
    this.pos,
    this.gloss,
    required this.rawText,
  });

  /// True if the entry has a parsed lemma.
  bool get isStructured => lemma != null && lemma!.isNotEmpty;

  /// Gloss with commas and semicolons normalized to have proper spacing.
  String? get normalizedGloss {
    if (gloss == null) return null;
    return normalizeSeparators(gloss!);
  }

  @override
  String toString() {
    if (isStructured) {
      final posStr = pos != null ? ' [$pos]' : '';
      final glossStr = gloss != null ? ' $gloss' : '';
      return 'ViCompoundEntry($lemma$posStr$glossStr)';
    }
    return 'ViCompoundEntry(raw: $rawText)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViCompoundEntry &&
          runtimeType == other.runtimeType &&
          lemma == other.lemma &&
          pos == other.pos &&
          gloss == other.gloss &&
          rawText == other.rawText;

  @override
  int get hashCode => Object.hash(lemma, pos, gloss, rawText);
}

/// Represents the structured result of parsing Vietnamese dictionary gloss strings.
class ParsedViGloss {
  /// Individual lead senses from `gloss_main`.
  final List<String> leadSenses;

  /// Compound sub-entries extracted from the tail of `gloss_full`.
  final List<ViCompoundEntry> compounds;

  const ParsedViGloss({
    required this.leadSenses,
    required this.compounds,
  });

  /// Lead senses joined into a single paragraph with ', '.
  String get leadParagraph => leadSenses.join(', ');

  /// Whether there are compound sub-entries.
  bool get hasCompounds => compounds.isNotEmpty;
}

/// Parses `glossMain` and optional `glossFull` into a [ParsedViGloss],
/// applying display-only cleaning rules R1–R6 and compound row formatting.
ParsedViGloss parseViGloss(String glossMain, String? glossFull) {
  // If glossFull is empty, missing, or equal to glossMain
  if (glossFull == null || glossFull.isEmpty || glossFull == glossMain) {
    final cleanedMain = cleanBuuChonSegment(glossMain);
    final leadSenses = splitSensesPreservingParentheses(cleanedMain);
    return ParsedViGloss(leadSenses: leadSenses, compounds: const []);
  }

  String effectiveMain = glossMain;
  String tail = '';

  if (glossMain.isNotEmpty && glossFull.startsWith(glossMain)) {
    tail = glossFull.substring(glossMain.length);
  } else if (glossMain.isEmpty) {
    tail = glossFull;
  } else {
    // If glossFull does not start with glossMain, check if glossFull itself contains ' --'
    final firstDelim = glossFull.indexOf(' --');
    if (firstDelim != -1) {
      effectiveMain = glossFull.substring(0, firstDelim).trim();
      tail = glossFull.substring(firstDelim);
    } else {
      effectiveMain = glossFull;
      tail = '';
    }
  }

  // Split tail on ' --' boundaries
  var trimmedTail = tail.trim();
  while (trimmedTail.startsWith(';') || trimmedTail.startsWith('--')) {
    if (trimmedTail.startsWith(';')) {
      trimmedTail = trimmedTail.substring(1).trim();
    } else if (trimmedTail.startsWith('--')) {
      trimmedTail = trimmedTail.substring(2).trim();
    }
  }

  final tailSegments = trimmedTail.isNotEmpty
      ? trimmedTail.split(RegExp(r'\s+--')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
      : <String>[];

  // R5: If effectiveMain has unbalanced parentheses, merge following segments into it until balanced
  var mainOpen = _countChar(effectiveMain, '(');
  var mainClose = _countChar(effectiveMain, ')');
  while (mainOpen > mainClose && tailSegments.isNotEmpty) {
    final nextSeg = tailSegments.removeAt(0);
    effectiveMain = '$effectiveMain — $nextSeg';
    mainOpen += _countChar(nextSeg, '(');
    mainClose += _countChar(nextSeg, ')');
  }

  // R5: Balance remaining tail segments among themselves
  final balancedTail = <String>[];
  var tIdx = 0;
  while (tIdx < tailSegments.length) {
    var seg = tailSegments[tIdx];
    var openCount = _countChar(seg, '(');
    var closeCount = _countChar(seg, ')');

    while (openCount > closeCount && tIdx + 1 < tailSegments.length) {
      tIdx++;
      final nextSeg = tailSegments[tIdx];
      seg = '$seg — $nextSeg';
      openCount += _countChar(nextSeg, '(');
      closeCount += _countChar(nextSeg, ')');
    }

    if (seg.isNotEmpty) {
      balancedTail.add(seg);
    }
    tIdx++;
  }

  final cleanedMain = cleanBuuChonSegment(effectiveMain);
  final leadSenses = effectiveMain.isNotEmpty
      ? splitSensesPreservingParentheses(cleanedMain)
      : <String>[];

  final compounds = <ViCompoundEntry>[];
  for (final seg in balancedTail) {
    compounds.add(_parseCompoundSegment(seg));
  }

  return ParsedViGloss(leadSenses: leadSenses, compounds: compounds);
}

/// Parses a single compound segment string.
///
/// Rules:
/// - Lemma token = up to first space or '['
/// - Drops a standalone POS abbreviation token (from R1 set) immediately after the compound lemma
/// - Bracketed POS tag [pos]
/// - Gloss text cleaned with R3 (trailing verb-form lists)
ViCompoundEntry _parseCompoundSegment(String rawSegment) {
  var segment = rawSegment.trim();
  while (segment.startsWith(';') || segment.startsWith('--')) {
    if (segment.startsWith(';')) {
      segment = segment.substring(1).trim();
    } else if (segment.startsWith('--')) {
      segment = segment.substring(2).trim();
    }
  }

  if (segment.isEmpty) {
    return ViCompoundEntry(rawText: rawSegment);
  }

  // Find delimiter: first space or '['
  final firstSpace = segment.indexOf(' ');
  final firstBracket = segment.indexOf('[');

  int delimIndex = -1;
  if (firstSpace != -1 && firstBracket != -1) {
    delimIndex = firstSpace < firstBracket ? firstSpace : firstBracket;
  } else if (firstSpace != -1) {
    delimIndex = firstSpace;
  } else if (firstBracket != -1) {
    delimIndex = firstBracket;
  }

  if (delimIndex == 0) {
    // Starts with space or '[', no lemma token -> plain row
    return ViCompoundEntry(rawText: segment);
  }

  if (delimIndex == -1) {
    // Whole segment is lemma token, e.g. 'esi'
    return ViCompoundEntry(
      lemma: segment,
      pos: null,
      gloss: null,
      rawText: segment,
    );
  }

  final lemma = segment.substring(0, delimIndex).trim();
  var remainder = segment.substring(delimIndex).trim();

  // Compound rows rule: drop standalone POS abbreviation token from R1 set
  // appearing immediately after the compound lemma (e.g. 'āyi prp taṭalaṭāyamāna')
  final standaloneMatch = RegExp(r'^([a-zA-Z]+)(\s+.*|\s*)$').firstMatch(remainder);
  if (standaloneMatch != null) {
    final firstWord = standaloneMatch.group(1)!.toLowerCase();
    if (grammarAbbrevs.contains(firstWord)) {
      remainder = (standaloneMatch.group(2) ?? '').trim();
    }
  }

  String? pos;
  String? gloss;

  if (remainder.startsWith('[')) {
    final closeBracket = remainder.indexOf(']');
    if (closeBracket != -1 && closeBracket > 1) {
      pos = remainder.substring(1, closeBracket).trim();
      remainder = remainder.substring(closeBracket + 1).trim();
    } else {
      // Unclosed bracket or empty '[]'
      return ViCompoundEntry(rawText: segment);
    }
  }

  if (remainder.isNotEmpty) {
    // Clean compound gloss with R3 (trailing verb-form lists)
    remainder = stripTrailingVerbForms(remainder);
    gloss = remainder;
  }

  return ViCompoundEntry(
    lemma: lemma,
    pos: pos,
    gloss: gloss,
    rawText: segment,
  );
}
