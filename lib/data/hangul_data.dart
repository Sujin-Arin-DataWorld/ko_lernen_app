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

  /// 연상 설명을 UI 언어로. `lib/models/grammar.dart`·`lib/models/vocab.dart`
  /// 의 `…For(lang)` 패턴과 같은 모양이다.
  ///
  /// 2026-08-17 테스터(Amor): "EN 인터페이스인데 연상 힌트가 독일어로 나온다."
  /// [descriptionEn] 은 50개 항목 전부 채워져 있었는데 화면이 [descriptionDe]
  /// 만 읽고 있었다 — 데이터가 아니라 배선 문제였다.
  String descriptionFor(String lang) =>
      (lang == 'en' && descriptionEn.trim().isNotEmpty)
      ? descriptionEn
      : descriptionDe;

  /// 예시어의 뜻을 UI 언어로.
  String exampleFor(String lang) =>
      (lang == 'en' && exampleEn.trim().isNotEmpty) ? exampleEn : exampleDe;
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
    '-/ng',
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

  /// 예시어의 뜻을 UI 언어로.
  String exampleFor(String lang) =>
      (lang == 'en' && exampleEn.trim().isNotEmpty) ? exampleEn : exampleDe;

  /// 카드 탭에서는 음절도 [HangulChar] 와 같은 모양으로 다룬다.
  ///
  /// 어댑터를 데이터 옆에 둔다 — 화면에서 `exampleDe`/`exampleEn` 필드를 직접
  /// 만지면 "언어 분기를 빼먹은 직접 참조" 와 구분이 안 되고, 그 구분이
  /// `test/hangul_content_locale_test.dart` 의 소스 스캔이 지키는 선이다.
  /// 설명 자리에 들어가는 구성(ㄱ + ㅏ)은 언어와 무관해 양쪽에 같이 넣는다.
  HangulChar toHangulChar() => HangulChar(
    letter,
    romanization,
    composition,
    composition,
    exampleWord,
    exampleDe,
    exampleEn,
  );
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

/// QA 에서 **실기기 오인이 확인된 글자만** 다른 1음절로 갈아끼우는 예외 표.
///
/// 2026-08-12에는 Chirp3-HD 의 1음절 불안정을 예시어 전체(ㄷ→'다리',
/// ㅏ→'아빠')로 우회했다. 2026-08-17 테스터(Amor)가 "카드를 누르면 순수
/// 음가가 아니라 예시어가 나온다"고 정확히 짚었다 — 낱자 카드는 **음가**를
/// 들려주는 화면이라 여러 음절을 읽으면 안 된다.
///
/// 불안정의 원인은 런타임 동적 합성이었다. `tool/generate_tts.py` 로 낱자
/// 전체를 미리 합성해 Storage 에 고정하면 재생이 결정적이 되므로, 예외 없이
/// 일반 규칙(자음+ㅡ · ㅇ+모음)으로 되돌린다. 자음을 전부 +ㅡ 로 통일하는
/// 편이 낫다 — 일부만 +ㅏ 로 바꾸면 "그·느·다·르" 처럼 들려 오히려 헷갈린다.
///
/// ⛔ 여기 값은 **반드시 1음절**이어야 하고, `tool/generate_tts.py` 의
/// `stable_carriers` 와 **항상 같아야** 한다 — `test/jamo_speech_test.dart` 가
/// 둘 다 강제한다. 예시어(2음절 이상)를 다시 넣지 말 것.
String? stableJamoCarrier(String letter) => switch (letter) {
  // 현재 비어 있다. Jin 의 청취 검수에서 특정 글자가 무음/오인으로 확인되면
  // 그 글자만 여기에 **1음절**로 등록한다. 예: 'ㄷ' => '다',
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
