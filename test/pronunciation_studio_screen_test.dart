import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  tearDown(SoriSpeech.resetForTesting);

  testWidgets('listen taps never open the microphone or change to recording', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final recorder = _FakeRecorder(permission: true);
    final playback = <Completer<bool>>[];
    SoriSpeech.speakImpl = (text, voice) {
      expect(text, '안녕하세요');
      final completion = Completer<bool>();
      playback.add(completion);
      return completion.future;
    };
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    final listen = find.byType(SoriSpeechIndicator);
    await tester.tap(listen);
    await tester.pump();
    expect(playback, hasLength(1));
    // speakImpl 은 TtsService 를 우회하는 가짜라 실제 재생-시작 신호가 없다
    // — resolving에서 speaking으로 승격하는 건 TtsService.phase 리스너
    // 뿐이므로(speakable.dart _onEnginePhaseChanged), 여기서 관찰 가능한
    // 상태는 "아직 idle이 아님"을 뜻하는 resolving이다.
    expect(SoriSpeech.phase.value, TtsSpeechPhase.resolving);
    expect(recorder.permissionRequests, 0);
    expect(recorder.startCalls, 0);
    expect(find.text('Record my voice'), findsOneWidget);
    expect(find.text('Stop recording'), findsNothing);

    playback.single.complete(false);
    await tester.pumpAndSettle();
    await tester.tap(listen);
    await tester.pump();
    expect(playback, hasLength(2));
    playback.last.complete(true);
    await tester.pumpAndSettle();
    expect(recorder.permissionRequests, 0);
    expect(recorder.startCalls, 0);
    expect(find.text('Record my voice'), findsOneWidget);
    expect(find.text('Stop recording'), findsNothing);
  });

  testWidgets('microphone waits for playback to release the audio session', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final stopped = Completer<void>();
    SoriSpeech.stopImpl = () => stopped.future;
    final recorder = _FakeRecorder(permission: true);
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    _invokeButton(tester, 'Record my voice');
    await tester.pump();
    expect(recorder.permissionRequests, 0);
    expect(recorder.startCalls, 0);
    expect(find.text('Stop recording'), findsNothing);

    stopped.complete();
    await tester.pump();
    await tester.pump();
    expect(recorder.startCalls, 1);
    expect(find.text('Stop recording'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('leaving while playback stops cannot open the microphone', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final stopped = Completer<void>();
    SoriSpeech.stopImpl = () => stopped.future;
    final recorder = _FakeRecorder(permission: true);
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    _invokeButton(tester, 'Record my voice');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    stopped.complete();
    await tester.pump();
    expect(recorder.startCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('declining voice consent keeps local recording available', (
    tester,
  ) async {
    final recorder = _FakeRecorder(
      permission: true,
      chunks: [
        Uint8List.fromList([0, 0, 1, 0]),
      ],
    );
    final gateway = _FailingGateway();
    await tester.pumpWidget(_app(recorder, gateway: gateway));
    await tester.pumpAndSettle();
    _invokeButton(tester, 'Record my voice');
    await tester.pump();
    await tester.pump();
    expect(find.text('Use your voice for an assessment?'), findsNothing);
    _invokeButton(tester, 'Stop recording');
    await _requestScore(tester);
    await tester.pumpAndSettle();
    expect(find.text('Use your voice for an assessment?'), findsOneWidget);
    await tester.tap(find.text('Practise without a score'));
    await tester.pumpAndSettle();
    expect(Storage.pronunciationConsent, isFalse);
    expect(recorder.permissionRequests, 1);
    expect(gateway.calls, 0);
    expect(find.text('Listen to my recording'), findsOneWidget);
  });

  testWidgets('microphone denial does not remove basic practice controls', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(permission: false);
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record my voice'))
        .onTap!();
    await tester.pumpAndSettle();

    expect(recorder.permissionRequests, 1);
    final notice = find.textContaining('Microphone access was not granted');
    await _scrollUntilBuilt(tester, notice);
    expect(notice, findsOneWidget);
    expect(find.byType(SoriSpeechIndicator), findsOneWidget);
  });

  testWidgets(
    'server failure after capture leaves a clear non-blocking fallback',
    (tester) async {
      await Storage.setPronunciationConsent(true);
      final recorder = _FakeRecorder(
        permission: true,
        chunks: <Uint8List>[
          Uint8List.fromList(<int>[0, 0, 1, 0]),
        ],
      );
      final gateway = _FailingGateway();
      await tester.pumpWidget(_app(recorder, gateway: gateway));
      await tester.pumpAndSettle();

      tester
          .widget<SoriButton>(
            find.widgetWithText(SoriButton, 'Record my voice'),
          )
          .onTap!();
      await tester.pump();
      await tester.pump();
      expect(find.text('Stop recording'), findsOneWidget);
      await tester.pump();
      tester
          .widget<SoriButton>(find.widgetWithText(SoriButton, 'Stop recording'))
          .onTap!();
      await tester.pump();
      await _requestScore(tester);
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && gateway.calls == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(gateway.calls, 1);
      final notice = find.text('Assessment service is unavailable');
      await _scrollUntilBuilt(tester, notice);
      expect(notice, findsOneWidget);
      expect(find.byType(SoriSpeechIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'uses cumulative phrases after normalizing the stored learner level',
    (tester) async {
      await Storage.setUserLevelCode('B1');
      const a1 = PronunciationPhrase(
        id: 'pronunciation_a1_0001',
        level: LearnerLevel.a1,
        ko: '안녕하세요',
        de: 'Guten Tag.',
        en: 'Hello.',
        focus: 'ㅎ 발음',
      );
      const b1 = PronunciationPhrase(
        id: 'pronunciation_b1_0001',
        level: LearnerLevel.b1,
        ko: '회의는 내일로 미뤄졌어요.',
        de: 'Das Treffen wurde auf morgen verschoben.',
        en: 'The meeting was postponed until tomorrow.',
        focus: '유음화',
      );
      final recorder = _FakeRecorder(permission: true);

      await tester.pumpWidget(
        _app(
          recorder,
          phraseLoader: () async => const <PronunciationPhrase>[a1, b1],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(a1.ko), findsOneWidget);
      final continueAction = find.text('Continue without a score');
      await _scrollUntilBuilt(tester, continueAction);
      await tester.tap(continueAction);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pump();
      expect(find.text(b1.ko), findsOneWidget);
    },
  );

  testWidgets('empty phrase data removes controls and remains retryable', (
    tester,
  ) async {
    var attempts = 0;
    final recorder = _FakeRecorder(permission: true);
    Future<List<PronunciationPhrase>> emptyLoader() async {
      attempts++;
      return const <PronunciationPhrase>[];
    }

    await tester.pumpWidget(_app(recorder, phraseLoader: emptyLoader));
    await tester.pumpAndSettle();

    expect(find.text('No pronunciation practice yet'), findsOneWidget);
    expect(find.text('Listen'), findsNothing);
    expect(find.text('Record my voice'), findsNothing);
    expect(attempts, 1);

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Try again'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('a phrase load failure is retryable without exposing controls', (
    tester,
  ) async {
    var attempts = 0;
    final recorder = _FakeRecorder(permission: true);
    Future<List<PronunciationPhrase>> failingLoader() async {
      attempts++;
      throw StateError('broken asset');
    }

    await tester.pumpWidget(_app(recorder, phraseLoader: failingLoader));
    await tester.pumpAndSettle();

    expect(find.text('Pronunciation practice unavailable'), findsOneWidget);
    expect(find.text('Listen'), findsNothing);
    expect(attempts, 1);

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Try again'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('home confirmation is active while recording and assessing', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(
      permission: true,
      chunks: <Uint8List>[
        Uint8List.fromList(<int>[0, 0, 1, 0]),
      ],
    );
    final gateway = _HoldingGateway();
    await tester.pumpWidget(_app(recorder, gateway: gateway));
    await tester.pumpAndSettle();

    expect(find.byType(SoriHomeAction), findsOneWidget);
    expect(
      tester
          .widget<SoriHomeAction>(find.byType(SoriHomeAction))
          .escape
          .confirmWhen,
      isFalse,
    );

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record my voice'))
        .onTap!();
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<SoriHomeAction>(find.byType(SoriHomeAction))
          .escape
          .confirmWhen,
      isTrue,
    );

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Stop recording'))
        .onTap!();
    await tester.pump();
    await _requestScore(tester);
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 20 && gateway.calls == 0; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pump();
    expect(gateway.calls, 1);
    expect(
      tester
          .widget<SoriHomeAction>(find.byType(SoriHomeAction))
          .escape
          .confirmWhen,
      isTrue,
    );

    gateway.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SoriHomeAction>(find.byType(SoriHomeAction))
          .escape
          .confirmWhen,
      isFalse,
    );
  });

  const failureCases =
      <
        ({
          PronunciationAssessmentFailureCategory category,
          String enTitle,
          String enBody,
          String deTitle,
          String deBody,
          bool needsNewRecording,
        })
      >[
        (
          category: PronunciationAssessmentFailureCategory.invalidRequest,
          enTitle: 'New recording needed',
          enBody:
              'This recording could not be assessed safely. Record the phrase again.',
          deTitle: 'Neue Aufnahme nötig',
          deBody:
              'Diese Aufnahme konnte nicht sicher bewertet werden. Nimm den Satz bitte noch einmal auf.',
          needsNewRecording: true,
        ),
        (
          category:
              PronunciationAssessmentFailureCategory.authenticationRequired,
          enTitle: 'Secure sign-in is not ready',
          enBody:
              'The assessment needs the app’s anonymous sign-in. Your recording stays ready here; retry when the connection is ready.',
          deTitle: 'Sichere Anmeldung noch nicht bereit',
          deBody:
              'Für die Bewertung braucht die App ihre anonyme Anmeldung. Deine Aufnahme bleibt hier bereit; versuche es erneut, sobald die Verbindung steht.',
          needsNewRecording: false,
        ),
        (
          category: PronunciationAssessmentFailureCategory.unavailable,
          enTitle: 'Assessment service is unavailable',
          enBody:
              'Your recording is still ready. Send the same recording again when the service is available.',
          deTitle: 'Bewertung gerade nicht erreichbar',
          deBody:
              'Deine Aufnahme bleibt bereit. Sende dieselbe Aufnahme erneut, sobald der Dienst erreichbar ist.',
          needsNewRecording: false,
        ),
        (
          category: PronunciationAssessmentFailureCategory.rateLimited,
          enTitle: 'Assessment limit reached',
          enBody:
              'Your recording stays ready on this screen. Retry later or continue without a score.',
          deTitle: 'Bewertungslimit erreicht',
          deBody:
              'Deine Aufnahme bleibt auf diesem Bildschirm bereit. Versuche es später erneut oder lerne ohne Bewertung weiter.',
          needsNewRecording: false,
        ),
        (
          category: PronunciationAssessmentFailureCategory.unknown,
          enTitle: 'Assessment could not be completed',
          enBody: 'No score was saved. Try the same recording again.',
          deTitle: 'Bewertung nicht abgeschlossen',
          deBody:
              'Es wurde keine Bewertung gespeichert. Versuche dieselbe Aufnahme noch einmal.',
          needsNewRecording: false,
        ),
      ];

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final failureCase in failureCases) {
      testWidgets(
        '${failureCase.category.name} has a distinct ${locale.languageCode} diagnosis and action',
        (tester) async {
          await Storage.setPronunciationConsent(true);
          final recorder = _FakeRecorder(
            permission: true,
            chunks: <Uint8List>[
              Uint8List.fromList(<int>[0, 0, 1, 0]),
            ],
          );
          final gateway = _CategoryFailingGateway(failureCase.category);
          await tester.pumpWidget(
            _app(recorder, gateway: gateway, locale: locale),
          );
          await tester.pumpAndSettle();

          await _captureAndAssess(tester, callStarted: () => gateway.calls > 0);

          final title = locale.languageCode == 'de'
              ? failureCase.deTitle
              : failureCase.enTitle;
          final body = locale.languageCode == 'de'
              ? failureCase.deBody
              : failureCase.enBody;
          final diagnostic = find.byKey(
            ValueKey('pronunciation-diagnostic-${failureCase.category.name}'),
          );
          await _scrollUntilBuilt(tester, diagnostic);
          expect(diagnostic, findsOneWidget);
          expect(find.text(title), findsOneWidget);
          expect(find.text(body), findsOneWidget);

          final actionLabel = failureCase.needsNewRecording
              ? (locale.languageCode == 'de' ? 'Neu aufnehmen' : 'Record again')
              : (locale.languageCode == 'de'
                    ? 'Dieselbe Aufnahme erneut bewerten'
                    : 'Retry same recording');
          final action = find.widgetWithText(SoriButton, actionLabel);
          await _scrollUntilBuilt(tester, action);
          expect(tester.widget<SoriButton>(action).onTap, isNotNull);
        },
      );
    }
  }

  testWidgets('recorder startup failure is distinct from permission denial', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _ThrowingStartRecorder();
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    _invokeButton(tester, 'Record my voice');
    await tester.pumpAndSettle();

    final diagnostic = find.byKey(
      const ValueKey('pronunciation-recorder-failure'),
    );
    await _scrollUntilBuilt(tester, diagnostic);
    expect(diagnostic, findsOneWidget);
    expect(find.text('Recording could not start'), findsOneWidget);
    expect(
      find.textContaining('Microphone access was not granted'),
      findsNothing,
    );
    expect(
      tester
          .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record again'))
          .onTap,
      isNotNull,
    );
  });

  testWidgets('assessment retry reuses PCM phrase and assessment id', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(
      permission: true,
      chunks: <Uint8List>[
        Uint8List.fromList(<int>[0, 0, 1, 0]),
      ],
    );
    final gateway = _RetryGateway();
    await tester.pumpWidget(_app(recorder, gateway: gateway));
    await tester.pumpAndSettle();

    await _captureAndAssess(
      tester,
      callStarted: () => gateway.calls.isNotEmpty,
    );
    final retry = find.widgetWithText(SoriButton, 'Retry same recording');
    await _scrollUntilBuilt(tester, retry);
    _invokeButton(tester, 'Retry same recording');
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && gateway.calls.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();

    expect(gateway.calls, hasLength(2));
    expect(gateway.calls[1].pcm16, orderedEquals(gateway.calls[0].pcm16));
    expect(gateway.calls[1].referenceText, gateway.calls[0].referenceText);
    expect(gateway.calls[1].assessmentId, gateway.calls[0].assessmentId);
    expect(Storage.pronunciationPassCount, 1);
  });

  testWidgets('phrase navigation suppresses a late permission completion', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _DelayedPermissionRecorder();
    await tester.pumpWidget(
      _app(
        recorder,
        phraseLoader: () async => const <PronunciationPhrase>[
          ..._testPhrases,
          PronunciationPhrase(
            id: 'pronunciation_a1_0002',
            level: LearnerLevel.a1,
            ko: '감사합니다',
            de: 'Danke.',
            en: 'Thank you.',
            focus: 'ㅂ 받침',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    _invokeButton(tester, 'Record my voice');
    await tester.pump();
    _invokeButton(tester, 'Continue without a score');
    await tester.pump();
    expect(find.text('감사합니다'), findsOneWidget);

    recorder.permission.complete(true);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();

    expect(recorder.startCalls, 0);
    expect(find.text('Recording…'), findsNothing);
  });

  testWidgets('dispose while recording cancels capture lifecycle', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _TrackingRecorder();
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    _invokeButton(tester, 'Record my voice');
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && recorder.disposeCalls == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    expect(recorder.disposeCalls, 1);
    expect(tester.takeException(), isNull);
    await recorder.close();
  });

  testWidgets('dispose while assessing suppresses late score persistence', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(
      permission: true,
      chunks: <Uint8List>[
        Uint8List.fromList(<int>[0, 0, 1, 0]),
      ],
    );
    final gateway = _HoldingSuccessGateway();
    await tester.pumpWidget(_app(recorder, gateway: gateway));
    await tester.pumpAndSettle();

    await _captureAndAssess(
      tester,
      callStarted: () => gateway.calls > 0,
      settle: false,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    gateway.complete();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();

    expect(Storage.pronunciationPassCount, 0);
    expect(tester.takeException(), isNull);
  });
}

const List<PronunciationPhrase> _testPhrases = <PronunciationPhrase>[
  PronunciationPhrase(
    id: 'pronunciation_a1_0001',
    level: LearnerLevel.a1,
    ko: '안녕하세요',
    de: 'Guten Tag.',
    en: 'Hello.',
    focus: 'ㅎ 발음',
  ),
];

Widget _app(
  PronunciationRecorder recorder, {
  PronunciationAssessmentGateway? gateway,
  Future<List<PronunciationPhrase>> Function()? phraseLoader,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppL10n.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppL10n.supportedLocales,
  home: PronunciationStudioScreen(
    recorder: recorder,
    gateway: gateway,
    cloudAssessmentEnabled: true,
    phraseLoader: phraseLoader ?? _loadTestPhrases,
  ),
);

Future<List<PronunciationPhrase>> _loadTestPhrases() async => _testPhrases;

void _invokeButton(WidgetTester tester, String label) {
  tester.widget<SoriButton>(find.widgetWithText(SoriButton, label)).onTap!();
}

Future<void> _captureAndAssess(
  WidgetTester tester, {
  required bool Function() callStarted,
  bool settle = true,
}) async {
  final t = AppL10n.of(tester.element(find.byType(PronunciationStudioScreen)));
  _invokeButton(tester, t.pronunciationRecord);
  await tester.pump();
  await tester.pump();
  _invokeButton(tester, t.pronunciationStop);
  await _requestScore(tester);
  await tester.runAsync(() async {
    for (var i = 0; i < 40 && !callStarted(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _requestScore(WidgetTester tester) async {
  await tester.runAsync(
    () async => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
  final score = find.byKey(const ValueKey('pronunciation-assess-action'));
  await _scrollUntilBuilt(tester, score);
  tester.widget<SoriButton>(score).onTap!();
  await tester.pump();
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Finder target) async {
  final listView = find.byType(ListView).first;
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(listView, const Offset(0, -160));
    await tester.pump();
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pump();
  }
}

class _FakeRecorder implements PronunciationRecorder {
  _FakeRecorder({required this.permission, this.chunks = const <Uint8List>[]});

  final bool permission;
  final List<Uint8List> chunks;
  int permissionRequests = 0;
  int startCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    startCalls++;
    return Stream<Uint8List>.fromIterable(chunks);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FailingGateway implements PronunciationAssessmentGateway {
  int calls = 0;

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls++;
    throw const PronunciationAssessmentFailure(
      PronunciationAssessmentFailureCategory.unavailable,
      retryable: true,
    );
  }
}

class _HoldingGateway implements PronunciationAssessmentGateway {
  final Completer<PronunciationAssessmentResult> _result = Completer();
  int calls = 0;

  void complete() {
    _result.complete(
      const PronunciationAssessmentResult(
        assessmentId: 'assessment-hold',
        pronunciationScore: 0,
        accuracyScore: 0,
        fluencyScore: 0,
        completenessScore: 0,
      ),
    );
  }

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) {
    calls++;
    return _result.future;
  }
}

class _CategoryFailingGateway implements PronunciationAssessmentGateway {
  _CategoryFailingGateway(this.category);

  final PronunciationAssessmentFailureCategory category;
  int calls = 0;

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls++;
    throw PronunciationAssessmentFailure(
      category,
      retryable:
          category != PronunciationAssessmentFailureCategory.invalidRequest &&
          category !=
              PronunciationAssessmentFailureCategory.authenticationRequired,
    );
  }
}

class _AssessmentCall {
  const _AssessmentCall({
    required this.pcm16,
    required this.referenceText,
    required this.assessmentId,
  });

  final Uint8List pcm16;
  final String referenceText;
  final String assessmentId;
}

class _RetryGateway implements PronunciationAssessmentGateway {
  final List<_AssessmentCall> calls = [];

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls.add(
      _AssessmentCall(
        pcm16: Uint8List.fromList(pcm16),
        referenceText: referenceText,
        assessmentId: assessmentId,
      ),
    );
    if (calls.length == 1) {
      throw const PronunciationAssessmentFailure(
        PronunciationAssessmentFailureCategory.unavailable,
        retryable: true,
      );
    }
    return PronunciationAssessmentResult(
      assessmentId: assessmentId,
      pronunciationScore: 88,
      accuracyScore: 90,
      fluencyScore: 86,
      completenessScore: 89,
    );
  }
}

class _ThrowingStartRecorder implements PronunciationRecorder {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async =>
      throw StateError('recorder unavailable');

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _DelayedPermissionRecorder implements PronunciationRecorder {
  final Completer<bool> permission = Completer<bool>();
  int startCalls = 0;

  @override
  Future<bool> requestPermission() => permission.future;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    startCalls++;
    return const Stream<Uint8List>.empty();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _TrackingRecorder implements PronunciationRecorder {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  int disposeCalls = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async => _controller.stream;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await close();
  }

  Future<void> close() =>
      _controller.isClosed ? Future<void>.value() : _controller.close();
}

class _HoldingSuccessGateway implements PronunciationAssessmentGateway {
  final Completer<PronunciationAssessmentResult> _result = Completer();
  int calls = 0;
  String? assessmentId;

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) {
    calls++;
    this.assessmentId = assessmentId;
    return _result.future;
  }

  void complete() {
    _result.complete(
      PronunciationAssessmentResult(
        assessmentId: assessmentId!,
        pronunciationScore: 91,
        accuracyScore: 91,
        fluencyScore: 91,
        completenessScore: 91,
      ),
    );
  }
}
