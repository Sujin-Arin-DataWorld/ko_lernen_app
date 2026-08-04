import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/widgets/sori/room_layer.dart';

void main() {
  testWidgets('locked anbang never exposes a placement write surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.anbang,
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .24),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RoomLayer), findsNothing);
    expect(find.text('This room is still being built'), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
