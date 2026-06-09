import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/spotlight_coach.dart';
import 'home_screen.dart';
import 'practice_hub_screen.dart';
import 'gye_tab_screen.dart';
import 'profile_screen.dart';

/// **AppShell** — BottomNav 4탭 셸 (R1 IA, 2026-06-06).
///
/// 탭 구성 (듀오링고 패턴 — deep-research 검증):
///   0. 홈   (HomeScreen — 학습 경로 진입)
///   1. 연습 (PracticeHubScreen — 배우기·게임·단어 named 섹션)
///   2. 계   (GyeTabScreen — 비경쟁 협력 그룹)
///   3. 나   (ProfileScreen — 통계·설정)
///
/// IndexedStack으로 탭 상태를 보존(스와이프 X — 게임/시나리오 제스처 충돌 회피).
/// 탭 내 `pushNamed`는 루트 Navigator → 상세화면이 탭바 위 전체화면(듀오링고식 진입).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Stage A: 홈 투어 스포트라이트 키.
  // NavigationBar를 Stack으로 감싸고 각 탭 위치에 크기 0 앵커를 올린다.
  // 이 방식은 NavigationBar 레이아웃에 전혀 영향을 주지 않는다.
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());
  final GlobalKey _pathTourKey = GlobalKey();
  // Stage B 예약: final GlobalKey _bookTourKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!Storage.tutHomeTourSeen) {
        _startHomeTour();
      }
    });
  }

  void _startHomeTour() {
    final t = AppL10n.of(context);
    SpotlightCoach.show(
      context,
      steps: [
        SpotlightStep(
          targetKey: _tabKeys[0],
          title: t.coachHomeTab0Title,
          body: t.coachHomeTab0Body,
          icon: Icons.home_outlined,
          cutoutPadding: const EdgeInsets.all(10),
          cutoutRadius: 24,
          shape: ShapeKind.circle,
        ),
        SpotlightStep(
          targetKey: _tabKeys[1],
          title: t.coachHomeTab1Title,
          body: t.coachHomeTab1Body,
          icon: Icons.sports_esports_outlined,
          cutoutPadding: const EdgeInsets.all(10),
          cutoutRadius: 24,
          shape: ShapeKind.circle,
        ),
        SpotlightStep(
          targetKey: _tabKeys[2],
          title: t.coachHomeTab2Title,
          body: t.coachHomeTab2Body,
          icon: Icons.groups_2_outlined,
          cutoutPadding: const EdgeInsets.all(10),
          cutoutRadius: 24,
          shape: ShapeKind.circle,
        ),
        SpotlightStep(
          targetKey: _tabKeys[3],
          title: t.coachHomeTab3Title,
          body: t.coachHomeTab3Body,
          icon: Icons.person_outline,
          cutoutPadding: const EdgeInsets.all(10),
          cutoutRadius: 24,
          shape: ShapeKind.circle,
        ),
        SpotlightStep(
          targetKey: _pathTourKey,
          title: t.coachHomePathTitle,
          body: t.coachHomePathBody,
          icon: Icons.route_outlined,
          cutoutPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          cutoutRadius: 16,
          shape: ShapeKind.rrect,
        ),
      ],
      onComplete: () => Storage.setTutHomeTourSeen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    final navBar = NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) {
        if (_index == i) {
          return;
        }
        setState(() => _index = i);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: t.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.sports_esports_outlined),
          selectedIcon: const Icon(Icons.sports_esports_rounded),
          label: t.navPractice,
        ),
        NavigationDestination(
          icon: const Icon(Icons.groups_2_outlined),
          selectedIcon: const Icon(Icons.groups_2_rounded),
          label: t.navGye,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person_rounded),
          label: t.navProfile,
        ),
      ],
    );

    // 크기 0 앵커를 NavigationBar 위에 Overlay처럼 절대위치로 올림.
    // IgnorePointer + SizedBox.shrink → 터치·레이아웃 모두 영향 없음.
    final anchors = IgnorePointer(
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox.shrink(key: _tabKeys[i]),
            ),
          );
        }),
      ),
    );

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(pathTourKey: _pathTourKey),
          const PracticeHubScreen(),
          const GyeTabScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          navBar,
          Positioned.fill(child: anchors),
        ],
      ),
    );
  }
}
