import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/widgets/sori/gye_dedication_picker.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  required List<String> candidates,
  GyeDedication? current,
  required void Function(String?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showSoriSheet<String>(
                  context: context,
                  builder: (_) => GyeDedicationPickerSheet(
                    candidates: candidates,
                    current: current,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

GyeDedication _currentExhibit() => GyeDedication.tryParse('member-a', {
  'schemaVersion': 1,
  'uid': 'member-a',
  'membershipId': 'membership-a',
  'decorationSlug': 'decoration_soban',
  'slotIndex': 1,
  'revision': 2,
  'lastOperationId': 'dedication-a-2',
})!;

void main() {
  test('withdraw sentinel cannot be a real decoration slug', () {
    expect(kGyeDedicationSlugs.contains(kGyeDedicationWithdraw), isFalse);
    expect(kGyeDedicationWithdraw.startsWith('decoration_'), isFalse);
  });

  testWidgets('empty ownership state explains how to earn a decoration', (
    tester,
  ) async {
    await _openSheet(tester, candidates: const [], onResult: (_) {});

    expect(
      find.text(
        'Open a Bojagi bundle to add a room decoration before showing one here.',
      ),
      findsOneWidget,
    );
    expect(find.text('Remove from exhibition'), findsNothing);
  });

  testWidgets('withdraw returns an explicit sentinel instead of null', (
    tester,
  ) async {
    String? result = 'untouched';
    await _openSheet(
      tester,
      candidates: const ['decoration_soban'],
      current: _currentExhibit(),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Remove from exhibition'));
    await tester.pumpAndSettle();

    expect(result, kGyeDedicationWithdraw);
  });
}
