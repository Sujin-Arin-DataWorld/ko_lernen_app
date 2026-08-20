import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets('SoriTextField preserves editing and submit behavior', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    final submissions = <String>[];

    await tester.pumpWidget(
      _host(
        SoriTextField(
          controller: controller,
          labelText: 'Search',
          hintText: 'Find a learning activity',
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: changes.add,
          onSubmitted: submissions.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Wortkette');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(controller.text, 'Wortkette');
    expect(changes, contains('Wortkette'));
    expect(submissions, ['Wortkette']);
    expect(field.decoration?.labelText, 'Search');
    expect(field.decoration?.hintText, 'Find a learning activity');
    expect(field.decoration?.prefixIcon, isA<Icon>());
    expect(tester.takeException(), isNull);
  });

  for (final copy in const <({String locale, String label, String hint})>[
    (
      locale: 'de',
      label: 'Persönliche Lernsammlung durchsuchen',
      hint: 'Zum Beispiel Aussprache, Buch oder Wortkette',
    ),
    (
      locale: 'en',
      label: 'Search your personal learning collection',
      hint: 'For example pronunciation, books, or word chains',
    ),
  ]) {
    testWidgets('${copy.locale} copy remains complete at 320×640 and 200%', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);

      await tester.pumpWidget(
        _host(
          SoriTextField(
            labelText: copy.label,
            hintText: copy.hint,
            helperText: copy.hint,
          ),
          textScale: 2,
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.labelText, copy.label);
      expect(field.decoration?.hintText, copy.hint);
      expect(field.decoration?.helperText, copy.hint);
      expect(
        tester.getSize(find.byType(SoriTextField)).width,
        lessThanOrEqualTo(272),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _host(Widget child, {double textScale = 1}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [child]),
      ),
    ),
  );
}
