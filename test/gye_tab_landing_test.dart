import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/gye_hanok.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

void main() {
  setUp(() async {
    TigerStageVideo.videoReady = false;
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
    expect(find.byType(GyeShowcaseArtwork), findsOneWidget);
    expect(
      find.byType(GyeHanok),
      findsNothing,
      reason: '빈 화면은 진행도 레이어 8장을 한꺼번에 합성하지 않는다',
    );
    final showcase = tester.widget<Image>(
      find.byKey(const ValueKey('gye-showcase-artwork')),
    );
    expect((showcase.image as AssetImage).assetName, GyeShowcaseArtwork.asset);
    expect(
      GyeShowcaseArtwork.videoAsset,
      'assets/video/gye/gye_shared_hanok_build.mp4',
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

  testWidgets(
    'standalone Gye keeps chrome and courtyard names complete at 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const courtyardName =
          'Mondhof für geduldige Lernende, die jeden Abend gemeinsam üben';

      await _pump(
        tester,
        () async => const [
          GyeMeta(
            id: 'ABC234',
            name: courtyardName,
            code: 'ABC234',
            ownerId: 'owner',
          ),
        ],
        textScale: 2,
        safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
      );

      expect(find.byType(SoriAppBar), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(courtyardName),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final name = tester.widget<Text>(find.text(courtyardName));
      expect(name.maxLines, isNull);
      expect(name.overflow, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('parent rebuild reuses one Gye load future', (tester) async {
    var loads = 0;
    Future<List<GyeMeta>> loader() async {
      loads++;
      return const <GyeMeta>[];
    }

    await _pump(tester, loader);
    expect(loads, 1);
    await _pump(tester, loader);
    expect(loads, 1);
  });

  testWidgets('Gye load failure is not disguised as an empty membership', (
    tester,
  ) async {
    await _pump(tester, () async => throw StateError('offline'), settle: false);

    expect(find.byType(AppError), findsOneWidget);
    expect(find.text('Freiwillige Lerngemeinschaft'), findsNothing);
  });

  testWidgets('inactive embedded Gye loads only when activated', (
    tester,
  ) async {
    var loads = 0;
    Future<List<GyeMeta>> loader() async {
      loads++;
      return const <GyeMeta>[];
    }

    await _pump(tester, loader, active: false, settle: false);
    expect(loads, 0);
    await _pump(tester, loader, active: true);
    expect(loads, 1);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Future<List<GyeMeta>> Function() loadGyeMetas, {
  VoidCallback? onFindOrCreate,
  VoidCallback? onContinueSolo,
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
  bool active = true,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: GyeTabScreen(
        loadGyeMetas: loadGyeMetas,
        onFindOrCreate: onFindOrCreate,
        onContinueSolo: onContinueSolo,
        enableCoach: false,
        active: active,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}
