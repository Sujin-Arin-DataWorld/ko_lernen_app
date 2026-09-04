import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart' show TtsSpeechPhase;
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/scenario_fixtures.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  test('load lifecycle starts tracking once and never after exit', () {
    final activeGate = ScenarioLoadLifecycleGate();
    var trackingStarts = 0;

    activeGate.startLessonTracking(() => trackingStarts += 1);
    activeGate.startLessonTracking(() => trackingStarts += 1);

    expect(trackingStarts, 1);
    expect(activeGate.requestExit(), isTrue);
    expect(activeGate.requestExit(), isFalse);
    activeGate.startLessonTracking(() => trackingStarts += 1);
    expect(trackingStarts, 1);

    final exitedGate = ScenarioLoadLifecycleGate();
    expect(exitedGate.requestExit(), isTrue);
    exitedGate.startLessonTracking(() => trackingStarts += 1);
    expect(trackingStarts, 1);
  });

  testWidgets('loading uses the standard Sori player state', (tester) async {
    final pending = Completer<Scenario?>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(null);
      }
    });

    await _pumpPlayer(
      tester,
      child: ScenarioPlayerScreen(
        scenarioId: scenarioAirportArrivalFixture.id,
        scenarioLoader: (_) => pending.future,
      ),
      size: const Size(390, 844),
      textScale: 1.3,
    );

    expect(find.byType(SoriStudyFrame), findsOneWidget);
    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.bySemanticsLabel('Schließen'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'load failure stays in the player and retries the same scenario',
    (tester) async {
      // _load()가 이제 항상 activeScenarioCheckpointContext(→
      // CourseProgressService.shared, CurriculumCatalog.load())를 거친다
      // (T8, 지시서 4.15) — 첫 시도는 실패하지만 재시도가 성공하면 그
      // 시점부터는 이 경로를 탄다. 그 서비스의 직렬화 큐는 testWidgets
      // 마다 새로 생기는 Zone 을 넘나들면 응답하지 않으므로 이 테스트
      // 자신의 Zone 안에서 새로 시작하고, CurriculumCatalog.load()는
      // ScenarioLoader.load()의 compute() 격리를 거치므로 runAsync로
      // 감싸 미리 예열한다(scenario_mission_context_test.dart와 동일
      // 패턴).
      CourseProgressService.shared.resetForTesting();
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });
      for (final locale in const [Locale('de'), Locale('en')]) {
        var attempts = 0;
        final isGerman = locale.languageCode == 'de';

        await _pumpPlayer(
          tester,
          child: ScenarioPlayerScreen(
            key: ValueKey('load-${locale.languageCode}'),
            scenarioId: scenarioAirportArrivalFixture.id,
            scenarioLoader: (_) async {
              attempts += 1;
              if (attempts == 1) {
                throw StateError('fixture load failure');
              }
              return scenarioAirportArrivalFixture;
            },
          ),
          size: const Size(320, 640),
          textScale: 2,
          locale: locale,
        );

        final errorTitle = isGerman
            ? 'Hm, da ist etwas schiefgelaufen'
            : 'Hmm, something went wrong';
        final retryLabel = isGerman ? 'Erneut versuchen' : 'Try again';
        final startLabel = isGerman ? "Los geht's!" : "Let's go";
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byType(AppError), findsOneWidget);
        expect(find.text(errorTitle), findsOneWidget);
        expect(find.text(retryLabel), findsOneWidget);
        expect(attempts, 1);

        await tester.tap(find.text(retryLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(attempts, 2);
        expect(find.byType(AppError), findsNothing);
        expect(
          find.text(
            scenarioAirportArrivalFixture.title.pick(locale.languageCode),
          ),
          findsWidgets,
        );
        expect(find.text(startLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'default route close blocks late initialization while still mounted',
    (tester) async {
      final pending = Completer<Scenario?>();

      await _pumpPlayer(
        tester,
        child: ScenarioPlayerScreen(
          scenarioId: scenarioAirportArrivalFixture.id,
          scenarioLoader: (_) => pending.future,
        ),
        size: const Size(320, 640),
        textScale: 2,
      );

      await tester.tap(find.bySemanticsLabel('Schließen'));
      await tester.pump();
      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);

      pending.complete(scenarioAirportArrivalFixture);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Einreise am Flughafen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vocabulary and dialogue audio controls are labeled buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpPreview(
      tester,
      stage: ScenarioStage.vocab,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    final vocabularyListen = find.byTooltip('Aussprache');
    expect(vocabularyListen, findsWidgets);
    expect(
      tester.getSize(vocabularyListen.first).height,
      greaterThanOrEqualTo(48),
    );

    await _pumpPreview(
      tester,
      stage: ScenarioStage.dialog,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    final dialogueListen = find.bySemanticsLabel(
      RegExp(r'^Aussprache: 여권 보여주세요\.'),
    );
    expect(dialogueListen, findsOneWidget);
    final semanticsData = tester
        .getSemantics(dialogueListen)
        .getSemanticsData();
    expect(semanticsData.flagsCollection.isButton, isTrue);
    expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets(
    'canonical player profile renders its name and supplies its voice',
    (tester) async {
      const spokenText = '네, 여기 있어요.';
      const scenario = Scenario(
        id: 'canonical-player-voice',
        level: LearnerLevel.a1,
        emoji: '🎭',
        register: Register.polite,
        title: LocalizedText(
          ko: '음성 계약',
          de: 'Stimmenvertrag',
          en: 'Voice contract',
        ),
        intro: LocalizedText(ko: '', de: '', en: ''),
        vocab: [],
        grammarIds: [],
        playerCharacterId: 'christian',
        participantIds: ['christian'],
        dialog: [
          DialogLine(
            speaker: 'user',
            ko: spokenText,
            de: 'Ja, hier bitte.',
            en: 'Yes, here you go.',
          ),
        ],
        quests: [],
      );
      final profileVoice = scenario.voiceForSpeaker('user');
      expect(
        profileVoice,
        'male',
        reason: 'Christian must override the legacy user=female fallback',
      );
      final speakCalls = <({String text, String voice})>[];
      SoriSpeech.resetForTesting();
      addTearDown(SoriSpeech.resetForTesting);
      SoriSpeech.speakImpl = (text, voice) async {
        speakCalls.add((text: text, voice: voice));
        return true;
      };

      await _pumpPlayer(
        tester,
        child: ScenarioPlayerScreen.preview(
          fixture: const ScenarioPlayerPreviewFixture.action(
            scenario: scenario,
            stage: ScenarioStage.dialog,
          ),
        ),
        size: const Size(390, 844),
        textScale: 1.3,
      );

      expect(find.text('크리스티안 (나)'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel(RegExp(r'^Aussprache: 네, 여기 있어요\.')),
      );
      await tester.pump();

      // 계약 변경(지시서 4.5, T2.1): 대사 스테이지 진입 자체가 첫 대사를
      // 1회 자동재생하므로, 이 단일 대사 시나리오에서는 자동재생과 탭이
      // 같은 (텍스트, 보이스) 쌍을 두 번 만든다.
      expect(speakCalls, [
        (text: spokenText, voice: profileVoice),
        (text: spokenText, voice: profileVoice),
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('스테이지 전환마다 대표 문장 1회 자동재생, 뒤로 전환 시 정지', (tester) async {
    final stub = stubSoriSpeech();

    await _pumpPlayer(
      tester,
      child: ScenarioPlayerScreen.preview(
        fixture: const ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: ScenarioStage.vocab,
        ),
      ),
      size: const Size(390, 844),
      textScale: 1.3,
    );

    expect(stub.spoken, isEmpty, reason: '대사 스테이지에 들어가기 전에는 자동재생이 없다');

    // vocab → dialog: 첫 대사(officer, '여권 보여주세요.')를 1회 자동재생.
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(stub.spoken, ['여권 보여주세요.']);

    // dialog → grammar: 대사 스테이지가 아니므로 추가 자동재생이 없다
    // (순차 전체 읽기 금지, §9-1 룰링 — 1회만).
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(stub.spoken, ['여권 보여주세요.']);
    expect(stub.stops, 0);

    // 뒤로/화면 이탈 시 정지 — ContentSpeechController.deactivate()가
    // 다음 프레임에 TtsService.stop()을 예약한다(speakable.dart 계약).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(stub.stops, greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '대사 카드 책갈피 탭은 문장형 typed bookmark로 1회 저장되고 quickAdd 미러도 남는다 '
    '(PR2 리뷰 Important 3-a/3-b, a11y HIGH)',
    (tester) async {
      TypedStudyBookmarkStore.resetProductionForTesting();
      CustomPackService.revision.value = 0;
      final stub = stubSoriSpeech();

      await _pumpPreview(
        tester,
        stage: ScenarioStage.dialog,
        size: const Size(390, 844),
        textScale: 1.3,
      );

      // 대사 스테이지 진입 자동재생(T2.1)이 이미 첫 대사를 1회 읽었다 —
      // 책갈피 탭은 이 이력을 건드리지 않아야 한다(§9-2: 책갈피만, 재생
      // 트리거 아님).
      expect(stub.spoken, ['여권 보여주세요.']);
      expect(CustomPackService.containsKorean('여권 보여주세요.'), isFalse);

      // 줄마다 다른 접근성 이름이 붙어야 한다 — 카드 본문의 재생 라벨과도,
      // 다른 대사 줄의 책갈피 버튼과도 겹치면 안 된다(a11y HIGH, WCAG
      // 4.1.2). IconButton.tooltip이 곧 시맨틱 이름이므로(Tooltip이
      // Semantics(label:)로 감싼다) 위젯 트리의 Tooltip.message로 직접
      // 확인한다 — 카드 본문의 "Aussprache: …" 라벨과 혼동되지 않는다.
      final bookmarkTooltip = find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message?.contains('여권 보여주세요') ?? false),
      );
      expect(bookmarkTooltip, findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_add_outlined).first);
      await tester.pumpAndSettle();

      // 정본 저장소: 대사 한 줄은 문장이다 — smalltalk_screen.dart의
      // `_savePhrase`와 같은 typed bookmark 경로(itemType: sentence)로,
      // 활성 로케일(de)로 저장된다(Important 3-a/3-b).
      final bookmarks = TypedStudyBookmarkStore.production().read().bookmarks;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.key.type, StudyLibraryItemType.sentence);
      expect(bookmarks.single.key.id, '여권 보여주세요.');
      expect(bookmarks.single.primaryText, '여권 보여주세요.');
      expect(bookmarks.single.secondaryLanguage, 'de');
      expect(
        bookmarks.single.sourceUnitId,
        scenarioAirportArrivalFixture.id,
        reason: 'provenance는 smalltalk_screen.dart:598처럼 출처 단위를 '
            '남겨야 한다(대사 줄엔 고유 id가 없어 시나리오 id를 쓴다)',
      );

      // 호환 미러: 단어 게임/플래시카드가 계속 보는 quickAdd 팩.
      final pack = CustomPackService.getById(CustomPackService.quickPackId);
      expect(pack, isNotNull);
      final mirrored = pack!.words.where(
        (w) => w.korean == '여권 보여주세요.',
      );
      expect(
        mirrored.length,
        1,
        reason: '탭 1회는 quickAdd 1회여야 한다(중복 없음)',
      );
      expect(mirrored.single.translationLanguage, 'de');
      expect(
        stub.spoken,
        ['여권 보여주세요.'],
        reason: '책갈피 탭은 카드 재생(SoriSpeech.speak)을 트리거하지 않아야 한다 — '
            'onTap 아레나로 전파되지 않는다',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '첫 대사(자동재생 대상) 카드 하나가 재생 정지 컨트롤이다 (WCAG 1.4.2) — '
    '별도 인디케이터를 중첩하지 않는다 (WCAG 4.1.2)',
    (tester) async {
      final stub = stubSoriSpeech(completeSpeak: false);
      final semantics = tester.ensureSemantics();

      await _pumpPreview(
        tester,
        stage: ScenarioStage.dialog,
        size: const Size(390, 844),
        textScale: 1.3,
      );

      // 진입 자동재생이 첫 대사를 speak 요청했다. completeSpeak:false라
      // future가 pending 상태로 남아 phase가 idle로 돌아오지 않는다 —
      // "3초 넘게 이어지는 자동재생"을 흉내내는 이 테스트의 전제.
      expect(stub.spoken, ['여권 보여주세요.']);
      expect(SoriSpeech.phase.value, isNot(TtsSpeechPhase.idle));

      // 리뷰 High: 카드(재생) 안에 별도 SoriSpeechIndicator(재생/정지
      // 토글)를 또 넣으면 같은 위치에 버튼 시맨틱이 중첩된다. 자동재생
      // 대상 줄에는 그 컴포넌트를 아예 두지 않는다 — 컨트롤은 카드 하나뿐.
      final indicator = find.byWidgetPredicate(
        (widget) =>
            widget is SoriSpeechIndicator && widget.text == '여권 보여주세요.',
      );
      expect(
        indicator,
        findsNothing,
        reason: '자동재생 대상 줄은 카드 하나가 유일한 컨트롤이어야 한다 — '
            '별도 인디케이터를 두면 버튼 시맨틱이 중첩된다(WCAG 4.1.2)',
      );

      // 둘째 대사는 자동재생 대상이 아니므로 중복 정지 컨트롤을 만들지 않는다.
      final secondLineIndicator = find.byWidgetPredicate(
        (widget) =>
            widget is SoriSpeechIndicator && widget.text == '네, 여기 있어요.',
      );
      expect(secondLineIndicator, findsNothing);

      // 첫 대사 카드 자체가 정지 가능한 컨트롤이다 — 카드의 버튼 시맨틱
      // label로 찾는다(다른 줄과 구분되는 고유 이름, a11y HIGH 회귀 방지).
      final card = find.bySemanticsLabel(
        RegExp(r'^Aussprache: 여권 보여주세요\.'),
      );
      expect(card, findsOneWidget);
      final beforeTapData = tester.getSemantics(card).getSemanticsData();
      expect(beforeTapData.flagsCollection.isButton, isTrue);
      expect(
        beforeTapData.value,
        'Wird geladen',
        reason: 'resolving 단계에서는 SoriSpeechIndicator와 같은 arb 키'
            '(speechIndicatorResolving)를 카드 value로 노출해야 한다',
      );

      // 첫 대사 카드 시맨틱 서브트리 안의 button 노드는 정확히 2개여야
      // 한다 — 카드 자신(재생/정지, 통합 컨트롤)과 책갈피
      // (AddToWordbookButton, 별개 동작·별개 라벨)뿐이다. 예전엔
      // SoriSpeechIndicator가 카드 안에 하나 더 있어 재생 위치에 동작이
      // 다른 버튼 2개(카드=재생 전용 / 인디케이터=토글 정지)가
      // 중첩됐다(리뷰 High, WCAG 4.1.2) — 그 회귀가 재발하면 이 카운트가
      // 3으로 늘어난다.
      final buttonNodeCount = _countButtonSemanticsNodes(
        tester.getSemantics(card),
      );
      expect(
        buttonNodeCount,
        2,
        reason: '카드(재생/정지 통합 컨트롤) + 책갈피 버튼만 있어야 한다 — '
            '3개 이상이면 같은 자리에 재생 컨트롤이 중첩된 것이다(WCAG 4.1.2)',
      );

      await tester.tap(card);
      await tester.pump();

      expect(
        stub.stops,
        1,
        reason: '재생 중 탭은 정지여야 한다(WCAG 1.4.2) — 다시 재생을 걸면 안 된다',
      );
      expect(stub.spoken, ['여권 보여주세요.']);
      expect(SoriSpeech.phase.value, TtsSpeechPhase.idle);

      final afterTapData = tester.getSemantics(card).getSemanticsData();
      expect(
        afterTapData.value,
        'Nicht aktiv',
        reason: '정지 후에는 speechIndicatorIdle 문구로 돌아와야 한다',
      );

      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'EN 로케일에서 대사 카드 책갈피는 translationLanguage=en으로 저장된다 '
    '(PR2 리뷰 Important 3-b)',
    (tester) async {
      TypedStudyBookmarkStore.resetProductionForTesting();
      CustomPackService.revision.value = 0;
      stubSoriSpeech();

      await _pumpPreview(
        tester,
        stage: ScenarioStage.dialog,
        size: const Size(390, 844),
        textScale: 1.3,
        locale: const Locale('en'),
      );

      await tester.tap(find.byIcon(Icons.bookmark_add_outlined).first);
      await tester.pumpAndSettle();

      final bookmarks = TypedStudyBookmarkStore.production().read().bookmarks;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.key.type, StudyLibraryItemType.sentence);
      expect(
        bookmarks.single.secondaryLanguage,
        'en',
        reason: 'EN 사용자의 책갈피가 독일어로 표시되는 회귀를 막는다',
      );

      final pack = CustomPackService.getById(CustomPackService.quickPackId);
      expect(
        pack!.words.singleWhere((w) => w.korean == '여권 보여주세요.').translationLanguage,
        'en',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('대사 카드 본문 탭은 여전히 발화를 1회 추가한다', (tester) async {
    final stub = stubSoriSpeech();

    await _pumpPreview(
      tester,
      stage: ScenarioStage.dialog,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    expect(stub.spoken, ['여권 보여주세요.'], reason: '진입 자동재생 1회');

    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Aussprache: 여권 보여주세요\.')),
    );
    await tester.pump();

    expect(
      stub.spoken,
      ['여권 보여주세요.', '여권 보여주세요.'],
      reason: '책갈피 버튼을 추가해도 카드 본문 탭 재생 계약은 그대로여야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('DE and EN states remain reachable across the viewport matrix', (
    tester,
  ) async {
    const cases = <({Size size, double scale, ScenarioStage stage})>[
      (size: Size(320, 640), scale: 2.0, stage: ScenarioStage.intro),
      (size: Size(360, 400), scale: 1.0, stage: ScenarioStage.vocab),
      (size: Size(390, 844), scale: 1.3, stage: ScenarioStage.dialog),
      (size: Size(720, 1024), scale: 1.3, stage: ScenarioStage.grammar),
      (size: Size(1280, 900), scale: 1.3, stage: ScenarioStage.result),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final testCase in cases) {
        await _pumpPreview(
          tester,
          stage: testCase.stage,
          size: testCase.size,
          textScale: testCase.scale,
          locale: locale,
        );

        final expectedTitle = scenarioAirportArrivalFixture.title.pick(
          locale.languageCode,
        );
        final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
        expect(appBar.title, expectedTitle);
        final title = tester.widget<Text>(
          find.descendant(
            of: find.byType(SoriAppBar),
            matching: find.text(expectedTitle),
          ),
        );
        expect(title.overflow, TextOverflow.clip);
        expect(find.bySemanticsLabel(_closeLabel(locale)), findsOneWidget);

        if (testCase.stage == ScenarioStage.result) {
          final returnLabel = locale.languageCode == 'de'
              ? 'Zurück zum Hanok'
              : 'Back to my Hanok';
          await _scrollTo(tester, find.text(returnLabel));
          expect(find.text(returnLabel), findsOneWidget);
        } else {
          final nextLabel = testCase.stage == ScenarioStage.intro
              ? locale.languageCode == 'de'
                    ? "Los geht's!"
                    : "Let's go"
              : locale.languageCode == 'de'
              ? 'Weiter'
              : 'Next';
          expect(find.text(nextLabel), findsOneWidget);
          final buttonRect = tester.getRect(find.text(nextLabel));
          expect(buttonRect.bottom, lessThanOrEqualTo(testCase.size.height));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('home confirmation follows intro, active, and result stages', (
    tester,
  ) async {
    for (final testCase in const <({ScenarioStage stage, bool confirm})>[
      (stage: ScenarioStage.intro, confirm: false),
      (stage: ScenarioStage.vocab, confirm: true),
      (stage: ScenarioStage.result, confirm: false),
    ]) {
      await _pumpPreview(
        tester,
        stage: testCase.stage,
        size: const Size(390, 844),
        textScale: 1,
      );

      expect(find.byType(SoriHomeAction), findsOneWidget);
      expect(
        tester
            .widget<SoriHomeAction>(find.byType(SoriHomeAction))
            .escape
            .confirmWhen,
        testCase.confirm,
        reason: testCase.stage.name,
      );
    }
  });

  testWidgets(
    // §NAV-4(J3): _scenarioExitButton's outer Semantics must repeat the
    // ExcludeSemantics-wrapped SoriPressable's onTap, or a screen reader's
    // double-tap does nothing (the same defect home_action.dart:56-62/
    // :114-121 already guards against). The intro/vocab/result matrix
    // above already covers the `_stage > 0 && !_isResultStage` confirm
    // gate via a pointer tap; this asserts the Semantics contract itself
    // and that *performing the Semantics action* (not a pointer tap)
    // reaches the same confirm sheet.
    'exit control exposes a tappable Semantics node repeating its inner action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpPreview(
        tester,
        stage: ScenarioStage.vocab,
        size: const Size(390, 844),
        textScale: 1.3,
      );

      final closeFinder = find.bySemanticsLabel('Schließen');
      expect(closeFinder, findsOneWidget);
      final semanticsData = tester
          .getSemantics(closeFinder)
          .getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(tester.getSize(closeFinder).height, greaterThanOrEqualTo(48));

      final nodeId = tester.getSemantics(closeFinder).id;
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        nodeId,
        ui.SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.text('Runde verlassen?'), findsOneWidget);

      semantics.dispose();
    },
  );

  testWidgets(
    'changed vocabulary and dialogue states cover the full DE and EN matrix',
    (tester) async {
      const viewports = <({Size size, double scale})>[
        (size: Size(320, 640), scale: 2),
        (size: Size(360, 400), scale: 1),
        (size: Size(390, 844), scale: 1.3),
        (size: Size(720, 1024), scale: 1.3),
        (size: Size(1280, 900), scale: 1.3),
      ];

      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final stage in const [ScenarioStage.vocab, ScenarioStage.dialog]) {
          for (final viewport in viewports) {
            await _pumpPreview(
              tester,
              stage: stage,
              size: viewport.size,
              textScale: viewport.scale,
              locale: locale,
            );

            final nextLabel = locale.languageCode == 'de' ? 'Weiter' : 'Next';
            expect(find.text(nextLabel), findsOneWidget);
            expect(
              find.bySemanticsLabel(
                locale.languageCode == 'de' ? 'Schließen' : 'Close',
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required ScenarioStage stage,
  required Size size,
  required double textScale,
  Locale locale = const Locale('de'),
}) {
  final fixture = stage == ScenarioStage.result
      ? const ScenarioPlayerPreviewFixture.result(
          scenario: scenarioAirportArrivalFixture,
          result: null,
        )
      : ScenarioPlayerPreviewFixture.action(
          scenario: scenarioAirportArrivalFixture,
          stage: stage,
        );
  return _pumpPlayer(
    tester,
    child: ScenarioPlayerScreen.preview(
      key: ValueKey('${locale.languageCode}-${stage.name}-${size.width}'),
      fixture: fixture,
    ),
    size: size,
    textScale: textScale,
    locale: locale,
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double textScale,
  Locale locale = const Locale('de'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
        return MediaQuery(
          data: media.copyWith(
            padding: safeInsets,
            viewPadding: safeInsets,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  for (var index = 0; index < 30 && finder.evaluate().isEmpty; index += 1) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pump();
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
  }
  await tester.pump();
}

String _closeLabel(Locale locale) =>
    locale.languageCode == 'de' ? 'Schließen' : 'Close';

/// [root]를 포함해 그 시맨틱 서브트리 안에서 `button` 플래그를 가진
/// 노드 개수를 센다 — 대사 카드 안에 재생 컨트롤이 중첩되지 않았는지
/// 검증하는 데 쓴다(리뷰 High, WCAG 4.1.2).
int _countButtonSemanticsNodes(SemanticsNode root) {
  var count = root.getSemanticsData().flagsCollection.isButton ? 1 : 0;
  root.visitChildren((child) {
    count += _countButtonSemanticsNodes(child);
    return true;
  });
  return count;
}
