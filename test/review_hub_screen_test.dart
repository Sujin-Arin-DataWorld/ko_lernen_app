import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sori_viewport_page.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_hub_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/learning_stage_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/real_fonts.dart';
import 'support/c_native_capture_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  setUp(() async {
    Storage.resetForTesting();
    final futureIso = Storage.todayIsoFor(
      DateTime.now().add(const Duration(days: 1)),
    );
    SharedPreferences.setMockInitialValues({
      'kl_study_log_v1_${Storage.todayIso()}': <String>['안녕', '학교'],
      'kl_study_log_v1_$futureIso': <String>['학교'],
    });
    await Storage.init();
  });

  test('the Lernen SRS catalog tile opens the review hub', () {
    final srs = soriActivityCatalog.singleWhere((entry) => entry.id == 'srs');

    expect(srs.route, '/review/hub');
  });

  testWidgets('today ledger entries resolve through the supplied vocabulary', (
    tester,
  ) async {
    await _pumpHub(tester);

    expect(find.text('안녕'), findsOneWidget);
    expect(find.byKey(const Key('review-hub-select-안녕')), findsOneWidget);
  });

  testWidgets('multiple words can be selected and update the CTA count', (
    tester,
  ) async {
    await _pumpHub(tester);

    final first = find.byKey(const Key('review-hub-select-안녕'));
    final second = find.byKey(const Key('review-hub-select-학교'));
    expect(tester.widget<CheckboxListTile>(first).value, isFalse);
    expect(tester.widget<CheckboxListTile>(second).value, isFalse);

    await showSoriViewportSection(tester, first);
    await tester.tap(first);
    await tester.pump();
    await showSoriViewportSection(tester, second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    await showSoriViewportSection(
      tester,
      find.byKey(const Key('review-hub-start-selected')),
    );

    expect(tester.widget<CheckboxListTile>(first).value, isTrue);
    expect(tester.widget<CheckboxListTile>(second).value, isTrue);
    final t = AppL10n.of(tester.element(find.byType(ReviewHubScreen)));
    expect(
      find.widgetWithText(TextButton, t.missionHeroReviewTitle(2)),
      findsOneWidget,
    );
  });

  testWidgets('zero selection disables review and select all can be cleared', (
    tester,
  ) async {
    await _pumpHub(tester);
    final start = find.byKey(const Key('review-hub-start-selected'));
    await showSoriViewportSection(tester, start);
    expect(tester.widget<TextButton>(start).onPressed, isNull);
    await showSoriViewportSection(tester, find.text('Alle auswählen'));
    await tester.tap(find.text('Alle auswählen'));
    await tester.pump();
    await showSoriViewportSection(tester, start);
    expect(tester.widget<TextButton>(start).onPressed, isNotNull);
    await showSoriViewportSection(tester, find.text('Auswahl aufheben'));
    await tester.tap(find.text('Auswahl aufheben'));
    await tester.pump();
    await showSoriViewportSection(tester, start);
    expect(tester.widget<TextButton>(start).onPressed, isNull);
  });

  testWidgets('archive searches only learned words within the chosen level', (
    tester,
  ) async {
    await _pumpHub(tester);
    await tester.tap(find.text('Nach Themen'));
    await tester.pumpAndSettle();
    expect(find.text('Begrüßung'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('review-archive-search')),
      'Schule',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bildung'), findsOneWidget);
    expect(find.text('Begrüßung'), findsNothing);
    await tester.tap(find.byKey(const Key('review-level-A2')));
    await tester.pumpAndSettle();
    expect(find.text('Bildung'), findsNothing);
  });

  testWidgets('packed words group by localized topic and match raw topics', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kl_study_log_v1_${Storage.todayIso()}', [
      '안녕하세요',
      '감사합니다',
      '죄송합니다',
    ]);
    await _pumpHub(
      tester,
      locale: const Locale('en'),
      reviewableLoader: () async => _captureWords,
    );
    await tester.tap(find.text('By topic'));
    await tester.pumpAndSettle();
    expect(find.text('Greetings & Politeness'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('review-archive-search')),
      'Höflichkeit',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Greetings & Politeness'));
    await tester.pumpAndSettle();
    expect(find.text('감사합니다'), findsOneWidget);
    expect(find.text('안녕하세요'), findsNothing);
  });

  testWidgets('a failed load is visible and can be retried', (tester) async {
    var attempts = 0;
    await _pumpHub(
      tester,
      reviewableLoader: () async {
        if (attempts++ == 0) throw StateError('unavailable');
        return _reviewableWords;
      },
    );
    expect(
      find.text('Die Wörter konnten nicht geladen werden.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('안녕'), findsOneWidget);
  });

  testWidgets('own learned words appear without a fabricated level', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kl_vok_seen_ids', ['책갈피']);
    const custom = Vocab(
      korean: '책갈피',
      romanization: 'chaekgalpi',
      german: 'Lesezeichen',
      level: '★',
      posDe: '',
      exampleKorean: '',
      exampleGerman: '',
      topic: '',
    );
    const unseen = Vocab(
      korean: '미지',
      romanization: 'miji',
      german: 'unbekannt',
      level: '★',
      posDe: '',
      exampleKorean: '',
      exampleGerman: '',
      topic: '',
    );
    await _pumpHub(
      tester,
      reviewableLoader: () async => [..._reviewableWords, custom, unseen],
    );
    await tester.tap(find.text('Nach Themen'));
    await tester.pumpAndSettle();
    await showSoriViewportSection(
      tester,
      find.byKey(const Key('review-own-words')),
    );
    await tester.tap(find.byKey(const Key('review-own-words')));
    await tester.pumpAndSettle();
    await showSoriViewportSection(tester, find.text('Weitere Wörter'));
    await tester.tap(find.text('Weitere Wörter'));
    await tester.pumpAndSettle();
    expect(find.text('책갈피'), findsOneWidget);
    expect(find.text('미지'), findsNothing);
  });

  testWidgets('selected real deck is passed to the session', (tester) async {
    await _pumpHub(tester);
    await showSoriViewportSection(
      tester,
      find.byKey(const Key('review-hub-select-안녕')),
    );
    await tester.tap(find.byKey(const Key('review-hub-select-안녕')));
    await tester.pumpAndSettle();
    final start = find.byKey(const Key('review-hub-start-selected'));
    await showSoriViewportSection(tester, start);
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final session = tester.widget<ReviewSessionScreen>(
      find.byType(ReviewSessionScreen),
    );
    expect(session.deck!.map((word) => word.korean), ['안녕']);
  });

  testWidgets('optional fixture captures of today and archive', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_REVIEW')) return;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const bool.fromEnvironment('CAPTURE_402')
        ? const Size(402, 874)
        : const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kl_study_log_v1_${Storage.todayIso()}', [
      '안녕하세요',
      '감사합니다',
      '죄송합니다',
    ]);
    await prefs.setStringList('kl_vok_seen_ids', ['괜찮아요']);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final captureContext = tester.element(find.byType(SizedBox).first);
    await tester.runAsync(() async {
      for (final path in [
        'assets/illustrations/concept_c/lernen_20261110/review-drawer.png',
        'assets/illustrations/concept_c/lernen_20261110/review-tray.png',
        'assets/illustrations/concept_c/lernen_20261110/brass-button.png',
        'assets/illustrations/concept_c/lernen_20261110/paper.png',
        'assets/illustrations/concept_c/lernen_20261110/jade.png',
        'assets/icons/navigation/today.png',
        'assets/icons/navigation/learn.png',
        'assets/icons/navigation/games.png',
        'assets/icons/navigation/hanok.png',
        'assets/icons/navigation/gye.png',
        'design_assets/hoeren/home-c-v1.png',
      ]) {
        await precacheImage(AssetImage(path), captureContext);
      }
    });
    await _pumpHub(tester, reviewableLoader: () async => _captureWords);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-hub-select-안녕하세요')));
    await tester.tap(find.byKey(const Key('review-hub-select-감사합니다')));
    await tester.pumpAndSettle();
    await settleCNativeCaptureAssets(tester);
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('review-hub-start-selected')))
          .dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byType(SoriLearningStageNavigation)).dy,
      ),
    );
    await _capture(tester, 'native-03.png');
    await tester.tap(find.text('Nach Themen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begrüßung & Höflichkeit'));
    await tester.pumpAndSettle();
    await settleCNativeCaptureAssets(tester);
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('review-hub-start-selected')))
          .dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byType(SoriLearningStageNavigation)).dy,
      ),
    );
    await _capture(tester, 'native-04.png');
  });

  testWidgets('calendar enables exactly the dates present in the ledger', (
    tester,
  ) async {
    await _pumpHub(tester);

    await showSoriViewportSection(
      tester,
      find.byKey(const Key('review-hub-calendar')),
    );
    await tester.tap(find.byKey(const Key('review-hub-calendar')));
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    expect(calendar.selectableDayPredicate!(today), isTrue);
    expect(calendar.selectableDayPredicate!(yesterday), isFalse);
  });

  testWidgets('calendar ignores canonical future ledger keys', (tester) async {
    final today = DateTime.now();
    final todayIso = Storage.todayIsoFor(today);
    final future = today.add(const Duration(days: 1));
    await _pumpHub(tester);

    final action = find.byKey(const Key('review-hub-calendar'));
    await showSoriViewportSection(tester, action);
    expect(tester.widget<OutlinedButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await tester.pump();
    expect(tester.takeException(), isNull);

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.selectableDayPredicate!(today), isTrue);
    expect(calendar.selectableDayPredicate!(future), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kl_study_log_v1_$todayIso');
    await _pumpHub(tester);
    await showSoriViewportSection(tester, action);
    expect(tester.widget<OutlinedButton>(action).onPressed, isNull);
  });

  testWidgets('calendar action waits for the reviewable vocabulary loader', (
    tester,
  ) async {
    final completer = Completer<List<Vocab>>();
    await _pumpHub(
      tester,
      reviewableLoader: () => completer.future,
      settle: false,
    );

    final action = find.byKey(const Key('review-hub-calendar'));
    expect(action, findsNothing);

    completer.complete(_reviewableWords);
    await tester.pumpAndSettle();
    await showSoriViewportSection(tester, action);
    expect(tester.widget<OutlinedButton>(action).onPressed, isNotNull);
  });

  testWidgets('320dp large-text layout has no overflow or clipping exception', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    await _pumpHub(tester, textScale: 2);

    final first = find.byKey(const Key('review-hub-select-안녕'));
    final start = find.byKey(const Key('review-hub-start-selected'));
    await showSoriViewportSection(tester, first);
    expect(
      tester.getSize(first).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    await showSoriViewportSection(tester, start);
    expect(
      tester.getSize(start).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    expect(tester.takeException(), isNull);
  });
}

const _reviewableWords = <Vocab>[
  Vocab(
    korean: '안녕',
    romanization: 'annyeong',
    german: 'Hallo',
    level: 'A1',
    posDe: 'Ausdruck',
    exampleKorean: '안녕!',
    exampleGerman: 'Hallo!',
    topic: 'Begrüßung',
  ),
  Vocab(
    korean: '학교',
    romanization: 'hakgyo',
    german: 'Schule',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '학교에 가요.',
    exampleGerman: 'Ich gehe zur Schule.',
    topic: 'Bildung',
  ),
];

const _captureWords = <Vocab>[
  Vocab(
    korean: '안녕하세요',
    romanization: '',
    german: 'Hallo (höflich)',
    level: 'A1',
    posDe: '',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'Begrüßung',
    packId: 'a1_greetings_1',
  ),
  Vocab(
    korean: '감사합니다',
    romanization: '',
    german: 'Vielen Dank (formell)',
    level: 'A1',
    posDe: '',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'Höflichkeit',
    packId: 'a1_greetings_1',
  ),
  Vocab(
    korean: '죄송합니다',
    romanization: '',
    german: 'Entschuldigung (formell)',
    level: 'A1',
    posDe: '',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'Höflichkeit',
    packId: 'a1_greetings_1',
  ),
  Vocab(
    korean: '괜찮아요',
    romanization: '',
    german: 'Alles gut',
    level: 'A1',
    posDe: '',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'Alltag',
  ),
];

Future<void> _pumpHub(
  WidgetTester tester, {
  double textScale = 1,
  Locale locale = const Locale('de'),
  Future<List<Vocab>> Function()? reviewableLoader,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('review-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        theme: AppTheme.light,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: ReviewHubScreen(
              reviewableLoader:
                  reviewableLoader ?? () async => _reviewableWords,
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('review-capture')),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${const String.fromEnvironment('REVIEW_CAPTURE_DIR', defaultValue: '.')}/$name',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
