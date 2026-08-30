import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_hub_screen.dart';
import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/features/guide/guide_topic_detail_screen.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/screens/study_library_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding V2 compact accessibility gate', () {
    final surfaces =
        <
          ({
            String name,
            List<ValueKey<String>> footerActionKeys,
            ValueKey<String> deepContentKey,
            Widget Function(OnboardingV2Copy copy) build,
          })
        >[
          for (var pageIndex = 0; pageIndex < 5; pageIndex++)
            (
              name: 'story page ${pageIndex + 1}',
              footerActionKeys: const [
                ValueKey('onboarding-v2-story-next'),
                ValueKey('onboarding-v2-story-back'),
              ],
              deepContentKey: switch (pageIndex) {
                0 => const ValueKey('onboarding-v2-curriculum-sources'),
                2 => const ValueKey('onboarding-v2-story-status'),
                3 => const ValueKey('onboarding-v2-reward-catalog'),
                4 => const ValueKey('onboarding-v2-heritage-sources'),
                _ => const ValueKey('onboarding-v2-story-hero'),
              },
              build: (copy) => OnboardingStoryScreen(
                copy: copy,
                pageIndex: pageIndex,
                onContinue: (_) {},
                onPrevious: (_) {},
              ),
            ),
          (
            name: 'setup empty',
            footerActionKeys: const [ValueKey('onboarding-v2-setup-continue')],
            deepContentKey: const ValueKey(
              'onboarding-v2-purpose-${OnboardingV2Ids.purposeKContent}',
            ),
            build: (copy) => OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: null,
              selectedLevelCode: null,
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
            ),
          ),
          (
            name: 'setup selected',
            footerActionKeys: const [ValueKey('onboarding-v2-setup-continue')],
            deepContentKey: const ValueKey('onboarding-v2-selected-level'),
            build: (copy) => OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: OnboardingV2Ids.purposeKContent,
              selectedLevelCode: 'C2',
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
            ),
          ),
          (
            name: 'companion choice empty',
            footerActionKeys: const [
              ValueKey('onboarding-v2-companion-continue'),
            ],
            deepContentKey: const ValueKey(
              'onboarding-v2-companion-equal-learning-note',
            ),
            build: (copy) => OnboardingCompanionScreen(
              copy: copy,
              selectedCompanionId: null,
              onCompanionChanged: (_) {},
              onContinue: (_) {},
            ),
          ),
          (
            name: 'companion choice selected',
            footerActionKeys: const [
              ValueKey('onboarding-v2-companion-continue'),
            ],
            deepContentKey: const ValueKey(
              'onboarding-v2-companion-equal-learning-note',
            ),
            build: (copy) => OnboardingCompanionScreen(
              copy: copy,
              selectedCompanionId: OnboardingV2Ids.companionJoy,
              onCompanionChanged: (_) {},
              onContinue: (_) {},
            ),
          ),
          (
            name: 'Taego confirmation',
            footerActionKeys: const [
              ValueKey('onboarding-v2-confirmation-start'),
              ValueKey('onboarding-v2-confirmation-change'),
            ],
            deepContentKey: const ValueKey(
              'onboarding-v2-confirmation-details',
            ),
            build: (copy) => OnboardingCompanionConfirmationScreen(
              copy: copy,
              companionId: OnboardingV2Ids.companionTaego,
              onStart: () {},
              onChange: () {},
            ),
          ),
          (
            name: 'Joy confirmation',
            footerActionKeys: const [
              ValueKey('onboarding-v2-confirmation-start'),
              ValueKey('onboarding-v2-confirmation-change'),
            ],
            deepContentKey: const ValueKey(
              'onboarding-v2-confirmation-details',
            ),
            build: (copy) => OnboardingCompanionConfirmationScreen(
              copy: copy,
              companionId: OnboardingV2Ids.companionJoy,
              onStart: () {},
              onChange: () {},
            ),
          ),
        ];

    const viewportMatrix = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 800), textScale: 1),
      (size: Size(360, 800), textScale: 1.3),
      (size: Size(360, 800), textScale: 2),
    ];

    for (final surface in surfaces) {
      testWidgets(
        '${surface.name} keeps body and CTA accessible across the locked matrix',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          for (final locale in const [Locale('de'), Locale('en')]) {
            for (final viewport in viewportMatrix) {
              _setViewport(tester, viewport.size);
              await tester.pumpWidget(
                _localizedApp(
                  locale: locale,
                  textScale: viewport.textScale,
                  homeBuilder: (context) =>
                      surface.build(onboardingV2Copy(AppL10n.of(context))),
                ),
              );
              await tester.pump();

              final evidence =
                  '${surface.name} ${locale.languageCode} '
                  '${viewport.size} @${viewport.textScale}';
              expect(tester.takeException(), isNull, reason: evidence);
              expect(
                find.byType(SingleChildScrollView),
                findsOneWidget,
                reason: evidence,
              );
              final footerActions = surface.footerActionKeys
                  .map(find.byKey)
                  .toList(growable: false);
              for (final action in footerActions) {
                _expectLabeled48DpButton(tester, action);
                _expectInsideSafeViewport(
                  tester,
                  action,
                  viewport.size,
                  reason: evidence,
                );
              }
              final footerRectsBeforeScroll = footerActions
                  .map(tester.getRect)
                  .toList(growable: false);
              for (
                var index = 0;
                index < footerRectsBeforeScroll.length;
                index++
              ) {
                for (
                  var other = index + 1;
                  other < footerRectsBeforeScroll.length;
                  other++
                ) {
                  expect(
                    footerRectsBeforeScroll[index].overlaps(
                      footerRectsBeforeScroll[other],
                    ),
                    isFalse,
                    reason: '$evidence footer actions overlap',
                  );
                }
              }
              final scrollRect = tester.getRect(
                find.byType(SingleChildScrollView),
              );
              final footerTop = footerRectsBeforeScroll
                  .map((rect) => rect.top)
                  .reduce((left, right) => left < right ? left : right);
              expect(
                scrollRect.bottom,
                lessThanOrEqualTo(footerTop),
                reason: evidence,
              );

              final deepContent = find.byKey(surface.deepContentKey);
              expect(deepContent, findsOneWidget, reason: evidence);
              final bodyScrollable = find.descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              );
              expect(bodyScrollable, findsOneWidget, reason: evidence);
              final position = tester
                  .state<ScrollableState>(bodyScrollable)
                  .position;
              final isCompactMaximumScale =
                  viewport.size == const Size(320, 640) &&
                  viewport.textScale == 2;
              if (isCompactMaximumScale) {
                expect(
                  position.maxScrollExtent,
                  greaterThan(0),
                  reason: '$evidence body must reflow into a scrollable region',
                );
              }
              if (position.maxScrollExtent > 0) {
                position.jumpTo(position.maxScrollExtent);
              }
              await tester.pump();
              expect(tester.takeException(), isNull, reason: evidence);
              final deepContentRect = tester.getRect(deepContent);
              expect(
                deepContentRect.bottom,
                lessThanOrEqualTo(scrollRect.bottom + 0.5),
                reason: '$evidence final body content is hidden by the footer',
              );
              expect(
                deepContentRect.bottom,
                greaterThan(scrollRect.top),
                reason: '$evidence final body content is not reachable',
              );
              for (var index = 0; index < footerActions.length; index++) {
                expect(
                  tester.getRect(footerActions[index]),
                  footerRectsBeforeScroll[index],
                  reason: '$evidence fixed footer moved while body scrolled',
                );
              }

              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
            }
          }
        },
      );
    }

    testWidgets(
      'German level comparison keeps its close CTA fixed at 320x640 and 200%',
      (tester) async {
        _setCompactViewport(tester);

        await tester.pumpWidget(
          _germanApp(
            (context) => OnboardingSetupScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              selectedPurposeId: OnboardingV2Ids.purposeLifeTravel,
              selectedLevelCode: null,
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
            ),
          ),
        );
        await tester.pump();

        final compareAction = find.byKey(
          const ValueKey('onboarding-v2-level-compare'),
        );
        await tester.scrollUntilVisible(compareAction, 180);
        await tester.tap(compareAction);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final sheet = find.byType(DraggableScrollableSheet);
        expect(sheet, findsOneWidget);
        final list = find.descendant(
          of: sheet,
          matching: find.byType(ListView),
        );
        expect(list, findsOneWidget);
        final close = find.byKey(
          const ValueKey('onboarding-v2-level-compare-close'),
        );
        _expectLabeled48DpButton(tester, close);
        _expectInsideSafeViewport(
          tester,
          close,
          const Size(320, 640),
          reason: 'German level comparison close CTA',
        );
        final closeRectBeforeScroll = tester.getRect(close);
        final listRect = tester.getRect(list);
        expect(listRect.bottom, lessThanOrEqualTo(closeRectBeforeScroll.top));

        final finalLevel = find.byKey(
          const ValueKey('onboarding-v2-level-compare-C2'),
        );
        final listScrollable = find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        );
        expect(listScrollable, findsOneWidget);
        expect(
          tester
              .state<ScrollableState>(listScrollable)
              .position
              .maxScrollExtent,
          greaterThan(0),
        );
        await tester.scrollUntilVisible(
          finalLevel,
          240,
          scrollable: listScrollable,
        );
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 8 &&
              tester.getRect(finalLevel).bottom > listRect.bottom + 0.5;
          attempt++
        ) {
          await tester.drag(list, const Offset(0, -300));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
        final finalLevelRect = tester.getRect(finalLevel);
        expect(finalLevelRect.bottom, lessThanOrEqualTo(listRect.bottom + 0.5));
        expect(finalLevelRect.bottom, greaterThan(listRect.top));
        expect(tester.getRect(close), closeRectBeforeScroll);
      },
    );

    testWidgets(
      'reduced motion removes story transition and decorative preview',
      (tester) async {
        _setCompactViewport(tester);

        await tester.pumpWidget(
          _germanApp(
            (context) => OnboardingStoryScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              pageIndex: 4,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          ),
        );
        await tester.pump();

        expect(
          tester
              .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
              .map((switcher) => switcher.duration),
          everyElement(Duration.zero),
        );
        _expectHeader(
          tester,
          find.byKey(const ValueKey('onboarding-v2-story-title')),
        );

        var previewBuilds = 0;
        await tester.pumpWidget(
          _germanApp(
            (context) => OnboardingCompanionConfirmationScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              companionId: OnboardingV2Ids.companionJoy,
              previewBuilder: (context, companionId) {
                previewBuilds += 1;
                return const ColoredBox(color: Colors.black);
              },
              onStart: () {},
              onChange: () {},
            ),
          ),
        );
        await tester.pump();

        expect(previewBuilds, 0);
        final liveHeading = tester
            .getSemantics(
              find.byKey(
                const ValueKey('onboarding-v2-confirmation-live-heading'),
              ),
            )
            .getSemanticsData();
        expect(liveHeading.flagsCollection.isHeader, isTrue);
        expect(liveHeading.flagsCollection.isLiveRegion, isTrue);
        expect(liveHeading.label.trim(), isNotEmpty);
        _expectLabeled48DpButton(
          tester,
          find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
        );
        _expectLabeled48DpButton(
          tester,
          find.byKey(const ValueKey('onboarding-v2-confirmation-change')),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets(
    'all guide topics keep every destination reachable at 320x640 and 200%',
    (tester) async {
      _setCompactViewport(tester);

      for (final locale in const [Locale('de'), Locale('en')]) {
        final l10n = lookupAppL10n(locale);
        for (final topic in GuideTopicCatalog.all) {
          final module = guideTopicModuleViewModel(l10n, topic);
          await tester.pumpWidget(
            _localizedApp(
              locale: locale,
              textScale: 2,
              homeBuilder: (_) => GuideTopicDetailScreen(
                key: ValueKey(
                  'guide-detail-${locale.languageCode}-${topic.id.stableId}',
                ),
                module: module,
                onActionRequested: (_) {},
              ),
            ),
          );
          await tester.pump();

          final evidence = '${locale.languageCode}:${topic.id.stableId}';
          expect(tester.takeException(), isNull, reason: evidence);
          final list = find.byType(ListView);
          expect(list, findsOneWidget);
          final scrollable = find.descendant(
            of: list,
            matching: find.byType(Scrollable),
          );
          expect(scrollable, findsOneWidget);
          final position = tester.state<ScrollableState>(scrollable).position;
          if (position.pixels != 0) {
            position.jumpTo(0);
            await tester.pump();
          }
          for (final actionSpec in module.actions) {
            final action = find.byKey(
              ValueKey('guide-module-action-${actionSpec.spec.id.stableId}'),
            );
            for (
              var attempt = 0;
              attempt < 100 && action.evaluate().isEmpty;
              attempt++
            ) {
              final nextOffset = (position.pixels + 400)
                  .clamp(0.0, position.maxScrollExtent)
                  .toDouble();
              if (nextOffset == position.pixels) {
                break;
              }
              position.jumpTo(nextOffset);
              await tester.pump();
            }
            expect(
              action,
              findsOneWidget,
              reason:
                  '$evidence scroll ${position.pixels}/'
                  '${position.maxScrollExtent}',
            );
            await tester.scrollUntilVisible(
              action,
              180,
              scrollable: scrollable,
            );
            await tester.pump();

            _expectLabeled48DpButton(tester, action);
            _expectInsideSafeViewport(
              tester,
              action,
              const Size(320, 640),
              reason: '$evidence:${actionSpec.spec.id.stableId}',
            );
            expect(
              tester.getSemantics(action).getSemanticsData().label,
              contains('${module.topic.title}: ${actionSpec.label}'),
            );
          }
          expect(tester.takeException(), isNull, reason: evidence);
        }
      }
    },
  );

  testWidgets(
    'German guide hub keeps long copy, headers, and actions accessible',
    (tester) async {
      _setCompactViewport(tester);
      final de = lookupAppL10n(const Locale('de'));
      final snapshot = GuideProgressSnapshot(
        completedTopicIds: const <GuideTopicId>{},
        isTodayCardDismissed: false,
      );
      final topics = guideTopicViewModels(de, snapshot);

      await tester.pumpWidget(
        _germanApp(
          (context) => GuideHubScreen(
            copy: guideHubCopy(AppL10n.of(context)),
            topics: guideTopicViewModels(AppL10n.of(context), snapshot),
            onDestinationRequested: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SoriStandardPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      _expectHeader(tester, find.text(de.guideHubTitle));

      for (final topic in topics) {
        final action = find.byKey(
          ValueKey('guide-topic-action-${topic.spec.id.stableId}'),
        );
        await tester.scrollUntilVisible(action, 240);
        await tester.pump();
        _expectLabeled48DpButton(tester, action);
        final data = tester.getSemantics(action).getSemanticsData();
        expect(data.label, contains('${topic.title}: ${topic.actionLabel}'));
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('German study library reflows and announces the selected view', (
    tester,
  ) async {
    _setCompactViewport(tester);
    final de = lookupAppL10n(const Locale('de'));
    final itemKey = StudyItemKey(
      type: StudyLibraryItemType.word,
      id: 'reservation-change',
    );

    await tester.pumpWidget(
      _germanApp(
        (context) => StudyLibraryScreen(
          repository: _studyLibraryRepository(itemKey),
          bookmarkStore: _memoryBookmarkStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SoriStandardPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    _expectHeader(tester, find.text(de.studyLibraryTitle));
    _expect48DpButton(
      tester,
      find.byKey(const ValueKey('study-library-refresh')),
    );
    expect(find.bySemanticsLabel(de.studyLibraryRefresh), findsOneWidget);

    final viewLabels = <StudyLibraryView, String>{
      StudyLibraryView.favorites: de.studyLibraryFavoritesTab,
      StudyLibraryView.saved: de.studyLibrarySavedTab,
      StudyLibraryView.due: de.studyLibraryDueTab,
    };
    final selector = find.byKey(const ValueKey('study-library-view-selector'));
    await tester.scrollUntilVisible(selector, 200);
    await tester.tapAt(tester.getTopLeft(selector) + const Offset(24, 24));
    await tester.pumpAndSettle();
    for (final entry in viewLabels.entries) {
      final control = find.byKey(
        ValueKey('study-library-view-${entry.key.name}'),
      );
      _expectLabeled48DpButton(tester, control);
      expect(
        tester.getSemantics(control).getSemanticsData().label,
        contains(entry.value),
      );
    }

    final dueControl = find.byKey(const ValueKey('study-library-view-due'));
    await tester.ensureVisible(dueControl);
    await tester.tap(dueControl);
    await tester.pump();

    final viewStatusFinder = find.byKey(
      const ValueKey('study-library-view-status'),
    );
    await tester.scrollUntilVisible(
      viewStatusFinder,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    final viewStatus = tester.getSemantics(viewStatusFinder).getSemanticsData();
    expect(viewStatus.flagsCollection.isLiveRegion, isTrue);
    expect(viewStatus.label, contains(de.studyLibraryDueTab));

    final bookmarkAction = find.byKey(
      ValueKey('study-library-bookmark-action-${itemKey.encoded}'),
    );
    await tester.scrollUntilVisible(bookmarkAction, 180);
    await tester.pump();
    _expectLabeled48DpButton(tester, bookmarkAction);
    expect(
      tester.getSemantics(bookmarkAction).getSemanticsData().label,
      contains('예약을 변경하고 싶습니다.'),
    );

    final reviewAction = find.byKey(
      const ValueKey('study-library-start-word-review'),
    );
    await tester.scrollUntilVisible(reviewAction, 180);
    await tester.pump();
    _expectLabeled48DpButton(tester, reviewAction);
    expect(tester.takeException(), isNull);
  });
}

const _phoneSafeInsets = EdgeInsets.only(top: 44, bottom: 34);

Widget _germanApp(WidgetBuilder homeBuilder) => _localizedApp(
  locale: const Locale('de'),
  textScale: 2,
  homeBuilder: homeBuilder,
);

Widget _localizedApp({
  required Locale locale,
  required double textScale,
  required WidgetBuilder homeBuilder,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: _phoneSafeInsets,
        viewPadding: _phoneSafeInsets,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: Builder(builder: homeBuilder),
);

void _setCompactViewport(WidgetTester tester) {
  _setViewport(tester, const Size(320, 640));
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void _expectInsideSafeViewport(
  WidgetTester tester,
  Finder finder,
  Size viewport, {
  required String reason,
}) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.width), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(_phoneSafeInsets.top), reason: reason);
  expect(
    rect.bottom,
    lessThanOrEqualTo(viewport.height - _phoneSafeInsets.bottom),
    reason: reason,
  );
}

void _expectHeader(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isHeader, isTrue);
  expect(data.label.trim(), isNotEmpty);
}

void _expectLabeled48DpButton(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.label.trim(), isNotEmpty);
  _expect48DpButton(tester, finder);
}

void _expect48DpButton(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  final size = tester.getSize(finder);
  expect(data.flagsCollection.isButton, isTrue);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

StudyLibraryRepository _studyLibraryRepository(StudyItemKey key) {
  final likedRecord = StudyLibrarySourceRecord(
    key: key,
    primaryText: '예약을 변경하고 싶습니다.',
    secondaryText:
        'Ich möchte meine Reservierung ändern, weil sich meine Reisepläne '
        'kurzfristig geändert haben.',
    sources: [
      StudyLibrarySource(
        origin: StudyLibraryOrigin.liked,
        sourceId: 'accessibility-liked',
      ),
    ],
  );
  final bookmarkRecord = StudyLibrarySourceRecord(
    key: key,
    primaryText: '예약을 변경하고 싶습니다.',
    secondaryText:
        'Ich möchte meine Reservierung ändern, weil sich meine Reisepläne '
        'kurzfristig geändert haben.',
    sources: [
      StudyLibrarySource(
        origin: StudyLibraryOrigin.typedBookmark,
        sourceId: 'accessibility-bookmark',
      ),
    ],
  );
  return StudyLibraryRepository(
    likedReader: _LikedReader([likedRecord]),
    customPackReader: const _CustomPackReader(),
    bookshelfReader: const _BookshelfReader(),
    srsReader: _SrsReader([
      StudyLibrarySrsRecord(key: key, reviewCount: 4, isDue: true),
    ]),
    bookmarkReader: _BookmarkReader([bookmarkRecord]),
  );
}

TypedStudyBookmarkStore _memoryBookmarkStore() {
  var raw = '';
  return TypedStudyBookmarkStore(
    readRaw: () => raw,
    writeRaw: (value) async => raw = value,
  );
}

final class _LikedReader implements StudyLibraryLikedReader {
  const _LikedReader(this.records);

  final List<StudyLibrarySourceRecord> records;

  @override
  Future<List<StudyLibrarySourceRecord>> readLiked() async => records;
}

final class _CustomPackReader implements StudyLibraryCustomPackReader {
  const _CustomPackReader();

  @override
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems() async =>
      const <StudyLibrarySourceRecord>[];
}

final class _BookshelfReader implements StudyLibraryBookshelfReader {
  const _BookshelfReader();

  @override
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems() async =>
      const <StudyLibrarySourceRecord>[];
}

final class _SrsReader implements StudyLibrarySrsReader {
  const _SrsReader(this.records);

  final List<StudyLibrarySrsRecord> records;

  @override
  Future<List<StudyLibrarySrsRecord>> readSrsRecords() async => records;
}

final class _BookmarkReader implements StudyLibraryBookmarkReader {
  const _BookmarkReader(this.records);

  final List<StudyLibrarySourceRecord> records;

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async =>
      StudyLibraryBookmarkSourceSnapshot(
        records: records,
        health: StudyLibraryBookmarkHealth.healthy,
      );
}
