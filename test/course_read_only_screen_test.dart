import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('04C completed course is byte-stable and never restarts', (
    tester,
  ) async {
    final catalog = await _loadCatalog(tester);
    final snapshot = CourseMasterySnapshot(
      placementLevel: 'a1',
      completedUnitIds: catalog.courseUnits.map((unit) => unit.id).toList(),
    );
    await _seed({
      Storage.courseMasterySnapshotPreferenceKey: jsonEncode(snapshot.toJson()),
      Storage.placementLevelPreferenceKey: 'a1',
      Storage.browseLevelPreferenceKey: 'b1',
      'kl_user_level': 'b2',
    });
    final before = await _coursePreferences();

    await tester.pumpWidget(_host(const LearningPathScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(await _coursePreferences(), before);
    expect(Storage.courseUnitId, isNull);
  });

  testWidgets('04C fresh browse creates no course keys', (tester) async {
    await _loadCatalog(tester);
    await _seed({
      Storage.browseLevelPreferenceKey: 'a2',
      'kl_user_level': 'b1',
    });

    await tester.pumpWidget(_host(const LearningPathScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final after = await _coursePreferences();
    expect(after, {
      Storage.browseLevelPreferenceKey: 'a2',
      'kl_user_level': 'b1',
    });
    expect(Storage.courseMasterySnapshotRawJson, isEmpty);
    expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
    expect(Storage.courseUnitId, isNull);
  });

  testWidgets('historical mission view keeps completed canonical bytes', (
    tester,
  ) async {
    final catalog = await _loadCatalog(tester);
    final firstUnit = catalog.courseUnits.first;
    final snapshot = CourseMasterySnapshot(
      placementLevel: 'a1',
      completedUnitIds: catalog.courseUnits.map((unit) => unit.id).toList(),
    );
    await _seed({
      Storage.courseMasterySnapshotPreferenceKey: jsonEncode(snapshot.toJson()),
      Storage.placementLevelPreferenceKey: 'a1',
      Storage.browseLevelPreferenceKey: 'b1',
      'kl_user_level': 'b2',
    });
    final before = await _coursePreferences();

    await tester.pumpWidget(
      _host(CourseMissionScreen(courseUnitId: firstUnit.id)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(await _coursePreferences(), before);
    expect(Storage.courseUnitId, isNull);
  });

  test('Today loader with legacy level only creates no course keys', () async {
    await _seed({
      Storage.browseLevelPreferenceKey: 'a2',
      'kl_user_level': 'b1',
    });
    final before = await _coursePreferences();

    final snapshot = await TodayLearningSnapshotLoader.load(
      readers: _courseOnlyReaders(),
    );

    expect(snapshot.pick, isNot(isA<CoursePick>()));
    expect(await _coursePreferences(), before);
    expect(Storage.courseMasterySnapshotRawJson, isEmpty);
    expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
    expect(Storage.courseUnitId, isNull);
  });

  test(
    'Today loader keeps completed canonical bytes and no current unit',
    () async {
      final catalog = await CurriculumCatalog.load();
      final canonical = jsonEncode(
        CourseMasterySnapshot(
          placementLevel: 'a1',
          completedUnitIds: catalog.courseUnits.map((unit) => unit.id).toList(),
        ).toJson(),
      );
      await _seed({
        Storage.courseMasterySnapshotPreferenceKey: canonical,
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.browseLevelPreferenceKey: 'b1',
        'kl_user_level': 'b2',
      });
      final before = await _coursePreferences();

      final snapshot = await TodayLearningSnapshotLoader.load(
        readers: _courseOnlyReaders(),
      );

      expect(snapshot.pick, isNot(isA<CoursePick>()));
      expect(await _coursePreferences(), before);
      expect(Storage.courseUnitId, isNull);
    },
  );
}

Future<void> _seed(Map<String, Object> values) async {
  Storage.resetForTesting();
  Storage.resetCourseMasteryForTesting();
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
}

Future<CurriculumCatalog> _loadCatalog(WidgetTester tester) async {
  // rootBundle asset reads use the real event loop. Keep them outside the
  // widget test's fake clock so setup cannot stall before the first pump.
  return (await tester.runAsync(CurriculumCatalog.load))!;
}

TodayLearningSourceReaders _courseOnlyReaders() => TodayLearningSourceReaders(
  course: () async {
    final catalog = await CurriculumCatalog.load();
    // Use an isolated service instance here. Widget loads above can still be
    // finishing after disposal; sharing the production serialization queue
    // would make these read-only assertions depend on that unrelated work.
    final snapshot = CourseMasteryService(catalog).readForDisplay();
    return snapshot == null
        ? (units: const <CourseUnit>[], snapshot: null)
        : (units: catalog.courseUnits, snapshot: snapshot);
  },
  nowNode: () async => null,
  scenario: () async =>
      (current: null, completed: const <String>{}, userLevel: LearnerLevel.a1),
  review: () async => (dueCount: 0, hardCount: 0),
);

Future<Map<String, Object?>> _coursePreferences() async {
  final prefs = await SharedPreferences.getInstance();
  const keys = <String>{
    Storage.courseMasterySnapshotPreferenceKey,
    Storage.legacyCourseMasteryPreferenceKey,
    Storage.placementLevelPreferenceKey,
    Storage.browseLevelPreferenceKey,
    Storage.courseUnitPreferenceKey,
    'kl_user_level',
  };
  return {
    for (final key in keys)
      if (prefs.containsKey(key)) key: prefs.get(key),
  };
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
