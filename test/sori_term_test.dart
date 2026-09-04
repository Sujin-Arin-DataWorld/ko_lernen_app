import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/widgets/sori/sori_term.dart';

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
  });

  testWidgets('tapping the term opens the sheet with the entry meaning', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const SoriTerm(
          termId: 'jangdokdae',
          text: 'Jangdokdae · 장독대',
          surface: 'test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.text('Jangdokdae · 장독대'));
    expect(
      node.label,
      AppL10nDe().culturalHelpSemantics('Jangdokdae · 장독대'),
    );
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.text('Jangdokdae · 장독대'));
    await tester.pumpAndSettle();

    expect(find.text('장독대'), findsOneWidget);
    expect(
      find.text(catalog.entry('jangdokdae')!.localized('de').meaning),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('has a minimum 44dp tall tap target', (tester) async {
    await tester.pumpWidget(
      _host(
        const SoriTerm(termId: 'gye', text: 'Gye', surface: 'test'),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(SoriTerm));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('SoriTerm.span opens the same sheet from inline flow text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Text.rich(
          TextSpan(
            style: const TextStyle(color: Colors.black),
            children: [
              const TextSpan(text: 'Dies ist '),
              SoriTerm.span(
                termId: 'dancheong',
                text: 'Dancheong',
                surface: 'test_span',
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dancheong'));
    await tester.pumpAndSettle();

    expect(
      find.text(catalog.entry('dancheong')!.localized('de').meaning),
      findsOneWidget,
    );
  });

  testWidgets('renders nothing selectable for an unknown termId', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SoriTerm(
          termId: 'not_a_real_term',
          text: 'Ghost Term',
          surface: 'test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The term itself always renders (it does not depend on the catalog to
    // draw); only opening the sheet is a no-op when the id is unknown.
    await tester.tap(find.text('Ghost Term'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(body: Center(child: child)),
  );
}
