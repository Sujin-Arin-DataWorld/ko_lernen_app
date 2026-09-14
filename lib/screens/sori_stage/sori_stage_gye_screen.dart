import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../gye_tab_screen.dart';

/// A single scroll surface for optional group entry and actual memberships.
class SoriStageGyeScreen extends StatelessWidget {
  const SoriStageGyeScreen({
    super.key,
    this.active = true,
    this.loadGyeMetas,
    this.onContinueSolo,
    this.refreshGeneration = 0,
  });

  /// The shell keeps every tab alive; other tabs refresh their own
  /// progression on activation. This tab has no such refresh-on-activation
  /// need beyond what `GyeTabScreen` already does internally (reload after a
  /// find-or-create round trip), so this flag only forwards to the embedded
  /// tab.
  final bool active;
  final VoidCallback? onContinueSolo;
  final int refreshGeneration;

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
                    title: t.soriStageNavGye,
                    titleStyle: SoriTextTheme.of(
                      context,
                    ).h1.copyWith(fontSize: 26, height: 1.35),
                    // 접힌 56dp 크롬 바용 짧은 제목(§W-G G5.1) — 없으면
                    // title 전체가 ellipsis 로 잘린다.
                    collapsedTitle: t.soriStageNavGye,
                    // §W-G G5.2(D4 확정): trailing = ⓘ 문화 설명 + 아바타
                    // 둘 다. 두 액션 모두 48dp 히트영역 — trailingSlots=2가
                    // 헤더 텍스트 폭 예산에서 그만큼을 미리 뺀다.
                    trailingSlots: 2,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: const ValueKey('cultural_help_gye'),
                          tooltip: t.gyeExplainMore,
                          onPressed: () => showGyeDetails(context),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                        const SizedBox(width: Spacing.xs),
                        const SoriAvatar(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
                GyeTabScreen(
                  embedded: true,
                  active: active,
                  refreshGeneration: refreshGeneration,
                  loadGyeMetas: loadGyeMetas,
                  onContinueSolo: onContinueSolo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
