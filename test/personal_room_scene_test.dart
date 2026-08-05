import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/widgets/sori/personal_room_scene.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  testWidgets('shows a stored decoration without exposing a read-only marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PersonalRoomScene(
          surface: PersonalRoomSurface.sarangbang,
          placements: {
            PersonalRoomSurface.sarangbang: {
              'floor_center': 'decoration_soban',
            },
          },
          owned: {},
          interactive: false,
        ),
      ),
    );

    expect(find.byType(SoriDecorationImage), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets('forwards a slot tap only in interactive mode', (tester) async {
    String? tappedSlot;
    await tester.pumpWidget(
      _host(
        PersonalRoomScene(
          surface: PersonalRoomSurface.sarangbang,
          placements: const {
            PersonalRoomSurface.sarangbang: {
              'floor_center': 'decoration_soban',
            },
          },
          owned: const {'decoration_soban'},
          interactive: true,
          onTapSlot: (slot) => tappedSlot = slot.id,
        ),
      ),
    );

    final slotGesture = find.byType(GestureDetector);
    expect(slotGesture, findsOneWidget);
    await tester.tap(slotGesture);
    await tester.pump();

    expect(tappedSlot, 'floor_center');
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, height: 400, child: child)),
  ),
);
