import '../data/hanja_lexicon.dart';
import '../models/book_page.dart';

enum VocabNuanceQuestionKind { register, hanjaRoot, sharedMeaning }

class VocabNuanceOption {
  const VocabNuanceOption({
    required this.korean,
    required this.meaning,
    this.hanja = '',
  });

  final String korean;
  final String meaning;
  final String hanja;
}

class VocabNuanceQuestion {
  const VocabNuanceQuestion({
    required this.id,
    required this.kind,
    required this.promptDe,
    required this.promptEn,
    required this.options,
    required this.correctKorean,
    required this.explanationDe,
    required this.explanationEn,
  });

  final String id;
  final VocabNuanceQuestionKind kind;
  final String promptDe;
  final String promptEn;
  final List<VocabNuanceOption> options;
  final String correctKorean;
  final String explanationDe;
  final String explanationEn;

  String promptFor(String language) => language == 'en' ? promptEn : promptDe;

  String explanationFor(String language) =>
      language == 'en' ? explanationEn : explanationDe;
}

class VocabNuanceCluster {
  const VocabNuanceCluster({
    required this.id,
    required this.words,
    required this.reason,
  });

  final String id;
  final List<ExtractedWord> words;
  final String reason;
}

/// Finds synonym / register clusters in the learner's own list and turns
/// them into playful comparison questions. Hanja is the teaching hook.
class VocabNuanceService {
  const VocabNuanceService._();

  static List<VocabNuanceCluster> clustersFor(
    Iterable<ExtractedWord> words, {
    String language = 'de',
  }) {
    final unique = <String, ExtractedWord>{};
    for (final word in words) {
      final korean = word.korean.trim();
      if (korean.isEmpty) {
        continue;
      }
      unique.putIfAbsent(korean, () => word);
    }
    final list = unique.values.toList(growable: false);
    final clusters = <VocabNuanceCluster>[];
    final used = <String>{};

    final byGroup = <String, List<ExtractedWord>>{};
    for (final word in list) {
      final entry = HanjaLexicon.lookup(word.korean);
      if (entry == null || entry.synonymGroup.isEmpty) {
        continue;
      }
      byGroup.putIfAbsent(entry.synonymGroup, () => <ExtractedWord>[]).add(word);
    }
    for (final entry in byGroup.entries) {
      if (entry.value.length < 2) {
        continue;
      }
      for (final word in entry.value) {
        used.add(word.korean);
      }
      clusters.add(
        VocabNuanceCluster(
          id: 'group:${entry.key}',
          words: entry.value,
          reason: 'hanja_group',
        ),
      );
    }

    final byMeaning = <String, List<ExtractedWord>>{};
    for (final word in list) {
      if (used.contains(word.korean)) {
        continue;
      }
      final meaning = _normalizedMeaning(word, language);
      if (meaning.length < 3) {
        continue;
      }
      byMeaning.putIfAbsent(meaning, () => <ExtractedWord>[]).add(word);
    }
    for (final entry in byMeaning.entries) {
      if (entry.value.length < 2) {
        continue;
      }
      clusters.add(
        VocabNuanceCluster(
          id: 'meaning:${entry.key}',
          words: entry.value,
          reason: 'shared_meaning',
        ),
      );
    }
    return clusters;
  }

  static List<VocabNuanceQuestion> questionsFor(
    Iterable<ExtractedWord> words, {
    String language = 'de',
  }) {
    final list = words
        .where((word) => word.korean.trim().isNotEmpty)
        .toList(growable: false);
    final questions = <VocabNuanceQuestion>[];
    final seen = <String>{};

    for (final cluster in clustersFor(list, language: language)) {
      final register = _registerQuestion(cluster, language: language);
      if (register != null && seen.add(register.id)) {
        questions.add(register);
      }
      final meaning = _sharedMeaningQuestion(cluster, language: language);
      if (meaning != null && seen.add(meaning.id)) {
        questions.add(meaning);
      }
    }

    for (final word in list) {
      final root = _hanjaRootQuestion(word, list, language: language);
      if (root != null && seen.add(root.id)) {
        questions.add(root);
      }
    }
    return questions;
  }

  static VocabNuanceQuestion? _registerQuestion(
    VocabNuanceCluster cluster, {
    required String language,
  }) {
    HanjaWordEntry? formal;
    HanjaWordEntry? everyday;
    ExtractedWord? formalWord;
    ExtractedWord? everydayWord;
    for (final word in cluster.words) {
      final entry = HanjaLexicon.lookup(word.korean);
      if (entry == null) {
        continue;
      }
      if (entry.isFormal && formal == null) {
        formal = entry;
        formalWord = word;
      } else if (!entry.isFormal && everyday == null) {
        everyday = entry;
        everydayWord = word;
      }
    }
    if (formal == null ||
        everyday == null ||
        formalWord == null ||
        everydayWord == null) {
      return null;
    }
    return VocabNuanceQuestion(
      id: 'register:${everyday.korean}:${formal.korean}',
      kind: VocabNuanceQuestionKind.register,
      promptDe: 'Welches Wort ist förmlicher?',
      promptEn: 'Which word is more formal?',
      options: <VocabNuanceOption>[
        _optionFor(everydayWord, everyday),
        _optionFor(formalWord, formal),
      ],
      correctKorean: formal.korean,
      explanationDe:
          '${formal.korean} (${formal.hanja.isEmpty ? 'kein Hanja' : formal.hanja}) '
          'ist förmlicher als ${everyday.korean}'
          '${everyday.hanja.isEmpty ? '' : ' (${everyday.hanja})'}. ${formal.nuanceDe}',
      explanationEn:
          '${formal.korean} (${formal.hanja.isEmpty ? 'no Hanja' : formal.hanja}) '
          'is more formal than ${everyday.korean}'
          '${everyday.hanja.isEmpty ? '' : ' (${everyday.hanja})'}. ${formal.nuanceEn}',
    );
  }

