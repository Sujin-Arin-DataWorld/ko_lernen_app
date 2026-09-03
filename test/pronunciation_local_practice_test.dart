import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/services/pronunciation_playback.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  tearDown(SoriSpeech.resetForTesting);
  testWidgets('default local recording needs no remote voice consent', (
    tester,
  ) async {
    final recorder = _Recorder();
    final gateway = _Gateway();
    final playback = _Playback();
    await _mount(tester, recorder, gateway, playback);
    await _action(tester, 'pronunciation-record-action');
    expect(recorder.starts, 1);
    expect(Storage.pronunciationConsent, isFalse);
    expect(find.text('Use your voice for an assessment?'), findsNothing);
    expect(gateway.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(playback.disposed, isTrue);
  });
  testWidgets(
    'default beta manual stop and replay never assess with stored consent',
    (tester) async {
      await Storage.setPronunciationConsent(true);
      final gateway = _Gateway();
      final playback = _Playback();
      await _mount(tester, _Recorder(), gateway, playback);
      await _capture(tester);
      expect(
        find.byKey(const ValueKey('pronunciation-assess-action')),
        findsNothing,
      );
      expect(find.textContaining('80'), findsNothing);
      await _action(tester, 'pronunciation-replay-action');
      expect(playback.recordings.single, orderedEquals([1, 0, 2, 0]));
      expect(find.text('Stop my recording'), findsOneWidget);
      await _action(tester, 'pronunciation-replay-action');
      expect(find.text('Listen to my recording'), findsOneWidget);
      expect(gateway.calls, 0);
      expect(Storage.pronunciationPassCount, 0);
    },
  );
  testWidgets('ten-second auto stop stays local and replayable', (
    tester,
  ) async {
    final gateway = _Gateway();
    final playback = _Playback();
    await _mount(tester, _Recorder(), gateway, playback);
    await _action(tester, 'pronunciation-record-action');
    await tester.pump(const Duration(seconds: 10));
    await _drain(tester);
    await _action(tester, 'pronunciation-replay-action');
    expect(playback.recordings, hasLength(1));
    expect(gateway.calls, 0);
    expect(Storage.pronunciationPassCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets('rerecord waits for replay release and replaces old audio', (
    tester,
  ) async {
    final recorder = _Recorder();
    final gateway = _Gateway();
    final playback = _Playback();
    await _mount(tester, recorder, gateway, playback);
    await _capture(tester);
    await _action(tester, 'pronunciation-replay-action');
    final release = playback.holdStop = Completer<void>();
    await _action(tester, 'pronunciation-record-action');
    expect(recorder.starts, 1);
    expect(
      find.byKey(const ValueKey('pronunciation-replay-action')),
      findsNothing,
    );
    release.complete();
    await tester.pump();
    await tester.pump();
    expect(recorder.starts, 2);
    playback.holdStop = null;
    await _action(tester, 'pronunciation-record-action');
    await _drain(tester);
    await _action(tester, 'pronunciation-replay-action');
    expect(playback.recordings.last, orderedEquals([2, 0, 2, 0]));
    expect(gateway.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets('model playback waits for local replay release', (tester) async {
    final playback = _Playback();
    var starts = 0;
    SoriSpeech.speakImpl = (text, voice) async {
      starts++;
      return true;
    };
    await _mount(tester, _Recorder(), _Gateway(), playback);
    await _capture(tester);
    await _action(tester, 'pronunciation-replay-action');
    final release = playback.holdStop = Completer<void>();
    tester
        .widget<SoriSpeechIndicator>(find.byType(SoriSpeechIndicator))
        .onTap!();
    await tester.pump();
    expect(starts, 0);
    release.complete();
    await tester.pump();
    expect(starts, 1);
    playback.holdStop = null;
  });
  testWidgets('next phrase and disposal cancel replay awaiting model stop', (
    tester,
  ) async {
    final playback = _Playback();
    await _mount(tester, _Recorder(), _Gateway(), playback);
    await _capture(tester);
    final release = Completer<void>();
    SoriSpeech.stopImpl = () => release.future;
    await _action(tester, 'pronunciation-replay-action');
    tester
        .widget<SoriButton>(
          find.widgetWithText(SoriButton, 'Continue without a score'),
        )
        .onTap!();
    await tester.pump();
    expect(find.text('감사합니다'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pronunciation-replay-action')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    release.complete();
    await tester.pump();
    expect(playback.recordings, isEmpty);
    expect(playback.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });
  for (final failure in [
    PronunciationAssessmentFailureCategory.unavailable,
    PronunciationAssessmentFailureCategory.rateLimited,
  ]) {
    testWidgets('$failure retains local replay and does not count a pass', (
      tester,
    ) async {
      final gateway = _Gateway(failure: failure);
      final playback = _Playback();
      await _mount(tester, _Recorder(), gateway, playback, scoring: true);
      await _capture(tester);
      expect(gateway.calls, 0);
      await _action(tester, 'pronunciation-assess-action');
      await tester.pumpAndSettle();
      expect(find.text('Use your voice for an assessment?'), findsOneWidget);
      expect(gateway.calls, 0);
      await tester.tap(find.text('I agree and want a score'));
      await tester.pumpAndSettle();
      expect(gateway.calls, 1);
      await _action(tester, 'pronunciation-replay-action');
      expect(playback.recordings.single, orderedEquals([1, 0, 2, 0]));
      expect(Storage.pronunciationPassCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

const _phrases = [
  PronunciationPhrase(
    id: 'local-a1',
    level: LearnerLevel.a1,
    ko: '안녕하세요',
    de: 'Guten Tag.',
    en: 'Hello.',
    focus: 'ㅎ',
  ),
  PronunciationPhrase(
    id: 'local-a2',
    level: LearnerLevel.a1,
    ko: '감사합니다',
    de: 'Danke.',
    en: 'Thank you.',
    focus: 'ㅂ',
  ),
];
Future<void> _mount(
  WidgetTester tester,
  _Recorder recorder,
  _Gateway gateway,
  _Playback playback, {
  bool? scoring,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(600, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  // Omit the override to prove the actual default beta setting.
  final screen = scoring == null
      ? PronunciationStudioScreen(
          recorder: recorder,
          gateway: gateway,
          playback: playback,
          phrases: _phrases,
        )
      : PronunciationStudioScreen(
          recorder: recorder,
          gateway: gateway,
          playback: playback,
          phrases: _phrases,
          cloudAssessmentEnabled: scoring,
        );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _action(WidgetTester tester, String key) async {
  tester.widget<SoriButton>(find.byKey(ValueKey(key))).onTap!();
  await tester.pump();
  await tester.pump();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.runAsync(
    () async => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

Future<void> _capture(WidgetTester tester) async {
  await _action(tester, 'pronunciation-record-action');
  await _action(tester, 'pronunciation-record-action');
  await _drain(tester);
  expect(find.text('Listen to my recording'), findsOneWidget);
}

class _Recorder implements PronunciationRecorder {
  int starts = 0;
  StreamController<Uint8List>? stream;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    starts++;
    stream = StreamController<Uint8List>();
    stream!.add(Uint8List.fromList([starts, 0, 2, 0]));
    return stream!.stream;
  }

  @override
  Future<void> stop() async {
    await stream?.close();
  }

  @override
  Future<void> dispose() async {
    await stream?.close();
  }
}

class _Playback implements PronunciationPlayback {
  final recordings = <Uint8List>[];
  Completer<void>? current;
  Completer<void>? holdStop;
  bool disposed = false;
  @override
  Future<void> play(Uint8List pcm16) {
    recordings.add(Uint8List.fromList(pcm16));
    current = Completer<void>();
    return current!.future;
  }

  @override
  Future<void> stop() async {
    if (current != null && !current!.isCompleted) {
      current!.complete();
    }
    await holdStop?.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }
}

class _Gateway implements PronunciationAssessmentGateway {
  _Gateway({this.failure = PronunciationAssessmentFailureCategory.unavailable});
  final PronunciationAssessmentFailureCategory failure;
  int calls = 0;
  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls++;
    throw PronunciationAssessmentFailure(failure, retryable: true);
  }
}
