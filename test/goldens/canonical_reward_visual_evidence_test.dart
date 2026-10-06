import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/companion_art.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_reward_moment.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_reward_presentation.dart';

import '../support/real_fonts.dart';

// Local rendered evidence only. Linux regression baselines are untouched.
const _directory = String.fromEnvironment('CANONICAL_REWARD_EVIDENCE_DIR');

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_snd_master': false,
      'kl_haptics_enabled': false,
    });
    await Storage.init();
  });

  for (final dark in [false, true]) {
    for (final family in ['taego', 'joy']) {
      testWidgets(
        'canon $family on ${dark ? 'dark' : 'light'}',
        skip: _directory.isEmpty,
        (tester) async {
          _size(tester, const Size(880, 1380));
          final assets = family == 'taego'
              ? [
                  CompanionArt.taego,
                  CompanionArt.taegoGuide,
                  CompanionArt.taegoSeated,
                  CompanionArt.taegoPortrait,
                ]
              : [
                  CompanionArt.joy,
                  CompanionArt.joyGuide,
                  CompanionArt.joyCelebrate,
                  CompanionArt.joyPortrait,
                ];
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '$family · 42 / 54 / 144 / 288 dp',
                        style: const TextStyle(fontSize: 24),
                      ),
                      for (final asset in assets)
                        Expanded(
                          child: Column(
                            children: [
                              Text(asset.split('/').last),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    for (final size in <double>[
                                      42,
                                      54,
                                      144,
                                      288,
                                    ])
                                      SizedBox.square(
                                        dimension: size,
                                        child: Image.asset(
                                          asset,
                                          fit: BoxFit.contain,
                                          cacheWidth: size.toInt(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              dark: dark,
            ),
          );
          await _capture(tester, 'canon-$family-${dark ? 'dark' : 'light'}');
        },
      );
    }
    for (final language in ['de', 'en']) {
      for (final first in [true, false]) {
        for (final small in [false, true]) {
          testWidgets(
            'receipt $language first=$first dark=$dark small=$small',
            skip: _directory.isEmpty,
            (tester) async {
              _size(
                tester,
                small ? const Size(320, 640) : const Size(390, 844),
              );
              final moment = YeopjeonRewardMoment(
                claims: {
                  'daily:2026-10-04:${first ? 'first' : 'second'}': first
                      ? 20
                      : 10,
                },
                balance: first ? 80 : 90,
                source: YeopjeonRewardSource.currentActivity,
                day: '2026-10-04',
              );
              await tester.pumpWidget(
                _app(
                  Scaffold(
                    body: _ReceiptOpener(
                      receipt: RewardReceipt(
                        activityId: 'lesson',
                        receiptId: 'example',
                        yeopjeonReward: moment,
                        items: [
                          RewardReceiptItem(
                            kind: SoriRewardKind.yeopjeon,
                            amount: moment.amount,
                            identity: moment.claims.keys.single,
                            label: const SoriLocalizedCopy(
                              de: 'Yeopjeon',
                              en: 'Yeopjeon',
                            ),
                          ),
                          const RewardReceiptItem(
                            kind: SoriRewardKind.xp,
                            amount: 10,
                            label: SoriLocalizedCopy(de: 'Lern-XP', en: 'XP'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  language: language,
                  dark: dark,
                  scale: small ? 2 : 1,
                ),
              );
              await tester.tap(find.byKey(const ValueKey('open-receipt')));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
              expect(
                find.byKey(const ValueKey('receipt-continue')).hitTestable(),
                findsOneWidget,
              );
              if (first) {
                final stage = tester.getRect(
                  find.byKey(const ValueKey('reward-mint-stage')),
                );
                final action = tester.getRect(
                  find.byKey(const ValueKey('receipt-continue')),
                );
                expect(stage.top, greaterThanOrEqualTo(0));
                expect(stage.bottom, lessThanOrEqualTo(action.top));
                expect(stage.width, greaterThanOrEqualTo(144));
              }
              await _capture(
                tester,
                'receipt-$language-${first ? 'first' : 'second'}-${dark ? 'dark' : 'light'}-${small ? '320-200' : '390-100'}',
              );
            },
          );
        }
      }
    }
  }

  for (final milliseconds in [0, 240, 560, 800]) {
    testWidgets(
      'short transfer at $milliseconds ms',
      skip: _directory.isEmpty,
      (tester) async {
        _size(tester, const Size(390, 844));
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      YeopjeonRewardPresentation(
                        moment: YeopjeonRewardMoment(
                          claims: {'daily:2026-10-04:second': 10},
                          balance: 30,
                          source: YeopjeonRewardSource.currentActivity,
                          day: '2026-10-04',
                        ),
                      ),
                      const Spacer(),
                      SoriButton(label: 'Continue', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
            reduced: false,
          ),
        );
        await tester.pump();
        await _precache(tester);
        await tester.pump(Duration(milliseconds: milliseconds));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(Uri.file('$_directory/short-$milliseconds.png')),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

class _ReceiptOpener extends StatelessWidget {
  const _ReceiptOpener({required this.receipt});
  final RewardReceipt receipt;
  @override
  Widget build(BuildContext context) => Center(
    child: SoriButton(
      key: const ValueKey('open-receipt'),
      label: 'Open receipt',
      onTap: () => showSoriStageRewardReceipt(context, receipt),
    ),
  );
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget home, {
  bool dark = false,
  String language = 'en',
  double scale = 1,
  bool reduced = true,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: Locale(language),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  navigatorObservers: [soriRouteObserver],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced,
      textScaler: TextScaler.linear(scale),
    ),
    child: RepaintBoundary(key: const ValueKey('capture'), child: child!),
  ),
  home: home,
);

Future<void> _precache(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((w) => w.image)
      .toList();
  await tester.runAsync(
    () => Future.wait([for (final p in providers) precacheImage(p, context)]),
  );
  await tester.pump();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await _precache(tester);
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byKey(const ValueKey('capture')),
    matchesGoldenFile(Uri.file('$_directory/$name.png')),
  );
}
