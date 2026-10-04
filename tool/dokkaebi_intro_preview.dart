import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  await Storage.init();
  TigerStageVideo.videoReady = true;
  runApp(
    MaterialApp(
      navigatorObservers: [soriRouteObserver],
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPracticeDokkaebiIntroduction(context),
                child: const Text('Open app introduction'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
