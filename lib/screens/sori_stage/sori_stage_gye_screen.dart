import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../gye_tab_screen.dart';

/// **Gye 탭** (§W-G, W-F `SoriStageHanokScreen`과 같은 슬리버 계약).
///
/// 이전엔 `SoriStageSafeViewport` → 고정 헤더 `Column` → `Expanded(GyeTabScreen
/// (embedded))` 였고, `GyeTabScreen`이 임베드 모드에서도 자체 `Scaffold` +
/// `ListView`를 그려 이중 스크롤이었다(§W-G G 브리프). 이제 Hanok 탭처럼
/// 헤더·스텝퍼·계 목록이 전부 슬리버로 한 `CustomScrollView`를 공유한다 —
/// `GyeTabScreen(embedded: true)`가 스스로 슬리버를 반환한다
/// (`buildEmbedded`, `HanokWorldScreen`과 같은 계약, §W-F F2).
class SoriStageGyeScreen extends StatelessWidget {
  const SoriStageGyeScreen({
    super.key,
    this.active = true,
    this.loadGyeMetas,
  });

  /// The shell keeps every tab alive; other tabs refresh their own
  /// progression on activation. This tab has no such refresh-on-activation
  /// need beyond what `GyeTabScreen` already does internally (reload after a
  /// find-or-create round trip), so this flag only forwards to the embedded
  /// tab.
  final bool active;

  /// Test seam forwarded straight to the embedded [GyeTabScreen] (§W-G
  /// G5.3) — production leaves this null so the tab keeps reading the
  /// shared [GyeService.myGyeMetas]. W-J's fold/visual-evidence captures use
  /// this seam to drive a deterministic one-gye state.
  final Future<List<GyeMeta>> Function()? loadGyeMetas;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: SoriMaxWidth.hub,
            // top=20/left=20/right=20/bottom=48 — 같은 클램프 상수를 쓰는
            // Hanok 탭(`sori_stage_hanok_screen.dart`)과 동일 리듬.
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                  ),
                  sliver: SoriCollapsingHeader(
                    eyebrow: t.soriStageNavGye,
                    title: t.soriStageGyePromise,
                    // 접힌 56dp 크롬 바용 짧은 제목(§W-G G5.1) — 없으면
                    // title 전체가 ellipsis 로 잘린다.
                    collapsedTitle: t.soriStageNavGye,
                    // §W-G G5.2(D4 확정): trailing = ⓘ 문화 설명 + 아바타
                    // 둘 다. 두 액션 모두 48dp 히트영역 — trailingSlots=2가
                    // 헤더 텍스트 폭 예산에서 그만큼을 미리 뺀다.
                    trailingSlots: 2,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CulturalHelpButton(termId: 'gye'),
                        SizedBox(width: Spacing.xs),
                        SoriAvatar(),
                      ],
                    ),
                  ),
                ),
                // §W-G G5.1: 헤더 다음 첫 콘텐츠 간격은 Spacing.xl 하나 —
                // 카탈로그의 `Spacing.xl + padding.bottom` 72dp 패턴은
                // 여기서 복제하지 않는다(Hanok 탭과 같은 규약).
                //
                // §W-G2 item 1: 스텝퍼는 더 이상 여기서 그리지 않는다 — 현재
                // 단계가 `metas`(로드한 계 목록)에서 파생되는데, 이 화면은
                // 그 값을 모른다. `GyeTabScreen._buildStepperSliver`가 이
                // 자리(첫 임베디드 슬리버)에서 대신 그린다.
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
                GyeTabScreen(
                  embedded: true,
                  active: active,
                  loadGyeMetas: loadGyeMetas,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
