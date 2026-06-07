import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PracticeHubScreen(),
          GyeTabScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
      ),
    );
  }
}
