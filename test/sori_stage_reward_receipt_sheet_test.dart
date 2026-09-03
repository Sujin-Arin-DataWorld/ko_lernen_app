import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';

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
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: home),
);
