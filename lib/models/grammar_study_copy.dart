import 'grammar.dart';

/// One grammar card, split so a rule line never swallows the title or examples.
class GrammarStudyCopy {
  const GrammarStudyCopy({
    required this.title,
    required this.rules,
    required this.examples,
    required this.note,
  });

  /// First sentence, e.g. "Polite past tense."
  final String title;

  /// Remaining `·` clauses, e.g. "ㅏ/ㅗ → 았어요".
  final List<String> rules;

  /// Korean + gloss pairs. One row per ` / `-separated example.
  final List<GrammarStudyExample> examples;

  /// Extra line that is not already a rule.
  final String note;

  factory GrammarStudyCopy.fromGrammar(Grammar grammar, String lang) {
    final raw = grammar.explanationFor(lang).trim();
    var title = raw;
    var rest = '';
    final dot = raw.indexOf('.');
    if (dot >= 0 && dot <= 72) {
      title = raw.substring(0, dot + 1).trim();
      rest = raw.substring(dot + 1).trim();
    }
    var rules = _splitClauses(rest);
    if (rules.isEmpty && raw.contains('·')) {
      final parts = _splitClauses(raw);
      if (parts.isNotEmpty) {
        title = parts.first;
        rules = parts.skip(1).toList(growable: false);
      }
    }

    final korean = splitStudyPhrases(grammar.exampleKorean);
    final glosses = splitStudyPhrases(grammar.exampleFor(lang));
    final examples = <GrammarStudyExample>[
      for (var i = 0; i < korean.length; i++)
        GrammarStudyExample(
          korean: korean[i],
          gloss: i < glosses.length ? glosses[i] : '',
        ),
    ];

    var note = grammar.noteFor(lang).trim();
    if (note.isNotEmpty &&
        (rules.any((rule) => _sameClause(rule, note)) ||
            title.contains(note))) {
      note = '';
    }

    return GrammarStudyCopy(
      title: title,
      rules: rules,
      examples: examples,
      note: note,
    );
  }

  /// Korean the listen button should speak — examples only, never the gloss.
  String get speakKorean {
    final parts = [
      for (final example in examples)
        if (example.korean.isNotEmpty) example.korean,
    ];
    return parts.join(' ');
  }
}

class GrammarStudyExample {
  const GrammarStudyExample({required this.korean, required this.gloss});

  final String korean;
  final String gloss;
}

/// Splits authored examples on ` / ` or `|` so each phrase stays whole.
List<String> splitStudyPhrases(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  final splitter = trimmed.contains(' / ')
      ? ' / '
      : (trimmed.contains('|') ? '|' : null);
  if (splitter == null) {
    return [trimmed];
  }
  return trimmed
      .split(splitter)
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitClauses(String raw) {
  if (raw.isEmpty) {
    return const [];
  }
  return raw
      .split(RegExp(r'\s*·\s*'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

bool _sameClause(String a, String b) {
  final left = a.replaceAll(RegExp(r'\s+'), '');
  final right = b.replaceAll(RegExp(r'\s+'), '');
  return left == right || left.contains(right) || right.contains(left);
}
