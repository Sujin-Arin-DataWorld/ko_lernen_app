import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/screens/gye_create_screen.dart';
import 'package:ko_lernen_app/screens/gye_join_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'support/privacy_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _packId = 'analytics-flow-fixture';
const _words = [
  ExtractedWord(
    korean: '학교',
    romanization: '',
    posDe: '',
    translationDe: 'Schule',
    translationEn: 'school',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '책',
    romanization: '',
    posDe: '',
    translationDe: 'Buch',
    translationEn: 'book',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
];
const _meta = GyeMeta(
  id: 'ABC234',
  code: 'ABC234',
  name: 'Morning Tigers',
  ownerId: 'fixture-user',
);

class _HeldAnalytics extends PrivacyFakeAnalytics {
  // Create the held native reply in the caller's zone, including test zones.
  Completer<void>? _held;
  Completer<void> get held => _held ??= Completer<void>();
  final payloads = <Map<String, Object>?>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    events.add(name);
    payloads.add(parameters);
    if (name == 'game_completed' ||
        name == 'gye_created' ||
        name == 'gye_joined') {
      return held.future;
    }
    return Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _HeldAnalytics analytics;

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpMatching': true,
      'kl_tut_cpTyping': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    await Storage.setBirthYear(1990);
    analytics = _HeldAnalytics();
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: PrivacyFakeCrash(),
    );
    Analytics.configureForTesting(client: analytics);
    await CustomPackService.save(
      CustomPack.manual(
        id: _packId,
        name: 'Private fixture name',
        words: _words,
      ),
    );
  });

  tearDown(() {
    Analytics.configureForTesting();
    Storage.resetForTesting();
  });

  for (final locale in ['de', 'en']) {
    for (final flow in ['join', 'create', 'typing', 'matching']) {
      for (final delivery in ['late success', 'late error', 'denied']) {
        testWidgets(
          '$locale $flow completes independently of $delivery analytics',
          (tester) async {
            final semantics = tester.ensureSemantics();
            final sessions = ValueNotifier<CloudWriteSession?>(
              const CloudWriteSession(
                uid: 'fixture-user',
                epoch: 1,
                mode: CloudWriteMode.ready,
              ),
            );
            addTearDown(sessions.dispose);
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            try {
              await tester.runAsync(
                () => PrivacyConsentService.setAnalytics(delivery != 'denied'),
              );
              expect(Analytics.canCollect, delivery != 'denied');
              var writes = 0;
              var arrivals = 0;
              final t = lookupAppL10n(Locale(locale));
              final screen = switch (flow) {
                'join' => GyeJoinScreen(
                  accountSessions: sessions,
                  joinGye: ({required code, required nickname}) async {
                    writes++;
                    expect(code, 'ABC234');
                    expect(nickname, 'Mina');
                    return _meta;
                  },
                ),
                'create' => GyeCreateScreen(
                  accountSessions: sessions,
                  createGye:
                      ({
                        required name,
                        required nickname,
                        required weeklyPromiseId,
                      }) async {
                        writes++;
                        expect(name, 'Morning Tigers');
                        expect(nickname, 'Mina');
                        return _meta;
                      },
                ),
                'typing' => CustomPackTypingScreen(
                  packId: _packId,
                  words: [_words.first],
                ),
                _ => const CustomPackMatchingScreen(
                  packId: _packId,
                  words: _words,
                ),
              };
              await tester.pumpWidget(
                MaterialApp(
                  theme: AppTheme.light,
                  locale: Locale(locale),
                  supportedLocales: AppL10n.supportedLocales,
                  localizationsDelegates: AppL10n.localizationsDelegates,
                  home: screen,
                  onGenerateRoute: (settings) {
                    expect(settings.name, '/gye');
                    expect(settings.arguments, 'ABC234');
                    arrivals++;
                    return MaterialPageRoute<void>(
                      builder: (_) =>
                          const Scaffold(body: Text('Joined group')),
                    );
                  },
                ),
              );
              await _pumpFrames(tester);
              if (flow == 'join' || flow == 'create') {
                await tester.enterText(
                  find.byType(TextField).at(0),
                  flow == 'join' ? 'ABC234' : 'Morning Tigers',
                );
                await tester.enterText(find.byType(TextField).at(1), 'Mina');
                await _tapButton(
                  tester,
                  flow == 'join' ? t.gyeJoinCta : t.gyeCreateCta,
                );
                await _pumpFrames(tester);
                expect(writes, 1);
                if (flow == 'create') {
                  expect(find.text('ABC234'), findsOneWidget);
                  await _tapButton(tester, t.gyeOpenCta);
                  await _pumpFrames(tester);
                }
                expect(find.text('Joined group'), findsOneWidget);
                expect(arrivals, 1);
              } else {
                if (flow == 'typing') {
                  await tester.enterText(find.byType(TextField), '학교');
                  await _tapButton(tester, t.btnSubmit);
                  await _tapButton(tester, t.btnNext);
                } else {
                  for (final word in _words) {
                    await tester.tap(find.bySemanticsLabel(word.korean));
                    await tester.pump();
                    await tester.tap(
                      find.bySemanticsLabel(word.translationFor(locale)),
                    );
                    await _pumpFrames(tester);
                  }
                }
                await _pumpFrames(tester);
                expect(Storage.xp, flow == 'typing' ? 5 : 8);
                expect(Storage.srsCard('학교')?.reviewCount, 1);
                expect(
                  find.widgetWithText(SoriButton, t.quizAgain),
                  findsOneWidget,
                );
              }
              final completionEvent = flow == 'join'
                  ? 'gye_joined'
                  : flow == 'create'
                  ? 'gye_created'
                  : 'game_completed';
              expect(
                analytics.events.where((name) => name == completionEvent),
                hasLength(delivery == 'denied' ? 0 : 1),
              );
              if (delivery == 'denied') {
                expect(analytics.events, isEmpty);
              }
              final xp = Storage.xp;
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
              expect(analytics.events, isNot(contains('quest_abandon')));
              if (delivery == 'late error') {
                analytics.held.completeError(
                  StateError('Analytics SDK reply failed'),
                );
              } else {
                analytics.held.complete();
              }
              await tester.pump();
              expect(Storage.xp, xp);
              expect(arrivals, flow == 'join' || flow == 'create' ? 1 : 0);
              expect(tester.takeException(), isNull);
            } finally {
              if (!analytics.held.isCompleted) {
                analytics.held.complete();
                await tester.pump();
              }
              semantics.dispose();
            }
          },
        );
      }
    }
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(SoriButton, label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _pumpFrames(tester);
}
