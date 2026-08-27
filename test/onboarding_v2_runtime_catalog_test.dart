import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/curriculum_alignment_registry.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/features/onboarding_v2/curriculum_evidence_projector.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_story_catalog_projector.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum_alignment_contract.dart';
import 'package:ko_lernen_app/models/heritage_journey_contract.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('page 1 renders validated CEFR and NIKL evidence from registry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final projection = OnboardingCurriculumEvidenceProjector.project()!;
    await tester.pumpWidget(_host(locale: const Locale('en'), pageIndex: 0));

    expect(find.textContaining('CEFR performance goals'), findsOneWidget);
    expect(find.textContaining('Korean Standard Curriculum'), findsOneWidget);
    final sources = find.byKey(
      const ValueKey('onboarding-v2-curriculum-sources'),
    );
    await tester.ensureVisible(sources);
    final sourcesSemantics = tester.getSemantics(sources).getSemanticsData();
    expect(sourcesSemantics.flagsCollection.isButton, isTrue);
    expect(sourcesSemantics.label, contains('Curriculum basis and sources'));

    await _focusWithKeyboard(tester, sources);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'onboarding-v2-curriculum-sources-heading',
    );
    final titleSemantics = tester
        .getSemantics(
          find.byKey(const ValueKey('onboarding-v2-curriculum-sources-title')),
        )
        .getSemanticsData();
    expect(titleSemantics.flagsCollection.isHeader, isTrue);
    expect(find.textContaining('current mapping is partial'), findsOneWidget);
    expect(find.textContaining('complete exam coverage'), findsOneWidget);

    for (final (index, source) in projection.references.indexed) {
      expect(find.text(source.documentName), findsWidgets);
      expect(find.text(source.documentVersion), findsOneWidget);
      expect(find.text(source.checkedAtIso), findsNWidgets(2));
      final url = tester.widget<SelectableText>(
        find.byKey(ValueKey('onboarding-v2-curriculum-source-url-$index')),
      );
      expect(url.textSpan?.toPlainText() ?? url.data, source.url.toString());
      final openButton = find.byKey(
        ValueKey('onboarding-v2-curriculum-source-open-$index'),
      );
      final openSemantics = tester.getSemantics(openButton).getSemanticsData();
      expect(openSemantics.flagsCollection.isButton, isTrue);
      expect(openSemantics.label, contains(source.documentName));
    }

    final close = find.byKey(
      const ValueKey('onboarding-v2-curriculum-sources-close'),
    );
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-v2-curriculum-sources-title')),
      findsNothing,
    );
    expect(_primaryFocusIsWithin(sources), isTrue);
    semantics.dispose();
  });

  testWidgets('page 1 hides claim and action when validation fails', (
    tester,
  ) async {
    final invalidValidator = CurriculumPublicClaimValidator(
      registry: const CurriculumAlignmentRegistry([]),
      topikRequirement: productionTopikCoverageRequirement,
    );
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        pageIndex: 0,
        curriculumEvidenceProjector: () =>
            OnboardingCurriculumEvidenceProjector.project(
              validator: invalidValidator,
            ),
      ),
    );

    expect(
      find.byKey(const ValueKey('onboarding-v2-curriculum-claim')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('onboarding-v2-curriculum-sources')),
      findsNothing,
    );
  });

  testWidgets('page 4 renders only activity-catalog reward examples', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var continued = false;
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        pageIndex: 3,
        onContinue: (_) => continued = true,
      ),
    );

    expect(
      find.text(
        'Read-only examples from ${soriActivityCatalog.length} current '
        'activities. Viewing this page does not grant or change anything.',
      ),
      findsOneWidget,
    );
    expect(find.text('Learning XP'), findsOneWidget);
    expect(find.text('Verified Hanok construction progress'), findsOneWidget);
    expect(find.text('Related quest'), findsOneWidget);
    expect(find.text('Dojang stamp'), findsOneWidget);
    expect(find.text('Personal best'), findsOneWidget);
    expect(find.text('Bojagi & accessories'), findsNothing);
    final xpSemantics = tester
        .getSemantics(find.byKey(const ValueKey('onboarding-v2-reward-xp')))
        .getSemanticsData();
    expect(xpSemantics.label, contains('Possible reward: Learning XP'));
    expect(continued, isFalse);
    semantics.dispose();
  });

  testWidgets(
    'page 4 stays navigable and hides rewards for inconsistent labels',
    (tester) async {
      var continued = false;
      final projection = OnboardingStoryCatalogProjector.projectRewards(
        catalog: _inconsistentRewardCatalog(),
      );
      expect(projection.isAvailable, isFalse);

      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          pageIndex: 3,
          onContinue: (_) => continued = true,
          rewardCatalogProjector: () => projection,
        ),
      );

      expect(
        find.byKey(const ValueKey('onboarding-v2-story-hero')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding-v2-reward-catalog-title')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('onboarding-v2-reward-xp')),
        findsNothing,
      );
      expect(find.text('Unverified points'), findsNothing);

      final next = find.byKey(const ValueKey('onboarding-v2-story-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      expect(continued, isTrue);
    },
  );

  testWidgets('page 5 renders registry preview and accessible attribution', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final chapter = HeritageJourneyCatalog.ilduGotaekPreview.chapters.single;
    await tester.pumpWidget(
      _host(locale: const Locale('en'), pageIndex: 4, textScale: 2),
    );

    expect(find.text(chapter.officialName), findsOneWidget);
    expect(
      _koreanLocaleCodes(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey('onboarding-v2-heritage-official-name'),
              ),
            )
            .getSemanticsData()
            .attributedLabel,
      ),
      contains('ko'),
    );
    expect(find.text('Preview · In preparation'), findsOneWidget);
    expect(
      find.textContaining('No heritage artwork is used here'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);

    final sources = find.byKey(
      const ValueKey('onboarding-v2-heritage-sources'),
    );
    await tester.ensureVisible(sources);
    await _focusWithKeyboard(tester, sources);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'onboarding-v2-heritage-sources-heading',
    );
    final titleSemantics = tester
        .getSemantics(
          find.byKey(const ValueKey('onboarding-v2-heritage-sources-title')),
        )
        .getSemanticsData();
    expect(titleSemantics.flagsCollection.isHeader, isTrue);
    expect(
      MediaQuery.textScalerOf(
        tester.element(
          find.byKey(const ValueKey('onboarding-v2-heritage-sources-title')),
        ),
      ).scale(1),
      2,
    );
    expect(_koreanLocaleCodes(titleSemantics.attributedLabel), contains('ko'));
    expect(find.text('License status'), findsNWidgets(2));
    expect(
      find.text('Citation only; reuse rights not asserted'),
      findsNWidgets(2),
    );

    for (final (index, source) in chapter.sources.indexed) {
      expect(find.text(source.institution), findsWidgets);
      expect(find.text(source.title), findsWidgets);
      expect(find.text(source.author), findsWidgets);
      final url = tester.widget<SelectableText>(
        find.byKey(ValueKey('onboarding-v2-heritage-source-url-$index')),
      );
      expect(url.textSpan?.toPlainText() ?? url.data, source.url.toString());
      final openButton = find.byKey(
        ValueKey('onboarding-v2-heritage-source-open-$index'),
      );
      final openSemantics = tester.getSemantics(openButton).getSemanticsData();
      expect(openSemantics.flagsCollection.isButton, isTrue);
      expect(openSemantics.label, contains(source.title));
      expect(_koreanLocaleCodes(openSemantics.attributedLabel), contains('ko'));

      final sourceCard = find.byKey(
        ValueKey('onboarding-v2-heritage-source-$index'),
      );
      for (final koreanValue in [
        source.title,
        source.institution,
        source.author,
      ]) {
        final valueSemantics = tester
            .getSemantics(
              find
                  .descendant(of: sourceCard, matching: find.text(koreanValue))
                  .first,
            )
            .getSemanticsData();
        expect(
          _koreanLocaleCodes(valueSemantics.attributedLabel),
          contains('ko'),
          reason: koreanValue,
        );
      }
    }

    final close = find.byKey(
      const ValueKey('onboarding-v2-heritage-sources-close'),
    );
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-v2-heritage-sources-title')),
      findsNothing,
    );
    expect(_primaryFocusIsWithin(sources), isTrue);
    semantics.dispose();
  });

  for (final scenario
      in <({String name, HeritageJourneyDescriptor descriptor})>[
        (name: 'invalid descriptor', descriptor: _invalidHeritageDescriptor()),
        (
          name: 'missing Ildu chapter',
          descriptor: _heritageDescriptorWithoutIldu(),
        ),
        (
          name: 'asset-authority violation',
          descriptor: _heritageDescriptorWithPendingAsset(),
        ),
      ]) {
    testWidgets(
      'page 5 stays navigable and hides heritage data for ${scenario.name}',
      (tester) async {
        var continued = false;
        final projection = OnboardingStoryCatalogProjector.projectIlduGotaek(
          descriptor: scenario.descriptor,
        );
        expect(projection.isAvailable, isFalse);

        await tester.pumpWidget(
          _host(
            locale: const Locale('en'),
            pageIndex: 4,
            onContinue: (_) => continued = true,
            heritageCatalogProjector: () => projection,
          ),
        );

        expect(
          find.byKey(const ValueKey('onboarding-v2-story-hero')),
          findsOneWidget,
        );
        expect(find.text('In preparation'), findsOneWidget);
        expect(find.text('함양 일두고택'), findsNothing);
        expect(
          find.byKey(const ValueKey('onboarding-v2-heritage-official-name')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-heritage-sources')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-heritage-runtime-status')),
          findsNothing,
        );

        final next = find.byKey(const ValueKey('onboarding-v2-story-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pump();
        expect(continued, isTrue);
      },
    );
  }
}

