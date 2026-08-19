import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

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
}
