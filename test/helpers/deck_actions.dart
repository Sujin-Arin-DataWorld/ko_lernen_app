import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/pressable.dart';

/// SoriDeckActionBar(§P2-3)의 원형 버튼을 Semantics 라벨로 찾아 콜백을 직접
/// 호출한다 — 옛 `SoriButton.firstWhere(label).onTap!()` 패턴의 후계.
/// (탭 좌표는 테스트 뷰포트의 오버레이에 가려 불안정하므로 콜백 직접 호출을
/// 유지한다. 게이트 의미는 보존된다: 플립 전에는 onTap 이 힌트 훅이라 판정이
/// 발동하지 않는다.)
void tapDeckAction(WidgetTester tester, String label) {
  final pressable = tester.widget<SoriPressable>(
    find
        .descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == label &&
                (w.properties.button ?? false),
          ),
          matching: find.byType(SoriPressable),
        )
        .first,
  );
  pressable.onTap?.call();
}
