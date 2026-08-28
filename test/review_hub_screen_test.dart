import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_hub_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_study_log_v1_${Storage.todayIso()}': <String>['안녕', '학교'],
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

    await tester.tap(first);
    await tester.pump();
    await tester.tap(second);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(first).value, isTrue);
    expect(tester.widget<CheckboxListTile>(second).value, isTrue);
    final t = AppL10n.of(tester.element(find.byType(ReviewHubScreen)));
    expect(
      find.widgetWithText(SoriButton, t.reviewHubStartSelected(2)),
      findsOneWidget,
    );
  });

  testWidgets('calendar enables exactly the dates present in the ledger', (
    tester,
  ) async {
    await _pumpHub(tester);

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
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(first, 200, scrollable: scrollable);
    expect(
      tester.getSize(first).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    await tester.scrollUntilVisible(start, 200, scrollable: scrollable);
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

Future<void> _pumpHub(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ReviewHubScreen(reviewableLoader: () async => _reviewableWords),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
