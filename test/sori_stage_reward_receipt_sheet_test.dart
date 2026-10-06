import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_reward_moment.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  for (final readFails in [false, true]) {
    testWidgets(
      'confirmed recovery without baseline survives read failure=$readFails',
      (tester) async {
        final wallet =
            YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0).copyWith(
              balance: 70,
              claims: {'historical:paid': 50, 'daily:2026-10-04:first': 20},
              completedSourceIds: {'lesson:pending'},
            );
        final receipt = RewardReceipt(
          activityId: 'lesson',
          receiptId: 'no-baseline',
          items: [],
          pendingYeopjeon: YeopjeonPendingReward(
            sourceIds: {'lesson:pending'},
            baselineClaimIds: {},
            hasClaimBaseline: false,
          ),
        );
        await tester.pumpWidget(
          _app(
            SoriStageRewardReceiptSheet(
              receipt: receipt,
              recoverYeopjeon: () async => YeopjeonTransactionResult(
                status: YeopjeonTransactionStatus.granted,
                amount: 20,
                wallet: wallet,
                confirmedClaimIds: ['daily:2026-10-04:first'],
              ),
              verifyYeopjeon: () async {
                if (readFails) {
                  throw StateError('optional read unavailable');
                }
                return wallet;
              },
            ),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('receipt-recheck-yeopjeon')),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('+20'), findsOneWidget);
        expect(find.text('+70'), findsNothing);
        expect(find.text('Wallet balance: 70 yeopjeon'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('receipt-yeopjeon-pending')),
          findsNothing,
        );
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('reward card keyboard action opens details and its progress CTA', (
    tester,
  ) async {
    const receipt = RewardReceipt(
      activityId: 'lesson',
      receiptId: 'xp-detail',
      items: [
        RewardReceiptItem(
          kind: SoriRewardKind.xp,
          amount: 10,
          label: SoriLocalizedCopy(de: 'Lern-XP', en: 'XP'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        routes: {
          '/stats': (_) =>
              const Scaffold(body: Text('Actual progress destination')),
        },
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
    final row = find.text('+10 XP');
    expect(row.hitTestable(), findsOneWidget);
    Focus.of(tester.element(row)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'These XP come from your completed learning. They count toward your learning progress.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('View learning progress'));
    await tester.pumpAndSettle();
    expect(find.text('Actual progress destination'), findsOneWidget);
    expect(find.byType(SoriStageRewardReceiptSheet), findsNothing);
  });
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

      expect(
        find.byKey(const ValueKey('receipt-continue')).hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Stage 13 → stage 15'), findsOneWidget);
      // The production bundle reads a real file outside the fake frame clock.
      await tester.runAsync(SarangchaeConstruction.load);
      await tester.pump();
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

  testWidgets(
    'an updated receipt loads construction only after its explicit action',
    (tester) async {
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

      expect(loads, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(loads, 1);
      expect(find.byType(SarangchaeConstructionExperience), findsOneWidget);
    },
  );

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

      await tester.ensureVisible(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('receipt-construction-details')),
      );
      await tester.pump();
      await tester.pump();
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
      expect(
        images,
        hasLength(3),
      ); // Only the three actually earned construction parts.
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
  testWidgets(
    'pending-only receipt preserves learning and retries ledger verification',
    (tester) async {
      final pending = YeopjeonPendingReward(
        sourceIds: {'unit:test'},
        baselineClaimIds: {},
      );
      var checks = 0;
      final wallet = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0)
          .copyWith(
            balance: 20,
            claims: {'daily:2026-10-04:first': 20},
            completedSourceIds: {'unit:test'},
          );
      final receipt = RewardReceipt(
        activityId: 'course',
        receiptId: 'pending',
        items: [],
        pendingYeopjeon: pending,
      );
      expect(receipt.isEmpty, isFalse);
      await tester.pumpWidget(
        _app(
          SoriStageRewardReceiptSheet(
            receipt: receipt,
            verifyYeopjeon: () async {
              checks++;
              if (checks == 1) {
                throw StateError('read unavailable');
              }
              return wallet;
            },
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('receipt-yeopjeon-pending')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('receipt-continue')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('receipt-recheck-yeopjeon')));
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('receipt-yeopjeon-pending')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('receipt-recheck-yeopjeon')));
      await tester.pump();
      await tester.pump();
      expect(checks, 2);
      expect(
        find.byKey(const ValueKey('receipt-yeopjeon-pending')),
        findsNothing,
      );
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('Wallet balance: 20 yeopjeon'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'retry after unshown excludes the natively displayed first claim',
    (tester) async {
      final observer = LearningJourneyObserver();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      final attempt = journey.beginAttempt()..complete();
      const first = 'daily:2026-10-04:first';
      const second = 'daily:2026-10-04:second';
      attempt.shown(SoriRewardKind.yeopjeon, 20, identity: first);
      final pending = YeopjeonPendingReward(
        sourceIds: {'lesson:second'},
        baselineClaimIds: {},
      );
      attempt.pendingReward(pending);
      expect(journey.pendingRewards.single.sourceIds, {'lesson:second'});
      final receipt = journey.unshown(
        RewardReceipt(
          activityId: 'course',
          receiptId: 'mixed-pending',
          pendingYeopjeon: pending,
          yeopjeonReward: YeopjeonRewardMoment(
            claims: {first: 20},
            balance: 20,
            source: YeopjeonRewardSource.currentActivity,
            day: '2026-10-04',
          ),
          items: const [
            RewardReceiptItem(
              kind: SoriRewardKind.yeopjeon,
              identity: first,
              amount: 20,
              label: SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
            ),
          ],
        ),
      );
      expect(receipt.yeopjeonReward, isNull);
      expect(receipt.pendingYeopjeon!.baselineClaimIds, contains(first));
      final wallet = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0)
          .copyWith(
            balance: 30,
            claims: {first: 20, second: 10},
            completedSourceIds: {'lesson:first', 'lesson:second'},
          );
      await tester.pumpWidget(
        _app(
          SoriStageRewardReceiptSheet(
            receipt: receipt,
            verifyYeopjeon: () async => wallet,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('receipt-recheck-yeopjeon')));
      await tester.pump();
      await tester.pump();
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('+30'), findsNothing);
      expect(find.text('+20'), findsNothing);
      expect(find.text('Wallet balance: 30 yeopjeon'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('receipt-yeopjeon-pending')),
        findsNothing,
      );
      attempt.pendingReward(null);
      expect(journey.pendingRewards, isEmpty);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpWidget(const SizedBox.shrink());
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
