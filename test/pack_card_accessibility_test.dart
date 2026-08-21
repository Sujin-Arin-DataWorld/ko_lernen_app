import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets(
    'locked hint uses the caption floor and remains complete at 200%',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 288,
                  height: 460,
                  child: PackCard(
                    packId: 'a1_02',
                    title: 'Unterwegs in der Stadt',
                    progress: PackProgress.fresh(
                      packId: 'a1_02',
                      level: 'A1',
                      wordsTotal: 10,
                      status: PackStatus.locked,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final t = AppL10n.of(tester.element(find.byType(PackCard)));
      final hint = find.text(t.packLockedHintShort);
      expect(hint, findsOneWidget);

      final hintText = tester.widget<Text>(hint);
      final caption = SoriTextTheme.of(tester.element(hint)).caption;
      expect(hintText.style?.fontSize, caption.fontSize);
      expect(
        tester.renderObject<RenderParagraph>(hint).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
