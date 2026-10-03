import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/personas/persona_dialogue_index.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/personas/persona_people_screen.dart';
import 'package:ko_lernen_app/features/personas/persona_profile_sheet.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/persona_presentation.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/persona_portrait.dart';
import 'package:ko_lernen_app/widgets/sori/persona_scene_intro.dart';

import 'support/real_fonts.dart';
import 'support/scenario_json.dart';

List<Scenario> corpus() => allScenarioJson().map(Scenario.fromJson).toList();
List<Scenario> drafts() =>
    (jsonDecode(
              File(
                'tools/content_factory/drafts/persona_a2_scenarios_20261003.json',
              ).readAsStringSync(),
            )['scenarios']
            as List)
        .map((j) => Scenario.fromJson(j))
        .toList();

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget app(
  Widget child, {
  double scale = 1,
  bool dark = false,
  Locale locale = const Locale('de'),
  RouteFactory? routes,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateRoute: routes,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: RepaintBoundary(
      key: const ValueKey('persona-visual-boundary'),
      child: child!,
    ),
  ),
  home: child,
);

void main() {
  setUpAll(() async {
    await loadSoriRealFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await ContentLearningCatalog.load(LearningContentKind.listening);
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a2',
      'kl_tut_scenarios': true,
    });
    await Storage.init();
  });

  for (final size in [
    const Size(375, 812),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('people and profile fit $size text $scale dark $dark', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            app(
              PersonaPeopleScreen(loadScenarios: () async => corpus()),
              scale: scale,
              dark: dark,
            ),
          );
          await frames(tester);
          expect(
            find.byKey(const ValueKey('persona-card-sujin')),
            findsOneWidget,
          );
          final capture = size.width == 390 && scale == 1;
          if (capture) {
            await capturePersona(tester, 'people-${dark ? 'dark' : 'light'}');
          }
          await tester.tap(find.byKey(const ValueKey('persona-card-sujin')));
          await frames(tester);
          expect(find.byType(PersonaProfileSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (capture) {
            await capturePersona(tester, 'profile-${dark ? 'dark' : 'light'}');
          }
          await tester.drag(
            find.byKey(const ValueKey('persona-profile-scroll')),
            const Offset(0, -550),
          );
          await frames(tester);
          expect(tester.takeException(), isNull);
          if (capture) {
            await capturePersona(tester, 'actions-${dark ? 'dark' : 'light'}');
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        });
      }
    }
  }

  testWidgets('actual partner intro fits narrow screens at 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SoriPersonaSceneIntro(scenario: drafts().last),
            ),
          ),
        ),
        scale: 2,
      ),
    );
    await frames(tester);
    expect(find.byType(SoriPersonaPortrait), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturePersona(tester, 'jun-intro-200');
  });

  testWidgets(
    'profile opened during loading receives the completed index without progress writes',
    (tester) async {
      final pending = Completer<List<Scenario>>();
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      await tester.pumpWidget(
        app(PersonaPeopleScreen(loadScenarios: () => pending.future)),
      );
      await frames(tester);
      await tester.tap(find.byKey(const ValueKey('persona-card-sujin')));
      await frames(tester);
      pending.complete(corpus());
      await frames(tester);
      expect(find.byKey(const ValueKey('persona-talk')), findsOneWidget);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(tester.takeException(), isNull);
    },
  );

  for (final listening in [false, true]) {
    testWidgets(
      'profile sends the existing ${listening ? 'listening' : 'roleplay'} route argument',
      (tester) async {
        final scenes = corpus();
        final index = PersonaDialogueIndex.fromCorpus(
          scenes,
          listeningSourceIds: scenes.map((s) => s.id),
        );
        RouteSettings? launched;
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showPersonaProfile(
                    context: context,
                    person: PersonaPresentationCatalog.presentationFor(
                      'sujin',
                    )!,
                    dialogues: Future.value(index),
                    reload: () async => index,
                    preferredLevel: LearnerLevel.a2,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            routes: (settings) {
              launched = settings;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('Launched')),
              );
            },
          ),
        );
        await tester.tap(find.text('Open'));
        await frames(tester);
        final key = ValueKey(listening ? 'persona-listen' : 'persona-talk');
        await tester.ensureVisible(find.byKey(key));
        await frames(tester);
        await tester.tap(find.byKey(key));
        await frames(tester);
        expect(launched?.name, listening ? '/listening/play' : '/scenario');
        final id = listening
            ? (launched!.arguments as Scenario).id
            : launched!.arguments as String;
        expect(index.conversationsFor('sujin').any((s) => s.id == id), isTrue);
        expect(find.byType(PersonaProfileSheet), findsNothing);
      },
    );
  }

  testWidgets(
    'no listening lesson disables listening; generic roles have no portrait',
    (tester) async {
      final index = PersonaDialogueIndex.fromCorpus(corpus());
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PersonaProfileSheet(
              person: PersonaPresentationCatalog.people.first,
              dialogues: Future.value(index),
              reload: () async => index,
            ),
          ),
        ),
      );
      await frames(tester);
      expect(
        tester
            .widget<SoriButton>(find.byKey(const ValueKey('persona-listen')))
            .onTap,
        isNull,
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SoriPersonaSceneIntro(
              scenario: Scenario.fromJson({
                'id': 'generic',
                'dialog': [
                  {'speaker': 'professor', 'ko': '안녕하세요.'},
                ],
              }),
            ),
          ),
        ),
      );
      expect(find.byType(SoriPersonaPortrait), findsNothing);
    },
  );

  test(
    'runtime corpus gives all eleven actual playable partners and listening IDs',
    () {
      final scenes = corpus();
      final payload = jsonDecode(
        File('assets/data/listening_lessons.json').readAsStringSync(),
      );
      final listeningIds = [
        for (final lesson in payload['lessons'])
          ...(lesson['contentIds'] as List).cast<String>(),
      ];
      final sceneIds = scenes.map((scene) => scene.id).toSet();
      expect(listeningIds.toSet(), sceneIds);
      expect(listeningIds.length, sceneIds.length);
      final index = PersonaDialogueIndex.fromCorpus(
        scenes,
        listeningSourceIds: listeningIds,
      );
      for (final person in PersonaPresentationCatalog.people) {
        expect(
          index.conversationsFor(person.characterId),
          isNotEmpty,
          reason: person.characterId,
        );
      }
      for (final scene in drafts()) {
        expect(index.hasListeningLesson(scene), isTrue);
        expect(
          scene.speakerDisplayName(
            'user',
            fallbackYou: 'Du',
            fallbackNarrator: 'Erzähler',
          ),
          scene.playerRoleDisplayName(fallbackYou: 'Du'),
        );
      }
    },
  );
}

Future<void> capturePersona(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('PERSONA_CAPTURE_DIR');
  if (directory.isEmpty) return;
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('persona-visual-boundary')),
  );
  await tester.runAsync(() async {
    final pixels = await boundary.toImage();
    final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    pixels.dispose();
  });
}
