import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_gye_tab': true});
    await Storage.init();
  });

  testWidgets('empty Gye landing makes participation and visibility optional', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    var chooserCalls = 0;
    var soloCalls = 0;
    await _pump(
      tester,
      () async => const <GyeMeta>[],
      onFindOrCreate: () => chooserCalls++,
      onContinueSolo: () => soloCalls++,
      textScale: 1.3,
    );

    expect(find.text('Freiwillige Lerngemeinschaft'), findsOneWidget);
    expect(
      find.text('Allein lernen ist vollständig. Zusammen kann es wärmer sein.'),
      findsOneWidget,
    );
    // §P5-1 (2026-08-14, 의도된 변경): 문단 3개 → 1줄 칩 카드. 장문 설명은
    // 삭제되지 않고 ⓘ 상세 시트로 강등됐다 (§C-2 원칙).
    await tester.scrollUntilVisible(
      find.text('Eine kleine, freiwillige Lerngruppe.'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Eine kleine, freiwillige Lerngruppe.'), findsOneWidget);
    // ⓘ 시트: 강등된 장문 3종 + 프라이버시 본문이 전부 도달 가능하다.
    await tester.ensureVisible(find.byTooltip('Mehr erfahren'));
    await tester.pump();
    await tester.tap(find.byTooltip('Mehr erfahren'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Eine 계 (Gye) ist eine kleine Lerngruppe, ganz freiwillig. '
        'Allein zu lernen ist genauso gut.',
      ),
      findsOneWidget,
      reason: '장문 gyeExplainWhat 은 ⓘ 시트에서 살아 있어야 한다 (키 삭제 금지)',
    );
    expect(
      find.textContaining('bleiben privat'),
      findsOneWidget,
      reason:
          'gyePrivacyBody 는 기여 사실만 공개되고 답변·단어·평가 결과는 '
          '비공개임을 말해야 한다',
    );
    await tester.tapAt(const Offset(5, 5)); // 시트 밖 탭 = 닫기
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Was andere sehen'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Was andere sehen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Eine 계 finden oder gründen'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Eine 계 finden oder gründen'), findsOneWidget);
    final chooser = find.byType(SoriButton);
    expect(tester.getSize(chooser).height, greaterThanOrEqualTo(48));
    final chooserSemantics = tester.getSemantics(chooser).getSemanticsData();
    expect(chooserSemantics.label, 'Eine 계 finden oder gründen');
    expect(chooserSemantics.hasAction(SemanticsAction.tap), isTrue);
    await tester.scrollUntilVisible(
      find.text('Ohne Gruppe weiterlernen'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ohne Gruppe weiterlernen'), findsOneWidget);
    tester.widget<SoriButton>(find.byType(SoriButton)).onTap!();
    tester.widget<TextButton>(find.byType(TextButton)).onPressed!();
    expect(chooserCalls, 1);
    expect(soloCalls, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('existing Gye list keeps the optional shared-courtyard context', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => const [
        GyeMeta(
          id: 'ABC234',
          name: 'Mondhof',
          code: 'ABC234',
          ownerId: 'owner',
        ),
      ],
    );

    expect(find.text('Euer Hof'), findsOneWidget);
    expect(find.textContaining('Wochenziel-Daten'), findsOneWidget);
    expect(find.text('Mondhof'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Future<List<GyeMeta>> Function() loadGyeMetas, {
  VoidCallback? onFindOrCreate,
  VoidCallback? onContinueSolo,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: GyeTabScreen(
        loadGyeMetas: loadGyeMetas,
        onFindOrCreate: onFindOrCreate,
        onContinueSolo: onContinueSolo,
        enableCoach: false,
      ),
    ),
  );
  // The existing shared-hanok preview intentionally has a repeating pulse,
  // so `pumpAndSettle` would never terminate here.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
