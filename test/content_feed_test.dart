import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets(
    'snap physics: underlay opacity returns to resting 0.18 after each commit (not pinned at 1.0)',
    (tester) async {
      // 리뷰 Important: _commit()의 whenComplete가 _dy는 0으로 되돌리면서
      // _snapCtrl은 그대로 뒀었다 — forward()는 1.0에서 끝나므로,
      // underlayOpacity(:288-290)가 커밋 이후 계속 1.0을 읽어 언더레이가
      // 완전 불투명에 고정된 채 다음 완전한 드래그 커밋 전까지 안 풀렸다.
      // disableAnimations를 켜지 않는다 — 켜면 reduce-motion 즉시 커밋
      // 경로로 빠져 _snapCtrl.forward()가 아예 호출되지 않아 이 버그를
      // 검증하지 못한다(기존 첫 snap 테스트가 wrap()을 써서 이 버그를
      // 놓친 이유와 동일).
      var next = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: SoriContentFeed(
                physics: FeedPhysics.snap,
                onNext: () => next++,
                underlay: const Text('다음'),
                child: const SizedBox.expand(child: Text('한국말')),
              ),
            ),
          ),
        ),
      );

      double underlayOpacity() => tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('다음'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;

      expect(underlayOpacity(), closeTo(0.18, 0.001));

      await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
      await tester.pumpAndSettle();
      expect(next, 1);
      expect(
        underlayOpacity(),
        closeTo(0.18, 0.001),
        reason: '첫 커밋 종료 후 언더레이는 쉬는 값(0.18)으로 돌아가야 한다 — 1.0에 고정되면 안 된다',
      );

      // 두 번째 커밋 — 첫 리셋이 우연이 아니라 매번 일어남을 증명한다.
      await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
      await tester.pumpAndSettle();
      expect(next, 2);
      expect(
        underlayOpacity(),
        closeTo(0.18, 0.001),
        reason: '두 번째 커밋 후에도 동일하게 복원돼야 한다',
      );
    },
  );

  testWidgets(
    'snap physics: re-entrant drag-end during an in-flight snap exit is ignored',
    (tester) async {
      // 리뷰 Minor: 첫 퇴장 애니메이션(120-220ms)이 끝나기 전에 두 번째
      // 드래그가 끝나면, 가드가 없을 경우 같은 _snapCtrl이 중간에
      // 재시작된다. 이때 onNext 호출 횟수(next)만으로는 재진입을 못 잡는다
      // — forward()를 다시 부르면 첫 TickerFuture의 whenComplete가 그냥
      // 스왑되어 어느 쪽이든 결국 정확히 1번만 부르는 것처럼 보일 수
      // 있다(직접 확인됨). 대신 커밋 시 정확히 1회여야 하는
      // HapticFeedback.selectionClick 호출 횟수로 재진입 자체를 센다 — 이
      // 가드는 committed 판정보다도 앞에 있어 재진입 시 햅틱조차 안 나가야
      // 한다.
      var next = 0;
      var hapticCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCount++;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
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

      // 애니메이션 중에도 히트테스트가 되는 좌표를 미리 고정해 둔다 —
      // GestureDetector 자신(Transform의 부모)은 변환되지 않으므로, 카드가
      // 퇴장 중이라 시각적으로 움직여도 이 지점은 계속 유효하다.
      final origin = tester.getCenter(find.text('한국말'));

      // 1차 커밋 — 위치 임계(88px)만으로 커밋시켜 퇴장 애니메이션을 건다.
      final first = await tester.startGesture(origin);
      await first.moveBy(const Offset(0, -200));
      await tester.pump();
      await first.up();
      await tester.pump(); // _commit() 진입 — _snapCtrl 애니메이션 시작

      // 아직 퇴장 애니메이션이 끝나지 않은 시점에 같은 좌표로 2차 제스처를
      // 끝낸다.
      final second = await tester.startGesture(origin);
      await second.moveBy(const Offset(0, -200));
      await tester.pump();
      await second.up();

      await tester.pumpAndSettle();
      expect(next, 1);
      expect(
        hapticCount,
        1,
        reason: '재진입 드래그엔드는 committed 판정보다 먼저 걸러져야 한다 — '
            '커밋 햅틱이 두 번 나가면 안 된다',
      );
    },
  );
}
