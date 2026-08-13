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
                label: SoriLocalizedCopy(de: 'Lern-XP', en: 'Learning XP'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('+20 Learning XP'), findsOneWidget);
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
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: home),
);
