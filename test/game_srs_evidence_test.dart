import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

const _matchingPackId = 'srs-evidence-pack';

const _matchingWords = [
  ExtractedWord(
    korean: '하나',
    romanization: 'hana',
    posDe: 'Zahl',
    translationDe: 'eins',
    translationEn: 'one',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '둘',
    romanization: 'dul',
    posDe: 'Zahl',
    translationDe: 'zwei',
    translationEn: 'two',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
];

const _speedWords = [
  Vocab(
    korean: '하나',
    romanization: 'hana',
    german: 'eins',
    level: 'a1',
    posDe: 'Zahl',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '둘',
    romanization: 'dul',
    german: 'zwei',
    level: 'a1',
    posDe: 'Zahl',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_cpMatching': true});
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: _matchingPackId,
        name: 'SRS evidence',
        words: _matchingWords,
      ),
    );
  });

  testWidgets('matching first-try success keeps its positive SRS credit', (
    tester,
  ) async {
    await Storage.srsReview('하나', gotIt: true);
    await _pumpMatching(tester);

    await _match(tester, korean: '하나', translation: 'eins');

    final card = Storage.srsCard('하나')!;
    expect(card.intervalDays, 3);
    expect(card.reviewCount, 2);
    expect(Storage.wrongCountOf('하나'), 0);
  });

  testWidgets('matching correction keeps the first-miss SRS evidence', (
    tester,
  ) async {
    await Storage.srsReview('하나', gotIt: true);
    await _pumpMatching(tester);

    await tester.tap(find.text('하나'));
    await tester.pump();
    await tester.tap(find.text('zwei'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('zwei'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('eins'));
    await tester.pump();

    final card = Storage.srsCard('하나')!;
    expect(card.intervalDays, 1);
    expect(card.reviewCount, 2);
    expect(Storage.wrongCountOf('하나'), 1);
  });

  testWidgets('Speed Match first-try success keeps its positive SRS credit', (
    tester,
  ) async {
    await Storage.srsReview('하나', gotIt: true);
    await _pumpSpeedMatch(tester);

    await _speedMatch(tester, korean: '하나', rightKorean: '하나');

    final card = Storage.srsCard('하나')!;
    expect(card.intervalDays, 3);
    expect(card.reviewCount, 2);
    expect(Storage.wrongCountOf('하나'), 0);
  });

  testWidgets('Speed Match correction keeps the first-miss SRS evidence', (
    tester,
  ) async {
    await Storage.srsReview('하나', gotIt: true);
    await _pumpSpeedMatch(tester);

    await _speedMatch(tester, korean: '하나', rightKorean: '둘');
    await tester.pump(const Duration(milliseconds: 500));
    await _speedMatch(tester, korean: '하나', rightKorean: '둘');
    await tester.pump(const Duration(milliseconds: 500));
    await _speedMatch(tester, korean: '하나', rightKorean: '하나');

    final card = Storage.srsCard('하나')!;
    expect(card.intervalDays, 1);
    expect(card.reviewCount, 2);
    expect(Storage.wrongCountOf('하나'), 1);
  });
}

Future<void> _pumpMatching(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(const CustomPackMatchingScreen(packId: _matchingPackId)),
  );
  await tester.pump();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpSpeedMatch(WidgetTester tester) async {
  await tester.pumpWidget(_wrap(const SpeedMatchScreen(items: _speedWords)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _match(
  WidgetTester tester, {
  required String korean,
  required String translation,
}) async {
  await tester.tap(find.text(korean));
  await tester.pump();
  await tester.tap(find.text(translation));
  await tester.pump();
}

Future<void> _speedMatch(
  WidgetTester tester, {
  required String korean,
  required String rightKorean,
}) async {
  await tester.tap(find.byKey(ValueKey('speed-match-left-$korean')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('speed-match-right-$rightKorean')));
  await tester.pump();
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