Future<void> _focusWithKeyboard(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (_primaryFocusIsWithin(target)) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard traversal did not reach $target.');
}

bool _primaryFocusIsWithin(Finder target) {
  final targetElements = target.evaluate();
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (targetElements.length != 1 || focusContext == null) {
    return false;
  }
  final targetElement = targetElements.single;
  if (identical(focusContext, targetElement)) {
    return true;
  }
  var isWithin = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, targetElement)) {
      isWithin = true;
      return false;
    }
    return true;
  });
  return isWithin;
}

Widget _host({
  required Locale locale,
  required int pageIndex,
  ValueChanged<String>? onContinue,
  OnboardingCurriculumEvidenceProjection? Function()?
  curriculumEvidenceProjector,
  OnboardingCatalogProjectionResult<OnboardingRewardCatalogProjection>
  Function()?
  rewardCatalogProjector,
  OnboardingCatalogProjectionResult<OnboardingHeritageCatalogProjection>
  Function()?
  heritageCatalogProjector,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Builder(
      builder: (context) => OnboardingStoryScreen(
        copy: onboardingV2Copy(AppL10n.of(context)),
        pageIndex: pageIndex,
        onContinue: onContinue ?? (_) {},
        onPrevious: (_) {},
        curriculumEvidenceProjector: curriculumEvidenceProjector,
        rewardCatalogProjector: rewardCatalogProjector,
        heritageCatalogProjector: heritageCatalogProjector,
      ),
    ),
  );
}

