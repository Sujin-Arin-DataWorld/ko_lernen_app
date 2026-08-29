import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  testWidgets('delayed loader remains in loading instead of empty', (
    tester,
  ) async {
    final completer = Completer<List<Vocab>>();
    await _pumpReview(tester, () => completer.future);

    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.text(_t.reviewEmptyTitle), findsNothing);

    completer.complete(const <Vocab>[_word]);
    await tester.pump();
    expect(find.text(_word.korean), findsOneWidget);
  });

  testWidgets('successful empty loader renders the true empty state', (
    tester,
  ) async {
    await _pumpReview(tester, () async => const <Vocab>[]);
    await tester.pump();

    expect(find.byType(AppLoading), findsNothing);
    expect(find.text(_t.reviewEmptyTitle), findsOneWidget);
  });

  testWidgets('load error is localized and retry can reach ready', (
    tester,
  ) async {
    var calls = 0;
    await _pumpReview(tester, () async {
      calls++;
      if (calls == 1) {
        throw StateError('raw loader secret');
      }
      return const <Vocab>[_word];
    });
    await tester.pump();

    expect(find.text(_t.loadErrorTryAgain), findsOneWidget);
    expect(find.textContaining('raw loader secret'), findsNothing);
    expect(find.text(_t.reviewEmptyTitle), findsNothing);

    await tester.tap(find.text(_t.btnRetry));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.text(_word.korean), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

late AppL10n _t;

Future<void> _pumpReview(WidgetTester tester, ReviewableLoader loader) async {
  _t = await AppL10n.delegate.load(const Locale('de'));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: ReviewSessionScreen(reviewableLoader: loader),
    ),
  );
  await tester.pump();
}

const _word = Vocab(
  id: 'review-loading-word',
  korean: '복습',
  romanization: 'bokseup',
  german: 'Wiederholung',
  english: 'review',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_review_loading',
  packOrder: 1,
);
