import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/widgets/sori/gye_dedication_layer.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  testWidgets('renders normalized exhibits as a passive visual layer', (
    tester,
  ) async {
    final dedication = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': 'membership-a',
      'decorationSlug': 'decoration_soban',
      'slotIndex': 1,
      'revision': 1,
      'lastOperationId': 'a-1',
    })!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: GyeDedicationLayer(dedications: [dedication]),
          ),
        ),
      ),
    );

    expect(find.byType(SoriDecorationImage), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
      findsOneWidget,
    );
  });
}
