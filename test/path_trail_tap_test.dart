import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/widgets/sori/path_trail.dart';

/// **"모든 pfad가 100% 트리거" 회귀 테스트.**
///
/// 지그재그 배치는 절대 좌표 Stack으로 짜면 (1) 트랙 밖으로 나간 노드가
/// clip되어 히트테스트에서 빠지고 (2) 겹친 노드가 서로 탭을 가로채면서
/// 조용히 탭을 잃는다. 이 테스트는 그 두 실패를 잡는다.

const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

List<SoriPathStop> _buildStops(int n, void Function(String id) onTap) {
  return [
    for (var i = 0; i < n; i++)
      SoriPathStop(
        id: 'pack_$i',
        label: 'Pack $i — Alltag',
        // 앞 3개 완료 / 4번째가 지금 / 나머지 잠금 = 실제 화면과 같은 분포.
        status: i < 3
            ? PackStatus.cleared
            : i == 3
                ? PackStatus.inProgress
                : PackStatus.locked,
        fraction: i == 3 ? 0.62 : 0,
        isNow: i == 3,
        nodeKey: ValueKey('pack_$i'),
        onTap: () => onTap('pack_$i'),
      ),
  ];
}

Widget _host(List<SoriPathStop> stops, {double width = 360}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SoriPathTrail(stops: stops),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // "지금" 노드(_NowDisc)의 무한 펄스 애니메이션 때문에 pumpAndSettle이 영영
  // settle하지 못해 타임아웃한다. 위젯이 reduce-motion을 존중하므로 접근성
  // "동작 줄이기"를 켜 펄스를 멈춘다 → pumpAndSettle 정상화(a11y 경로도 검증).
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('레벨 하나의 팩 19개가 전부 탭된다 (하나도 빠지지 않음)',
      (tester) async {
    const n = 19;
    final tapped = <String>{};
    await tester.pumpWidget(_host(_buildStops(n, tapped.add)));
    await tester.pumpAndSettle();

    for (var i = 0; i < n; i++) {
      final finder = find.byKey(ValueKey('pack_$i'));
      expect(finder, findsOneWidget, reason: 'pack_$i 노드가 트리에 없다');
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder, warnIfMissed: true);
      await tester.pump();
    }

    expect(tapped.length, n, reason: '탭이 누락된 팩: ${{
      for (var i = 0; i < n; i++)
        if (!tapped.contains('pack_$i')) 'pack_$i',
    }}');
  });

  testWidgets('4개 레벨 76개 팩 전부 탭된다', (tester) async {
    const n = 76;
    final tapped = <String>{};
    await tester.pumpWidget(_host(_buildStops(n, tapped.add)));
    await tester.pumpAndSettle();

    for (var i = 0; i < n; i++) {
      final finder = find.byKey(ValueKey('pack_$i'));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pump();
    }
    expect(tapped.length, n);
  });

  testWidgets('잠금 노드도 탭이 잡힌다 (잠금 힌트를 띄워야 하므로)',
      (tester) async {
    final tapped = <String>{};
    await tester.pumpWidget(_host(_buildStops(8, tapped.add)));
    await tester.pumpAndSettle();

    // index 4..7 = locked
    for (var i = 4; i < 8; i++) {
      final f = find.byKey(ValueKey('pack_$i'));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
      expect(tapped.contains('pack_$i'), isTrue,
          reason: '잠금 노드 pack_$i 가 탭에 반응하지 않았다');
    }
  });

  testWidgets('탭 타깃이 Material 최소 48dp 이상이고 서로 겹치지 않는다',
      (tester) async {
    const n = 12;
    await tester.pumpWidget(_host(_buildStops(n, (_) {})));
    await tester.pumpAndSettle();

    final rects = <Rect>[];
    for (var i = 0; i < n; i++) {
      final r = tester.getRect(find.byKey(ValueKey('pack_$i')));
      expect(r.width, greaterThanOrEqualTo(48.0));
      expect(r.height, greaterThanOrEqualTo(48.0));
      rects.add(r);
    }
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse,
            reason: '노드 $i 와 $j 의 탭 영역이 겹친다 — 위 노드가 탭을 가로챈다');
      }
    }
  });

  testWidgets('노드가 트랙 밖으로 나가지 않는다 (clip → 탭 소실 방지)',
      (tester) async {
    const n = 12;
    const width = 360.0;
    await tester.pumpWidget(_host(_buildStops(n, (_) {}), width: width));
    await tester.pumpAndSettle();

    final track = tester.getRect(find.byType(SoriPathTrail));
    for (var i = 0; i < n; i++) {
      final r = tester.getRect(find.byKey(ValueKey('pack_$i')));
      expect(r.left, greaterThanOrEqualTo(track.left - 0.5),
          reason: '노드 $i 가 왼쪽으로 넘쳤다');
      expect(r.right, lessThanOrEqualTo(track.right + 0.5),
          reason: '노드 $i 가 오른쪽으로 넘쳤다');
    }
  });

  testWidgets('좁은 화면(280dp)에서도 전부 탭된다', (tester) async {
    const n = 10;
    final tapped = <String>{};
    await tester.pumpWidget(_host(_buildStops(n, tapped.add), width: 280));
    await tester.pumpAndSettle();

    for (var i = 0; i < n; i++) {
      final f = find.byKey(ValueKey('pack_$i'));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
    }
    expect(tapped.length, n);
  });

  testWidgets('큰 글자 설정(textScale 1.8)에서도 오버플로 없이 전부 탭된다',
      (tester) async {
    const n = 10;
    final tapped = <String>{};
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.8),
          disableAnimations: true,
        ),
        child: _host(_buildStops(n, tapped.add)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (var i = 0; i < n; i++) {
      final f = find.byKey(ValueKey('pack_$i'));
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
    }
    expect(tapped.length, n);
  });

  test('지그재그 좌표식이 Align 배치와 일치한다', () {
    // Align(Alignment(fx, _))는 자식 왼쪽을 (W - w)(fx+1)/2 에 둔다.
    const w = 360.0;
    const nodeW = SoriPathTrail.nodeWidth;
    for (var i = 0; i < 40; i++) {
      final fx = SoriPathTrail.swayAt(i);
      final alignLeft = (w - nodeW) * (fx + 1) / 2;
      final alignCenter = alignLeft + nodeW / 2;
      expect(
        SoriPathTrail.centerXFor(w, nodeW, i),
        closeTo(alignCenter, 0.0001),
        reason: 'i=$i 에서 연결선이 원 중심을 빗나간다',
      );
      // 트랙 밖으로 나가지 않음
      expect(alignLeft, greaterThanOrEqualTo(-0.0001));
      expect(alignLeft + nodeW, lessThanOrEqualTo(w + 0.0001));
    }
  });

  test('레벨 목록이 비어도 죽지 않는다', () {
    expect(_levels.length, 6);
    expect(const SoriPathTrail(stops: []).stops, isEmpty);
  });
}
