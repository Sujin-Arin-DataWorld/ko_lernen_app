/// A reading aid using Revised Romanization, including common liaison,
/// nasal/liquid assimilation and aspiration within each Korean word.
///
/// Kept local so saved notebook examples work offline as well. This is not a
/// phonetic transcription: lexical exceptions and word-boundary sandhi still
/// belong to the accompanying Korean audio.
String romanizeKorean(String text) => text.replaceAllMapped(
  RegExp(r'[가-힣]+'),
  (match) => _romanizeWord(match.group(0)!),
);

const _initial = <String>[
  'g',
  'kk',
  'n',
  'd',
  'tt',
  'r',
  'm',
  'b',
  'pp',
  's',
  'ss',
  '',
  'j',
  'jj',
  'ch',
  'k',
  't',
  'p',
  'h',
];
const _vowel = <String>[
  'a',
  'ae',
  'ya',
  'yae',
  'eo',
  'e',
  'yeo',
  'ye',
  'o',
  'wa',
  'wae',
  'oe',
  'yo',
  'u',
  'wo',
  'we',
  'wi',
  'yu',
  'eu',
  'ui',
  'i',
];
const _final = <String>[
  '',
  'k',
  'k',
  'k',
  'n',
  'n',
  'n',
  't',
  'l',
  'k',
  'm',
  'l',
  'l',
  'l',
  'p',
  'l',
  'm',
  'p',
  'p',
  't',
  't',
  'ng',
  't',
  't',
  'k',
  't',
  'p',
  't',
];
// When a vowel follows, a double coda splits at the syllable boundary.
const _liaison = <(String, String)>[
  ('', ''),
  ('', 'g'),
  ('', 'kk'),
  ('k', 's'),
  ('', 'n'),
  ('n', 'j'),
  ('', 'n'),
  ('', 'd'),
  ('', 'r'),
  ('l', 'g'),
  ('l', 'm'),
  ('l', 'b'),
  ('l', 's'),
  ('l', 't'),
  ('l', 'p'),
  ('', 'r'),
  ('', 'm'),
  ('', 'b'),
  ('p', 's'),
  ('', 's'),
  ('', 'ss'),
  ('ng', ''),
  ('', 'j'),
  ('', 'ch'),
  ('', 'k'),
  ('', 't'),
  ('', 'p'),
  ('', ''),
];

String _romanizeWord(String word) {
  final syllables = word.runes.map((code) => code - 0xac00).toList();
  final onsets = [for (final s in syllables) _initial[s ~/ 588]];
  final vowels = [for (final s in syllables) _vowel[(s % 588) ~/ 28]];
  final codas = [for (final s in syllables) _final[s % 28]];
  for (var i = 0; i + 1 < syllables.length; i++) {
    final coda = syllables[i] % 28;
    final next = onsets[i + 1];
    if (coda == 0) {
      continue;
    }
    // Verb stems such as 읽고 / 읽기 retain ㄹ before ㄱ. RR does not
    // separately mark the resulting tense consonant.
    if (coda == 9 &&
        next == 'g' &&
        const {
          '읽',
          '맑',
          '묽',
          '밝',
          '붉',
          '늙',
          '얽',
          '긁',
          '낡',
          '굵',
          '옭',
        }.contains(word[i])) {
      codas[i] = 'l';
      continue;
    }
    if (next.isEmpty) {
      final liaison = _liaison[coda];
      codas[i] = liaison.$1;
      onsets[i + 1] = liaison.$2;
      if (vowels[i + 1] == 'i' && (coda == 7 || coda == 25 || coda == 13)) {
        onsets[i + 1] = coda == 7 ? 'j' : 'ch';
      }
      continue;
    }
    if (coda == 27 || coda == 6 || coda == 15) {
      final aspirated = const {'g': 'k', 'd': 't', 'j': 'ch'}[next];
      if (aspirated != null) {
        codas[i] = coda == 6 ? 'n' : (coda == 15 ? 'l' : '');
        onsets[i + 1] = aspirated;
        continue;
      }
      if (next == 'n') {
        codas[i] = coda == 15 ? 'l' : 'n';
      }
    }
    if (next == 'h' && vowels[i + 1] == 'i' && coda == 7) {
      codas[i] = '';
      onsets[i + 1] = 'ch';
      continue;
    }
    if ((codas[i] == 'n' && next == 'r') ||
        (codas[i] == 'l' && (next == 'n' || next == 'r'))) {
      codas[i] = 'l';
      onsets[i + 1] = 'l';
      continue;
    }
    if (next == 'r' && codas[i] != 'l') {
      onsets[i + 1] = 'n';
    }
    if (onsets[i + 1] == 'n' || onsets[i + 1] == 'm') {
      codas[i] = const {'k': 'ng', 't': 'n', 'p': 'm'}[codas[i]] ?? codas[i];
    }
  }
  return [
    for (var i = 0; i < syllables.length; i++)
      '${onsets[i]}${vowels[i]}${codas[i]}',
  ].join();
}
