/// Hangul-Buchstaben mit Aussprache, Erklärung und Beispielwort.
library;

class HangulChar {
  final String letter;
  final String romanization;
  final String descriptionDe;
  final String descriptionEn;
  final String exampleWord; // Beispielwort (Koreanisch)
  final String exampleDe; // Bedeutung (Deutsch)
  final String exampleEn; // Bedeutung (Englisch)
  const HangulChar(
    this.letter,
    this.romanization,
    this.descriptionDe,
    this.descriptionEn, [
    this.exampleWord = '',
    this.exampleDe = '',
    this.exampleEn = '',
  ]);
}

const List<HangulChar> consonants = [
  HangulChar(
    'ㄱ',
    'g/k',
    "wie 'g' in Gabe (Anfang) / 'k' (Ende)",
    "like 'g' in good (start) / 'k' (end)",
    '가방',
    'Tasche',
    'bag',
  ),
  HangulChar(
    'ㄴ',
    'n',
    "wie 'n' in Name",
    "like 'n' in name",
    '나무',
    'Baum',
    'tree',
  ),
  HangulChar(
    'ㄷ',
    'd/t',
    "wie 'd' in Dach (Anfang) / 't' (Ende)",
    "like 'd' in dog / 't' (end)",
    '다리',
    'Bein',
    'leg',
  ),
  HangulChar(
    'ㄹ',
    'r/l',
    "zwischen 'r' und 'l', vor Vokal gerollt",
    "between 'r' and 'l'",
    '라디오',
    'Radio',
    'radio',
  ),
  HangulChar(
    'ㅁ',
    'm',
    "wie 'm' in Mutter",
    "like 'm' in mom",
    '머리',
    'Kopf',
    'head',
  ),
  HangulChar(
    'ㅂ',
    'b/p',
    "wie 'b' in Ball (Anfang) / 'p' (Ende)",
    "like 'b' in ball / 'p' (end)",
    '바다',
    'Meer',
    'sea',
  ),
  HangulChar(
    'ㅅ',
    's',
    "wie 's' in Sonne",
    "like 's' in sun",
    '사과',
    'Apfel',
    'apple',
  ),
  HangulChar(
    'ㅇ',
    '–/ng',
    "stumm am Silbenanfang · 'ng' am Ende",
    "silent at start · 'ng' at end",
    '아기',
    'Baby',
    'baby',
  ),
  HangulChar(
    'ㅈ',
    'j',
    "wie 'j' in Jahr",
    "like 'j' in jam",
    '자동차',
    'Auto',
    'car',
  ),
  HangulChar(
    'ㅊ',
    'ch',
    "wie 'ch' in Tschüss, aspiriert",
    "like 'ch' in church, aspirated",
    '책',
    'Buch',
    'book',
  ),
  HangulChar(
    'ㅋ',
    'k',
    "wie 'k' in Kalt, stark aspiriert",
    "like 'k' in kite, strongly aspirated",
    '코',
    'Nase',
    'nose',
  ),
  HangulChar(
    'ㅌ',
    't',
    "wie 't' in Tisch, stark aspiriert",
    "like 't' in top, strongly aspirated",
    '토끼',
    'Hase',
    'rabbit',
  ),
  HangulChar(
    'ㅍ',
    'p',
    "wie 'p' in Park, stark aspiriert",
    "like 'p' in park, strongly aspirated",
    '포도',
    'Traube',
    'grape',
  ),
  HangulChar(
    'ㅎ',
    'h',
    "wie 'h' in Haus",
    "like 'h' in house",
    '하늘',
    'Himmel',
    'sky',
  ),
  HangulChar(
    'ㄲ',
    'kk',
    "doppeltes ㄱ, gespannt und ohne Hauch",
    "tense ㄱ, no aspiration",
    '꽃',
    'Blume',
    'flower',
  ),
  HangulChar(
    'ㄸ',
    'tt',
    "doppeltes ㄷ, gespannt",
    "tense ㄷ",
    '딸기',
    'Erdbeere',
    'strawberry',
  ),
  HangulChar(
    'ㅃ',
    'pp',
    "doppeltes ㅂ, gespannt",
    "tense ㅂ",
    '빵',
    'Brot',
    'bread',
  ),
  HangulChar(
    'ㅆ',
    'ss',
    "doppeltes ㅅ, gespannt",
    "tense ㅅ",
    '쌀',
    'Reis',
    'rice',
  ),
  HangulChar(
    'ㅉ',
    'jj',
    "doppeltes ㅈ, gespannt",
    "tense ㅈ",
    '찌개',
    'Eintopf',
    'stew',
  ),
];

