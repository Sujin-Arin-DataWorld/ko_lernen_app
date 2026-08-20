import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets(
    'study frame keeps focused content reachable across the responsive matrix',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      for (final size in const <Size>[
        Size(320, 640),
        Size(360, 400),
        Size(390, 844),
        Size(720, 1024),
        Size(1280, 900),
      ]) {
        for (final textScale in const <double>[1, 1.3, 1.6, 2]) {
          tester.view.physicalSize = size;
          var taps = 0;

          await tester.pumpWidget(
            _host(
              textScale: textScale,
              child: SoriStudyFrame(
                title: 'Grammatik erkennen und sicher anwenden',
                eyebrow: 'Freies Training',
                child: ListView(
                  children: [
                    const SizedBox(
                      key: Key('study-frame-width-marker'),
                      width: double.infinity,
                      height: 700,
                    ),
                    FilledButton(
                      key: const Key('study-frame-final-action'),
                      onPressed: () => taps += 1,
                      child: const Text(
                        'Antwort prüfen und mit der nächsten Aufgabe fortfahren',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(SoriAppBar), findsOneWidget);
          expect(find.byType(SoriScreenBackground), findsOneWidget);
          expect(tester.takeException(), isNull);

          final marker = find.byKey(const Key('study-frame-width-marker'));
          expect(tester.getSize(marker).width, lessThanOrEqualTo(760));

          final action = find.byKey(const Key('study-frame-final-action'));
          await tester.scrollUntilVisible(
            action,
            240,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(action);
          await tester.pump();
          expect(
            tester.getRect(action).bottom,
            lessThanOrEqualTo(size.height - 34),
          );
          await tester.tap(action);
          await tester.pump();
          expect(taps, 1);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

Widget _host({required double textScale, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}
