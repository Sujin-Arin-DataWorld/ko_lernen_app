/// Hangul-Hilfsfunktionen — Chosung-Extraktion etc.
///
/// **자모 테이블과 음절 분해 산술의 단일 소유자.** 새 코드가 0xAC00 계산을
/// 직접 하지 말고 [decomposeHangulSyllable] 을 쓰면 테이블이 어긋날 일이 없다.
library;

/// 초성 19자.
const List<String> chosungTable = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// 중성(모음) 21자.
const List<String> jungsungTable = [
  'ㅏ',
  'ㅐ',
  'ㅑ',
  'ㅒ',
  'ㅓ',
  'ㅔ',
  'ㅕ',
  'ㅖ',
  'ㅗ',
  'ㅘ',
  'ㅙ',
  'ㅚ',
  'ㅛ',
  'ㅜ',
  'ㅝ',
  'ㅞ',
  'ㅟ',
  'ㅠ',
  'ㅡ',
  'ㅢ',
  'ㅣ',
];

/// 종성(받침) 28자 — index 0 = 받침 없음(`''`).
const List<String> jongsungTable = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄳ',
  'ㄴ',
  'ㄵ',
  'ㄶ',
  'ㄷ',
  'ㄹ',
  'ㄺ',
  'ㄻ',
  'ㄼ',
  'ㄽ',
  'ㄾ',
  'ㄿ',
  'ㅀ',
  'ㅁ',
  'ㅂ',
  'ㅄ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// 한글 음절 블록 U+AC00–U+D7A3.
const int hangulSyllableBase = 0xAC00;
const int hangulSyllableLast = 0xD7A3;

/// 초성 하나당 음절 수 = 21 × 28.
const int _syllableStride = 21 * 28;

bool isHangulSyllable(int rune) =>
    rune >= hangulSyllableBase && rune <= hangulSyllableLast;

/// 완성형 음절 하나를 (초성, 중성, 종성)으로 분해한다.
/// 종성 `''` = 받침 없음. 한글 음절이 아니면 `null`.
(String chosung, String jungsung, String jongsung)? decomposeHangulSyllable(
  int rune,
) {
  if (!isHangulSyllable(rune)) {
    return null;
  }
  final idx = rune - hangulSyllableBase;
  return (
    chosungTable[idx ~/ _syllableStride],
    jungsungTable[(idx % _syllableStride) ~/ jongsungTable.length],
    jongsungTable[idx % jongsungTable.length],
  );
}

/// (초성, 중성, 종성) → 완성형 음절 한 글자. [decomposeHangulSyllable] 의
/// 역함수. 종성 `''` = 받침 없음. 테이블에 없는 자모면 `null`.
String? composeHangulSyllable(String chosung, String jungsung, String jongsung) {
  final cho = chosungTable.indexOf(chosung);
  final jung = jungsungTable.indexOf(jungsung);
  final jong = jongsungTable.indexOf(jongsung);
  if (cho < 0 || jung < 0 || jong < 0) {
    return null;
  }
  return String.fromCharCode(
    hangulSyllableBase +
        cho * _syllableStride +
        jung * jongsungTable.length +
        jong,
  );
}

/// Extrahiert die Initial-Konsonanten (초성) eines Hangul-Strings.
/// Beispiel: "안녕하세요" → "ㅇㄴㅎㅅㅇ"
String extractChosung(String text) {
  final buf = StringBuffer();
  for (final code in text.runes) {
    final parts = decomposeHangulSyllable(code);
    if (parts != null) {
      buf.write(parts.$1);
    } else if (code == 0x20) {
      buf.write(' ');
    }
  }
  return buf.toString();
}

/// Anzahl der Hangul-Silben in einem String (Leerzeichen/Sonderzeichen ignoriert).
int hangulLength(String text) {
  int n = 0;
  for (final code in text.runes) {
    if (isHangulSyllable(code)) n++;
  }
  return n;
}

/// Reine Hangul-Wörter (keine Leerzeichen, keine Sonderzeichen).
bool isPureHangul(String text) {
  if (text.isEmpty) return false;
  for (final code in text.runes) {
    if (!isHangulSyllable(code)) return false;
  }
  return true;
}
