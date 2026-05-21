/// Hangul-Hilfsfunktionen — Chosung-Extraktion etc.
library;

const _chosung = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

/// Extrahiert die Initial-Konsonanten (초성) eines Hangul-Strings.
/// Beispiel: "안녕하세요" → "ㅇㄴㅎㅅㅇ"
String extractChosung(String text) {
  final buf = StringBuffer();
  for (final code in text.runes) {
    if (code >= 0xAC00 && code <= 0xD7A3) {
      final idx = (code - 0xAC00) ~/ (21 * 28);
      buf.write(_chosung[idx]);
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
    if (code >= 0xAC00 && code <= 0xD7A3) n++;
  }
  return n;
}

/// Reine Hangul-Wörter (keine Leerzeichen, keine Sonderzeichen).
bool isPureHangul(String text) {
  if (text.isEmpty) return false;
  for (final code in text.runes) {
    if (code < 0xAC00 || code > 0xD7A3) return false;
  }
  return true;
}
