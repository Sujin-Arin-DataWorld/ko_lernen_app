import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';

/// finding 10 — `_ChromeSlot` 은 44dp `SizedBox` 안에 48dp `OverflowBox` 를
/// 넣는다. Flutter 는 히트테스트를 조상의 실제 크기(44dp)에서 끊으므로
/// 문서화된 48dp 터치 영역 중 조상 밖으로 튀어나온 구간은 "보이기만 하고
/// 눌리지 않는다" — speakable.dart:144-157(SoriSpeechIndicator)이 검수#13
/// 에서 고친 것과 같은 버그다. 현재 호출부가 0곳이라 잠복해 있다.
void main() {
  testWidgets('필터 아이콘의 48dp 터치 영역 전체가 눌린다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriChromeRow(
            onFilterTap: () => tapped = true,
            filterSemanticLabel: 'filter',
          ),
        ),
      ),
    );

    final rowTopLeft = tester.getTopLeft(find.byType(SoriChromeRow));
    // 옛 버그에서는 SoriChromeRow 자신의 히트테스트가 44dp 조상
    // SizedBox 에서 끊겼다 — (2, 46) 은 44dp 안에는 없고 48dp 안에는
    // 있는 지점이다.
    await tester.tapAt(rowTopLeft + const Offset(2, 46));
    await tester.pump();

    expect(
      tapped,
      isTrue,
      reason:
          '문서화된 48dp 터치 영역 중 옛 44dp 경계 밖(y=46)을 찍었는데 '
          '반응이 없다 — 조상이 여전히 44dp 에서 히트테스트를 끊고 있다.',
    );
  });
}
