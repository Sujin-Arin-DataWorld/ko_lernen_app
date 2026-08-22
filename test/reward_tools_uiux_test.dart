import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _matrix = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];
final _glossaryFixture = CulturalGlossary.fromJsonString('''
{
  "schemaVersion": 1,
  "entries": [
    {
      "termId": "sagunja",
      "ko": "사군자",
      "romanization": "Sagunja",
      "localizations": {
        "de": {"meaning": "Die vier Edlen.", "story": "Eine Kulturgeschichte."},
        "en": {"meaning": "The four gentlemen.", "story": "A cultural story."},
        "ko": {"meaning": "네 식물이에요.", "story": "문화 이야기예요."}
      },
      "decorationSlugs": [
        "decoration_sagunja_guk",
        "decoration_sagunja_juk"
      ],
      "sources": [
        {"title": "Fixture", "url": "https://example.com/sagunja"}
      ]
    }
  ]
}
''');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    CulturalGlossaryRepository.resetForTesting();
    CulturalGlossaryRepository.setLoaderForTesting(
      () async => _glossaryFixture,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_dojang': true,
    });
    await Storage.init();
  });

  testWidgets('populated reward tools reflow in the locked DE/EN matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    await Storage.addEarnedStamp(DancheongMotif.lotus.name);
    await Storage.setPendingBoxes(const <String>['q_punggyeong']);
    final candidates = DecorationRewardService.candidatesForQuest(
      'q_punggyeong',
    );

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      final lotus = dancheongMotifName(t, DancheongMotif.lotus);
      final plum = dancheongMotifName(t, DancheongMotif.plum);
      final lastDecoration = decorName(t, candidates.last);
      for (final testCase in _matrix) {
        await _pumpScreen(
          tester,
          const DojangcheopScreen(),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );
        await tester.pump(const Duration(milliseconds: 800));

        await tester.scrollUntilVisible(
          find.text(t.dojangDecorHintCta),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        final roomButton = find.widgetWithText(
          SoriButton,
          t.dojangDecorHintCta,
        );
        expect(tester.getSize(roomButton).height, greaterThanOrEqualTo(48));
        _expectActionSemantics(
          tester,
          _soriButtonSemantics(roomButton),
          t.dojangDecorHintCta,
        );
        expect(
          find.bySemanticsLabel(t.dojangStampEarned(lotus)),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(t.dojangStampLocked(plum)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await _pumpScreen(
          tester,
          const BojagiScreen(),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );
        await _finishBojagiAsync(tester);

        final knot = find.bySemanticsLabel(t.bojagiOpenHint);
        expect(tester.getSize(knot).shortestSide, greaterThanOrEqualTo(48));
        _expectActionSemantics(tester, knot, t.bojagiOpenHint);
        await tester.tap(knot);
        await _finishBojagiAsync(tester);

        final lastName = find.text(lastDecoration);
        await tester.ensureVisible(lastName);
        await tester.pump();
        final paragraph = tester.renderObject<RenderParagraph>(lastName);
        expect(paragraph.didExceedMaxLines, isFalse);
        final choose = find.bySemanticsLabel(
          t.bojagiChooseDecoration(lastDecoration),
        );
        expect(tester.getSize(choose).height, greaterThanOrEqualTo(48));
        _expectActionSemantics(
          tester,
          choose,
          t.bojagiChooseDecoration(lastDecoration),
        );
        final candidate = tester.widget<Container>(
          find.byKey(ValueKey('bojagi-candidate-${candidates.last}')),
        );
        final decoration = candidate.decoration! as BoxDecoration;
        final border = decoration.border! as Border;
        expect(
          SoriColors.contrastRatio(border.top.color, SoriColors.lightBg),
          greaterThanOrEqualTo(3),
        );
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets('dojang empty CTA is reachable and opens vocab packs', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      await _pumpScreen(
        tester,
        const DojangcheopScreen(),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.pump(const Duration(milliseconds: 800));

      await tester.ensureVisible(find.text(t.dojangEmptyCta));
      await tester.pump();
      final cta = find.widgetWithText(SoriButton, t.dojangEmptyCta);
      expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
      _expectActionSemantics(
        tester,
        _soriButtonSemantics(cta),
        t.dojangEmptyCta,
      );
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.text('vocab-packs-destination'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpScreen(
        tester,
        const BojagiScreen(),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await _finishBojagiAsync(tester);
      expect(
        find.widgetWithText(SoriEmptyState, t.bojagiEmptyTitle),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text(t.bojagiEmptyBody));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets(
    'bojagi loading failure is live, preserves the queue, and retries',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        await Storage.setPendingBoxes(const <String>['q_punggyeong']);
        final firstLoad = Completer<DecorationRewardOffer>();
        var attempts = 0;

        Future<DecorationRewardOffer> loadOffer() {
          attempts += 1;
          if (attempts == 1) {
            return firstLoad.future;
          }
          return DecorationRewardService.loadNextOffer();
        }

        final t = lookupAppL10n(locale);
        await _pumpScreen(
          tester,
          BojagiScreen(offerLoader: loadOffer),
          locale: locale,
          size: const Size(320, 640),
          textScale: 2,
        );
        await tester.pump();

        expect(find.byType(AppLoading), findsOneWidget);
        final loadingData = tester
            .getSemantics(find.bySemanticsLabel(t.bojagiLoading))
            .getSemanticsData();
        expect(loadingData.label, t.bojagiLoading);
        expect(loadingData.flagsCollection.isLiveRegion, isTrue);

        firstLoad.completeError(StateError('fixture load failure'));
        await _finishBojagiAsync(tester);

        expect(find.byType(AppError), findsOneWidget);
        final errorData = tester
            .getSemantics(find.bySemanticsLabel(t.bojagiProblemBody))
            .getSemanticsData();
        expect(errorData.label, t.bojagiProblemBody);
        expect(errorData.flagsCollection.isLiveRegion, isTrue);
        expect(Storage.pendingBoxes, const <String>['q_punggyeong']);

        await tester.ensureVisible(find.text(t.bojagiRetry));
        await tester.pump();
        final retry = find.bySemanticsLabel(t.bojagiRetry);
        _expectActionSemantics(tester, retry, t.bojagiRetry);
        await tester.tap(retry);
        await _finishBojagiAsync(tester);

        expect(find.byType(AppError), findsNothing);
        expect(find.bySemanticsLabel(t.bojagiOpenHint), findsOneWidget);
        expect(Storage.pendingBoxes, const <String>['q_punggyeong']);
        expect(attempts, 2);
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets('a claimed decoration remains visible if next-offer load fails', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    await Storage.setPendingBoxes(const <String>['q_punggyeong']);
    var loads = 0;

    Future<DecorationRewardOffer> loadOffer() {
      loads += 1;
      if (loads == 1) {
        return DecorationRewardService.loadNextOffer();
      }
      return Future<DecorationRewardOffer>.error(
        StateError('fixture next-offer failure'),
      );
    }

    const locale = Locale('en');
    final t = lookupAppL10n(locale);
    final slug = DecorationRewardService.candidatesForQuest(
      'q_punggyeong',
    ).first;
    await _pumpScreen(
      tester,
      BojagiScreen(offerLoader: loadOffer),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _finishBojagiAsync(tester);
    await tester.tap(find.bySemanticsLabel(t.bojagiOpenHint));
    await _finishBojagiAsync(tester);
    await tester.tap(
      find.bySemanticsLabel(t.bojagiChooseDecoration(decorName(t, slug))),
    );
    await _finishBojagiAsync(tester);

    final announcement = tester
        .getSemantics(
          find.bySemanticsLabel(
            t.bojagiClaimedAnnouncement(decorName(t, slug)),
          ),
        )
        .getSemanticsData();
    expect(announcement.label, t.bojagiClaimedAnnouncement(decorName(t, slug)));
    expect(announcement.flagsCollection.isLiveRegion, isTrue);
    expect(find.byType(AppError), findsNothing);
    expect(Storage.ownedDecor, contains(slug));
    expect(Storage.pendingBoxes, isEmpty);
    expect(loads, 2);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('decoration choice and cultural help remain separate actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    await Storage.setPendingBoxes(const <String>['q_punggyeong']);
    const locale = Locale('de');
    final t = lookupAppL10n(locale);
    final candidates = DecorationRewardService.candidatesForQuest(
      'q_punggyeong',
    );
    final helpedSlug = candidates.first;
    final culturalLabel = t.culturalHelpSemantics('사군자');
    final chooseLabel = t.bojagiChooseDecoration(decorName(t, helpedSlug));

    await _pumpScreen(
      tester,
      const BojagiScreen(),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _finishBojagiAsync(tester);
    await tester.tap(find.bySemanticsLabel(t.bojagiOpenHint));
    await _finishBojagiAsync(tester);

    final choose = find.bySemanticsLabel(chooseLabel);
    final help = find.bySemanticsLabel(culturalLabel);
    expect(choose, findsOneWidget);
    expect(help, findsOneWidget);
    _expectActionSemantics(tester, choose, chooseLabel);
    _expectActionSemantics(tester, help, culturalLabel);
    expect(tester.getSize(help).shortestSide, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

void _expectActionSemantics(WidgetTester tester, Finder finder, String label) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

Finder _soriButtonSemantics(Finder button) =>
    find.descendant(of: button, matching: find.byType(Semantics)).first;

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/vocab': (_) => const Scaffold(
          body: Center(child: Text('vocab-packs-destination')),
        ),
        '/sarangbang/furnish': (_) =>
            const Scaffold(body: Center(child: Text('furnish-destination'))),
      },
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _safeInsets,
            viewPadding: _safeInsets,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: screen,
    ),
  );
}

Future<void> _finishBojagiAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void _resetViewAfterTest(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
