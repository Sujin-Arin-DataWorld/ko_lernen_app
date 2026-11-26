// Local QA entry point. The fixture below never writes learner progress.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/ildu_world_projection_adapter.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  final params = Uri.base.queryParameters;
  final scale = double.tryParse(params['textScale'] ?? '') ?? 1;
  final showBuildings = params['fixture'] == 'complete';
  runApp(
    MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Banner(
        message: 'LOCAL QA',
        location: BannerLocation.topEnd,
        child: IlDuWorldScreen(
          loadProjection: () async => IlDuWorldProjection(
            era: IlDuWorldEra.b2,
            hasVerifiedEvidence: showBuildings,
          ),
        ),
      ),
    ),
  );
}