const List<HangulChar> vowels = [
  HangulChar(
    'ㅏ',
    'a',
    "wie 'a' in Vater",
    "like 'a' in father",
    '아빠',
    'Papa',
    'dad',
  ),
  HangulChar(
    'ㅑ',
    'ya',
    "wie 'ja'",
    "like 'ya' in yard",
    '야구',
    'Baseball',
    'baseball',
  ),
  HangulChar(
    'ㅓ',
    'eo',
    "wie 'ö' ohne Lippenrundung",
    "like 'u' in but",
    '어머니',
    'Mutter',
    'mother',
  ),
  HangulChar(
    'ㅕ',
    'yeo',
    "wie 'yö'",
    "like 'yu' in young",
    '여자',
    'Frau',
    'woman',
  ),
  HangulChar(
    'ㅗ',
    'o',
    "wie 'o' in Mond",
    "like 'o' in moan",
    '오리',
    'Ente',
    'duck',
  ),
  HangulChar(
    'ㅛ',
    'yo',
    "wie 'yo'",
    "like 'yo' in yoga",
    '요리',
    'Gericht',
    'dish',
  ),
  HangulChar(
    'ㅜ',
    'u',
    "wie 'u' in Mund",
    "like 'oo' in mood",
    '우유',
    'Milch',
    'milk',
  ),
  HangulChar('ㅠ', 'yu', "wie 'yu'", "like 'yu' in you", '유리', 'Glas', 'glass'),
  HangulChar(
    'ㅡ',
    'eu',
    "wie 'ü' ohne Lippenrundung (kein dt. Äquivalent)",
    "no English equivalent",
    '그림',
    'Bild',
    'picture',
  ),
  HangulChar(
    'ㅣ',
    'i',
    "wie 'i' in Igel",
    "like 'ee' in see",
    '기차',
    'Zug',
    'train',
  ),
  HangulChar(
    'ㅐ',
    'ae',
    "wie 'ä' in Käse",
    "like 'a' in cat",
    '새',
    'Vogel',
    'bird',
  ),
  HangulChar(
    'ㅔ',
    'e',
    "wie 'e' in Bett",
    "like 'e' in bed",
    '게',
    'Krabbe',
    'crab',
  ),
  HangulChar(
    'ㅘ',
    'wa',
    "Kombination ㅗ+ㅏ",
    "ㅗ+ㅏ combined",
    '과일',
    'Obst',
    'fruit',
  ),
  HangulChar(
    'ㅝ',
    'wo',
    "Kombination ㅜ+ㅓ",
    "ㅜ+ㅓ combined",
    '원숭이',
    'Affe',
    'monkey',
  ),
  HangulChar(
    'ㅢ',
    'ui',
    "Kombination ㅡ+ㅣ",
    "ㅡ+ㅣ combined",
    '의자',
    'Stuhl',
    'chair',
  ),
];

class Syllable {
  final String letter;
  final String romanization;
  final String composition;
  final String exampleWord; // Beispielwort (Koreanisch)
  final String exampleDe; // Bedeutung (Deutsch)
  final String exampleEn; // Bedeutung (Englisch)
  const Syllable(
    this.letter,
    this.romanization,
    this.composition, [
    this.exampleWord = '',
    this.exampleDe = '',
    this.exampleEn = '',
  ]);
}

