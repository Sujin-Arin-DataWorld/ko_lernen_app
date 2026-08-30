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
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  testWidgets('declining voice consent keeps listen-and-repeat available', (
    tester,
  ) async {
    final recorder = _FakeRecorder(permission: true);
    await tester.pumpWidget(_app(recorder));
    await tester.pumpAndSettle();

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record my voice'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Use your voice for an assessment?'), findsOneWidget);

    await tester.tap(find.text('Practise without a score'));
    await tester.pumpAndSettle();

    expect(Storage.pronunciationConsent, isFalse);
    expect(recorder.permissionRequests, 0);
    expect(find.text('Listen'), findsOneWidget);
    final notice = find.textContaining('Voice assessment is off');
    await _scrollUntilBuilt(tester, notice);
    expect(notice, findsOneWidget);
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
    expect(find.text('Listen'), findsOneWidget);
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
      expect(find.text('Stop and assess'), findsOneWidget);
      await tester.pump();
      tester
          .widget<SoriButton>(
            find.widgetWithText(SoriButton, 'Stop and assess'),
          )
          .onTap!();
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && gateway.calls == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(gateway.calls, 1);
      final notice = find.textContaining('score is unavailable');
      await _scrollUntilBuilt(tester, notice);
      expect(notice, findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
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
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Stop and assess'))
        .onTap!();
    await tester.pump();
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
}) => MaterialApp(
  locale: const Locale('en'),
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
    phraseLoader: phraseLoader ?? _loadTestPhrases,
  ),
);

Future<List<PronunciationPhrase>> _loadTestPhrases() async => _testPhrases;

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

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async =>
      Stream<Uint8List>.fromIterable(chunks);

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
