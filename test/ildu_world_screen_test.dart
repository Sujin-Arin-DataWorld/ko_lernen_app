import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/ildu_decoration_placement_service.dart';

void main() {
  late IlDuWorldManifest manifest;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
  });

  testWidgets('renders the spacious map fail-closed at iPhone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: IlDuWorldScreen(
          loadManifest: () async => manifest,
          loadProjection: () async => PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          ),
          decorationStore: _MemoryDecorationStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mein Ildu Gotaek'), findsOneWidget);
    expect(find.text('0 von 11 Gebäuden'), findsOneWidget);
    expect(find.text('Bauplatz'), findsOneWidget);
    expect(
      find.text('Schließe bestätigte Lernschritte auf A1 ab.'),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryDecorationStore implements IlDuDecorationPlacementStore {
  List<IlDuDecorationPlacement> placements = const [];

  @override
  Future<List<IlDuDecorationPlacement>> load(
    IlDuWorldManifest manifest,
  ) async => placements;

  @override
  Future<void> save(List<IlDuDecorationPlacement> placements) async {
    this.placements = List.unmodifiable(placements);
  }
}
