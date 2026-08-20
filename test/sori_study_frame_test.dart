import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets('short 100% title preserves the legacy toolbar geometry', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);

    await tester.pumpWidget(
      _host(
        textScale: 1,
        child: const SoriStudyFrame(
          title: 'Wortschatz',
          child: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
    final title = tester.widget<Text>(find.text('Wortschatz'));
    expect(appBar.preferredSize.height, kToolbarHeight);
    expect(title.maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360dp app bar preserves legacy geometry with two actions', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          appBar: const SoriAppBar(
            title: 'Vokabel-Pakete',
            textScale: 1,
            viewportWidth: 360,
            actions: [
              IconButton(onPressed: null, icon: Icon(Icons.star)),
              IconButton(onPressed: null, icon: Icon(Icons.swap_horiz)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
    final title = tester.widget<Text>(find.text('Vokabel-Pakete'));
    expect(appBar.preferredSize.height, kToolbarHeight);
    expect(title.maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal-scale long app bar copy wraps without truncation', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    const title =
        'Persönliche Lernsammlung aufmerksam bearbeiten und fortsetzen';
    const eyebrow = 'Aus deinem koreanischen Lernweg';
    await tester.pumpWidget(
      _host(
        textScale: 1,
        child: const SoriStudyFrame(
          title: title,
          eyebrow: eyebrow,
          child: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
    final titleText = tester.widget<Text>(find.text(title));
    final eyebrowText = tester.widget<Text>(find.text(eyebrow));
    final titleParagraph = tester.renderObject<RenderParagraph>(
      find.text(title),
    );
    final eyebrowParagraph = tester.renderObject<RenderParagraph>(
      find.text(eyebrow),
    );

    expect(appBar.preferredSize.height, greaterThan(kToolbarHeight));
    expect(titleText.maxLines, greaterThan(1));
    expect(titleText.overflow, TextOverflow.clip);
    expect(eyebrowText.overflow, TextOverflow.clip);
    expect(titleParagraph.didExceedMaxLines, isFalse);
    expect(eyebrowParagraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study frame app bar preserves its full title at 200% text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);

    const title = 'Grammatik erkennen und sicher anwenden';
    await tester.pumpWidget(
      _host(
        textScale: 2,
        child: const SoriStudyFrame(
          title: title,
          eyebrow: 'Freies Training',
          child: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
    final titleText = tester.widget<Text>(find.text(title));
    final titleParagraph = tester.renderObject<RenderParagraph>(
      find.text(title),
    );
    expect(appBar.preferredSize.height, greaterThan(kToolbarHeight));
    expect(titleText.maxLines, greaterThan(1));
    expect(titleText.overflow, TextOverflow.clip);
    expect(titleParagraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

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
                  key: ValueKey('$size-$textScale'),
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
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
          final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
          final titleText = tester.widget<Text>(
            find.text('Grammatik erkennen und sicher anwenden'),
          );
          final actionParagraph = tester.renderObject<RenderParagraph>(
            find.text('Antwort prüfen und mit der nächsten Aufgabe fortfahren'),
          );
          expect(
            tester.getRect(action).bottom,
            lessThanOrEqualTo(size.height - 34),
            reason:
                '$size at ${textScale}x, scroll '
                '${position.pixels}/${position.maxScrollExtent}, '
                'viewport ${position.viewportDimension}, '
                'app bar ${appBar.preferredSize.height}, '
                'title lines ${titleText.maxLines}',
          );
          expect(actionParagraph.didExceedMaxLines, isFalse);
          final actionRect = tester.getRect(action);
          await tester.tapAt(
            Offset(actionRect.center.dx, actionRect.bottom - 8),
          );
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
