import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/hangul_util.dart';
import 'package:ko_lernen_app/widgets/hangul_syllable_table.dart';

void main() {
  test('basic chart composes every visible consonant and vowel', () {
    expect(basicSyllableConsonants.length, 14);
    expect(basicSyllableVowels.length, 10);
    for (final consonant in basicSyllableConsonants) {
      for (final vowel in basicSyllableVowels) {
        expect(composeHangulSyllable(consonant, vowel, ''), isNotNull);
      }
    }
    expect(composeHangulSyllable('ㄱ', 'ㅏ', ''), '가');
    expect(composeHangulSyllable('ㄱ', 'ㅑ', ''), '갸');
    expect(composeHangulSyllable('ㄱ', 'ㅓ', ''), '거');
    expect(composeHangulSyllable('ㄱ', 'ㅕ', ''), '겨');
    expect(composeHangulSyllable('ㄷ', 'ㅡ', ''), '드');
  });

  for (final viewport in const <({Size size, double textScale})>[
    (size: Size(320, 640), textScale: 2),
    (size: Size(720, 1024), textScale: 1.3),
  ]) {
    testWidgets('chart speaks tapped syllables without overflow at '
        '${viewport.size.width.toInt()}dp and ${viewport.textScale}x text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final spoken = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(viewport.textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HangulSyllableTable(
                speak: (syllable) async {
                  spoken.add(syllable);
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      for (final syllable in ['가', '갸', '거', '겨']) {
        final cell = find.byKey(ValueKey('hangul-syllable-$syllable'));
        await tester.ensureVisible(cell);
        await tester.pumpAndSettle();
        await tester.tap(cell);
        await tester.pump();
        expect(find.text(syllable), findsWidgets);
      }
      expect(spoken, ['가', '갸', '거', '겨']);
      expect(find.bySemanticsLabel('ㄱ + ㅕ = 겨'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('chart cells expose and execute a screen-reader tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final spoken = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HangulSyllableTable(
              speak: (syllable) async {
                spoken.add(syllable);
                return true;
              },
            ),
          ),
        ),
      ),
    );

    final cell = find.byKey(const ValueKey('hangul-syllable-갸'));
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    final node = tester.getSemantics(cell);
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      ui.SemanticsAction.tap,
    );
    await tester.pump();
    expect(spoken, ['갸']);
    expect(find.text('갸'), findsWidgets);
    semantics.dispose();
  });
}
