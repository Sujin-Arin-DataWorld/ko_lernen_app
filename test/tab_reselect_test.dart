import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/tab_reselect.dart';

void main() {
  testWidgets('tab reselect returns a primary scroll view to the top', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 160);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 20,
            itemBuilder: (_, index) =>
                SizedBox(height: 48, child: Text('$index')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await reselectTabScroll(controller, reduceMotion: true);
    expect(controller.offset, 0);
  });
}
