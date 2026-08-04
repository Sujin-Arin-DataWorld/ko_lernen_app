import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/room_layer.dart';

void main() {
  group('RoomLayer', () {
    testWidgets('does not render a decor in an incompatible slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: RoomLayer(
              slots: kSarangbangSlots,
              placement: {'wall_back': 'decoration_soban'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DecorationFallback), findsNothing);
    });

    testWidgets('renders a decor in a compatible slot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: RoomLayer(
              slots: kSarangbangSlots,
              placement: {'floor_center': 'decoration_soban'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SoriDecorationImage), findsOneWidget);
      expect(find.byType(DecorationFallback), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
    // 선반 슬롯은 둘(alcove_top·alcove_bottom)인데 shelf 장식은 문방사우
    // 하나뿐이다. 그걸 한쪽에 놓으면 다른 쪽에는 놓을 게 없다 —
    // 그런데도 마커가 뜨면 눌러도 빈 목록만 나오는 죽은 버튼이 된다.
    testWidgets('no marker when the only candidate sits in another slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: RoomLayer(
              slots: kSarangbangSlots,
              placement: {'alcove_top': 'decoration_munbangsau'},
              owned: {'decoration_munbangsau'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    });

    // 반대 방향 — 아직 아무 데도 안 놓았으면 두 선반 모두 표식이 떠야 한다.
    // 위 테스트가 "그냥 마커를 다 껐다"로 통과하는 걸 막는다.
    testWidgets('marks every empty slot that has something to put in it', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: RoomLayer(
              slots: kSarangbangSlots,
              placement: {},
              owned: {'decoration_munbangsau'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
    });
  });
}
