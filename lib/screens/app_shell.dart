import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../config/sori_stage_feature.dart';
import '../services/storage_service.dart';
import '../widgets/sori/adaptive_navigation.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tab_reselect.dart';
import 'home_screen.dart';
import 'practice_hub_screen.dart';
import 'discover_screen.dart';
import 'gye_tab_screen.dart';
import 'profile_screen.dart';
import 'sori_stage/sori_stage_shell.dart';

/// **AppShell** — 5-destination adaptive app shell.
///
///   0. 홈       (HomeScreen — 오늘의 미션과 학습 경로)
///   1. 배우기   (PracticeHubScreen — 현재 학습과 빠른 연습)
///   2. Entdecken (DiscoverScreen — 검색 가능한 전체 기능 지도)
///   3. 계       (GyeTabScreen — 비경쟁 협력 그룹)
///   4. 나       (ProfileScreen — 통계·설정)
///
/// IndexedStack으로 탭 상태를 보존(스와이프 X — 게임/시나리오 제스처 충돌 회피).
/// 탭 내 `pushNamed`는 루트 Navigator → 상세화면이 탭바 위 전체화면(듀오링고식 진입).
class AppShell extends StatelessWidget {
  const AppShell({super.key, this.featureGate = const SoriStageFeatureGate()});

  final SoriStageFeatureGate featureGate;

  /// 앱 재시작 없이 홈 투어를 다시 띄우는 신호.
  /// 설정 "튜토리얼 다시 보기"가 값을 올리면 → 홈 탭으로 전환 후 투어 재생.
  /// (플래그만 리셋하면 [State.initState]가 다시 안 돌아 재시작 전엔 안 보이던 갭 해소.)
  static final ValueNotifier<int> replayHomeTour = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => featureGate.isEnabled
      ? SoriStageShell(replayHomeTour: replayHomeTour)
      : const LegacyAppShell();
}

class LegacyAppShell extends StatefulWidget {
  const LegacyAppShell({super.key});

  @override
  State<LegacyAppShell> createState() => _LegacyAppShellState();
}

class _LegacyAppShellState extends State<LegacyAppShell> {
  int _index = 0;
  final List<ScrollController> _tabScrollControllers = List.generate(
    5,
    (_) => ScrollController(),
  );

