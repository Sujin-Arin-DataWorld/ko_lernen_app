/// 초성 퀴즈 힌트 — 계획(plan)과 렌더링을 한 파일에 묶어 둔다.
///
/// **불변식: 화면에 그려진 힌트만 보고 정답을 복원할 수 있으면 안 된다.**
///
/// 2026-08-12 회귀에서 배운 것: 같은 규칙을 "문자열 힌트"와 "위젯 힌트" 두
/// 곳에서 각각 계산하면 한쪽만 고쳐지고 화면은 계속 정답을 흘린다. 그래서
/// 이 파일에는 **경로가 하나뿐이다** — [ChosungHintPlan] 은 오직
/// [buildChosungHintPlan] 만이 만들 수 있고, 그 계획을 그리는 위젯은
/// [ChosungHint] 하나다. 화면이 쓰지 않는 대체 표현(문자열 패턴 등)은
/// 두지 않는다. 그런 부산물이 있으면 규칙이 또 한쪽에만 적용된다.
library;

import 'package:flutter/material.dart';

import '../../services/hangul_util.dart';
import 'tokens.dart';

/// 사용자가 고르는 힌트 난이도.
/// - [chosung]: 초성만 (어려움). 중성·받침은 점선 슬롯.
/// - [chosungVowel]: 초성 + 중성 (쉬움). 받침만 점선 슬롯.
enum HintMode { chosung, chosungVowel }

/// 힌트 한 칸.
sealed class ChosungHintUnit {
  const ChosungHintUnit();
}

/// 한글이 아닌 글자 — 그대로 보여준다(공백, 하이픈, 라틴 문자 등).
final class ChosungHintLiteral extends ChosungHintUnit {
  final String text;
  const ChosungHintLiteral(this.text);
}

/// 한글 음절 하나가 화면에 어떻게 그려지는지에 대한 기술(記述).
///
/// 화면 슬롯과 1:1 대응한다:
///   초성 = 항상 채워진 슬롯
///   중성 = [revealJungsung] 이면 채워진 슬롯, 아니면 "모음" 점선 슬롯
///   받침 = [hasJongsung] 일 때만 "받침" 점선 슬롯 (내용은 절대 안 보여줌)
final class ChosungHintSyllable extends ChosungHintUnit {
  final String chosung;
  final String jungsung;

  /// 실제 받침. `''` = 받침 없음. **화면에는 절대 그리지 않는다** —
  /// 존재 여부만 점선 슬롯으로 드러난다.
  final String jongsung;
  final bool revealJungsung;

  const ChosungHintSyllable({
    required this.chosung,
    required this.jungsung,
    required this.jongsung,
    required this.revealJungsung,
  });

  bool get hasJongsung => jongsung.isNotEmpty;

  /// 이 음절이 화면만 보고 완전히 복원되는가?
  ///
  /// 초성은 언제나 공개다. 따라서 중성이 공개되고 받침이 없으면
  /// (= 받침 슬롯 자체가 없어서 "받침 없음"이 확정되면) 음절이 그대로 드러난다.
  /// 받침이 있으면 어떤 받침인지 모르므로 드러나지 않는다.
  bool get revealsSyllable => revealJungsung && jongsung.isEmpty;
}

/// 한 단어의 힌트 계획. **[buildChosungHintPlan] 으로만 만들 수 있다** —
/// 정규화를 거치지 않은 계획은 이 라이브러리 밖에서 존재할 수 없다.
@immutable
class ChosungHintPlan {
  final String word;

  /// 사용자가 고른 모드.
  final HintMode requestedMode;

  /// 정답 노출을 막기 위해 강등된 뒤의 실제 모드.
  final HintMode effectiveMode;

  final List<ChosungHintUnit> units;

  const ChosungHintPlan._({
    required this.word,
    required this.requestedMode,
    required this.effectiveMode,
    required this.units,
  });

  /// 사용자가 고른 모드가 정답을 노출해서 강등됐는가?
  bool get wasDowngraded => requestedMode != effectiveMode;

  /// **이 계획대로 그리면 정답이 통째로 드러나는가?**
  ///
  /// 한글 음절이 하나도 없으면(= 보여줄 게 리터럴뿐이면) 판정 대상이 아니다.
  bool get revealsAnswer {
    var sawSyllable = false;
    for (final unit in units) {
      if (unit is ChosungHintSyllable) {
        sawSyllable = true;
        if (!unit.revealsSyllable) {
          return false;
        }
      }
    }
    return sawSyllable;
  }
}

/// 정답을 노출하지 않는 힌트 계획을 만든다 — **유일한 진입점**.
///
/// [requested] 대로 그리면 정답이 통째로 드러나는 단어는 자동으로
/// [HintMode.chosung] 으로 강등한다. 예: `더`(무받침 1음절)는 쉬움 모드에서
/// `ㄷ` + `ㅓ` = 정답이므로 초성만 남긴다. 번들 어휘 930개 중 197개가 해당.
ChosungHintPlan buildChosungHintPlan(String word, HintMode requested) {
  final plan = _rawPlan(word, requested);
  if (!plan.revealsAnswer) {
    return plan;
  }
  // 모음을 가리면 어떤 음절도 완전히 복원되지 않는다 → 유일한 안전 모드.
  final safe = _rawPlan(word, HintMode.chosung);
  assert(
    !safe.revealsAnswer,
    '초성 모드로 강등했는데도 정답이 노출된다: "$word". '
    '슬롯 렌더링 규칙을 바꿨다면 ChosungHintSyllable.revealsSyllable 도 같이 고쳐라.',
  );
  return ChosungHintPlan._(
    word: safe.word,
    requestedMode: requested,
    effectiveMode: safe.effectiveMode,
    units: safe.units,
  );
}

