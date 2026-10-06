// Local review harness. Sample receipts never grant money or finish learning.
import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_reward_moment.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Storage.setHapticsEnabled(false);
  await Storage.setSndMaster(false);
  runApp(const _Preview());
}

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  String language = 'de';
  bool dark = false;
  bool reduced = false;
  bool largeText = false;
  int step = 0;
  String? purpose;
  String? level;
  bool beginner = true;
  String companion = 'joy';

  RewardReceipt _receipt(bool first) {
    final day = YeopjeonRewardMoment.dayKey(DateTime.now());
    final id = 'daily:$day:${first ? 'first' : 'second'}';
    final amount = first ? 20 : 10;
    return RewardReceipt(
      activityId: 'preview',
      receiptId: 'preview:$id',
      yeopjeonReward: YeopjeonRewardMoment(
        claims: {id: amount},
        balance: first ? 80 : 90,
        source: YeopjeonRewardSource.currentActivity,
        day: day,
      ),
      items: [
        RewardReceiptItem(
          kind: SoriRewardKind.yeopjeon,
          identity: id,
          amount: amount,
          label: const SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
        ),
        const RewardReceiptItem(
          kind: SoriRewardKind.xp,
          amount: 10,
          label: SoriLocalizedCopy(de: 'Lern-XP', en: 'XP'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: Locale(language),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    navigatorObservers: [soriRouteObserver],
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(settings.name ?? 'Preview')),
        body: const Center(child: Text('Read-only preview destination')),
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(largeText ? 2 : 1),
      ),
      child: SoriTypeScale(child: child!),
    ),
    home: Builder(
      builder: (context) {
        final copy = onboardingV2Copy(AppL10n.of(context));
        final Widget screen = step == 0
            ? OnboardingSetupScreen(
                copy: copy,
                selectedPurposeId: purpose,
                selectedLevelCode: level,
                beginnerSelected: beginner,
                onBeginnerSelected: () => setState(() => beginner = true),
                onPurposeChanged: (value) => setState(() => purpose = value),
                onLevelChanged: (value) => setState(() {
                  level = value;
                  beginner = false;
                }),
                onContinue: (_) => setState(() => step = 1),
              )
            : step == 6
            ? OnboardingCompanionScreen(
                copy: copy,
                selectedCompanionId: companion,
                onCompanionChanged: (value) =>
                    setState(() => companion = value),
                onContinue: (_) => setState(() => step = 0),
                onBack: () => setState(() => step--),
              )
            : OnboardingStoryScreen(
                copy: copy,
                pageIndex: step - 1,
                beginner: beginner,
                selectedLevel: LearnerLevel.values.firstWhere(
                  (value) => value.name == level,
                  orElse: () => LearnerLevel.a1,
                ),
                onContinue: (_) => setState(() => step++),
                onPrevious: (_) => setState(() => step--),
              );
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'UI preview • no payout',
              style: TextStyle(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    setState(() => language = language == 'de' ? 'en' : 'de'),
                child: Text(language.toUpperCase()),
              ),
              IconButton(
                tooltip: 'Light / dark',
                icon: const Icon(Icons.contrast),
                onPressed: () => setState(() => dark = !dark),
              ),
              IconButton(
                tooltip: 'Text 100 / 200%',
                icon: const Icon(Icons.text_increase),
                onPressed: () => setState(() => largeText = !largeText),
              ),
              IconButton(
                tooltip: 'Reduce motion',
                icon: const Icon(Icons.motion_photos_off),
                onPressed: () => setState(() => reduced = !reduced),
              ),
            ],
          ),
          body: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () =>
                        showSoriStageRewardReceipt(context, _receipt(true)),
                    child: const Text('First +20'),
                  ),
                  TextButton(
                    onPressed: () =>
                        showSoriStageRewardReceipt(context, _receipt(false)),
                    child: const Text('Second +10'),
                  ),
                  for (var index = 0; index < 7; index++)
                    TextButton(
                      onPressed: () => setState(() => step = index),
                      child: Text('${index + 1}'),
                    ),
                ],
              ),
              Expanded(child: screen),
            ],
          ),
        );
      },
    ),
  );
}
