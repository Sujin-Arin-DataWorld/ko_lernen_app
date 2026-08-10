import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/personal_room_scene.dart';
import 'package:ko_lernen_app/widgets/sori/room_layer.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('locked anbang never exposes a placement write surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.anbang,
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .24),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RoomLayer), findsNothing);
    expect(find.text('This room is still being built'), findsOneWidget);
  });

  testWidgets('keeps the unlocked room interactive through the shared scene', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PersonalRoomScene), findsOneWidget);
    expect(find.byType(RoomLayer), findsOneWidget);
  });

  testWidgets('unlocks a room from verified course structure alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
          loadProjection: (_) async => _courseSarangbangProjection(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PersonalRoomScene), findsOneWidget);
    expect(find.byType(RoomLayer), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);

const _text = CurriculumText(ko: '?λ㈃', de: 'Szene', en: 'Scene');

PersonalHanokProjection _courseSarangbangProjection() =>
    PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      competence: HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_01', 'a2_01', 'b1_01'],
        ),
        courseUnits: const [
          CourseUnit(
            id: 'a1_01',
            level: 'a1',
            order: 1,
            title: _text,
            canDo: _text,
          ),
          CourseUnit(
            id: 'a2_01',
            level: 'a2',
            order: 1,
            title: _text,
            canDo: _text,
          ),
          CourseUnit(
            id: 'b1_01',
            level: 'b1',
            order: 1,
            title: _text,
            canDo: _text,
          ),
        ],
      ),
    );

Future<PersonalHanokProjection> _legacyProjection(LevelRatios ratios) async =>
    PersonalHanokProjection.from(ratios);
