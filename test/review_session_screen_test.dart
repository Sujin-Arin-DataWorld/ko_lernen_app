import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      'kl_tut_review': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    SoriSpeech.resetForTesting();
    SoriSpeech.speakImpl = (_, _) async => true;
  });

  tearDown(SoriSpeech.resetForTesting);

  testWidgets(
    'served-history previous and forward show real cards without SRS or XP writes',
    (tester) async {
      await _pumpReview(tester);

      expect(_currentCardText('학교'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await _flip(tester);
      _feed(tester).onHard!();
      await _settleTransition(tester);

      expect(_currentCardText('선생님'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);

      await _flip(tester);
      _feed(tester).onNext!();
      await _settleTransition(tester);

      expect(_currentCardText('학교'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(Storage.srsCard('학교')?.reviewCount, 1);
      expect(Storage.srsCard('선생님')?.reviewCount, 1);
      expect(Storage.wrongCountOf('학교'), 1);
      expect(Storage.xp, 0);

      final beforeA = Storage.srsCard('학교')?.reviewCount;
      final beforeB = Storage.srsCard('선생님')?.reviewCount;

      _feed(tester).onPrevious!();
      await _settleTransition(tester);
      expect(_currentCardText('선생님'), findsOneWidget);

      _feed(tester).onPrevious!();
      await _settleTransition(tester);
      expect(_currentCardText('학교'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      _feed(tester).onNext!();
      await _settleTransition(tester);
      expect(_currentCardText('선생님'), findsOneWidget);

      _feed(tester).onNext!();
      await _settleTransition(tester);
      expect(_currentCardText('학교'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);

      expect(Storage.srsCard('학교')?.reviewCount, beforeA);
      expect(Storage.srsCard('선생님')?.reviewCount, beforeB);
      expect(Storage.wrongCountOf('학교'), 1);
      expect(Storage.xp, 0);

      await _flip(tester);
      _feed(tester).onHard!();
      await _settleTransition(tester);

      expect(Storage.srsCard('학교')?.reviewCount, 1);
      expect(Storage.srsCard('선생님')?.reviewCount, 1);
      expect(Storage.wrongCountOf('학교'), 2);
      expect(Storage.xp, 4);
      expect(find.text('+4 XP'), findsOneWidget);
    },
  );

  testWidgets('review session opts into snap feed physics (지시서 1.7)', (
    tester,
  ) async {
    await _pumpReview(tester);
    expect(_feed(tester).physics, FeedPhysics.snap);
  });

  testWidgets(
    'history exposes semantic navigation and oldest-card downward fling stays put',
    (tester) async {
      await _pumpReview(tester);

      await _flip(tester);
      _feed(tester).onHard!();
      await _settleTransition(tester);
      await _flip(tester);
      _feed(tester).onNext!();
      await _settleTransition(tester);

      final t = AppL10n.of(tester.element(find.byType(ReviewSessionScreen)));

      Set<String> semanticActionLabels() {
        return tester
            .widgetList<Semantics>(find.byType(Semantics))
            .expand(
              (widget) =>
                  widget.properties.customSemanticsActions?.keys ??
                  const <CustomSemanticsAction>[],
            )
            .map((action) => action.label)
            .whereType<String>()
            .toSet();
      }

      expect(semanticActionLabels(), contains(t.legacyVocabPrevious));
      expect(semanticActionLabels(), isNot(contains(t.btnNext)));

      _feed(tester).onPrevious!();
      await _settleTransition(tester);
      expect(_currentCardText('선생님'), findsOneWidget);
      expect(
        semanticActionLabels(),
        containsAll(<String>[t.legacyVocabPrevious, t.btnNext]),
      );

      _feed(tester).onPrevious!();
      await _settleTransition(tester);
      expect(_currentCardText('학교'), findsOneWidget);
      expect(semanticActionLabels(), isNot(contains(t.legacyVocabPrevious)));
      expect(semanticActionLabels(), contains(t.btnNext));

      await tester.drag(
        find.byKey(const ValueKey('deck-card-slot')),
        const Offset(0, 220),
      );
      await tester.pumpAndSettle();

      expect(
        _currentCardText('학교'),
        findsOneWidget,
        reason: 'oldest history has no previous card, so down must spring back',
      );
    },
  );
}

Future<void> _pumpReview(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: ReviewSessionScreen(
          deck: _deck,
          cultureNotesLoader: () async {},
        ),
      ),
    ),
  );
  await _settleTransition(tester);
}

Future<void> _flip(WidgetTester tester) async {
  final card = find.byKey(const ValueKey('deck-card-slot'));
  final pressable = find.ancestor(
    of: card,
    matching: find.byType(SoriPressable),
  );
  tester.widget<SoriPressable>(pressable).onTap!();
  await tester.pump();
}

SoriContentFeed _feed(WidgetTester tester) {
  return tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
}

Finder _currentCardText(String text) {
  return find.descendant(
    of: find.byKey(const ValueKey('deck-card-slot')),
    matching: find.text(text),
  );
}

Future<void> _settleTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _deck = <Vocab>[
  Vocab(
    id: 'review-a',
    korean: '학교',
    romanization: 'hakgyo',
    german: 'Schule',
    english: 'school',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '학교에 가다',
    exampleGerman: 'Zur Schule gehen',
    topic: 'Bildung',
  ),
  Vocab(
    id: 'review-b',
    korean: '선생님',
    romanization: 'seonsaengnim',
    german: 'Lehrer',
    english: 'teacher',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '선생님이 오다',
    exampleGerman: 'Der Lehrer kommt',
    topic: 'Bildung',
  ),
];
