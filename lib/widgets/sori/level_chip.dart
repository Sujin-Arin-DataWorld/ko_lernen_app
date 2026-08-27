import 'package:flutter/material.dart';

import 'hanok_tokens.dart';
import 'tokens.dart';

/// **SoriLevelChip** — 레벨 표기의 단일 문법 (§4.4-2 색 수렴).
///
/// 단청 여섯 색(`HanokLevelPalette`) 채움 + 흰 라벨 — 팔레트 여섯 색 전부
/// 흰 글씨 AA(4.50:1+) 확보(hanok_tokens 주석 준거). 미션 히어로(§10.1)와
/// `/path` 챕터 헤더(§6.2-②)가 같은 칩을 쓴다.
class SoriLevelChip extends StatelessWidget {
  /// 'A1'…'B2' — 표기 그대로 라벨이 된다.
  final String code;

  /// 채움 색 강제(예: "챕터 0"의 먹색) — null이면 레벨 코드로 결정.
  final Color? color;

  const SoriLevelChip({super.key, required this.code, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? HanokLevelPalette.of(code),
        borderRadius: SoriRadius.brSm,
      ),
      child: Text(
        code,
        style: SoriTextTheme.of(
          context,
        ).label.copyWith(fontSize: 11, color: Colors.white),
      ),
    );
  }
}
