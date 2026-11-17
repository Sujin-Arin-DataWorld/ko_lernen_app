import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/services/pronunciation_playback.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/pronunciation_phrase_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  tearDown(SoriSpeech.resetForTesting);
  testWidgets('paper practice surface stays legible in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: PronunciationStudioScreen(
          phrases: _phrases,
          recorder: _Recorder(),
          playback: _Playback(),
          gateway: _Gateway(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final focus = find.text('Pronunciation of ㅎ');
    expect(focus, findsOneWidget);
    expect(Theme.of(tester.element(focus)).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });
  testWidgets('background stops an active microphone', (tester) async {
    final recorder = _Recorder();
    await _mount(tester, recorder, _Gateway(), _Playback());
    await _action(tester, 'pronunciation-record-action');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _drain(tester);
    expect(recorder.stops, 1);
    expect(find.text('Stop recording'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets('backgrounding during audio handoff releases the controls', (
    tester,
  ) async {
    final playback = _Playback();
    await _mount(tester, _Recorder(), _Gateway(), playback);
    final release = playback.holdStop = Completer<void>();
    final model = find.byKey(const ValueKey('pronunciation-model-action'));
    var spoken = 0;
    SoriSpeech.speakImpl = (text, voice) async {
      spoken++;
      return true;
    };
    await tester.tap(model);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(_callback(tester, model), isNull);
    release.complete();
    playback.holdStop = null;
    await tester.pumpAndSettle();
    expect(spoken, 0);
    await tester.tap(model);
    await tester.pumpAndSettle();
    expect(spoken, 1);
  });
  testWidgets('microphone denial preserves the practice screen', (
    tester,
  ) async {
    final recorder = _Recorder(permission: false);
    await _mount(tester, recorder, _Gateway(), _Playback());
    await _action(tester, 'pronunciation-record-action');
    expect(recorder.starts, 0);
    expect(
      find.textContaining('Microphone access was not granted'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pronunciation-model-action')),
      findsOneWidget,
    );
  });
  testWidgets(
    'narrow large text and reduced motion keep the recording action reachable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: PronunciationStudioScreen(
            phrases: _phrases,
            recorder: _Recorder(),
            playback: _Playback(),
            gateway: _Gateway(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('pronunciation-record-action')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _action(tester, 'pronunciation-record-action');
      expect(find.text('Stop recording'), findsOneWidget);
    },
  );
  testWidgets(
    'C2 reference and level selection render real localized content',
    (tester) async {
      final phrases = (await tester.runAsync(PronunciationPhraseLoader.load))!;
      final reference = phrases.singleWhere(
        (p) => p.id == 'pronunciation_c2_0016',
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const bool.fromEnvironment('CAPTURE_402')
          ? const Size(402, 874)
          : const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('de'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: PronunciationStudioScreen(
              phrases: phrases,
              initialPhraseId: reference.id,
              recorder: _Recorder(),
              playback: _Playback(),
              gateway: _Gateway(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(reference.ko), findsOneWidget);
      final translation = find.byKey(
        const ValueKey('pronunciation-translation'),
      );
      final germanText = tester.widget<Text>(translation);
      if (const bool.fromEnvironment('CAPTURE_402')) {
        expect(
          germanText.data!.replaceAll(RegExp(r'\s+'), ' '),
          reference.de.replaceAll(RegExp(r'\s+'), ' '),
        );
      } else {
        expect(germanText.data, reference.deDisplay);
        expect(germanText.data!.split('\n'), hasLength(5));
      }
      expect(germanText.semanticsLabel, reference.de);
      expect(
        find.text('Nach dem Bedingungssatz kurz pausieren.'),
        findsOneWidget,
      );
      Future<void> capture(String name) async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final geometry = {
          for (final anchor in [
            'pronunciation-translation',
            'pronunciation-audio-panel',
            'pronunciation-model-action',
            'pronunciation-next-action',
            'pronunciation-record-action',
            'sori-image-navigation-bar',
          ])
            anchor: tester.getRect(find.byKey(ValueKey(anchor))),
        };
        final navigation = geometry['sori-image-navigation-bar']!;
        final bottomAction = [
          geometry['pronunciation-next-action']!.bottom,
          geometry['pronunciation-record-action']!.bottom,
        ].reduce((a, b) => a > b ? a : b);
        expect(navigation.top - bottomAction, greaterThanOrEqualTo(16));
        expect(
          geometry['pronunciation-model-action']!.size.shortestSide,
          greaterThanOrEqualTo(48),
        );
        const directory = String.fromEnvironment(
          'PRONUNCIATION_CAPTURE_DIR',
          defaultValue: '.',
        );
        boundary.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$directory/$name',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          await File('$directory/$name.geometry.json').writeAsString(
            jsonEncode({
              for (final entry in geometry.entries)
                entry.key: [
                  entry.value.left,
                  entry.value.top,
                  entry.value.width,
                  entry.value.height,
                ],
            }),
          );
          image.dispose();
        });
      }

      if (const bool.fromEnvironment('CAPTURE_PRONUNCIATION')) {
        await settleCNativeCaptureAssets(tester);
        await capture('flutter-pronunciation-ready.png');
      }
      await _capture(tester);
      if (const bool.fromEnvironment('CAPTURE_PRONUNCIATION')) {
        await settleCNativeCaptureAssets(tester);
        await capture('flutter-pronunciation-compare.png');
      }
      await tester.tap(find.byKey(const ValueKey('pronunciation-level')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A1').last);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          phrases.firstWhere((p) => p.level == LearnerLevel.a1).ko,
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(reference.ko), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
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
    _callback(
      tester,
      find.byKey(const ValueKey('pronunciation-model-action')),
    )!();
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
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Next sentence'))
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
    focus: 'ㅎ 발음',
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

VoidCallback? _callback(WidgetTester tester, Finder target) => switch (tester
    .widget(target)) {
  SoriButton(:final onTap) => onTap,
  SoriPressable(:final onTap) => onTap,
  IconButton(:final onPressed) => onPressed,
  final widget => throw StateError('Unexpected pronunciation control: $widget'),
};

Future<void> _action(WidgetTester tester, String key) async {
  _callback(tester, find.byKey(ValueKey(key)))!();
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
  expect(
    find.byKey(const ValueKey('pronunciation-replay-action')),
    findsOneWidget,
  );
}

class _Recorder implements PronunciationRecorder {
  _Recorder({this.permission = true});
  final bool permission;
  int starts = 0;
  int stops = 0;
  StreamController<Uint8List>? stream;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    starts++;
    stream = StreamController<Uint8List>();
    stream!.add(Uint8List.fromList([starts, 0, 2, 0]));
    return stream!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
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