  // Stage A: 홈 투어 스포트라이트 키.
  // NavigationBar를 Stack으로 감싸고 각 탭 위치에 크기 0 앵커를 올린다.
  // 이 방식은 NavigationBar 레이아웃에 전혀 영향을 주지 않는다.
  final List<GlobalKey> _tabKeys = List.generate(5, (_) => GlobalKey());
  final GlobalKey _pathTourKey = GlobalKey();
  final GlobalKey _missionTourKey = GlobalKey();
  // Stage B 예약: final GlobalKey _bookTourKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AppShell.replayHomeTour.addListener(_onReplayRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!Storage.tutHomeTourSeen) {
        _startHomeTour();
      }
    });
  }

  @override
  void dispose() {
    AppShell.replayHomeTour.removeListener(_onReplayRequested);
    for (final controller in _tabScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (_index == index) {
      reselectTabScroll(
        _tabScrollControllers[index],
        reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      );
      return;
    }
    setState(() => _index = index);
  }

  /// 설정에서 재생 요청 → 홈 탭으로 전환하고 한 프레임 뒤 투어를 다시 시작.
  void _onReplayRequested() {
    if (!mounted) {
      return;
    }
    setState(() => _index = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startHomeTour();
      }
    });
  }

  /// 첫 실행에서 가르치는 것은 **딱 하나** — 오늘의 미션이 어디서 시작되는지.
  ///
  /// 2026-08-06 이전에는 4개 탭 + 학습경로를 5단계로 강제 통과시켰다. 그런데
  /// Start·Üben·Gruppe·Profil 은 아이콘+라벨만으로 이미 읽히고, `Üben` 을
  /// 설명하는 카드가 화면 반대편에 떠서 오히려 "지금 뭘 가리키는 거지?"가 됐다
  /// (Jin 태블릿 실기기). 교육보다 마찰이 컸다.
  ///
  /// 나머지는 **그 기능을 처음 쓸 때** 설명한다(progressive onboarding):
  /// 연습 허브·계 탭·프로필은 각자 [ScreenCoachMixin] 으로 첫 진입 시 뜬다.
  /// 학습경로는 `learningPath` 화면 코치가 이미 담당한다.
  void _startHomeTour() {
    final t = AppL10n.of(context);
    SpotlightCoach.show(
      context,
      steps: [
        SpotlightStep(
          targetKey: _missionTourKey,
          title: t.coachHomeMissionTitle,
          body: t.coachHomeMissionBody,
          icon: Icons.play_circle_outline,
          cutoutPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          cutoutRadius: 20,
          shape: ShapeKind.rrect,
        ),
      ],
      onComplete: () => Storage.setTutHomeTourSeen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    final width = MediaQuery.sizeOf(context).width;
    final usesRail = SoriAdaptiveNavigation.usesRailForWidth(width);
    final navigation = SoriAdaptiveNavigation(
      selectedIndex: _index,
      onDestinationSelected: _onDestinationSelected,
      items: [
        SoriAdaptiveNavigationItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: t.navHome,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.sports_esports_outlined,
          selectedIcon: Icons.sports_esports_rounded,
          label: t.navPractice,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.explore_outlined,
          selectedIcon: Icons.explore_rounded,
          label: t.navDiscover,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.groups_2_outlined,
          selectedIcon: Icons.groups_2_rounded,
          label: t.navGye,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person_rounded,
          label: t.navProfile,
        ),
      ],
    );

    // 크기 0 앵커를 NavigationBar 위에 Overlay처럼 절대위치로 올림.
    // IgnorePointer + SizedBox.shrink → 터치·레이아웃 모두 영향 없음.
    final anchors = IgnorePointer(
      child: Row(
        children: List.generate(5, (i) {
          return Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox.shrink(key: _tabKeys[i]),
            ),
          );
        }),
      ),
    );
    final railAnchors = IgnorePointer(
      child: Column(
        children: List.generate(5, (i) {
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox.shrink(key: _tabKeys[i]),
            ),
          );
        }),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          if (usesRail)
            SafeArea(
              child: SizedBox(
                width: SoriAdaptiveNavigation.railWidthForWidth(width),
                child: Stack(
                  children: [
                    navigation,
                    Positioned.fill(child: railAnchors),
                  ],
                ),
              ),
            ),
          Expanded(
            key: const ValueKey('app-shell-content'),
            child: IndexedStack(
              index: _index,
              // TickerMode: 숨은 탭의 애니메이션·영상(TigerStageVideo) 정지 — 배터리.
              children: [
                PrimaryScrollController(
                  controller: _tabScrollControllers[0],
                  child: TickerMode(
                    enabled: _index == 0,
                    child: HomeScreen(
                      pathTourKey: _pathTourKey,
                      missionTourKey: _missionTourKey,
                    ),
                  ),
                ),
                PrimaryScrollController(
                  controller: _tabScrollControllers[1],
                  child: TickerMode(
                    enabled: _index == 1,
                    child: const PracticeHubScreen(),
                  ),
                ),
                PrimaryScrollController(
                  controller: _tabScrollControllers[2],
                  child: TickerMode(
                    enabled: _index == 2,
                    child: const DiscoverScreen(),
                  ),
                ),
                PrimaryScrollController(
                  controller: _tabScrollControllers[3],
                  child: TickerMode(
                    enabled: _index == 3,
                    child: const GyeTabScreen(),
                  ),
                ),
                PrimaryScrollController(
                  controller: _tabScrollControllers[4],
                  child: TickerMode(
                    enabled: _index == 4,
                    child: const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: usesRail
          ? null
          : Stack(
              clipBehavior: Clip.none,
              children: [
                navigation,
                Positioned.fill(child: anchors),
              ],
            ),
    );
  }
}
