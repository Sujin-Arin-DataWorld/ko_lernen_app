import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/practice_guide.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_intro.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  await Storage.init();
  runApp(
    MaterialApp(
      navigatorObservers: [soriRouteObserver],
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Center(
                  child: SizedBox(width: 342, child: DokkaebiIntro()),
                ),
                PracticeGuide(dokkaebi: true, child: Text('Dokkaebi')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
