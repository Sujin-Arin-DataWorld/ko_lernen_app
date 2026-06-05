import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'home_screen.dart';
import 'learn_hub_screen.dart';
import 'practice_hub_screen.dart';
import 'wordbook_hub_screen.dart';

/// **AppShell** — BottomNav 4탭 셸.
///
/// 탭 구성:
///   0. 홈     (HomeScreen)
///   1. 배우기  (LearnHubScreen)
///   2. 연습    (PracticeHubScreen)
///   3. 단어장  (WordbookHubScreen)
///
/// IndexedStack으로 탭 상태를 보존한다. 탭 내 `pushNamed`는 루트 Navigator를 통해
/// 상세화면이 탭바 위 전체화면으로 열린다(듀오링고식 레슨 진입).
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
          LearnHubScreen(),
          PracticeHubScreen(),
          WordbookHubScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (_index == i) return; // 재탭 시 pop-to-root(후속 세션)
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: t.navLearn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: const Icon(Icons.sports_esports_rounded),
            label: t.navPractice,
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: const Icon(Icons.style_rounded),
            label: t.navWordbook,
          ),
        ],
      ),
    );
  }
}
