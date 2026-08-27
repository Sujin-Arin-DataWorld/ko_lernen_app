import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// **SoriChromeRow** — §17 앱바 아래 단 하나의 크롬 행.
///
/// leading 필터 아이콘 + center 진행 메타 + trailing 컨트롤 1개(보통
/// `TtsSpeedAction`)만 담는다. **본문 위에 이 행을 두 번 쌓지 않는다** —
/// `chrome_stack_guard_test.dart`가 화면당 Wrap+칩 중복 적층을 잡는다.
///
/// 레이아웃 높이는 [SoriLayout.chromeRowTouchHeight](48dp)로 고정한다 —
/// leading/trailing 아이콘의 실제 터치 영역과 같은 값이어야 한다.
/// Flutter 는 히트테스트를 조상의 실제 크기에서 끊으므로, 이 행 자신이
/// 44dp 라면 안쪽에서 48dp 를 아무리 그려도 위/아래 2dp 는 절대 눌리지
/// 않는다(검수#13 이 speakable.dart 에서 고친 것과 같은 버그, finding
/// 10). 아이콘의 시각 크기(44dp)는 `_ChromeSlot` 안에서 `Center` 로
/// 배치한다.
class SoriChromeRow extends StatelessWidget {
  const SoriChromeRow({
    super.key,
    this.onFilterTap,
    this.filterSemanticLabel,
    this.meta,
    this.trailing,
  });

  /// 탭하면 필터 시트를 여는 콜백(예: `showSoriFilterSheet`). null이면
  /// leading 아이콘 자체를 숨긴다.
  final VoidCallback? onFilterTap;
  final String? filterSemanticLabel;

  /// 가운데 진행 메타 — 보통 `Text('3 / 12', style: tt.meta)`.
  final Widget? meta;

  /// 오른쪽 단일 컨트롤 — 보통 `TtsSpeedAction`. 두 번째 컨트롤을 넣지 않는다.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SoriLayout.chromeRowTouchHeight,
      child: Row(
        children: [
          if (onFilterTap != null)
            _ChromeSlot(
              icon: Icons.tune_rounded,
              semanticLabel: filterSemanticLabel ?? '',
              onTap: onFilterTap!,
            )
          else
            const SizedBox(width: Spacing.sm),
          Expanded(child: Center(child: meta ?? const SizedBox.shrink())),
          if (trailing != null)
            trailing!
          else
            const SizedBox(width: Spacing.sm),
        ],
      ),
    );
  }
}

class _ChromeSlot extends StatelessWidget {
  const _ChromeSlot({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    // SoriPressable 을 48dp SizedBox 로 직접 감싼다 — speakable.dart 의
    // SoriSpeechIndicator 와 같은 패턴(검수#13). OverflowBox 트릭을 쓰지
    // 않는다: 그 트릭은 조상이 44dp 인 채로 남아 있을 때만 필요했는데,
    // 이제 SoriChromeRow 자신이 48dp 이므로 불필요하고, 여전히 조상이
    // 44dp 라고 착각하게 만드는 코드 냄새다.
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          child: SizedBox(
            width: SoriLayout.chromeRowTouchHeight,
            height: SoriLayout.chromeRowTouchHeight,
            child: Center(
              child: Icon(icon, size: 22, color: s.text),
            ),
          ),
        ),
      ),
    );
  }
}
