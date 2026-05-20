/// Hangul-Buchstaben mit Aussprache und kurzer Erklärung.

class HangulChar {
  final String letter;
  final String romanization;
  final String descriptionDe;
  final String descriptionEn;
  const HangulChar(this.letter, this.romanization, this.descriptionDe, this.descriptionEn);
}

const List<HangulChar> consonants = [
  HangulChar('ㄱ', 'g/k', "wie 'g' in Gabe (Anfang) / 'k' (Ende)",        "like 'g' in good (start) / 'k' (end)"),
  HangulChar('ㄴ', 'n',   "wie 'n' in Name",                              "like 'n' in name"),
  HangulChar('ㄷ', 'd/t', "wie 'd' in Dach (Anfang) / 't' (Ende)",        "like 'd' in dog / 't' (end)"),
  HangulChar('ㄹ', 'r/l', "zwischen 'r' und 'l' — rollendes r vor Vokal", "between 'r' and 'l'"),
  HangulChar('ㅁ', 'm',   "wie 'm' in Mutter",                            "like 'm' in mom"),
  HangulChar('ㅂ', 'b/p', "wie 'b' in Ball (Anfang) / 'p' (Ende)",        "like 'b' in ball / 'p' (end)"),
  HangulChar('ㅅ', 's',   "wie 's' in Sonne",                             "like 's' in sun"),
  HangulChar('ㅇ', '–/ng',"stumm am Silbenanfang · 'ng' am Ende",         "silent at start · 'ng' at end"),
  HangulChar('ㅈ', 'j',   "wie 'j' in Jahr",                              "like 'j' in jam"),
  HangulChar('ㅊ', 'ch',  "wie 'ch' in Tschüss — aspiriert",              "like 'ch' in church — aspirated"),
  HangulChar('ㅋ', 'k',   "wie 'k' in Kalt — stark aspiriert",            "like 'k' in kite — strongly aspirated"),
  HangulChar('ㅌ', 't',   "wie 't' in Tisch — stark aspiriert",           "like 't' in top — strongly aspirated"),
  HangulChar('ㅍ', 'p',   "wie 'p' in Park — stark aspiriert",            "like 'p' in park — strongly aspirated"),
  HangulChar('ㅎ', 'h',   "wie 'h' in Haus",                              "like 'h' in house"),
  HangulChar('ㄲ', 'kk',  "doppeltes ㄱ — gespannt, kein Hauch",          "tense ㄱ, no aspiration"),
  HangulChar('ㄸ', 'tt',  "doppeltes ㄷ — gespannt",                      "tense ㄷ"),
  HangulChar('ㅃ', 'pp',  "doppeltes ㅂ — gespannt",                      "tense ㅂ"),
  HangulChar('ㅆ', 'ss',  "doppeltes ㅅ — gespannt",                      "tense ㅅ"),
  HangulChar('ㅉ', 'jj',  "doppeltes ㅈ — gespannt",                      "tense ㅈ"),
];

const List<HangulChar> vowels = [
  HangulChar('ㅏ', 'a',   "wie 'a' in Vater",                              "like 'a' in father"),
  HangulChar('ㅑ', 'ya',  "wie 'ja'",                                       "like 'ya' in yard"),
  HangulChar('ㅓ', 'eo',  "wie 'ö' ohne Lippenrundung",                    "like 'u' in but"),
  HangulChar('ㅕ', 'yeo', "wie 'yö'",                                       "like 'yu' in young"),
  HangulChar('ㅗ', 'o',   "wie 'o' in Mond",                                "like 'o' in moan"),
  HangulChar('ㅛ', 'yo',  "wie 'yo'",                                       "like 'yo' in yoga"),
  HangulChar('ㅜ', 'u',   "wie 'u' in Mund",                                "like 'oo' in mood"),
  HangulChar('ㅠ', 'yu',  "wie 'yu'",                                       "like 'yu' in you"),
  HangulChar('ㅡ', 'eu',  "wie 'ü' ohne Lippenrundung — kein dt. Äquivalent","no English equivalent"),
  HangulChar('ㅣ', 'i',   "wie 'i' in Igel",                                "like 'ee' in see"),
  HangulChar('ㅐ', 'ae',  "wie 'ä' in Käse",                                "like 'a' in cat"),
  HangulChar('ㅔ', 'e',   "wie 'e' in Bett",                                "like 'e' in bed"),
  HangulChar('ㅘ', 'wa',  "Kombination ㅗ+ㅏ",                              "ㅗ+ㅏ combined"),
  HangulChar('ㅝ', 'wo',  "Kombination ㅜ+ㅓ",                              "ㅜ+ㅓ combined"),
  HangulChar('ㅢ', 'ui',  "Kombination ㅡ+ㅣ",                              "ㅡ+ㅣ combined"),
];

class Syllable {
  final String letter;
  final String romanization;
  final String composition;
  const Syllable(this.letter, this.romanization, this.composition);
}

const List<Syllable> syllables = [
  Syllable('가', 'ga',  'ㄱ + ㅏ'),
  Syllable('나', 'na',  'ㄴ + ㅏ'),
  Syllable('다', 'da',  'ㄷ + ㅏ'),
  Syllable('라', 'ra',  'ㄹ + ㅏ'),
  Syllable('마', 'ma',  'ㅁ + ㅏ'),
  Syllable('바', 'ba',  'ㅂ + ㅏ'),
  Syllable('사', 'sa',  'ㅅ + ㅏ'),
  Syllable('아', 'a',   'ㅇ + ㅏ'),
  Syllable('자', 'ja',  'ㅈ + ㅏ'),
  Syllable('하', 'ha',  'ㅎ + ㅏ'),
  Syllable('한', 'han', 'ㅎ + ㅏ + ㄴ'),
  Syllable('국', 'guk', 'ㄱ + ㅜ + ㄱ'),
  Syllable('말', 'mal', 'ㅁ + ㅏ + ㄹ'),
  Syllable('밥', 'bap', 'ㅂ + ㅏ + ㅂ'),
  Syllable('집', 'jip', 'ㅈ + ㅣ + ㅂ'),
  Syllable('책', 'chaek','ㅊ + ㅐ + ㄱ'),
];
