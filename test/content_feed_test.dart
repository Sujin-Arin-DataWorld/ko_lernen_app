import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: Scaffold(body: home),
      ),
    );
  }

  testWidgets('horizontal drag does not advance or judge', (tester) async {
    var next = 0;
    var hard = 0;
    var skip = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          judgmentsEnabled: true,
          onNext: () => next++,
          onHard: () => hard++,
          onSkip: () => skip++,
          knowLabel: 'Gewusst!',
          hardLabel: 'Nicht gewusst',
          skipLabel: 'Überspringen',
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    await tester.drag(find.text('한국말'), const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(next, 0);
    expect(hard, 0);
    expect(skip, 0);
  });

  testWidgets('unrevealed vertical fling skips, not know', (tester) async {
    var next = 0;
    var skip = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          judgmentsEnabled: false,
          onNext: () => next++,
          onSkip: () => skip++,
          knowLabel: 'Gewusst!',
          skipLabel: 'Überspringen',
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    await tester.fling(find.text('한국말'), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();
    expect(skip, 1);
    expect(next, 0);
  });

  testWidgets('revealed vertical fling up calls onNext', (tester) async {
    var next = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          judgmentsEnabled: true,
          onNext: () => next++,
          knowLabel: 'Gewusst!',
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    expect(next, 1);
  });

  testWidgets('like stamp does not call bookmark', (tester) async {
    var like = 0;
    var bookmark = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          onLike: () => like++,
          onBookmark: () => bookmark++,
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    final t = await AppL10n.delegate.load(const Locale('de'));
    await tester.tap(find.bySemanticsLabel(t.contentActionLike));
    await tester.pump();
    expect(like, 1);
    expect(bookmark, 0);
  });

  testWidgets('judgment labels stack without truncation at 320dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const hard = 'Das wusste ich noch nicht';
    const skip = 'Diese Aufgabe überspringen';
    const know = 'Das habe ich sicher gewusst';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SoriContentActions(
              onHard: () {},
              onSkip: () {},
              onKnow: () {},
              showFlip: false,
              showShare: false,
              showLike: false,
              showBookmark: false,
              flipLabel: 'Umdrehen',
              shareLabel: 'Teilen',
              likeLabel: 'Gefällt mir',
              bookmarkLabel: 'Speichern',
              hardLabel: hard,
              skipLabel: skip,
              knowLabel: know,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final hardRect = tester.getRect(find.byKey(deckActionKey('dontknow')));
    final skipRect = tester.getRect(find.byKey(deckActionKey('skip')));
    final knowRect = tester.getRect(find.byKey(deckActionKey('know')));
    expect(skipRect.top, greaterThan(hardRect.top));
    expect(knowRect.top, greaterThan(skipRect.top));
    for (final label in const [hard, skip, know]) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('bookmark stamp stays ink-colored even when saved (not accent)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          onBookmark: () {},
          bookmarked: true,
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
    expect(icon.color, isNot(SoriColors.like));
  });
}
