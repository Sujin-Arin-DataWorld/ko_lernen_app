import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/chip.dart';

/// 최종 픽스 A1 — SoriChip 의 공용 경로(`semanticLabel` 이 없는 칩, 즉
/// `SoriLevelFilterBar`(level_filter_bar.dart:124-131)를 포함한 대다수
/// 칩)는 예전엔 내부 [Text](chip.dart:107-121)가 감싸이지 않아 라벨을 한
/// 번 더 냈고("A1\nA1" 처럼 병합), 같은 조건에서 탭 시맨틱 액션도
/// (`onTap: hasSemanticOverride ? onTap : null`) 떨어져 나갔다 —
/// TalkBack/VoiceOver 두 손가락 탭이 아무 일도 안 했다. `_Stamp`
/// (content_feed.dart:593-599)·`_ChromeSlot`·`SoriHomeAction`·
/// `_DeckActionButton` 과 같은 명시적 `Semantics(onTap:)` + 전용
/// `ExcludeSemantics` 패턴으로 고정한다.
void main() {
  testWidgets(
    'semanticLabel 없는 칩(공용 경로) — 라벨은 한 번만 읽히고 탭 액션이 살아있다',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SoriChip(label: 'A1', onTap: () {})),
        ),
      );

      final data = tester
          .getSemantics(find.byType(SoriChip))
          .getSemanticsData();
      // 병합 버그가 있으면 내부 Text 의 자동 라벨이 새어 나와 "A1\nA1" 처럼
      // 겹친다 — 정확히 한 번만 나와야 이 등가 비교를 통과한다.
      expect(data.label, 'A1', reason: '라벨이 한 번만 읽혀야 한다(내부 Text 중복 누출 없음)');
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '탭 시맨틱 액션이 살아있어야 한다');
      semantics.dispose();
    },
  );

  testWidgets('선택된 칩도 라벨 한 번 + 탭 액션 + selected 플래그를 유지한다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriChip(label: 'B2', selected: true, onTap: () {}),
        ),
      ),
    );

    final data = tester.getSemantics(find.byType(SoriChip)).getSemanticsData();
    expect(data.label, 'B2');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('탭이 없는 전시용 칩도 라벨이 한 번만 읽히고 탭 액션이 없다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SoriChip(label: '5개'))),
    );

    final data = tester.getSemantics(find.byType(SoriChip)).getSemanticsData();
    expect(data.label, '5개');
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  testWidgets('semanticLabel override 는 그대로 라벨을 대체하고 탭 액션도 유지된다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriChip(
            label: 'C1',
            semanticLabel: 'C1 레벨, 5개 단어',
            onTap: () {},
          ),
        ),
      ),
    );

    final data = tester.getSemantics(find.byType(SoriChip)).getSemanticsData();
    expect(data.label, 'C1 레벨, 5개 단어');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}
