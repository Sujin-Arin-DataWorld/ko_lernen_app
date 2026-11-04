import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/features/content_learning/listening_object_art.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_writing_check_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scene_asset_resolver.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/learning_stage_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_c.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_write_after_roleplay_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _capture = ValueKey('alltag-native-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Scenario source;
  late Grammar promise;
  late List<Scenario> corpus;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    final font = File('assets/fonts/Lora/Lora-Variable.ttf').readAsBytesSync();
    await (FontLoader(
      'Lora',
    )..addFont(Future.value(ByteData.sublistView(font)))).load();
    final raw =
        (jsonDecode(File('assets/data/scenarios_a2.json').readAsStringSync())
                as Map<String, dynamic>)['scenarios']
            as List;
    corpus = raw
        .map((row) => Scenario.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    source = corpus.singleWhere((s) => s.id == ScenarioC.kitchenScene);
    promise = (await DataLoader.loadGrammar()).singleWhere(
      (g) => g.id == 'grammar_a2_promise',
    );
    await SceneAssetResolver.load();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
      'kl_tut_scenarios': true,
    });
    await Storage.init();
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
  });
  tearDown(SoundService.resetForTesting);

  for (final exit in [
    'active-home',
    'active-back',
    'active-tab',
    'loading-home',
    'loading-close',
  ]) {
    testWidgets('$exit preserves a routing onExit and stops speech once', (
      tester,
    ) async {
      final observer = _NamedRouteObserver();
      final speech = stubSoriSpeech();
      var exits = 0;
      final loading = exit.startsWith('loading');
      await _pump(
        tester,
        Builder(
          builder: (context) {
            void leave() {
              exits++;
              Navigator.of(context).pushReplacementNamed('/embedded');
            }

            return loading
                ? ScenarioPlayerScreen(
                    scenarioId: source.id,
                    scenarioLoader: (_) => Completer<Scenario?>().future,
                    onExit: leave,
                  )
                : ScenarioPlayerScreen.preview(
                    onExit: leave,
                    fixture: ScenarioPlayerPreviewFixture.action(
                      scenario: source,
                      stage: ScenarioStage.dialog,
                    ),
                  );
          },
        ),
        observer: observer,
        routes: {
          '/embedded': (_) =>
              const Scaffold(body: Text('embedded destination')),
        },
      );
      final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));
      if (exit.endsWith('home')) {
        await tester.tap(find.byType(SoriHomeAction));
      } else if (exit.endsWith('tab')) {
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .onDestinationSelected!(0);
      } else if (loading) {
        await tester.tap(find.byType(SoriCloseAction));
      } else {
        await tester.tap(find.bySemanticsLabel(t.closeActionLabel));
      }
      if (!loading) {
        await tester.pumpAndSettle();
        expect(exits, 0);
      }
      final stopsBeforeLeave = speech.stops;
      if (!loading) {
        await tester.tap(
          find.widgetWithText(SoriButton, t.homeActionConfirmLeave),
        );
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(exits, 1);
      expect(find.text('embedded destination'), findsOneWidget);
      expect(observer.names, ['/', '/embedded']);
      // Loading exits are synchronous; their deferred stop still runs on the
      // first frame after the tap. Active exits stop only after confirmation.
      expect(speech.stops, stopsBeforeLeave + 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (var destination = 0; destination < 5; destination++) {
    testWidgets(
      'destination $destination confirms then preserves embedded exit exactly once',
      (tester) async {
        var exits = 0;
        final speech = stubSoriSpeech();
        await _pump(
          tester,
          ScenarioPlayerScreen.preview(
            onExit: () => exits++,
            fixture: ScenarioPlayerPreviewFixture.action(
              scenario: source,
              stage: ScenarioStage.dialog,
            ),
          ),
        );
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        bar.onDestinationSelected!(destination);
        await tester.pumpAndSettle();
        expect(exits, 0);
        final stopsBeforeConfirmation = speech.stops;
        final context = tester.element(find.byType(ScenarioPlayerScreen));
        final t = AppL10n.of(context);
        await tester.tap(
          find.widgetWithText(SoriButton, t.homeActionConfirmLeave),
        );
        await tester.pumpAndSettle();
        expect(exits, 1);
        expect(speech.stops, stopsBeforeConfirmation + 1);
        expect(
          find.byType(ScenarioPlayerScreen),
          findsOneWidget,
          reason:
              'Embedded exit owns routing; default shell navigation must not follow.',
        );
        bar.onDestinationSelected!(destination);
        await tester.pump();
        expect(exits, 1);
        expect(speech.stops, stopsBeforeConfirmation + 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all real roleplay turns lead to optional unscored writing with native input',
    (tester) async {
      await _pump(
        tester,
        ScenarioPlayerScreen.preview(
          fixture: ScenarioPlayerPreviewFixture.action(
            scenario: source,
            stage: ScenarioStage.rollenspiel,
          ),
        ),
      );
      var capturedAssembly = false;
      var turnIndex = 0;
      for (final line in source.dialog.where(
        (line) => line.speaker == 'user',
      )) {
        if (turnIndex == 2) await _save(tester, 'roleplay-third-turn');
        final tokens = [
          ...SatzBauenQuest.tokenize(line.ko),
          if (SatzBauenQuest.terminalPunctuation(line.ko)
              case final punctuation?)
            punctuation,
        ];
        for (final token in tokens) {
          final tile = find
              .byWidgetPredicate(
                (w) =>
                    w is SoriWordTile &&
                    w.state == SoriWordTileState.idle &&
                    w.label == token,
              )
              .first;
          await Scrollable.ensureVisible(tile.evaluate().single, alignment: .5);
          await tester.pump();
          await tester.tap(tile);
          await tester.pump();
        }
        if (!capturedAssembly) {
          final tray = find.byType(ScenarioCAnswerTray);
          await Scrollable.ensureVisible(tray.evaluate().single, alignment: 1);
          await tester.pump();
          _expectAnswerMaterialTextOnPlane(tester);
          await _save(tester, 'roleplay-assembled-answer');
          capturedAssembly = true;
        }
        await tester.tap(find.byKey(const ValueKey('quest-submit')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('quest-continue')));
        await tester.pump(const Duration(milliseconds: 300));
        turnIndex++;
      }
      expect(find.byType(ScenarioWriteAfterRoleplayCard), findsOneWidget);
      final prompt = source.dialog
          .lastWhere((line) => line.speaker == 'user')
          .ko;
      expect(find.text(prompt), findsOneWidget);
      await _save(tester, 'writing');
      final input = find.byKey(const ValueKey('scenario-write-input'));
      await Scrollable.ensureVisible(input.evaluate().single, alignment: .5);
      await tester.enterText(input, '응. 열두 시에 시작하자.');
      await tester.pump();
      expect(
        tester
            .widget<ScenarioCGoldButton>(
              find.byKey(const ValueKey('scenario-write-check')),
            )
            .onTap,
        isNotNull,
      );
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'writing source cue stays inside the flat paper at scale $scale',
      (tester) async {
        final line = source.dialog.lastWhere((line) => line.speaker == 'user');
        await _pump(
          tester,
          ScenarioCFrame(
            title: 'Alltagsszenen · A2',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ScenarioWriteAfterRoleplayCard(
                promptKo: line.ko,
                promptSpeaker: 'Andrea',
                promptTranslation: line.de,
                evidence: ScenarioWritingEvidence.fromScenario(
                  scenario: source,
                  language: 'de',
                ),
              ),
            ),
          ),
          size: scale == 1 ? const Size(402, 874) : const Size(320, 640),
          scale: scale,
        );
        final paper = tester.getRect(
          find.byKey(const ValueKey('scenario-write-prompt')),
        );
        final translated = tester.getRect(find.text(line.de));
        expect(paper.bottom - 16 - translated.bottom, greaterThanOrEqualTo(12));
        _expectFoldTextOnPaper(tester);
        final board = tester.getRect(find.byType(ScenarioCWritingBoard));
        final editable = tester.getRect(find.byType(EditableText));
        expect(editable.left, greaterThanOrEqualTo(board.left + 24));
        expect(editable.right, lessThanOrEqualTo(board.right - 24));
        expect(editable.top, greaterThanOrEqualTo(board.top + 24));
        expect(editable.bottom, lessThanOrEqualTo(board.bottom - 24));
        expect(tester.takeException(), isNull);
        await _save(tester, 'writing-paper-${scale == 1 ? 402 : 320}-$scale');
      },
    );
    for (final stage in [
      ScenarioStage.intro,
      ScenarioStage.vocab,
      ScenarioStage.dialog,
      ScenarioStage.grammar,
      ScenarioStage.rollenspiel,
    ]) {
      testWidgets(
        'source ${stage.name} ${scale == 1 ? 402 : 320} scale $scale keeps navigation and native content',
        (tester) async {
          await _pump(
            tester,
            ScenarioPlayerScreen.preview(
              fixture: ScenarioPlayerPreviewFixture.action(
                scenario: source,
                stage: stage,
                resolvedGrammar: [promise],
              ),
            ),
            size: scale == 1 ? const Size(402, 874) : const Size(320, 640),
            scale: scale,
          );
          expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
          final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(
            nav.labelBehavior,
            NavigationDestinationLabelBehavior.alwaysHide,
          );
          expect(nav.destinations.length, 5);
          expect(
            tester
                .widgetList<ApprovedChromeImage>(
                  find.byType(ApprovedChromeImage),
                )
                .map((i) => i.asset),
            contains(ApprovedChromeAssets.cloud),
          );
          if (stage == ScenarioStage.intro) {
            expect(find.text(source.title.ko), findsOneWidget);
            expect(find.text('Andrea'), findsOneWidget);
          }
          if (stage == ScenarioStage.vocab) {
            for (final word in source.vocab) {
              expect(find.text(word.korean), findsOneWidget);
            }
          }
          if (stage == ScenarioStage.dialog) {
            for (final line in source.dialog) {
              expect(find.text(line.ko), findsOneWidget);
            }
          }
          if (stage == ScenarioStage.grammar) {
            expect(find.text(promise.pattern), findsOneWidget);
            expect(find.text(promise.exampleKorean), findsOneWidget);
          }
          if (stage == ScenarioStage.rollenspiel) {
            expect(find.byType(ScenarioCWordTile), findsWidgets);
            expect(find.byType(ScenarioCAnswerTray), findsOneWidget);
            expect(
              tester
                  .widgetList<ScenarioCSpeakerBadge>(
                    find.byType(ScenarioCSpeakerBadge),
                  )
                  .map((badge) => badge.name),
              containsAll(['Minho', 'Andrea']),
            );
            _expectAnswerMaterialTextOnPlane(tester);
            if (scale == 1) {
              final speed = find.byType(ScenarioCSpeedControl);
              expect(tester.getSize(speed).height, greaterThanOrEqualTo(48));
              final replay = find.byType(ScenarioCAudioDisc);
              expect(tester.getSize(replay), const Size(48, 48));
              final speech = stubSoriSpeech();
              await tester.tap(replay);
              await tester.pump();
              expect(speech.spoken, [
                source.dialog.firstWhere((line) => line.speaker == 'user').ko,
              ]);
              expect(
                tester.getRect(find.text(source.dialog.first.ko)).height,
                lessThan(40),
                reason:
                    'A fitting full-width Korean line must not split a word for the speaker plaque.',
              );
              final contextPaper = find.ancestor(
                of: find.text(source.dialog.first.ko),
                matching: find.byType(ScenarioCFold),
              );
              final learnerPaper = find.byKey(
                const ValueKey('quest-prompt-card'),
              );
              expect(
                tester.getRect(contextPaper).bottom + 4,
                lessThanOrEqualTo(tester.getRect(learnerPaper).top),
                reason:
                    'The complete source paper must clear the learner prompt.',
              );
            }
          }
          final actions = find.byType(ScenarioCGoldButton);
          if (actions.evaluate().isNotEmpty &&
              find
                  .byKey(const ValueKey('scenario-roleplay-scroll'))
                  .evaluate()
                  .isEmpty) {
            final action = actions.last;
            final navRect = tester.getRect(
              find.byType(SoriLearningStageNavigation),
            );
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            expect(
              navRect.top - tester.getRect(action).bottom,
              greaterThanOrEqualTo(16),
            );
          }
          expect(tester.takeException(), isNull);
          _expectFoldTextOnPaper(tester);
          await _save(tester, '${stage.name}-${scale == 1 ? 402 : 320}-$scale');
        },
      );
    }
  }

  testWidgets(
    'short enlarged roleplay exposes complete tappable tiles and tray',
    (tester) async {
      await _pump(
        tester,
        ScenarioPlayerScreen.preview(
          fixture: ScenarioPlayerPreviewFixture.action(
            scenario: source,
            stage: ScenarioStage.rollenspiel,
          ),
        ),
        size: const Size(320, 640),
        scale: 1.6,
      );
      final scroll = find.byKey(const ValueKey('scenario-roleplay-scroll'));
      expect(scroll, findsOneWidget);
      final viewport = tester.getRect(scroll);
      expect(viewport.height, greaterThanOrEqualTo(240));

      Future<void> expose(Finder target) async {
        await Scrollable.ensureVisible(target.evaluate().single, alignment: .5);
        await tester.pump();
        final rect = tester.getRect(target);
        final visible = rect.intersect(viewport);
        expect(visible.height, closeTo(rect.height, .5));
        expect(visible.width, closeTo(rect.width, .5));
      }

      final learnerTurns = source.dialog
          .where((line) => line.speaker == 'user')
          .toList();
      final first = learnerTurns.first;
      final tokens = [
        ...SatzBauenQuest.tokenize(first.ko),
        if (SatzBauenQuest.terminalPunctuation(first.ko) case final mark?) mark,
      ];
      for (final token in tokens) {
        final tile = find
            .byWidgetPredicate(
              (widget) =>
                  widget is SoriWordTile &&
                  widget.state == SoriWordTileState.idle &&
                  widget.label == token,
            )
            .first;
        await expose(tile);
        final rect = tester.getRect(tile);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
        await tester.tap(tile);
        await tester.pump();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SoriWordTile &&
                widget.state == SoriWordTileState.selected &&
                widget.label == token,
          ),
          findsOneWidget,
        );
        if (token == tokens.first) {
          tester.view.physicalSize = const Size(320, 1100);
          await tester.pump();
          expect(scroll, findsNothing);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is SoriWordTile &&
                  widget.state == SoriWordTileState.selected &&
                  widget.label == token,
            ),
            findsOneWidget,
          );
          tester.view.physicalSize = const Size(320, 640);
          await tester.pump();
          expect(scroll, findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is SoriWordTile &&
                  widget.state == SoriWordTileState.selected &&
                  widget.label == token,
            ),
            findsOneWidget,
          );
        }
      }
      await expose(find.byType(ScenarioCAnswerTray));
      final submit = find.byKey(const ValueKey('quest-submit'));
      await expose(submit);
      await tester.drag(scroll, const Offset(0, -300));
      await tester.pumpAndSettle();
      final nav = tester.getRect(find.byType(SoriLearningStageNavigation));
      expect(nav.top - tester.getRect(submit).bottom, greaterThanOrEqualTo(16));
      await _save(tester, 'roleplay-large-answer-visible');
      await tester.tap(submit);
      await tester.pump();
      final next = find.byKey(const ValueKey('quest-continue'));
      await expose(next);
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(learnerTurns[1].de), findsOneWidget);
      final sceneScrollable = find
          .descendant(of: scroll, matching: find.byType(Scrollable))
          .first;
      expect(tester.state<ScrollableState>(sceneScrollable).position.pixels, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (var index = 0; index < 6; index++) {
    final questIndex = index;
    testWidgets(
      'source quest $questIndex retains its input contract and one action owner',
      (tester) async {
        final quest = source.quests[questIndex];
        await _pump(
          tester,
          ScenarioPlayerScreen.preview(
            fixture: ScenarioPlayerPreviewFixture.action(
              scenario: source,
              stage: ScenarioStage.quest,
              questIndex: questIndex,
            ),
          ),
        );
        expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
        expect(find.text('Weiter'), findsNothing);
        if (questIndex == 0) {
          final transcript = quest.data['audioKo'] as String;
          expect(find.text(transcript), findsNothing);
          expect(find.bySemanticsLabel(transcript), findsNothing);
          await _save(tester, 'quest-0-unanswered-hoerverstehen');
        }
        if ([
          QuestType.hoerverstehen,
          QuestType.uebersetzen,
          QuestType.luecken,
        ].contains(quest.type)) {
          expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
          final index = quest.data['correctIndex'] as int;
          final option = find.byKey(ValueKey('answer-$index'));
          await Scrollable.ensureVisible(
            option.evaluate().single,
            alignment: .5,
          );
          await tester.tap(option);
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
        } else {
          expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);
          final action = tester.widget<ScenarioCGoldButton>(
            find.byKey(const ValueKey('quest-submit')),
          );
          expect(action.onTap, isNull);
        }
        final actions = find.byWidgetPredicate(
          (widget) =>
              widget is ScenarioCGoldButton &&
              (widget.key == const ValueKey('quest-submit') ||
                  widget.key == const ValueKey('quest-continue')),
        );
        if (actions.evaluate().isNotEmpty) {
          expect(actions, findsOneWidget);
          final nav = tester.getRect(find.byType(SoriLearningStageNavigation));
          expect(
            nav.top - tester.getRect(actions).bottom,
            greaterThanOrEqualTo(16),
          );
        }
        expect(tester.takeException(), isNull);
        await _save(tester, 'quest-$questIndex-${quest.type.name}');
      },
    );
  }

  for (final keyboard in [false, true]) {
    testWidgets(
      'paper dictation remains reachable with ${keyboard ? 'keyboard' : 'large text'}',
      (tester) async {
        if (keyboard) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          addTearDown(tester.view.resetViewInsets);
        }
        await _pump(
          tester,
          ScenarioPlayerScreen.preview(
            fixture: ScenarioPlayerPreviewFixture.action(
              scenario: source,
              stage: ScenarioStage.quest,
              questIndex: 4,
            ),
          ),
          size: keyboard ? const Size(390, 844) : const Size(320, 640),
          scale: keyboard ? 1 : 1.6,
        );
        final field = find.byKey(const ValueKey('diktat-answer-field'));
        await tester.ensureVisible(field);
        await tester.pump();
        await tester.enterText(
          field,
          source.quests[4].data['targetKo'] as String,
        );
        await tester.pump();
        final action = find.byKey(const ValueKey('quest-submit'));
        final actionRect = tester.getRect(action);
        expect(actionRect.height, greaterThanOrEqualTo(48));
        expect(
          actionRect.bottom,
          lessThanOrEqualTo((keyboard ? 844 : 640) - (keyboard ? 280 : 0)),
        );
        await tester.tap(action);
        await tester.pump();
        expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real six-quest completion keeps pending save blocked and retries identical result once',
    (tester) async {
      var pending = Completer<ScenarioCanDoResult?>();
      var completions = 0;
      final calls = <(String, int, int)>[];
      CourseProgressService.shared.resetForTesting();
      await tester.runAsync(CurriculumCatalog.load);
      await _pump(
        tester,
        ScenarioPlayerScreen(
          scenarioId: source.id,
          scenarioLoader: (_) async => source,
          questCorpusLoader: (_) async => corpus,
          grammarLoader: () async => [promise],
          mode: ScenarioPlayerMode.onboardingFirstScene,
          resultPersister: (scenario, stars, xp) {
            calls.add((scenario.id, stars, xp));
            return pending.future;
          },
          onCompleted: (_) => completions++,
        ),
      );
      for (
        var questIndex = 0;
        questIndex < source.quests.length;
        questIndex++
      ) {
        final quest = source.quests[questIndex];
        Finder inQuest(Finder candidate) => find.descendant(
          of: find.byKey(ValueKey('quest-$questIndex')),
          matching: candidate,
        );
        if (questIndex == 0) {
          expect(find.text(quest.data['audioKo'] as String), findsNothing);
          await _save(tester, 'quest-0-unanswered-real-audio');
        }
        if (quest.type == QuestType.satzBauen) {
          final target = quest.data['targetKo'] as String;
          for (final token in [
            ...SatzBauenQuest.tokenize(target),
            if (SatzBauenQuest.terminalPunctuation(target)
                case final punctuation?)
              punctuation,
          ]) {
            final tile = inQuest(
              find.byWidgetPredicate(
                (w) =>
                    w is SoriWordTile &&
                    w.state == SoriWordTileState.idle &&
                    w.label == token,
              ),
            ).first;
            await Scrollable.ensureVisible(
              tile.evaluate().single,
              alignment: .5,
            );
            await tester.pump();
            await tester.tap(tile);
            await tester.pump();
          }
          await tester.tap(inQuest(find.byKey(const ValueKey('quest-submit'))));
        } else if (quest.type == QuestType.diktat) {
          final field = inQuest(find.byType(TextField));
          await tester.ensureVisible(field);
          await tester.enterText(field, quest.data['targetKo'] as String);
          await tester.pump();
          await tester.tap(inQuest(find.byKey(const ValueKey('quest-submit'))));
        } else {
          final answer = inQuest(
            find.byKey(ValueKey('answer-${quest.data['correctIndex']}')),
          );
          await tester.ensureVisible(answer);
          await tester.pump();
          await tester.tap(answer);
        }
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(inQuest(find.byKey(const ValueKey('quest-continue'))));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(calls, hasLength(1));
      expect(completions, 0);
      expect(
        tester
            .widget<SoriLearningStageNavigation>(
              find.byType(SoriLearningStageNavigation),
            )
            .enabled,
        isFalse,
      );
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(0);
      await tester.pump();
      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);
      expect(calls, hasLength(1));
      final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));
      expect(find.text(t.scenarioResultSavingTitle), findsOneWidget);
      expect(find.text(t.scenarioResultSaving), findsOneWidget);
      await _save(tester, 'saving-real-persistence');
      pending.completeError(StateError('injected persistence failure'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(completions, 0);
      expect(find.text(t.scenarioResultSaveErrorTitle), findsOneWidget);
      expect(find.text(t.courseCheckpointSaveError), findsOneWidget);
      expect(find.text(t.scenarioResultSaveRetry), findsOneWidget);
      await _save(tester, 'save-error-real-persistence');
      pending = Completer<ScenarioCanDoResult?>();
      await tester.tap(find.text(t.scenarioResultSaveRetry));
      await tester.pump();
      expect(calls, hasLength(2));
      expect(calls[1], calls[0]);
      pending.complete(
        const ScenarioCanDoResult(
          status: ScenarioCanDoStatus.practiceOnly,
          score: 1,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(completions, 1);
      expect(find.text(t.scenarioCanDoPracticeTitle), findsOneWidget);
      await _save(tester, 'saved-after-real-retry');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stored practice result uses actual evidence and canonical navigation',
    (tester) async {
      await _pump(
        tester,
        ScenarioPlayerScreen.preview(
          fixture: ScenarioPlayerPreviewFixture.result(
            scenario: source,
            result: const ScenarioCanDoResult(
              status: ScenarioCanDoStatus.practiceOnly,
              score: .5,
            ),
            onReturn: () {},
            onRepeat: () {},
          ),
        ),
      );
      expect(find.text('Übung gespeichert.'), findsOneWidget);
      expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
      await _save(tester, 'saved-practice');
    },
  );

  testWidgets(
    '320dp normal-text catalog keeps every level target at least 48dp',
    (tester) async {
      await _pump(
        tester,
        ScenariosListScreen(loadScenarios: () async => corpus),
        size: const Size(320, 640),
      );
      for (final level in LearnerLevel.values) {
        final size = tester.getSize(
          find.byKey(ValueKey('scenario-level-${level.code}')),
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'source catalog preserves all available level and topic navigation',
    (tester) async {
      await _pump(
        tester,
        ScenariosListScreen(loadScenarios: () async => corpus),
      );
      expect(find.byType(SoriLearningStageNavigation), findsOneWidget);
      expect(find.byKey(const ValueKey('scenario-level-a2')), findsOneWidget);
      final topicArt = tester.widgetList<ListeningObjectArt>(
        find.byType(ListeningObjectArt),
      );
      expect(topicArt, isNotEmpty);
      expect(
        topicArt.every((art) => listeningObjects.containsKey(art.topicId)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await _save(tester, 'catalog');
      final category = find.byKey(
        ValueKey('scenario-category-${source.shelf}'),
      );
      await tester.ensureVisible(category);
      await tester.pump();
      await tester.tap(category);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('scenario-category-back')),
        findsOneWidget,
      );
      await _save(tester, 'catalog-selected-topic');
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(402, 874),
  double scale = 1,
  NavigatorObserver? observer,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      navigatorObservers: [soriRouteObserver, if (observer != null) observer],
      routes: routes,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: screen,
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _NamedRouteObserver extends NavigatorObserver {
  final names = <String>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name case final name?) names.add(name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings.name case final name?) names.add(name);
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_ALLTAG_C')) return;
  await tester.pump(const Duration(milliseconds: 600));
  await settleCNativeCaptureAssets(tester);
  final measured = <Map<String, Object?>>[];
  List<double> box(Finder finder) {
    final rect = tester.getRect(finder);
    return [rect.left, rect.top, rect.width, rect.height];
  }

  List<double> visibleBox(Finder finder) {
    var rect = tester.getRect(finder);
    RenderObject? object = finder.evaluate().single.findRenderObject();
    while (object != null) {
      if (object is RenderAbstractViewport && object is RenderBox) {
        final viewport = object as RenderBox;
        rect = rect.intersect(
          viewport.localToGlobal(Offset.zero) & viewport.size,
        );
      }
      object = object.parent;
    }
    return [
      rect.left,
      rect.top,
      rect.isEmpty ? 0 : rect.width,
      rect.isEmpty ? 0 : rect.height,
    ];
  }

  Map<String, Object?> textGeometry(Element element) {
    final text = element.widget as Text;
    return {
      'text': text.data,
      'font_family': text.style?.fontFamily,
      'font_size': text.style?.fontSize,
      'line_height': text.style?.height,
      'rect': box(
        find.byElementPredicate((candidate) => identical(candidate, element)),
      ),
    };
  }

  for (final element in find.byType(ScenarioCFold).evaluate()) {
    final widget = element.widget as ScenarioCFold;
    final finder = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final rect = tester.getRect(finder);
    measured.add({
      'kind': 'fold',
      'key': widget.key.toString(),
      'rect': [rect.left, rect.top, rect.width, rect.height],
      'visible_rect': visibleBox(finder),
      'texts': [
        for (final text
            in find
                .descendant(of: finder, matching: find.byType(Text))
                .evaluate())
          textGeometry(text),
      ],
      'objects': [
        for (final art in tester.widgetList<ListeningObjectArt>(
          find.descendant(
            of: finder,
            matching: find.byType(ListeningObjectArt),
          ),
        ))
          {'topic': art.topicId, 'asset': listeningObjects[art.topicId]?.file},
      ],
    });
  }
  for (final entry in <(String, Finder)>[
    ('gold_cta', find.byType(ScenarioCGoldButton)),
    ('header', find.byType(ScenarioCHeader)),
    ('hero', find.byType(ScenarioCHero)),
    ('word_tile', find.byType(ScenarioCWordTile)),
    ('answer_tray', find.byType(ScenarioCAnswerTray)),
    ('speaker_badge', find.byType(ScenarioCSpeakerBadge)),
    ('speed_control', find.byType(ScenarioCSpeedControl)),
    ('audio_disc', find.byType(ScenarioCAudioDisc)),
    ('writing_board', find.byKey(const ValueKey('scenario-write-board'))),
    (
      'book_art',
      find.byWidgetPredicate(
        (widget) => widget is CAtlasArt && widget.path == ScenarioC.book,
      ),
    ),
  ]) {
    for (final element in entry.$2.evaluate()) {
      final finder = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
      measured.add({
        'kind': entry.$1,
        'key': element.widget.key.toString(),
        'rect': box(finder),
        'visible_rect': visibleBox(finder),
        'texts': [
          for (final text
              in find
                  .descendant(of: finder, matching: find.byType(Text))
                  .evaluate())
            textGeometry(text),
        ],
      });
    }
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    const directory = String.fromEnvironment(
      'ALLTAG_CAPTURE_DIR',
      defaultValue: 'build/alltag-c-captures',
    );
    final file = File('$directory/native-alltag-$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    await File(
      '$directory/native-alltag-$name.geometry.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(measured));
  });
}

void _expectFoldTextOnPaper(WidgetTester tester) {
  for (final element in find.byType(ScenarioCFold).evaluate()) {
    final fold = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final rect = tester.getRect(fold);
    final bottomEdge = rect.width < 40 || rect.height < 72 ? 8.0 : 16.0;
    for (final text
        in find.descendant(of: fold, matching: find.byType(Text)).evaluate()) {
      final textRect = tester.getRect(
        find.byElementPredicate((candidate) => identical(candidate, text)),
      );
      expect(
        textRect.bottom,
        lessThanOrEqualTo(rect.bottom - bottomEdge + .5),
        reason:
            '${(text.widget as Text).data} must stay above the folded lower edge.',
      );
    }
  }
}

void _expectAnswerMaterialTextOnPlane(WidgetTester tester) {
  for (final type in [ScenarioCWordTile, ScenarioCAnswerTray]) {
    for (final element in find.byType(type).evaluate()) {
      final material = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
      final plane = tester.getRect(material).deflate(12);
      for (final text
          in find
              .descendant(of: material, matching: find.byType(Text))
              .evaluate()) {
        final rect = tester.getRect(
          find.byElementPredicate((candidate) => identical(candidate, text)),
        );
        expect(rect.left, greaterThanOrEqualTo(plane.left - .5));
        expect(rect.right, lessThanOrEqualTo(plane.right + .5));
        expect(rect.top, greaterThanOrEqualTo(plane.top - .5));
        expect(rect.bottom, lessThanOrEqualTo(plane.bottom + .5));
      }
    }
  }
}
