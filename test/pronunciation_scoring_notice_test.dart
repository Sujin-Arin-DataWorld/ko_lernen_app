import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// W10 T-P1 (Jin 결정): 클라우드 채점이 꺼져 있을 때는 마이크를 누르기 전에
/// "채점이 아직 없다"는 안내가 먼저 보여야 한다. 채점이 켜져 있으면 안내는
/// 사라지고 기존 "점수 요청" 버튼 경로는 그대로 남는다.
void main() {
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  tearDown(SoriSpeech.resetForTesting);

  testWidgets(
    'cloud assessment disabled shows the scoring-soon notice and hides '
    'the request-score button',
    (tester) async {
      final t = lookupAppL10n(const Locale('en'));
      final recorder = _FakeRecorder(permission: true);
      await tester.pumpWidget(_app(recorder, cloudAssessmentEnabled: false));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pronunciation-scoring-soon-notice')),
        findsOneWidget,
      );
      expect(find.text(t.pronunciationScoringSoonTitle), findsOneWidget);
      expect(find.text(t.pronunciationRequestScore), findsNothing);
    },
  );

  testWidgets(
    'cloud assessment enabled hides the scoring-soon notice',
    (tester) async {
      final recorder = _FakeRecorder(permission: true);
      await tester.pumpWidget(_app(recorder, cloudAssessmentEnabled: true));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pronunciation-scoring-soon-notice')),
        findsNothing,
      );
    },
  );
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
  required bool cloudAssessmentEnabled,
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
    cloudAssessmentEnabled: cloudAssessmentEnabled,
    phraseLoader: _loadTestPhrases,
  ),
);

Future<List<PronunciationPhrase>> _loadTestPhrases() async => _testPhrases;

class _FakeRecorder implements PronunciationRecorder {
  _FakeRecorder({required this.permission});

  final bool permission;
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
    return const Stream<Uint8List>.empty();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
