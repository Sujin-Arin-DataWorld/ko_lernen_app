/// 화면 자모 자판용 **한글 조합 오토마타** (2벌식).
///
/// 왜 필요한가: Anlaut-Quiz 의 화면 자판은 누른 자모를 문자열에 그냥 이어붙였다.
/// ㅅ·ㅏ·ㄱ·ㅘ 를 누르면 `"ㅅㅏㄱㅘ"` 가 되는데 채점은 `답 == "사과"` 라서 정답을
/// 만드는 것 자체가 불가능했다("ㅇ 눌렀는데 틀렸다고 나와" — Jin, 2026-08-12
/// 실기기). 모음 키를 추가하는 것만으로는 안 되고, 자모를 음절로 **합치는**
/// 단계가 있어야 한다.
///
/// 시스템 IME 와는 무관하다 — 이 클래스는 앱이 그린 자판에만 쓴다. 사용자가
/// 시스템 키보드로 직접 고치면 [resetTo] 로 상태를 맞춘다.
///
/// 자모 테이블 산술은 [hangul_util] 이 단일 소유자다. 여기서 0xAC00 을 직접
/// 계산하는 곳은 [_pending] 한 곳뿐이고, 인덱스 규약(초성 19 / 중성 21 /
/// 종성 28, 0=없음)은 전부 그 테이블에서 끌어온다.
library;

import 'hangul_util.dart';

/// 겹모음: (선행 중성 index, 후행 중성 index) → 합쳐진 중성 index.
const Map<(int, int), int> _vowelJoins = {
  (8, 0): 9, // ㅗ + ㅏ = ㅘ
  (8, 1): 10, // ㅗ + ㅐ = ㅙ
  (8, 20): 11, // ㅗ + ㅣ = ㅚ
  (13, 4): 14, // ㅜ + ㅓ = ㅝ
  (13, 5): 15, // ㅜ + ㅔ = ㅞ
  (13, 20): 16, // ㅜ + ㅣ = ㅟ
  (18, 20): 19, // ㅡ + ㅣ = ㅢ
};

/// 겹받침: (선행 종성 index, 후행 종성 index) → 합쳐진 종성 index.
const Map<(int, int), int> _jongJoins = {
  (1, 19): 3, // ㄱ + ㅅ = ㄳ
  (4, 22): 5, // ㄴ + ㅈ = ㄵ
  (4, 27): 6, // ㄴ + ㅎ = ㄶ
  (8, 1): 9, // ㄹ + ㄱ = ㄺ
  (8, 16): 10, // ㄹ + ㅁ = ㄻ
  (8, 17): 11, // ㄹ + ㅂ = ㄼ
  (8, 19): 12, // ㄹ + ㅅ = ㄽ
  (8, 25): 13, // ㄹ + ㅌ = ㄾ
  (8, 26): 14, // ㄹ + ㅍ = ㄿ
  (8, 27): 15, // ㄹ + ㅎ = ㅀ
  (17, 19): 18, // ㅂ + ㅅ = ㅄ
};

/// 겹받침 되돌리기: 합쳐진 종성 index → (남는 종성 index, 떨어져 나갈 종성).
final Map<int, (int, int)> _jongSplits = {
  for (final e in _jongJoins.entries) e.value: (e.key.$1, e.key.$2),
};

/// 종성 index → 초성 index. 받침이 다음 음절의 초성으로 넘어갈 때 쓴다.
/// 겹받침(ㄳ·ㄵ…)은 여기 없다 — [_jongSplits] 로 먼저 쪼갠 뒤 조회한다.
final Map<int, int> _jongToCho = {
  for (var j = 1; j < jongsungTable.length; j++)
    if (chosungTable.contains(jongsungTable[j]))
      j: chosungTable.indexOf(jongsungTable[j]),
};

/// 초성 index → 종성 index. ㄸ·ㅃ·ㅉ 은 받침이 될 수 없어 빠진다.
final Map<int, int> _choToJong = {
  for (var c = 0; c < chosungTable.length; c++)
    if (jongsungTable.contains(chosungTable[c]))
      c: jongsungTable.indexOf(chosungTable[c]),
};

/// 자모를 하나씩 받아 한글 음절로 조합한다.
///
/// 조합 중인 음절도 [text] 끝에 항상 반영되므로 화면은 [text] 만 그리면 된다.
/// 확정/미확정을 나눠 보여주지 않는 건 의도다 — 퀴즈 입력창에서 IME 식 밑줄
/// 연출은 오히려 방해가 된다.
class HangulComposer {
  String _committed = '';
  int? _cho;
  int? _jung;
  int _jong = 0;

  /// 확정된 부분 + 조합 중인 음절.
  String get text => _committed + _pending;

