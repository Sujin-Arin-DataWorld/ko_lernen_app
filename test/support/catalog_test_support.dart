import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';

SoriStageProgressionSnapshot catalogSnapshot({
  Map<String, SoriActivityProgress> progress = const {},
  Map<String, int> bests = const {},
}) => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(pick: null),
  hanokCompetence: const HanokCompetenceProjection.empty(),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
  activityProgress: progress,
  gameBests: bests,
);

/// Actual bundled curriculum/link resolution; account state is explicitly
/// seeded as a first unit with no completions, not claimed as a live account.
Future<LearningFocus> loadFirstCatalogFocus() async {
  final catalog = await CurriculumCatalog.load();
  final unit = catalog.courseUnits.first;
  return LearningFocus.load(
    loadToday: () async => TodayLearningSnapshot(
      pick: CoursePick(
        unit: unit,
        missionNumber: 1,
        totalMissions: catalog.courseUnits.length,
        fraction: 0,
        started: false,
      ),
    ),
    loadBrief: (_) async => CourseMissionBrief.from(
      unit: unit,
      links: catalog.linksForCourseUnit(unit.id),
      scenarios: const [],
      isCurrent: true,
    ),
  );
}

Widget catalogTestApp({
  SoriStageTab tab = SoriStageTab.learn,
  String locale = 'en',
  double scale = 1,
  ThemeData? theme,
  LearningFocusController? controller,
  FutureOr<void> Function(TodayLearningDestination destination, String? id)?
  onOpen,
  Future<SoriStageProgressionSnapshot> Function()? loadSnapshot,
  ScrollController? scrollController,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? AppTheme.light,
  locale: Locale(locale),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Builder(
    builder: (context) {
      final t = AppL10n.of(context);
      Widget catalog = SoriStageCatalogScreen(
        tab: tab,
        loadSnapshot: loadSnapshot ?? () async => catalogSnapshot(),
      );
      if (scrollController != null) {
        catalog = PrimaryScrollController(
          controller: scrollController,
          child: catalog,
        );
      }
      if (controller != null) {
        catalog = LearningFocusScope(
          controller: controller,
          open: (_, destination, {focus, activityId}) async =>
              onOpen?.call(destination, activityId),
          child: catalog,
        );
      }
      final nav = SoriAdaptiveNavigation(
        selectedIndex: tab.index,
        onDestinationSelected: (_) {},
        items: [
          SoriAdaptiveNavigationItem(
            label: t.soriStageNavToday,
            icon: Icons.today_outlined,
            selectedIcon: Icons.today_rounded,
          ),
          SoriAdaptiveNavigationItem(
            label: t.soriStageNavLearn,
            icon: Icons.school_outlined,
            selectedIcon: Icons.school_rounded,
          ),
          SoriAdaptiveNavigationItem(
            label: t.soriStageNavGames,
            icon: Icons.sports_esports_outlined,
            selectedIcon: Icons.sports_esports_rounded,
          ),
          SoriAdaptiveNavigationItem(
            label: t.soriStageNavHanok,
            icon: Icons.home_work_outlined,
            selectedIcon: Icons.home_work_rounded,
          ),
          SoriAdaptiveNavigationItem(
            label: t.soriStageNavGye,
            icon: Icons.groups_2_outlined,
            selectedIcon: Icons.groups_2_rounded,
          ),
        ],
      );
      final width = MediaQuery.sizeOf(context).width;
      final rail = SoriAdaptiveNavigation.usesRailForWidth(width);
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: Row(
            children: [
              if (rail)
                SizedBox(
                  width: SoriAdaptiveNavigation.railWidthForWidth(width),
                  child: nav,
                ),
              Expanded(child: catalog),
            ],
          ),
          bottomNavigationBar: rail ? null : nav,
        ),
      );
    },
  ),
);
