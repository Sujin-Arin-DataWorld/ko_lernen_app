import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';

void main() {
  test('DE and EN builders keep the complete stable presentation contract', () {
    final de = onboardingV2Copy(lookupAppL10n(const Locale('de')));
    final en = onboardingV2Copy(lookupAppL10n(const Locale('en')));

    for (final copy in [de, en]) {
      expect(copy.storyPages.map((page) => page.id), const [
        OnboardingV2Ids.storyPersonalCurriculum,
        OnboardingV2Ids.storyLearn,
        OnboardingV2Ids.storySaveAndReview,
        OnboardingV2Ids.storyGamesAndRewards,
        OnboardingV2Ids.storyHeritageJourney,
      ]);
      expect(copy.setup.purposes, hasLength(4));
      expect(
        copy.setup.levels.map((level) => level.code),
        OnboardingV2Ids.levels,
      );
      expect(copy.companion.companions.map((companion) => companion.id), const [
        OnboardingV2Ids.companionTaego,
        OnboardingV2Ids.companionJoy,
      ]);
      expect(copy.storyPages[2].statusLabel, isNotEmpty);
      expect(copy.storyPages[3].statusLabel, isNotEmpty);
      expect(copy.storyPages[4].statusLabel, isNotEmpty);
      expect(copy.storyPages.first.curriculumEvidenceCopy, isNotNull);
      expect(_allCopy(copy), isNot(contains('Netflix')));
      expect(_allCopy(copy), isNot(contains('AI-generated')));
      expect(copy.setup.levelHelp, isNot(contains('National Institute')));
      expect(copy.setup.levelHelp, isNot(contains('Nationalinstitut')));
      expect(copy.setup.levelHelp, isNot(contains('Standard Curriculum')));
      expect(copy.setup.levelHelp, isNot(contains('Standardcurriculum')));
    }

    expect(de.navigation.progress(2, 5), 'Seite 2 von 5');
    expect(en.navigation.progress(2, 5), 'Page 2 of 5');
    expect(de.storyPages.last.statusLabel, contains('In Vorbereitung'));
    expect(en.storyPages.last.statusLabel, contains('In preparation'));
    expect(en.storyPages.first.body, contains('EU analysis service'));
    expect(de.storyPages.first.body, contains('Analysedienst in der EU'));
    expect(
      en.storyPages.first.curriculumEvidenceCopy!.claim,
      contains('CEFR performance goals'),
    );
    expect(
      en.storyPages.first.curriculumEvidenceCopy!.claim,
      contains('Korean Standard Curriculum'),
    );
    expect(
      de.storyPages.first.curriculumEvidenceCopy!.claim,
      contains('CEFR-Handlungszielen'),
    );
    expect(
      de.storyPages.first.curriculumEvidenceCopy!.claim,
      contains('Koreanischen Standardcurriculum'),
    );
    expect(
      en.storyPages.first.highlights[2].body,
      contains('does not request camera access'),
    );
    expect(
      de.storyPages.first.highlights[2].body,
      contains('fragt nicht nach Kamerazugriff'),
    );
    expect(en.storyPages[2].statusLabel, contains('favorites, saved items'));
    expect(
      en.storyPages[2].statusLabel,
      contains('review engine supports words only'),
    );
    expect(
      de.storyPages[2].statusLabel,
      contains('Favoriten, gespeicherte Inhalte'),
    );
    expect(
      de.storyPages[2].statusLabel,
      contains('aktuelle Wiederholung unterstützt nur Wörter'),
    );
    expect(
      en.storyPages[2].statusLabel,
      contains('without a fake review action'),
    );
    expect(de.storyPages[2].statusLabel, contains('ohne vorgetäuschte'));
    expect(_allCopy(en), isNot(contains('Bookmark = review')));
    expect(_allCopy(de), isNot(contains('Lesezeichen = wiederholen')));
    expect(en.setup.levelHelp, contains('change it later in Settings'));
    expect(de.setup.levelHelp, contains('später in den Einstellungen'));
  });
}

String _allCopy(OnboardingV2Copy copy) {
  final values = <String>[
    copy.navigation.back,
    copy.navigation.next,
    copy.navigation.finishStory,
    for (final page in copy.storyPages) ...[
      page.eyebrow,
      page.title,
      page.body,
      page.heroSemanticLabel,
      if (page.statusLabel case final status?) status,
      if (page.curriculumEvidenceCopy case final evidence?) ...[
        evidence.claim,
        evidence.sourcesAction,
        evidence.sourcesTitle,
        evidence.sourcesBody,
        evidence.cefrAuthorityLabel,
        evidence.niklAuthorityLabel,
        evidence.documentLabel,
        evidence.versionLabel,
        evidence.checkedAtLabel,
        evidence.urlLabel,
        evidence.closeAction,
      ],
      for (final item in page.highlights) ...[item.title, item.body],
    ],
    copy.setup.eyebrow,
    copy.setup.title,
    copy.setup.body,
    copy.setup.levelHelp,
    for (final purpose in copy.setup.purposes) ...[purpose.title, purpose.body],
    for (final level in copy.setup.levels) ...[
      level.name,
      level.exampleKorean,
      level.exampleTranslation,
      level.canDo,
      level.learnHere,
    ],
    copy.companion.title,
    copy.companion.body,
    copy.companion.equalLearningNote,
    for (final companion in copy.companion.companions) ...[
      companion.name,
      companion.koreanName,
      companion.rhythm,
      companion.body,
      companion.selectedMessage,
    ],
  ];
  return values.join('\n');
}
