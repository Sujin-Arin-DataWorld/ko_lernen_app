import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
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
    expect(find.textContaining('Voice assessment is off'), findsOneWidget);
  });

  testWidgets('microphone denial does not remove basic practice controls', (
    tester,
  ) async {
    await Storage.setPronunciationConsent(true);
    final recorder = _FakeRecorder(permission: false);
    await tester.pumpWidget(_app(recorder));

    tester
        .widget<SoriButton>(find.widgetWithText(SoriButton, 'Record my voice'))
        .onTap!();
    await tester.pumpAndSettle();

    expect(recorder.permissionRequests, 1);
    expect(
      find.textContaining('Microphone access was not granted'),
      findsOneWidget,
    );
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
      expect(find.textContaining('score is unavailable'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
    },
  );
}

Widget _app(
  PronunciationRecorder recorder, {
  PronunciationAssessmentGateway? gateway,
}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppL10n.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppL10n.supportedLocales,
  home: PronunciationStudioScreen(recorder: recorder, gateway: gateway),
);

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
