import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/culture_notes_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    CultureNotesService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_review': true,
      'kl_tut_legacyVocab': true,
    });
    await Storage.init();
  });

  for (final screenCase in _screenCases) {
    testWidgets('${screenCase.name} contains a culture-note load failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          screenCase.build(() async {
            throw StateError('optional culture-note failure');
          }),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${screenCase.name} ignores culture-note completion after disposal',
      (tester) async {
        final completer = Completer<void>();
        await tester.pumpWidget(_app(screenCase.build(() => completer.future)));
        await tester.pump();

        await tester.pumpWidget(_app(const SizedBox.shrink()));
        completer.complete();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

typedef _ScreenBuilder = Widget Function(Future<void> Function() loader);

class _ScreenCase {
  const _ScreenCase(this.name, this.build);

  final String name;
  final _ScreenBuilder build;
}

final _screenCases = <_ScreenCase>[
  _ScreenCase(
    'review session',
    (loader) => ReviewSessionScreen(
      deck: const <Vocab>[_word],
      cultureNotesLoader: loader,
    ),
  ),
  _ScreenCase(
    'legacy vocab',
    (loader) => LegacyVocabScreen(
      vocabLoader: () async => const <Vocab>[_word],
      cultureNotesLoader: loader,
    ),
  ),
];

const _word = Vocab(
  id: 'culture-lifecycle-word',
  korean: '문화',
  romanization: 'munhwa',
  german: 'Kultur',
  english: 'culture',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_culture_lifecycle',
  packOrder: 1,
);
