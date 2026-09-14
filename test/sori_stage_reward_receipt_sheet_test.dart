import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

void main() {
  testWidgets('receipt sheet renders only observed items', (tester) async {
    await tester.pumpWidget(
      _app(
        SoriStageRewardReceiptSheet(
          receipt: const RewardReceipt(
            activityId: 'course',
            receiptId: 'receipt-1',
            items: <RewardReceiptItem>[
              RewardReceiptItem(
                kind: SoriRewardKind.xp,
                amount: 20,
                label: SoriLocalizedCopy(
                  key: SoriCopyKey.rewardXp,
                  de: 'Lern-XP',
                  en: 'XP',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('+20 XP'), findsOneWidget);
    expect(find.textContaining('Hanok building piece'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Earned rewards' &&
            widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('receipt sheet closes via close button', (tester) async {
    const receipt = RewardReceipt(
      activityId: 'course',
      receiptId: 'receipt-1',
      items: <RewardReceiptItem>[
        RewardReceiptItem(
          kind: SoriRewardKind.xp,
          amount: 20,
          label: SoriLocalizedCopy(
            key: SoriCopyKey.rewardXp,
            de: 'Lern-XP',
            en: 'XP',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSoriStageRewardReceipt(context, receipt),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SoriStageRewardReceiptSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt-close')));
    await tester.pumpAndSettle();

    expect(find.byType(SoriStageRewardReceiptSheet), findsNothing);
  });

  testWidgets(
    'multi-unit receipt reveals every gained stage at 320dp and 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const receipt = RewardReceipt(
        activityId: 'course',
        receiptId: 'receipt-construction',
        items: <RewardReceiptItem>[
          RewardReceiptItem(
            kind: SoriRewardKind.hanokProgress,
            amount: 2,
            label: SoriLocalizedCopy(
              key: SoriCopyKey.rewardHanokPiece,
              de: 'Neues Hanok-Bauteil',
              en: 'New Hanok building piece',
            ),
          ),
        ],
        sarangchaeStageBefore: 13,
        sarangchaeStageAfter: 15,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSoriStageRewardReceipt(context, receipt),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('2 new construction stages'), findsOneWidget);
      expect(find.text('Stage 13 → stage 15'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sarangchae-stage-choice-14')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sarangchae-stage-choice-15')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sarangchae-before-artwork')),
          matching: find.byKey(const ValueKey('sarangchae-stage-artwork-13')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sarangchae-after-artwork')),
          matching: find.byKey(const ValueKey('sarangchae-stage-artwork-15')),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('창호'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sarangchae-stage-choice-14')),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.byKey(const ValueKey('sarangchae-stage-choice-14')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('누마루'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sarangchae-lesson-language')),
        -120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.byKey(const ValueKey('sarangchae-lesson-language')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('한국어').last);
      await tester.pumpAndSettle();
      expect(find.text('바람을 맞는 마루'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an updated receipt starts the construction load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final construction = _constructionFixture();
    var loads = 0;
    Future<SarangchaeConstruction> loadConstruction() {
      loads++;
      return Future.value(construction);
    }

    Widget sheet(RewardReceipt receipt) => _app(
      SoriStageRewardReceiptSheet(
        receipt: receipt,
        loadConstruction: loadConstruction,
      ),
    );

    await tester.pumpWidget(
      sheet(
        const RewardReceipt(
          activityId: 'course',
          receiptId: 'before',
          items: <RewardReceiptItem>[],
        ),
      ),
    );
    expect(loads, 0);

    await tester.pumpWidget(
      sheet(
        const RewardReceipt(
          activityId: 'course',
          receiptId: 'after',
          items: <RewardReceiptItem>[],
          sarangchaeStageBefore: 1,
          sarangchaeStageAfter: 2,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(loads, 1);
    expect(find.byType(SarangchaeConstructionExperience), findsOneWidget);
  });

  testWidgets(
    'B2 crossing receipt shows actual before-after assets and Korean terms',
    (tester) async {
      final catalog = _b2CatalogFixture();
      await tester.pumpWidget(
        _app(
          SoriStageRewardReceiptSheet(
            receipt: const RewardReceipt(
              activityId: 'course',
              receiptId: 'b2-crossing',
              items: [],
              b2ConstructionStageBefore: 11,
              b2ConstructionStageAfter: 17,
            ),
            loadConstructionArt: () async => catalog,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('construction-reveal-ansarangchae')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('construction-reveal-sadangmun')),
        findsOneWidget,
      );
      expect(find.text('부재 14'), findsOneWidget);
      expect(find.text('부재 3'), findsOneWidget);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(3));
      expect(
        images.map((image) => (image.image as AssetImage).assetName),
        containsAll(<String>[
          'assets/illustrations/personal_hanok_v3/construction/ansarangchae/stage_11_part.png',
          'assets/illustrations/personal_hanok_v3/construction/ansarangchae/stage_14_part.png',
          'assets/illustrations/personal_hanok_v3/construction/sadangmun/stage_03_part.png',
        ]),
      );
    },
  );
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: home),
);

SarangchaeConstruction
_constructionFixture() => SarangchaeConstruction.fromJson({
  'id': 'sarangchae-v3-16',
  'canonicalSha256': SarangchaeConstruction.canonicalSha256,
  'completedStage': SarangchaeConstruction.stageCount,
  'stages': [
    for (
      var sequence = 1;
      sequence <= SarangchaeConstruction.stageCount;
      sequence++
    )
      {
        'stageId': sequence == SarangchaeConstruction.stageCount
            ? 'sarangchae-complete'
            : 'stage-$sequence',
        'sequence': sequence,
        'assetPath':
            'assets/illustrations/personal_hanok_v3/sarangchae/stage_01_site.png',
        'sha256': sequence == SarangchaeConstruction.stageCount
            ? SarangchaeConstruction.canonicalSha256
            : 'fixture-$sequence',
        'term': '부재',
        for (final field in const [
          'gloss',
          'chapter',
          'title',
          'question',
          'body',
          'caption',
        ])
          field: const {'ko': '설명', 'en': 'Detail', 'de': 'Detail'},
      },
  ],
});

IlDuConstructionArtCatalog _b2CatalogFixture() => IlDuConstructionArtCatalog([
  _series('ansarangchae', 'ansarang', 14),
  _series('sadangmun', 'sadang-gate', 8),
  _series('sadang', 'sadang', 12),
]);

IlDuConstructionArtSeries _series(
  String id,
  String anchor,
  int count,
) => IlDuConstructionArtSeries(
  id: id,
  mapAnchorId: anchor,
  name: {'ko': id, 'en': id, 'de': id},
  culture: const {'ko': '문화', 'en': 'Culture', 'de': 'Kultur'},
  stages: [
    for (var sequence = 1; sequence <= count; sequence++)
      IlDuConstructionArtStage(
        id: '$id-part-$sequence',
        sequence: sequence,
        asset:
            'assets/illustrations/personal_hanok_v3/construction/$id/'
            'stage_${sequence.toString().padLeft(2, '0')}_part.png',
        sha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        width: id == 'sadangmun' ? 1086 : 1536,
        height: id == 'sadangmun' ? 1448 : 1024,
        title: {
          'ko': '부재 $sequence',
          'en': 'Part $sequence',
          'de': 'Bauteil $sequence',
        },
        observe: const {
          'ko': '짧은 설명',
          'en': 'Short explanation',
          'de': 'Kurze Erklärung',
        },
        line: const {'ko': '문장', 'en': 'Line', 'de': 'Satz'},
        scene: const {'ko': '장면', 'en': 'Scene', 'de': 'Szene'},
        task: const {'ko': '보기', 'en': 'Read', 'de': 'Lesen'},
        options: const {},
        correctOptionId: null,
        glossary: [
          (
            label: {
              'ko': '부재 $sequence',
              'en': 'Part $sequence',
              'de': 'Bauteil $sequence',
            },
            explanation: const {
              'ko': '짧은 설명',
              'en': 'Short explanation',
              'de': 'Kurze Erklärung',
            },
          ),
        ],
      ),
  ],
);
