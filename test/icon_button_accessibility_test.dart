import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/stats_top_bar.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  late SoriSpeechStub speech;
  setUp(() async {
    speech = stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_legacyVocab': true,
      'kl_tut_review': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    DataLoader.reset();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final profileLabel in <String?>[null, '   ', 'Custom profile']) {
      testWidgets('${locale.languageCode} header icons label, explain and act '
          'at 320dp/200% (profile: $profileLabel)', (tester) async {
        _viewport(tester, const Size(320, 640));
        final semantics = tester.ensureSemantics();
        try {
          final t = await AppL10n.delegate.load(locale);
          var profileTaps = 0;
          await tester.pumpWidget(
            _app(
              locale,
              Scaffold(
                body: SoriStatsTopBar(
                  streak: 7,
                  level: 4,
                  xp: 320,
                  onStreakTap: () {},
                  onStatsTap: () {},
                  onProfileTap: () => profileTaps++,
                  profileTooltip: profileLabel,
                ),
              ),
              textScale: 2,
            ),
          );
          await tester.pump();
          final expectedProfile = profileLabel?.trim().isNotEmpty == true
              ? profileLabel!.trim()
              : t.soriStageProfileTooltip;
          for (final label in [expectedProfile, t.settingsTitle]) {
            expect(find.byTooltip(label), findsOneWidget);
            _expectButton(tester, label);
            final size = tester.getSize(find.byTooltip(label));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          await tester.longPress(find.byTooltip(t.settingsTitle));
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text(t.settingsTitle), findsOneWidget);
          expect(profileTaps, 0);
          await tester.tap(find.byTooltip(expectedProfile));
          await tester.pump();
          expect(profileTaps, 1);
          await tester.tap(find.byTooltip(t.settingsTitle));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            find.byKey(const ValueKey('settings-destination')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('${locale.languageCode} example audio retains tap and slow '
        'long press with a labeled 48dp target', (tester) async {
      _viewport(tester, const Size(390, 844));
      final semantics = tester.ensureSemantics();
      try {
        final t = await AppL10n.delegate.load(locale);
        await tester.pumpWidget(
          _app(
            locale,
            LegacyVocabScreen(vocabLoader: () async => const [_word]),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final label = t.ttsListenTarget(_word.exampleKorean);
        expect(find.byTooltip(label), findsOneWidget);
        _expectButton(tester, label);
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.longPress),
          isTrue,
        );
        expect(node.getSemanticsData().hint, t.vocabSlowHint);
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        speech.spoken.clear();
        speech.spokenSlow.clear();
        await tester.tap(find.byTooltip(label));
        await tester.pump();
        await tester.longPress(find.byTooltip(label));
        await tester.pump();
        expect(speech.spoken, [_word.exampleKorean]);
        expect(speech.spokenSlow, [_word.exampleKorean]);
        expect(tester.widget<FlipCard>(find.byType(FlipCard)).flipped, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('${locale.languageCode} completed review bonus audio has a '
        'labeled 48dp control', (tester) async {
      _viewport(tester, const Size(390, 844));
      final semantics = tester.ensureSemantics();
      try {
        final t = await AppL10n.delegate.load(locale);
        await tester.pumpWidget(
          _app(
            locale,
            const ReviewSessionScreen(deck: [_word], bonusPhrase: _bonus),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byKey(deckActionKey('flip')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(deckActionKey('know')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final label = t.ttsListenTarget(_bonus.ko);
        expect(find.byTooltip(label), findsOneWidget);
        await tester.ensureVisible(find.byTooltip(label));
        await tester.pump();
        _expectButton(tester, label);
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(Storage.srsCard(_word.korean)?.reviewCount, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}

void _expectButton(WidgetTester tester, String label) {
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Locale locale, Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: child!,
  ),
  routes: {
    '/settings': (_) => const Scaffold(key: ValueKey('settings-destination')),
  },
  home: home,
);

const _word = Vocab(
  id: 'a11y-apple',
  korean: '사과',
  romanization: 'sagwa',
  german: 'Apfel',
  english: 'apple',
  level: 'A1',
  posDe: 'N.',
  topic: 'food',
  exampleKorean: '사과를 먹어요.',
  exampleGerman: 'Ich esse einen Apfel.',
);
const _bonus = SmalltalkPhrase(
  id: 'a11y-bonus',
  category: 'greetings',
  level: 'A1',
  kind: 'statement',
  ko: '좋은 하루 보내세요.',
  de: 'Einen schönen Tag noch.',
  en: 'Have a nice day.',
);
