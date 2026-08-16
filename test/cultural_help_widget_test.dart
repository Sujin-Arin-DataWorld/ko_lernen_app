import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/room_layout.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/cultural_help.dart';
import 'package:ko_lernen_app/widgets/sori/free_room_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CulturalGlossary catalog;

  setUpAll(() async {
    catalog = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  setUp(() {
    CulturalGlossaryRepository.setLoaderForTesting(() async => catalog);
  });

  tearDown(() {
    CulturalGlossaryRepository.resetForTesting();
    Storage.resetForTesting();
  });

  testWidgets('renders a 48dp labeled question mark and restores focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final child = CulturalHelpButton(termId: 'hanok', focusNode: focusNode);

    await tester.pumpWidget(_host(child));
    await tester.pumpAndSettle();

    const key = Key('cultural_help_hanok');
    expect(tester.getSize(find.byKey(key)), const Size(48, 48));
    final node = tester.getSemantics(find.byKey(key));
    expect(node.label, 'Mehr über 한옥 erfahren');
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(find.text('한옥'), findsOneWidget);
    expect(find.text('Was ist das?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cultural_help_close')));
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    semantics.dispose();
  });

  testWidgets('updates an open story when the app locale changes', (
    tester,
  ) async {
    const child = CulturalHelpButton(termId: 'gye');
    await tester.pumpWidget(_host(child));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cultural_help_gye')));
    await tester.pumpAndSettle();

    expect(find.text('Was ist das?'), findsOneWidget);
    expect(
      find.text(catalog.entry('gye')!.localized('de').meaning),
      findsOneWidget,
    );

    await tester.pumpWidget(_host(child, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('What is it?'), findsOneWidget);
    expect(
      find.text(catalog.entry('gye')!.localized('en').meaning),
      findsOneWidget,
    );
  });

  testWidgets('scrolls safely at 390x844 and 200 percent text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host(
        const CulturalHelpButton(termId: 'jangdokdae'),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cultural_help_jangdokdae')));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides optional help when the catalog load fails', (
    tester,
  ) async {
    CulturalGlossaryRepository.setLoaderForTesting(() async => null);
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hanok'),
            CulturalHelpButton(termId: 'hanok'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hanok'), findsOneWidget);
    expect(find.byKey(const Key('cultural_help_hanok')), findsNothing);
  });

  testWidgets('read-only decoration exposes a labeled 48dp inspection tap', (
    tester,
  ) async {
    const item = RoomLayoutItem(
      instanceId: 'decor:jangdok:1',
      kind: RoomAssetKind.decoration,
      assetId: 'decoration_jangdokdae',
      x: .5,
      y: .5,
      width: .08,
    );
    String? inspected;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 300,
          height: 400,
          child: FreeRoomLayer(
            items: const [item],
            interactive: false,
            inspectableDecorationSlugs: const {'decoration_jangdokdae'},
            onInspectDecoration: (slug) => inspected = slug,
          ),
        ),
        locale: const Locale('en'),
      ),
    );

    const key = ValueKey('inspect-room-item-decor:jangdok:1');
    expect(tester.getSize(find.byKey(key)), const Size(48, 48));
    expect(
      tester.getSemantics(find.byKey(key)).label,
      contains('Learn more about'),
    );
    await tester.tap(find.byKey(key));
    await tester.pump();
    expect(inspected, 'decoration_jangdokdae');
    semantics.dispose();
  });

  testWidgets('object hint is stored locally and shown only once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await tester.pumpWidget(_host(const CulturalObjectHint(enabled: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cultural_object_hint')), findsOneWidget);

    await tester.tap(find.byTooltip('Hinweis schließen'));
    await tester.pumpAndSettle();
    expect(Storage.culturalObjectHintSeen, isTrue);
    expect(find.byKey(const Key('cultural_object_hint')), findsNothing);

    await tester.pumpWidget(
      _host(const CulturalObjectHint(key: ValueKey('second'), enabled: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cultural_object_hint')), findsNothing);
  });
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('de'),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: MediaQuery(
      data: MediaQueryData(size: const Size(390, 844), textScaler: textScaler),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
