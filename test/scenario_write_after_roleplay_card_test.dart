import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/korean_proofreading_service.dart';
import 'package:ko_lernen_app/services/scenario_writing_check_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_write_after_roleplay_card.dart';

void main() {
  Widget app({
    required ScenarioWritingCheckService service,
    ScenarioWritingEvidence? evidence,
    CompanionPreference? companion,
    TextScaler? textScaler,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ScenarioWriteAfterRoleplayCard(
          evidence: evidence ?? _evidence,
          service: service,
          previewCompanion: companion,
        ),
      ),
    ),
  );

  testWidgets('shows original and suggestion without replacing learner input', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.available,
      ),
      result: const KoreanProofreadingResult(
        status: KoreanProofreadingStatus.completed,
        originalText: '저는 내일 공부할 거에요.',
        suggestion: '저는 내일 공부할 거예요.',
      ),
    );
    await tester.pumpWidget(
      app(service: ScenarioWritingCheckService(gateway: gateway)),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 내일 공부할 거에요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('scenario-write-comparison')),
      findsOneWidget,
    );
    expect(find.text('Your original'), findsOneWidget);
    expect(find.text('Suggestion'), findsOneWidget);
    expect(find.text('저는 내일 공부할 거예요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('scenario-write-changes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-change-0')),
      findsOneWidget,
    );
    expect(find.text('거에요'), findsOneWidget);
    expect(find.text('거예요'), findsOneWidget);
    expect(
      find.text(
        'The on-device checker does not provide a verified reason for each change.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-ask-companion')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('scenario-write-ask-companion')),
      findsOneWidget,
    );
    expect(find.text('Reference grammar from this scene'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('scenario-write-input')),
    );
    expect(field.controller?.text, '저는 내일 공부할 거에요.');
    expect(field.maxLength, KoreanProofreadingService.maxInputCodePoints);
    expect(gateway.proofreadCalls, 1);
  });

  testWidgets('390px and large text stack comparison panels without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.available,
      ),
      result: const KoreanProofreadingResult(
        status: KoreanProofreadingStatus.completed,
        originalText: '저는 학쌩이고 내일 가게요.',
        suggestion: '저는 학생이고 내일 갈게요.',
      ),
    );
    await tester.pumpWidget(
      app(
        service: ScenarioWritingCheckService(gateway: gateway),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 학쌩이고 내일 가게요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('scenario-write-comparison-vertical')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-change-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-change-1')),
      findsOneWidget,
    );
    expect(find.text('학쌩이고'), findsOneWidget);
    expect(find.text('학생이고'), findsOneWidget);
    expect(find.text('가게요'), findsOneWidget);
    expect(find.text('갈게요'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('scenario-write-change-reason-boundary'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-ask-companion')),
      findsOneWidget,
    );
    expect(find.text('Reference grammar from this scene'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('download starts only after the explicit download button', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.downloadable,
      ),
      downloadAvailability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.available,
      ),
    );
    await tester.pumpWidget(
      app(service: ScenarioWritingCheckService(gateway: gateway)),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 내일 공부할 거예요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(gateway.downloadCalls, 0);
    expect(gateway.proofreadCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('scenario-write-download')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-download')),
    );
    await tester.pumpAndSettle();

    expect(gateway.downloadCalls, 1);
    expect(gateway.proofreadCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('scenario-write-ready')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-download')),
      findsNothing,
    );
  });

  testWidgets('downloading state never offers a second download action', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.downloading,
      ),
    );
    await tester.pumpWidget(
      app(service: ScenarioWritingCheckService(gateway: gateway)),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 내일 공부할 거예요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('scenario-write-download-required')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-download')),
      findsNothing,
    );
    expect(gateway.downloadCalls, 0);
  });

  testWidgets('unsupported checker falls back to authored scene evidence', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.unsupportedPlatform,
        error: KoreanProofreadingError.unavailable,
      ),
    );
    final service = ScenarioWritingCheckService(gateway: gateway);
    await tester.pumpWidget(
      app(service: service, companion: CompanionPreference.tiger),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 내일 공부할 거예요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('scenario-write-fallback')),
      findsOneWidget,
    );
    expect(
      find.textContaining('저는 내일 공부할 거예요. — I will study tomorrow.'),
      findsOneWidget,
    );
    expect(find.text('Future plan'), findsOneWidget);
    expect(find.text('Use -(으)ㄹ 거예요 for a plan.'), findsOneWidget);

    final companionButton = find.byKey(
      const ValueKey<String>('scenario-write-ask-companion'),
    );
    await tester.ensureVisible(companionButton);
    await tester.pumpAndSettle();
    await tester.tap(companionButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('scenario-write-companion-answer')),
      findsOneWidget,
    );
    expect(find.textContaining('Taego ·'), findsOneWidget);
    expect(find.text('Use -(으)ㄹ 거예요 for a plan.'), findsNWidgets(2));

    await tester.pumpWidget(
      app(service: service, companion: CompanionPreference.magpie),
    );
    await tester.pump();
    expect(find.textContaining('Joy ·'), findsOneWidget);
    expect(find.text('Use -(으)ㄹ 거예요 for a plan.'), findsNWidgets(2));
  });

  testWidgets('grammarIds alone never create a why or companion answer', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      availability: const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.unsupportedPlatform,
        error: KoreanProofreadingError.unavailable,
      ),
    );
    await tester.pumpWidget(
      app(
        service: ScenarioWritingCheckService(gateway: gateway),
        evidence: _evidenceWithoutGrammar,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scenario-write-input')),
      '저는 내일 공부할 거예요.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('scenario-write-check')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('저는 내일 공부할 거예요. — I will study tomorrow.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-declared-grammar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('scenario-write-ask-companion')),
      findsNothing,
    );
  });
}

final _evidence = ScenarioWritingEvidence(
  references: const <ScenarioWritingReference>[
    ScenarioWritingReference(
      korean: '저는 내일 공부할 거예요.',
      localizedMeaning: 'I will study tomorrow.',
    ),
  ],
  grammar: const ScenarioWritingDeclaredGrammar(
    title: 'Future plan',
    explanation: 'Use -(으)ㄹ 거예요 for a plan.',
  ),
);

final _evidenceWithoutGrammar = ScenarioWritingEvidence(
  references: const <ScenarioWritingReference>[
    ScenarioWritingReference(
      korean: '저는 내일 공부할 거예요.',
      localizedMeaning: 'I will study tomorrow.',
    ),
  ],
  grammar: null,
);

final class _FakeGateway implements ScenarioProofreadingGateway {
  _FakeGateway({
    required this.availability,
    this.downloadAvailability = const KoreanProofreadingAvailability(
      status: KoreanProofreadingStatus.available,
    ),
    this.result,
  });

  KoreanProofreadingAvailability availability;
  KoreanProofreadingAvailability downloadAvailability;
  KoreanProofreadingResult? result;
  int downloadCalls = 0;
  int proofreadCalls = 0;

  @override
  Future<KoreanProofreadingAvailability> check() async => availability;

  @override
  Future<KoreanProofreadingAvailability> download() async {
    downloadCalls++;
    return downloadAvailability;
  }

  @override
  Future<KoreanProofreadingResult> proofread(String originalText) async {
    proofreadCalls++;
    return result ??
        KoreanProofreadingResult(
          status: KoreanProofreadingStatus.completed,
          originalText: originalText,
          suggestion: originalText,
        );
  }

  @override
  Future<void> close() async {}
}
