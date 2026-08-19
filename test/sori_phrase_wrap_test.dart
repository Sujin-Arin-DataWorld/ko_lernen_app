import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';

void main() {
  testWidgets('does not split 포기하지 across lines', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 160,
          child: SoriPhraseWrap(
            '어렵더라도 포기하지 마세요.',
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
    expect(find.text('포기하지'), findsOneWidget);
    expect(find.textContaining('포기하'), findsOneWidget);
    expect(find.text('포기하'), findsNothing);
  });
}
