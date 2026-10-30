import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../widgets/sori/top_chrome.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../gye_tab_screen.dart';
import '../../widgets/sori/ildu_r16_estate_artwork.dart';
import 'c_stage_chrome.dart';

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
      body: CStageBackground(
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
                  sliver: Builder(
                    builder: (context) {
                      return SoriRootHeader(
                        title: t.soriStageNavGye,
                        foreground: CPalette.paper,
                        background: CPalette.jade,
                        trailing: IconButton(
                          key: const ValueKey('cultural_help_gye'),
                          tooltip: t.gyeExplainMore,
                          onPressed: () => showGyeDetails(context),
                          icon: const Icon(Icons.help_outline_rounded),
                          color: CPalette.paper,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
                GyeTabScreen(
                  embedded: true,
                  conceptC: true,
                  active: active,
                  refreshGeneration: refreshGeneration,
                  loadGyeMetas: loadGyeMetas,
                  onContinueSolo: onContinueSolo,
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    0,
                    padding.right,
                    Spacing.lg,
                  ),
                  sliver: const SliverToBoxAdapter(child: IlDuR16EstateEntry()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
