import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/adaptive_navigation.dart';
import '../../widgets/sori/tab_reselect.dart';
import 'sori_stage_catalog_screen.dart';
import 'sori_stage_gye_screen.dart';
import 'sori_stage_hanok_screen.dart';
import 'sori_stage_today_screen.dart';

class SoriStageShell extends StatefulWidget {
  const SoriStageShell({super.key, required this.replayHomeTour});

  final ValueListenable<int> replayHomeTour;

  @override
  State<SoriStageShell> createState() => _SoriStageShellState();
}

class _SoriStageShellState extends State<SoriStageShell> {
  int _index = 0;
  final _scrollControllers = List.generate(5, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    widget.replayHomeTour.addListener(_onReplayRequested);
  }

  @override
  void didUpdateWidget(covariant SoriStageShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayHomeTour != widget.replayHomeTour) {
      oldWidget.replayHomeTour.removeListener(_onReplayRequested);
      widget.replayHomeTour.addListener(_onReplayRequested);
    }
  }

  @override
  void dispose() {
    widget.replayHomeTour.removeListener(_onReplayRequested);
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onReplayRequested() {
    if (!mounted) {
      return;
    }
    setState(() => _index = 0);
  }

  void _select(int index) {
    if (_index == index) {
      reselectTabScroll(
        _scrollControllers[index],
        reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      );
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final usesRail = SoriAdaptiveNavigation.usesRailForWidth(width);
    final navigation = SoriAdaptiveNavigation(
      selectedIndex: _index,
      onDestinationSelected: _select,
      items: [
        SoriAdaptiveNavigationItem(
          icon: Icons.today_outlined,
          selectedIcon: Icons.today_rounded,
          label: t.soriStageNavToday,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          label: t.soriStageNavLearn,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.sports_esports_outlined,
          selectedIcon: Icons.sports_esports_rounded,
          label: t.soriStageNavGames,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.home_work_outlined,
          selectedIcon: Icons.home_work_rounded,
          label: t.soriStageNavHanok,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.groups_2_outlined,
          selectedIcon: Icons.groups_2_rounded,
          label: t.soriStageNavGye,
        ),
      ],
    );
    final screens = [
      SoriStageTodayScreen(
        replayHomeTour: widget.replayHomeTour,
        active: _index == 0,
      ),
      SoriStageCatalogScreen(tab: SoriStageTab.learn, active: _index == 1),
      SoriStageCatalogScreen(tab: SoriStageTab.games, active: _index == 2),
      SoriStageHanokScreen(active: _index == 3),
      SoriStageGyeScreen(active: _index == 4),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (usesRail)
            SafeArea(
              child: SizedBox(
                width: SoriAdaptiveNavigation.railWidthForWidth(width),
                child: navigation,
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (var index = 0; index < screens.length; index++)
                  PrimaryScrollController(
                    controller: _scrollControllers[index],
                    child: TickerMode(
                      enabled: _index == index,
                      child: screens[index],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: usesRail ? null : navigation,
    );
  }
}
