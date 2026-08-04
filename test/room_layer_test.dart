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
      expect(find.byType(DecorationFallback), findsOneWidget);
    });
  });
}
