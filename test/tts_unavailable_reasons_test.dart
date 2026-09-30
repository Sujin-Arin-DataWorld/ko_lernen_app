import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/tts_unavailable_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(TtsService.clearUnavailable);

  test('session and service policy denials stop after one callable', () async {
    for (final (code, details, reason) in [
      ('unauthenticated', null, TtsUnavailableReason.sessionUnavailable),
      (
        'functions/unauthenticated',
        {'reason': 'session_unavailable'},
        TtsUnavailableReason.sessionUnavailable,
      ),
      (
        'unavailable',
        {'reason': 'service_policy'},
        TtsUnavailableReason.servicePolicy,
      ),
      (
        'resource-exhausted',
        {'reason': 'service_policy'},
        TtsUnavailableReason.servicePolicy,
      ),
    ]) {
      var calls = 0;
      await expectLater(
        TtsService.takeCallableAudio(
          invoke: () async {
            calls++;
            throw FirebaseFunctionsException(
              code: code,
              message: 'Request rejected.',
              details: details,
            );
          },
        ),
        throwsA(
          isA<TtsSynthesisBlocked>().having(
            (blocked) => blocked.reason,
            'reason',
            reason,
          ),
        ),
      );
      expect(calls, 1);
    }
  });

  test(
    'policy details do not override unrelated failures or old quota codes',
    () {
      expect(
        TtsCallableFailure.classify(
          code: 'permission-denied',
          details: const {'reason': 'service_policy'},
        ),
        TtsCallableKind.fallback,
      );
      for (final details in [
        null,
        'service_policy',
        {
          'reason': ['service_policy'],
        },
      ]) {
        expect(
          TtsCallableFailure.classify(
            code: 'resource-exhausted',
            details: details,
          ),
          TtsCallableKind.blockQuota,
        );
      }
      expect(
        TtsCallableFailure.classify(
          code: 'unavailable',
          message: 'AI cost approval unavailable.',
        ),
        TtsCallableKind.fallback,
        reason: 'Unknown legacy messages must not invent a policy diagnosis.',
      );
    },
  );

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final reason in [
      TtsUnavailableReason.sessionUnavailable,
      TtsUnavailableReason.servicePolicy,
    ]) {
      testWidgets('${locale.languageCode} $reason banner at 320dp/200%', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final t = await AppL10n.delegate.load(locale);
        TtsService.unavailable.value = reason;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const TtsUnavailableBanner(
              child: Scaffold(body: Text('content')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            reason == TtsUnavailableReason.sessionUnavailable
                ? t.ttsUnavailableSession
                : t.ttsUnavailablePolicy,
          ),
          findsOneWidget,
        );
        expect(find.text(t.ttsUnavailableOffline), findsNothing);
        expect(find.text(t.ttsUnavailableQuota), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
