import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/module_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('module badges use the active locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('DUE'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('NEU'), findsOneWidget);
    expect(find.text('FÄLLIG'), findsOneWidget);
  });
}

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Scaffold(
    body: Column(
      children: [
        ModuleCard(
          icon: Icons.auto_awesome,
          title: 'Title',
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'new',
        ),
        FeaturedModuleCard(
          icon: Icons.refresh,
          title: 'Title',
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'due',
        ),
      ],
    ),
  ),
);