  bool get isEmpty => text.isEmpty;

  String get _pending {
    final cho = _cho;
    final jung = _jung;
    if (cho != null && jung != null) {
      return String.fromCharCode(
        hangulSyllableBase +
            (cho * jungsungTable.length + jung) * jongsungTable.length +
            _jong,
      );
    }
    if (cho != null) {
      return chosungTable[cho];
    }
    if (jung != null) {
      return jungsungTable[jung];
    }
    return '';
  }

  void _commit() {
    _committed += _pending;
    _cho = null;
    _jung = null;
    _jong = 0;
  }

  /// 외부(시스템 키보드·초기화)에서 온 텍스트로 상태를 맞춘다.
  /// 조합 중이던 음절은 버리고 [value] 전체를 확정으로 본다.
  void resetTo(String value) {
    _committed = value;
    _cho = null;
    _jung = null;
    _jong = 0;
  }

  void clear() => resetTo('');

  /// 자판에서 자모 하나를 받는다. 한글 자모가 아니면 확정 문자열에 그냥 붙인다.
  void addJamo(String jamo) {
    final vowel = jungsungTable.indexOf(jamo);
    if (vowel >= 0) {
      _addVowel(vowel);
      return;
    }
    final consonant = chosungTable.indexOf(jamo);
    if (consonant >= 0) {
      _addConsonant(consonant);
      return;
    }
    _commit();
    _committed += jamo;
  }

  void _addConsonant(int cho) {
    if (_cho == null && _jung == null) {
      _cho = cho;
      return;
    }
    if (_jung == null) {
      // 초성만 있는데 자음이 또 왔다 → 앞 자음은 홀로 확정.
      _commit();
      _cho = cho;
      return;
    }
    final asJong = _choToJong[cho];
    if (_jong == 0) {
      if (asJong != null) {
        _jong = asJong;
      } else {
        // ㄸ·ㅃ·ㅉ 은 받침이 못 된다 → 새 음절의 초성으로.
        _commit();
        _cho = cho;
      }
      return;
    }
    // 이미 받침이 있다 → 겹받침이 되면 합치고, 안 되면 새 음절로.
    final joined = asJong == null ? null : _jongJoins[(_jong, asJong)];
    if (joined != null) {
      _jong = joined;
      return;
    }
    _commit();
    _cho = cho;
  }

  void _addVowel(int jung) {
    if (_jung == null) {
      // 초성만 있든(사) 아무것도 없든(홀모음) 중성 자리에 들어간다.
      _jung = jung;
      return;
    }
    if (_jong == 0) {
      // 겹모음이 되면 합치고, 안 되면 앞 음절을 확정하고 홀모음으로 시작.
      final joined = _vowelJoins[(_jung!, jung)];
      if (joined != null) {
        _jung = joined;
        return;
      }
      _commit();
      _jung = jung;
      return;
    }
    // 받침이 있는데 모음이 왔다 → 받침이 다음 음절의 초성으로 넘어간다.
    // 예: "삭" 상태에서 ㅘ → "사" 확정 + "과". 겹받침이면 뒷자만 넘어간다.
    final split = _jongSplits[_jong];
    final movingJong = split == null ? _jong : split.$2;
    _jong = split == null ? 0 : split.$1;
    _commit();
    _cho = _jongToCho[movingJong];
    _jung = jung;
  }

  /// 자모 한 단위를 지운다. 조합 중이면 그 안에서, 아니면 확정 문자열의 마지막
  /// 글자를 분해해 마지막 자모만 뗀다 — 시스템 IME 와 같은 감각.
  void backspace() {
    if (_jong != 0) {
      final split = _jongSplits[_jong];
      _jong = split == null ? 0 : split.$1;
      return;
    }
    if (_jung != null) {
      final source = _vowelJoins.entries
          .where((e) => e.value == _jung)
          .firstOrNull;
      _jung = source?.key.$1;
      return;
    }
    if (_cho != null) {
      _cho = null;
      return;
    }
    if (_committed.isEmpty) {
      return;
    }
    // 확정 문자열의 마지막 글자를 조합 상태로 되돌린 뒤 한 자모만 뗀다.
    final runes = _committed.runes.toList();
    final last = runes.removeLast();
    _committed = String.fromCharCodes(runes);
    final parts = decomposeHangulSyllable(last);
    if (parts == null) {
      return; // 한글 음절이 아니면 글자를 통째로 지운 것으로 끝.
    }
    _cho = chosungTable.indexOf(parts.$1);
    _jung = jungsungTable.indexOf(parts.$2);
    _jong = jongsungTable.indexOf(parts.$3);
    backspace();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
