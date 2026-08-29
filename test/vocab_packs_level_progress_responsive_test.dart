import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
    });
    await Storage.init();
    DataLoader.reset();
    VocabPackService.reset();
  });

  const viewports = <String, Size>{
    'compact': Size(360, 800),
    'medium': Size(800, 1280),
    'expanded': Size(1280, 800),
  };

  for (final level in <String>['a1', 'c2']) {
    for (final viewport in viewports.entries) {
      testWidgets(
        '${level.toUpperCase()} progress header fits ${viewport.key}',
        (tester) async {
          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await Storage.setBrowseLevelCode(level);
          await tester.runAsync(VocabPackService.loadAll);
          await tester.pumpWidget(_host(const VocabPacksScreen()));

          for (var i = 0; i < 40; i += 1) {
            await tester.pump(const Duration(milliseconds: 50));
            if (find.byType(PackCard).evaluate().isNotEmpty) {
              break;
            }
          }

          expect(find.byType(PackCard), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, app) => SoriTypeScale(child: app!),
  home: child,
);
