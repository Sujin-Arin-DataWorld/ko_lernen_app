import 'package:flutter/material.dart';

import 'sori_stage/sori_stage_shell.dart';

/// **AppShell** — Sori Stage 5탭 셸 진입점.
///
/// Phase 4 (2026-08-14): `SoriStageFeatureGate` 제거 — Sori Stage가 유일한 셸.
/// 레거시 `LegacyAppShell`/`HomeScreen` 삭제 완료.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  /// 앱 재시작 없이 홈 투어를 다시 띄우는 신호.
  /// 설정 "튜토리얼 다시 보기"가 값을 올리면 → 홈 탭으로 전환 후 투어 재생.
  /// (플래그만 리셋하면 [State.initState]가 다시 안 돌아 재시작 전엔 안 보이던 갭 해소.)
  static final ValueNotifier<int> replayHomeTour = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) =>
      SoriStageShell(replayHomeTour: replayHomeTour);
}
