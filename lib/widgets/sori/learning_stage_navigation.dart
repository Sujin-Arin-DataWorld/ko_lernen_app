import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'approved_chrome_assets.dart';
import '../../screens/app_shell.dart';
import 'adaptive_navigation.dart';
import 'home_action.dart';

/// Reuses the real shell destinations for the approved mobile learning book.
/// The existing shell owns state and refresh; this never creates a second shell.
class SoriLearningStageNavigation extends StatelessWidget {
  const SoriLearningStageNavigation({
    super.key,
    this.woodenSurface = false,
    this.escape = const SoriHomeEscape(),
    this.onLeave,
    this.canLeave,
    this.enabled = true,
    this.onDestinationSelected,
  });
  final bool woodenSurface;
  final SoriHomeEscape escape;
  final VoidCallback? onLeave;
  final bool Function()? canLeave;
  final bool enabled;

  /// An embedded learning journey may own its exit instead of the shell.
  /// Called only after the same leave guard and cleanup as normal navigation.
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    if (SoriAdaptiveNavigation.usesRailForWidth(
      MediaQuery.sizeOf(context).width,
    )) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoriAdaptiveNavigation(
          selectedIndex: 1,
          onDestinationSelected: (index) async {
            if (!enabled || canLeave?.call() == false) {
              return;
            }
            if (!await showLeaveConfirmSheet(context, escape) ||
                !context.mounted ||
                canLeave?.call() == false) {
              return;
            }
            onLeave?.call();
            final destination = onDestinationSelected;
            if (destination != null) {
              destination(index);
              return;
            }
            Navigator.of(context).popUntil((route) => route.isFirst);
            AppShell.openStageTab(index);
          },
          items: [
            SoriAdaptiveNavigationItem(
              label: t.soriStageNavToday,
              icon: Icons.today_outlined,
              selectedIcon: Icons.today_rounded,
              imageAsset: ApprovedChromeAssets.today,
            ),
            SoriAdaptiveNavigationItem(
              label: t.soriStageNavLearn,
              icon: Icons.school_outlined,
              selectedIcon: Icons.school_rounded,
              imageAsset: ApprovedChromeAssets.learn,
            ),
            SoriAdaptiveNavigationItem(
              label: t.soriStageNavGames,
              icon: Icons.sports_esports_outlined,
              selectedIcon: Icons.sports_esports_rounded,
              imageAsset: ApprovedChromeAssets.games,
            ),
            SoriAdaptiveNavigationItem(
              label: t.soriStageNavHanok,
              icon: Icons.home_work_outlined,
              selectedIcon: Icons.home_work_rounded,
              imageAsset: ApprovedChromeAssets.hanok,
            ),
            SoriAdaptiveNavigationItem(
              label: t.soriStageNavGye,
              icon: Icons.groups_2_outlined,
              selectedIcon: Icons.groups_2_rounded,
              imageAsset: ApprovedChromeAssets.gye,
            ),
          ],
        ),
      ],
    );
  }
}