  static VocabNuanceQuestion? _sharedMeaningQuestion(
    VocabNuanceCluster cluster, {
    required String language,
  }) {
    if (cluster.words.length < 2) {
      return null;
    }
    final first = cluster.words[0];
    final second = cluster.words[1];
    final firstEntry = HanjaLexicon.lookup(first.korean);
    final secondEntry = HanjaLexicon.lookup(second.korean);
    final firstHanja = firstEntry?.hanja ?? '';
    final secondHanja = secondEntry?.hanja ?? '';
    if (firstHanja.isEmpty && secondHanja.isEmpty) {
      return null;
    }
    final meaning = _displayMeaning(first, language);
    return VocabNuanceQuestion(
      id: 'meaning:${first.korean}:${second.korean}',
      kind: VocabNuanceQuestionKind.sharedMeaning,
      promptDe:
          'Beide können „$meaning“ nahekommen. Welches Hanja trägt ${first.korean}?',
      promptEn:
          'Both can come close to “$meaning”. Which Hanja belongs to ${first.korean}?',
      options: <VocabNuanceOption>[
        VocabNuanceOption(
          korean: first.korean,
          meaning: firstHanja.isEmpty ? first.korean : firstHanja,
          hanja: firstHanja,
        ),
        VocabNuanceOption(
          korean: second.korean,
          meaning: secondHanja.isEmpty ? second.korean : secondHanja,
          hanja: secondHanja,
        ),
      ],
      correctKorean: first.korean,
      explanationDe: _pairExplanation(first, second, firstEntry, secondEntry, 'de'),
      explanationEn: _pairExplanation(first, second, firstEntry, secondEntry, 'en'),
    );
  }

  static VocabNuanceQuestion? _hanjaRootQuestion(
    ExtractedWord word,
    List<ExtractedWord> pool, {
    required String language,
  }) {
    final entry = HanjaLexicon.lookup(word.korean);
    if (entry == null || entry.roots.isEmpty) {
      return null;
    }
    final root = entry.roots.first;
    ExtractedWord? distractor;
    for (final candidate in pool) {
      if (candidate.korean == word.korean) {
        continue;
      }
      final other = HanjaLexicon.lookup(candidate.korean);
      if (other == null ||
          other.roots.any((item) => item.character == root.character)) {
        continue;
      }
      distractor = candidate;
      break;
    }
    if (distractor == null) {
      return null;
    }
    final rootMeaning = root.meaningFor(language);
    return VocabNuanceQuestion(
      id: 'root:${root.character}:${word.korean}',
      kind: VocabNuanceQuestionKind.hanjaRoot,
      promptDe: 'Welches Wort trägt die Silbe ${root.character} ($rootMeaning)?',
      promptEn: 'Which word carries the root ${root.character} ($rootMeaning)?',
      options: <VocabNuanceOption>[
        _optionFor(word, entry),
        _optionFor(distractor, HanjaLexicon.lookup(distractor.korean)),
      ],
      correctKorean: word.korean,
      explanationDe:
          '${word.korean} ${entry.hanja} enthält ${root.character} = ${root.meaningDe}.',
      explanationEn:
          '${word.korean} ${entry.hanja} contains ${root.character} = ${root.meaningEn}.',
    );
  }

  static VocabNuanceOption _optionFor(
    ExtractedWord word,
    HanjaWordEntry? entry,
  ) => VocabNuanceOption(
    korean: word.korean,
    meaning: word.translationDe,
    hanja: entry?.hanja ?? '',
  );

  static String _pairExplanation(
    ExtractedWord first,
    ExtractedWord second,
    HanjaWordEntry? firstEntry,
    HanjaWordEntry? secondEntry,
    String language,
  ) {
    final firstHanja = firstEntry?.hanja ?? '';
    final secondHanja = secondEntry?.hanja ?? '';
    final firstNote = firstEntry?.nuanceFor(language) ?? '';
    final secondNote = secondEntry?.nuanceFor(language) ?? '';
    if (language == 'en') {
      return '${first.korean} ${firstHanja.isEmpty ? '' : '($firstHanja)'} '
              'and ${second.korean} ${secondHanja.isEmpty ? '' : '($secondHanja)'} '
              'are close, but not the same. $firstNote $secondNote'
          .trim();
    }
    return '${first.korean} ${firstHanja.isEmpty ? '' : '($firstHanja)'} '
            'und ${second.korean} ${secondHanja.isEmpty ? '' : '($secondHanja)'} '
            'liegen nah beieinander, sind aber nicht gleich. $firstNote $secondNote'
        .trim();
  }

  static String _normalizedMeaning(ExtractedWord word, String language) {
    final raw = language == 'en' && word.translationEn.isNotEmpty
        ? word.translationEn
        : word.translationDe;
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß\u00C0-\u024F]+'), ' ').trim();
  }

  static String _displayMeaning(ExtractedWord word, String language) {
    if (language == 'en' && word.translationEn.isNotEmpty) {
      return word.translationEn;
    }
    return word.translationDe;
  }
}
