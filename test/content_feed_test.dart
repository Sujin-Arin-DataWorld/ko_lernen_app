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

  testWidgets(
    'bookmark stamp announces saved state, not just the static action name',
    (tester) async {
      // 지시서 1.24 검수 finding #1: AppBar 중복 버튼을 지우며 이 스탬프를
      // 유일한 a11y 타깃으로 승격했으니, 담김 여부가 안내에 반영돼야 한다 —
      // 라벨("Merken")만으로는 스크린 리더가 담긴 것과 안 담긴 것을 구분 못했다.
      final semantics = tester.ensureSemantics();
      final t = await AppL10n.delegate.load(const Locale('de'));

      await tester.pumpWidget(
        wrap(
          SoriContentFeed(
            onBookmark: () {},
            bookmarked: false,
            child: const SizedBox.expand(child: Text('한국말')),
          ),
        ),
      );
      final unsaved = tester
          .getSemantics(find.bySemanticsLabel(t.contentActionBookmark))
          .getSemanticsData();
      expect(unsaved.label, t.contentActionBookmark, reason: '동작명은 그대로 유지');
      expect(unsaved.value, t.contentActionBookmarkUnsaved);

      await tester.pumpWidget(
        wrap(
          SoriContentFeed(
            onBookmark: () {},
            bookmarked: true,
            child: const SizedBox.expand(child: Text('한국말')),
          ),
        ),
      );
      final saved = tester
          .getSemantics(find.bySemanticsLabel(t.contentActionBookmark))
          .getSemanticsData();
      expect(saved.value, t.contentActionBookmarkSaved);
      expect(
        saved.value,
        isNot(unsaved.value),
        reason: '담김 전/후 안내가 달라야 한다 — 라벨이 같아도 값이 상태를 말해야 함',
      );

      semantics.dispose();
    },
  );

  testWidgets('snap physics: revealed fling still calls onNext after animation', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          physics: FeedPhysics.snap,
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

  testWidgets('snap physics + reduce motion: commits instantly (no lingering animation)', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
          child: Scaffold(
            body: SoriContentFeed(
              physics: FeedPhysics.snap,
              onNext: () => next++,
              child: const SizedBox.expand(child: Text('한국말')),
            ),
          ),
        ),
      ),
    );
    await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
    await tester.pump();
    expect(next, 1); // 애니메이션 없이 즉시
  });
}
