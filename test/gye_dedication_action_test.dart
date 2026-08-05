import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/services/gye_dedication_service.dart';
import 'package:ko_lernen_app/widgets/sori/gye_dedication_action.dart';

GyeDedication _currentExhibit() => GyeDedication.tryParse('member-a', {
  'schemaVersion': 1,
  'uid': 'member-a',
  'membershipId': 'membership-a',
  'decorationSlug': 'decoration_soban',
  'slotIndex': 1,
  'revision': 2,
  'lastOperationId': 'dedication-a-2',
})!;

Widget _host({
  Iterable<String> ownedDecor = const <String>[],
  GyeDedication? current,
  bool actionsAvailable = true,
  required GyeDedicationCommit onCommit,
}) => MaterialApp(
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: Center(
      child: GyeDedicationAction(
        gyeId: 'ABC234',
        ownedDecor: ownedDecor,
        current: current,
        actionsAvailable: actionsAvailable,
        onCommit: onCommit,
      ),
    ),
  ),
);

Future<void> _openAndConfirmFirstCandidate(WidgetTester tester) async {
  await tester.tap(find.text('Exhibit'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tray table (소반)'));
  await tester.pumpAndSettle();
  expect(find.text('Show this in the courtyard?'), findsOneWidget);
  await tester.tap(find.text('Show in courtyard'));
  await tester.pump();
}

void main() {
  testWidgets('explains the no-owned-decor state without making a request', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        onCommit:
            ({
              required gyeId,
              required decorationSlug,
              required expectedRevision,
              required operationId,
            }) async {
              calls += 1;
              return const GyeDedicationMutation(
                state: GyeDedicationMutationState.unchanged,
                revision: 0,
              );
            },
      ),
    );

    await tester.tap(find.text('Exhibit'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Open a Bojagi bundle to add a room decoration before showing one here.',
      ),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets(
    'confirms a dedication and suppresses a duplicate while pending',
    (tester) async {
      final completion = Completer<GyeDedicationMutation>();
      final requests = <({String? slug, int revision, String operationId})>[];
      await tester.pumpWidget(
        _host(
          ownedDecor: const <String>['decoration_soban'],
          onCommit:
              ({
                required gyeId,
                required decorationSlug,
                required expectedRevision,
                required operationId,
              }) {
                requests.add((
                  slug: decorationSlug,
                  revision: expectedRevision,
                  operationId: operationId,
                ));
                return completion.future;
              },
        ),
      );

      await _openAndConfirmFirstCandidate(tester);

      expect(requests, hasLength(1));
      expect(requests.single.slug, 'decoration_soban');
      expect(requests.single.revision, 0);
      await tester.tap(find.text('Exhibit'));
      await tester.pump();
      expect(requests, hasLength(1));

      completion.complete(
        const GyeDedicationMutation(
          state: GyeDedicationMutationState.dedicated,
          revision: 1,
          slotIndex: 0,
          decorationSlug: 'decoration_soban',
        ),
      );
      await tester.pump();
    },
  );

  testWidgets('withdrawal is explicit and uses the active document revision', (
    tester,
  ) async {
    final requests = <({String? slug, int revision})>[];
    await tester.pumpWidget(
      _host(
        ownedDecor: const <String>['decoration_soban'],
        current: _currentExhibit(),
        onCommit:
            ({
              required gyeId,
              required decorationSlug,
              required expectedRevision,
              required operationId,
            }) async {
              requests.add((slug: decorationSlug, revision: expectedRevision));
              return const GyeDedicationMutation(
                state: GyeDedicationMutationState.withdrawn,
                revision: 0,
              );
            },
      ),
    );

    await tester.tap(find.text('Exhibit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from exhibition'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Remove this exhibit from the shared courtyard? Your private decoration stays yours.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove from exhibition').last);
    await tester.pumpAndSettle();

    expect(requests, equals([(slug: null, revision: 2)]));
  });

  testWidgets(
    'a stale revision conflict waits for the stream instead of retrying',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ownedDecor: const <String>['decoration_soban'],
          onCommit:
              ({
                required gyeId,
                required decorationSlug,
                required expectedRevision,
                required operationId,
              }) async {
                throw const GyeDedicationClientFailure(
                  GyeDedicationFailureCategory.conflict,
                  retryable: true,
                );
              },
        ),
      );

      await _openAndConfirmFirstCandidate(tester);
      await tester.pump();

      expect(
        find.text(
          'The exhibition changed elsewhere. The latest view is shown.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsNothing);
    },
  );

  testWidgets('a transient retry is inert after its action leaves the tree', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, isVisible, _) => isVisible
                  ? GyeDedicationAction(
                      gyeId: 'ABC234',
                      ownedDecor: const <String>['decoration_soban'],
                      current: null,
                      actionsAvailable: true,
                      onCommit:
                          ({
                            required gyeId,
                            required decorationSlug,
                            required expectedRevision,
                            required operationId,
                          }) async {
                            calls += 1;
                            throw const GyeDedicationClientFailure(
                              GyeDedicationFailureCategory.unavailable,
                              retryable: true,
                            );
                          },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    await _openAndConfirmFirstCandidate(tester);
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(calls, 1);

    visible.value = false;
    await tester.pump();
    await tester.tap(find.text('Try again'), warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