Iterable<String> _koreanLocaleCodes(AttributedString attributedLabel) =>
    attributedLabel.attributes.whereType<LocaleStringAttribute>().map(
      (attribute) => attribute.locale.languageCode,
    );

List<ActivityCatalogEntry> _inconsistentRewardCatalog() {
  const canonical = RewardContractItem(
    kind: SoriRewardKind.xp,
    label: SoriLocalizedCopy(
      de: 'Lern-XP',
      en: 'Learning XP',
      key: SoriCopyKey.rewardXp,
    ),
  );
  const inconsistent = RewardContractItem(
    kind: SoriRewardKind.xp,
    label: SoriLocalizedCopy(
      de: 'Nicht belegte Punkte',
      en: 'Unverified points',
      key: SoriCopyKey.rewardXp,
    ),
  );
  return [
    _rewardActivity('reward-source-a', canonical),
    _rewardActivity('reward-source-b', inconsistent),
  ];
}

ActivityCatalogEntry _rewardActivity(String id, RewardContractItem reward) =>
    ActivityCatalogEntry(
      id: id,
      tab: SoriStageTab.games,
      title: SoriLocalizedCopy(de: id, en: id),
      description: SoriLocalizedCopy(de: id, en: id),
      route: '/test-reward',
      minutes: 1,
      colorRole: SoriActivityColorRole.reward,
      iconName: 'test',
      reward: RewardContract(
        activityId: id,
        condition: const SoriLocalizedCopy(
          de: 'Beim Abschluss',
          en: 'On completion',
          key: SoriCopyKey.finishSession,
        ),
        items: [reward],
      ),
    );

EstateChapter _heritageChapter({
  String estateId = HeritageJourneyCatalog.ilduGotaekEstateId,
  HeritageAssetAuthority assetAuthority = const HeritageAssetAuthority.none(),
}) {
  final approved = HeritageJourneyCatalog.ilduGotaekPreview.chapters.single;
  return EstateChapter(
    estateId: estateId,
    officialName: approved.officialName,
    availability: HeritageAvailability.preview,
    sources: approved.sources,
    assetAuthority: assetAuthority,
    learningBeatBinding: approved.learningBeatBinding,
    progress: approved.progress,
    cultureStoryLocalizationKey: approved.cultureStoryLocalizationKey,
  );
}

HeritageJourneyDescriptor _invalidHeritageDescriptor() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'not a stable descriptor version',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [_heritageChapter()],
    );

HeritageJourneyDescriptor _heritageDescriptorWithoutIldu() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'other-estate-preview-v1',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [_heritageChapter(estateId: 'other-estate')],
    );

HeritageJourneyDescriptor _heritageDescriptorWithPendingAsset() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'ildu-pending-asset-v1',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [
        _heritageChapter(
          assetAuthority: const HeritageAssetAuthority(
            status: HeritageAssetReviewStatus.pendingReview,
            runtimeAssetPath: 'assets/pending_review/ildu.png',
            authorityVersion: null,
            approvedBy: null,
            approvedAtIso: null,
          ),
        ),
      ],
    );
