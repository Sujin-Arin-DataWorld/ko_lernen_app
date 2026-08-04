import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/module_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('module cards use the readable card type scale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), subtitle: 'Description'));

    expect(tester.widget<Text>(find.text('Title').first).style!.fontSize, 15);
    expect(
      tester.widget<Text>(find.text('Description').first).style!.fontSize,
      12,
    );
    expect(tester.widget<Text>(find.text('NEW')).style!.fontSize, 11);
  });

  testWidgets('module badges use the active locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('DUE'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('NEU'), findsOneWidget);
    expect(find.text('FÄLLIG'), findsOneWidget);
  });
}

Widget _app(Locale locale, {String? subtitle}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Scaffold(
    body: Column(
      children: [
        ModuleCard(
          icon: Icons.auto_awesome,
          title: 'Title',
          subtitle: subtitle,
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'new',
        ),
        FeaturedModuleCard(
          icon: Icons.refresh,
          title: 'Title',
          subtitle: subtitle,
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'due',
        ),
      ],
    ),
  ),
);
