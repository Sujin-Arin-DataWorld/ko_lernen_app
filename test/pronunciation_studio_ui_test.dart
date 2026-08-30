import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _phrase = PronunciationPhrase(
  id: 'pronunciation_ui_a1',
  level: LearnerLevel.a1,
  ko: '안녕하세요',
  de: 'Guten Tag.',
  en: 'Hello.',
  focus: 'ㅎ 발음',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('pronunciation keeps one hierarchy and complete actions in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        _configureView(tester, viewport.size);

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: PronunciationStudioScreen(
              phrases: const [_phrase],
              recorder: _FakeRecorder(permission: false),
              gateway: _DelayedGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final screen = find.byType(PronunciationStudioScreen);
        final context = tester.element(screen);
        final t = AppL10n.of(context);
        final frame = tester.widget<SoriStudyFrame>(
          find.byType(SoriStudyFrame),
        );
        expect(frame.title, t.pronunciationTitle);
        expect(frame.hero, isNull);
        expect(find.byType(Mascot), findsNothing);
        expect(
          tester
              .widgetList<SoriCard>(find.byType(SoriCard))
              .where((card) => card.variant == SoriCardVariant.hero),
          isEmpty,
        );

        final phraseFinder = find.text(_phrase.ko);
        await _scrollUntilBuilt(tester, phraseFinder);
        final phraseText = tester.widget<Text>(phraseFinder);
        final type = SoriTextTheme.of(tester.element(phraseFinder));
        expect(phraseText.maxLines, isNull);
        expect(phraseText.overflow, isNull);
        expect(phraseText.style?.fontFamily, type.koDisplay.fontFamily);
        expect(phraseText.style?.fontWeight, type.koDisplay.fontWeight);

        expect(find.byType(SoriSpeechIndicator), findsOneWidget);
        expect(
          tester
              .widget<SoriSpeechIndicator>(find.byType(SoriSpeechIndicator))
              .text,
          _phrase.ko,
        );
        expect(
          find.widgetWithText(SoriButton, t.pronunciationListen),
          findsNothing,
        );

        for (final label in [
          t.pronunciationRecord,
          t.pronunciationContinueWithoutScore,
        ]) {
          final action = find.widgetWithText(SoriButton, label);
          await _scrollUntilBuilt(tester, action);
          expect(action, findsOneWidget);
          final size = tester.getSize(action);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
          final button = tester.widget<SoriButton>(action);
          expect(button.label, label);
          expect(button.maxLines, isNull);
        }
        final recordAction = tester.widget<SoriButton>(
          find.byKey(const ValueKey('pronunciation-record-action')),
        );
        expect(recordAction.variant, SoriButtonVariant.filled);
        expect(recordAction.fullWidth, isTrue);
        expect(
          tester.widget<Column>(
            find.byKey(const ValueKey('pronunciation-diagnostic-feed')),
          ),
          isA<Column>(),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('capture and assessment have distinct app-owned states', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(
      permission: true,
      chunks: <Uint8List>[
        Uint8List.fromList(const [0, 0, 1, 0]),
      ],
    );
    final gateway = _DelayedGateway();

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        textScale: 1,
        child: PronunciationStudioScreen(
          phrases: const [_phrase],
          recorder: recorder,
          gateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record my voice'))
        .onTap!();
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(SoriButton, 'Stop and assess'), findsOneWidget);

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Stop and assess'))
        .onTap!();
    await tester.pump();

    final assessing = find.widgetWithText(SoriButton, 'Preparing your score…');
    expect(assessing, findsOneWidget);
    expect(tester.widget<SoriButton>(assessing).onTap, isNull);
    expect(find.text('Recording…'), findsNothing);

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 20 && gateway.calls == 0; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    expect(gateway.calls, 1);
    gateway.complete();
    await tester.runAsync(() async {
      for (
        var attempt = 0;
        attempt < 20 && Storage.pronunciationPassCount == 0;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
    expect(Storage.pronunciationPassCount, 1);

    final scorePanel = find.byKey(const Key('pronunciation-score-panel'));
    await _scrollUntilBuilt(tester, scorePanel);
    expect(scorePanel, findsOneWidget);
    final scoreFinder = find.descendant(
      of: scorePanel,
      matching: find.text('88'),
    );
    final scoreText = tester.widget<Text>(scoreFinder);
    final type = SoriTextTheme.of(tester.element(scoreFinder));
    expect(scoreText.style?.fontFamily, type.numeral.fontFamily);
    expect(scoreText.style?.fontWeight, type.numeral.fontWeight);
    expect(
      tester
          .widgetList<SoriCard>(find.byType(SoriCard))
          .where((card) => card.variant == SoriCardVariant.hero),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(ListView).first;
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -160));
    await tester.pump();
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pump();
  }
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
}) {
  return MaterialApp(
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
  );
}

class _FakeRecorder implements PronunciationRecorder {
  _FakeRecorder({required this.permission, this.chunks = const []});

  final bool permission;
  final List<Uint8List> chunks;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async =>
      Stream<Uint8List>.fromIterable(chunks);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _DelayedGateway implements PronunciationAssessmentGateway {
  final Completer<PronunciationAssessmentResult> _completer = Completer();
  int calls = 0;
  String? _assessmentId;

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) {
    calls++;
    _assessmentId = assessmentId;
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      PronunciationAssessmentResult(
        assessmentId: _assessmentId!,
        pronunciationScore: 88,
        accuracyScore: 90,
        fluencyScore: 86,
        completenessScore: 89,
      ),
    );
  }
}