/// Wandelt einen einzelnen Jamo-Buchstaben in eine *aussprechbare* Silbe um,
/// damit TTS den LAUT liest statt des Buchstabennamens.
/// z. B. ㅉ → 쯔 (statt „쌍지읏"), ㄱ → 그, ㅏ → 아.
/// Vollständige Silben/Wörter werden unverändert zurückgegeben.
String speakableJamo(String letter) {
  final stableCarrier = stableJamoCarrier(letter);
  if (stableCarrier != null) {
    return stableCarrier;
  }
  // Führende Konsonanten (초성) in Unicode-Reihenfolge (Index 0–18)
  const leads = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];
  // Vokale (중성) in Unicode-Reihenfolge (Index 0–20)
  const vowels = [
    'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', //
    'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
  ];

  final li = leads.indexOf(letter);
  if (li >= 0) {
    // Konsonant + ㅡ (중성-Index 18) → z. B. ㅉ → 쯔
    return String.fromCharCode(0xAC00 + (li * 21 + 18) * 28);
  }
  final vi = vowels.indexOf(letter);
  if (vi >= 0) {
    // ㅇ (초성-Index 11) + Vokal → z. B. ㅏ → 아
    return String.fromCharCode(0xAC00 + (11 * 21 + vi) * 28);
  }
  return letter; // schon eine Silbe / kein einzelner Jamo
}

/// Chirp3-HD의 1음절 출력은 같은 요청도 길이/음가가 흔들린다. 실기기에서
/// 무음·종성 오인·된소리 오인이 확인된 글자는 화면에 이미 제시하는 예시어를
/// 발음 표본으로 쓴다. 텍스트가 달라져 잘못된 단음절 로컬 캐시도 재사용하지
/// 않는다.
String? stableJamoCarrier(String letter) => switch (letter) {
  'ㅃ' => '빵',
  'ㄷ' => '다리',
  'ㅏ' => '아빠',
  'ㅠ' => '유리',
  'ㅢ' => '의자',
  _ => null,
};

const List<Syllable> syllables = [
  Syllable('가', 'ga', 'ㄱ + ㅏ', '가방', 'Tasche', 'bag'),
  Syllable('나', 'na', 'ㄴ + ㅏ', '나무', 'Baum', 'tree'),
  Syllable('다', 'da', 'ㄷ + ㅏ', '다리', 'Bein', 'leg'),
  Syllable('라', 'ra', 'ㄹ + ㅏ', '라면', 'Ramen', 'ramen'),
  Syllable('마', 'ma', 'ㅁ + ㅏ', '마음', 'Herz', 'heart'),
  Syllable('바', 'ba', 'ㅂ + ㅏ', '바다', 'Meer', 'sea'),
  Syllable('사', 'sa', 'ㅅ + ㅏ', '사과', 'Apfel', 'apple'),
  Syllable('아', 'a', 'ㅇ + ㅏ', '아기', 'Baby', 'baby'),
  Syllable('자', 'ja', 'ㅈ + ㅏ', '자동차', 'Auto', 'car'),
  Syllable('하', 'ha', 'ㅎ + ㅏ', '하늘', 'Himmel', 'sky'),
  Syllable('한', 'han', 'ㅎ + ㅏ + ㄴ', '한국', 'Korea', 'Korea'),
  Syllable('국', 'guk', 'ㄱ + ㅜ + ㄱ', '국수', 'Nudeln', 'noodles'),
  Syllable('말', 'mal', 'ㅁ + ㅏ + ㄹ', '말', 'Pferd', 'horse'),
  Syllable('밥', 'bap', 'ㅂ + ㅏ + ㅂ', '밥', 'Reis', 'rice'),
  Syllable('집', 'jip', 'ㅈ + ㅣ + ㅂ', '집', 'Haus', 'house'),
  Syllable('책', 'chaek', 'ㅊ + ㅐ + ㄱ', '책', 'Buch', 'book'),
];