/// 정규화 이전의 날 것 — 이 라이브러리 밖으로 새어 나가면 안 된다.
ChosungHintPlan _rawPlan(String word, HintMode mode) {
  final revealJungsung = mode == HintMode.chosungVowel;
  final units = <ChosungHintUnit>[];
  for (final rune in word.runes) {
    final parts = decomposeHangulSyllable(rune);
    if (parts == null) {
      units.add(ChosungHintLiteral(String.fromCharCode(rune)));
      continue;
    }
    final (cho, jung, jong) = parts;
    units.add(
      ChosungHintSyllable(
        chosung: cho,
        jungsung: jung,
        jongsung: jong,
        revealJungsung: revealJungsung,
      ),
    );
  }
  return ChosungHintPlan._(
    word: word,
    requestedMode: mode,
    effectiveMode: mode,
    units: List.unmodifiable(units),
  );
}

// ── 렌더링 ────────────────────────────────────────────────────────────────────
// 음절 스캐폴드: 각 음절 = 초성 / 중성 / (받침) 슬롯 박스.
// 채워진 슬롯 = 주어진 자모, 점선 슬롯 = 학습자가 채워야 할 부분.

/// 초성 퀴즈 힌트 위젯. [word] 와 [mode] 만 받고 계획은 스스로 만든다 —
/// 정규화를 건너뛴 상태를 밖에서 주입할 방법이 없다.
class ChosungHint extends StatelessWidget {
  final String word;
  final HintMode mode;
  final Color accent;

  /// 점선 슬롯 라벨.
  final String vowelLabel;
  final String jongsungLabel;

  const ChosungHint({
    super.key,
    required this.word,
    required this.mode,
    required this.accent,
    // 기본값을 두면 아무도 안 넘겨서 한국어가 그대로 화면에 남는다
    // (docs/SESSION_LOG.md:6665 에 미해결로 기록돼 있던 건). required 로
    // 바꿔 컴파일러가 호출부를 전부 잡게 한다.
    required this.vowelLabel,
    required this.jongsungLabel,
  });

  @override
  Widget build(BuildContext context) {
    final plan = buildChosungHintPlan(word, mode);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final unit in plan.units)
          switch (unit) {
            ChosungHintSyllable() => _SyllableBox(
              syllable: unit,
              accent: accent,
              vowelLabel: vowelLabel,
              jongsungLabel: jongsungLabel,
            ),
            ChosungHintLiteral() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                unit.text,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          },
      ],
    );
  }
}

class _SyllableBox extends StatelessWidget {
  final ChosungHintSyllable syllable;
  final Color accent;
  final String vowelLabel;
  final String jongsungLabel;

  const _SyllableBox({
    required this.syllable,
    required this.accent,
    required this.vowelLabel,
    required this.jongsungLabel,
  });

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      _Slot(text: syllable.chosung, filled: true, accent: accent),
      _Slot(
        text: syllable.revealJungsung ? syllable.jungsung : vowelLabel,
        filled: syllable.revealJungsung,
        accent: accent,
      ),
      // 받침은 "있다"만 알려준다 — 내용은 절대 그리지 않는다.
      if (syllable.hasJongsung)
        _Slot(text: jongsungLabel, filled: false, accent: accent),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            slots[i],
          ],
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String text;
  final bool filled;
  final Color accent;
  const _Slot({required this.text, required this.filled, required this.accent});

  // W10 T-V5(2026-09-05, Jin 신고): 30×40 상자 + 24px 텍스트가 큰 배율에서
  // 글자 하단(특히 받침 있는 자모)을 잘랐다. 36×48 로 여유를 두고, 배율을
  // 1.3배로 상한하고, 줄 높이를 1.0으로 고정해 여분 leading을 없앤다.
  static const _slotSize = Size(36, 48);
  static const _textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);
    if (filled) {
      return Container(
        width: _slotSize.width,
        height: _slotSize.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: tt.h3.copyWith(
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          textScaler: textScaler,
          textHeightBehavior: _textHeightBehavior,
        ),
      );
    }
    // 채울 칸 — 점선 박스 + 무엇을 넣을지 라벨(모음/받침).
    return CustomPaint(
      painter: _DashedBoxPainter(color: accent.withValues(alpha: 0.65)),
      child: Container(
        width: _slotSize.width,
        height: _slotSize.height,
        alignment: Alignment.center,
        child: Text(
          text,
          style: tt.caption.copyWith(
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: accent.withValues(alpha: 0.75),
          ),
          textScaler: textScaler,
          textHeightBehavior: _textHeightBehavior,
        ),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(7),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBoxPainter old) => old.color != color;
}
