import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/tts_unavailable_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(TtsService.clearUnavailable);

  test(
    'hourly callable denial is distinct and never retries synthesis',
    () async {
      for (final error in <Object>[
        FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'Hourly synthesis limit reached.',
          details: const {'reason': 'quota_global_hour'},
        ),
        const TtsCallableProbe(
          code: 'functions/resource-exhausted',
          details: {'reason': 'quota_global_hour'},
        ),
      ]) {
        var calls = 0;
        await expectLater(
          TtsService.takeCallableAudio(
            invoke: () async {
              calls++;
              throw error;
            },
          ),
          throwsA(
            isA<TtsSynthesisBlocked>().having(
              (blocked) => blocked.reason,
              'reason',
              TtsUnavailableReason.hourlyQuota,
            ),
          ),
        );
        expect(calls, 1);
      }
    },
  );

  test('unknown details keep the legacy daily quota contract', () {
    for (final details in <Object?>[
      null,
      'quota_global_hour',
      25,
      <String, Object>{},
      {'reason': 'quota_global'},
      {
        'reason': ['quota_global_hour'],
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
        code: 'internal',
        details: const {'reason': 'quota_global_hour'},
      ),
      TtsCallableKind.fallback,
    );
    expect(
      TtsCallableFailure.classify(
        code: 'unavailable',
        message: TtsCallableFailure.audioUnavailableMessage,
      ),
      TtsCallableKind.blockUnavailable,
      reason: 'Legacy availability responses must not retry or say tomorrow.',
    );
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      '${locale.languageCode} hourly banner avoids tomorrow at 320dp/200%',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final t = await AppL10n.delegate.load(locale);
        TtsService.unavailable.value = TtsUnavailableReason.hourlyQuota;
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
        expect(find.text(t.ttsUnavailableHourlyQuota), findsOneWidget);
        expect(find.text(t.ttsUnavailableQuota), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
