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

  /// 스피커가 읽어야 할 한국어 — **화면에 보이는 예문 하나**.
  ///
  /// 예전에는 예문 전부를 공백으로 이어 붙여 읽었다. 문제가 둘이었다.
  ///
  /// 1. 보는 것과 듣는 것이 달랐다. 카드 앞면은 `examples.first` 만
  ///    보여주는데 스피커는 세 문장을 내리 읽었다 (Jin: "tts파일이랑 내용
  ///    이랑 1도 안 맞고").
  /// 2. 그 이어붙인 문자열은 **어디에도 합성돼 있지 않다**. 캐시 키가
  ///    `sha1('{voice}|{text}')` 인데 사전생성기는 CSV 원본
  ///    (`'갔어요. / 먹었어요. / 했어요.'`)을 합성하고 앱은 공백 join
  ///    (`'갔어요. 먹었어요. 했어요.'`)을 요청했다 — 영구 miss.
  ///    2026-08-19 `--verify-storage` 에서 발화 11,438개 중 유일한 누락이
  ///    정확히 이 문자열이었다.
  ///
  /// 예문 하나만 읽으면 발화 문자열이 언제나 `splitStudyPhrases` 의
  /// 원소와 같아져 드리프트가 구조적으로 사라진다.
  String speakKoreanAt(int index) {
    if (index < 0 || index >= examples.length) {
      return '';
    }
    return examples[index].korean;
  }

  /// 카드 앞면이 보여주는 예문. 스피커도 이것만 읽는다.
  String get speakKorean => speakKoreanAt(0);
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
