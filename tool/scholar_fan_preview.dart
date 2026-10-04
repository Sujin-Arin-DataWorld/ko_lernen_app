// Local-only review harness using production learning and history widgets.
// Run: flutter run -d web-server -t tool/scholar_fan_preview.dart --web-port 8767
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/models/silben_practice.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_context_screen.dart';
import 'package:ko_lernen_app/screens/hanok_practice_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/hanok_practice_entry.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  await Storage.init();
  TigerStageVideo.videoReady = true;
  // Visual-only localhost preview. Production speech resolvers are untouched;
  // remote TTS/App Check/CORS is deliberately outside this harness's evidence.
  SoriSpeech.speakImpl = (_, __) async => false;
  SoriSpeech.speakSlowImpl = (_, __) async => false;
  SoriSpeech.prefetchImpl = (_, __) async {};
  SoriSpeech.stopImpl = () async {};
  final params = Uri.base.queryParameters;
  // Skip the first-visit coach in this scoped visual harness.
  await Storage.setTutSeen('silben_kreuz');
  runApp(
    MaterialApp(
      locale: Locale(params['lang'] ?? 'de'),
      theme: params['dark'] == '1' ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      navigatorObservers: [soriRouteObserver],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            double.tryParse(params['scale'] ?? '') ?? 1,
          ),
          disableAnimations: params['reduce'] == '1',
        ),
        child: child!,
      ),
      home: params['flow'] == 'silben'
          ? const SilbenKreuzScreen()
          : const SmalltalkContextScreen(),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => switch (settings.name) {
          '/smalltalk/context' => SmalltalkContextScreen(
            request:
                settings.arguments as SmalltalkContextRequest? ??
                const SmalltalkContextRequest(),
          ),
          '/hanok/practice' => const HanokPracticeScreen(),
          '/wordle' => SilbenKreuzScreen(
            review: settings.arguments as SilbenReviewRequest?,
          ),
          // Review the production entry without unrelated room/network services.
          '/sarangbang' => SoriStudyFrame(
            adaptTitleAtNormalScale: true,
            title: AppL10n.of(context).practiceToSarangbang,
            child: const SingleChildScrollView(child: HanokPracticeEntry()),
          ),
          _ => const SmalltalkContextScreen(),
        },
      ),
    ),
  );
}

// The localhost-only visual harness deliberately injects the speech test hooks
// so its unauthenticated origin never calls production TTS/App Check services.
// ignore_for_file: invalid_use_of_visible_for_testing_member
