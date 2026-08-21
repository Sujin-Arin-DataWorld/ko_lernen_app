import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/screens/quests_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart'
    show decorName;
import 'package:ko_lernen_app/widgets/sori/progress.dart';
import 'package:ko_lernen_app/widgets/sori/reward_thumb.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_quests': true});
    Storage.resetForTesting();
    await Storage.init();
    await Storage.setTutSeen('quests');
    await Storage.markQuestCompleted('q_sonamu');
  });

  testWidgets(
    'DE and EN expose shared progress and reward language to assistive tech',
    (tester) async {
      final semantics = tester.ensureSemantics();

      for (final locale in const [Locale('de'), Locale('en')]) {
        await _configureView(tester, const Size(390, 844));
        await tester.pumpWidget(
          _host(_screenWith(_mixedQuestStates), locale: locale, textScale: 1.3),
        );
        await _finishLoad(tester);

        final context = tester.element(find.byType(QuestsScreen));
        final t = AppL10n.of(context);
        final definition = kQuestById['q_jangdokdae']!;
        final name = locale.languageCode == 'en'
            ? definition.name.en
            : definition.name.de;

        expect(find.byType(SoriProgressBar), findsNWidgets(2));
        expect(
          find.bySemanticsLabel('$name, ${t.questsSectionInProgress}'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('1 ${t.questsSectionInProgress}'),
          findsOneWidget,
        );
        final rewardSemantics = tester.widgetList<Semantics>(
          find.descendant(
            of: find.byType(SoriRewardThumb).first,
            matching: find.byType(Semantics),
          ),
        );
        expect(
          rewardSemantics.any(
            (widget) =>
                widget.properties.label ==
                decorName(t, definition.decorationSlug),
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'loading, retry, and empty states keep the shared Sori language',
    (tester) async {
      var shouldFail = true;
      await tester.pumpWidget(
        _host(
          QuestsScreen(
            loadQuests: () async {
              if (shouldFail) {
                throw StateError('fixture failure');
              }
              return const [];
            },
            persistNewCompletions: (_) async {},
          ),
        ),
      );

      expect(find.byType(AppLoading), findsOneWidget);
      await _finishLoad(tester);
      expect(find.byType(AppError), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.byIcon(Icons.refresh));
      await _finishLoad(tester);

      expect(find.byType(SoriEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DE and EN quest content reflows across the locked matrix', (
    tester,
  ) async {
    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final viewport in viewports) {
        await _configureView(tester, viewport.size);
        await tester.pumpWidget(
          _host(
            _screenWith(_mixedQuestStates),
            locale: locale,
            textScale: viewport.textScale,
          ),
        );
        await _finishLoad(tester);

        final definition = kQuestById['q_seollal']!;
        final lockedName = locale.languageCode == 'en'
            ? definition.name.en
            : definition.name.de;
        final target = find.text(lockedName);
        await tester.scrollUntilVisible(
          target,
          260,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(target);
        await tester.pump();

        expect(target, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

const _mixedQuestStates = <QuestProgress>[
  QuestProgress(
    questId: 'q_jangdokdae',
    current: 3,
    target: 15,
    active: true,
    completed: false,
    completedAtIso: null,
  ),
  QuestProgress(
    questId: 'q_maehwa',
    current: 0,
    target: 30,
    active: true,
    completed: false,
    completedAtIso: null,
  ),
  QuestProgress(
    questId: 'q_sonamu',
    current: 10,
    target: 10,
    active: true,
    completed: true,
    completedAtIso: '2026-08-20T00:00:00.000Z',
  ),
  QuestProgress(
    questId: 'q_seollal',
    current: 0,
    target: 5,
    active: false,
    completed: false,
    completedAtIso: null,
  ),
];

QuestsScreen _screenWith(List<QuestProgress> quests) => QuestsScreen(
  loadQuests: () async => quests,
  persistNewCompletions: (_) async {},
);

Future<void> _finishLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _configureView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('de'),
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
    return MediaQuery(
      data: media.copyWith(
        padding: safeInsets,
        viewPadding: safeInsets,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: SoriTypeScale(child: appChild!),
    );
  },
  home: child,
);
