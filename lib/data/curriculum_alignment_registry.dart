import '../models/curriculum_alignment_contract.dart';
import '../models/learner_level.dart';

/// Stable names copied from the reviewed official TOPIK tutorials. These are
/// the current public-task denominator, not claims that Hangul Sori covers it.
abstract final class TopikPublicTaskType {
  static const listeningStatementMatching = 'listening statement matching';
  static const readingSequenceOrdering = 'reading sequence ordering';
  static const writingOpinionWithTwoReasons =
      'writing opinion with two reasons';
}

const _topikStructureAndLevelsUrl =
    'https://www.niied.go.kr/web/niied/contents/niied_topik';
const _topikListeningTutorialUrl =
    'https://www.topik.go.kr/asset/vendor/tutorial/exam2/listen_exam.html';
const _topikReadingTutorialUrl =
    'https://www.topik.go.kr/asset/vendor/tutorial/exam2/read_exam.html';
const _topikWritingTutorialUrl =
    'https://www.topik.go.kr/asset/vendor/tutorial/exam2/write_exam.html';

const productionTopikCoverageRequirement = TopikCoverageRequirement(
  domains: {
    CurriculumLanguageDomain.listening,
    CurriculumLanguageDomain.reading,
    CurriculumLanguageDomain.writing,
    CurriculumLanguageDomain.speaking,
  },
  publicTaskTypes: {
    TopikPublicTaskType.listeningStatementMatching,
    TopikPublicTaskType.readingSequenceOrdering,
    TopikPublicTaskType.writingOpinionWithTwoReasons,
  },
  // These three official IBT tutorial examples are verified source records,
  // but they are not yet an educationally reviewed exhaustive denominator.
  // Partial status keeps comprehensive TOPIK copy fail-closed even if an
  // individual evidence record is later approved.
  reviewStatus: TopikDenominatorReviewStatus.partial,
);

final OfficialCurriculumReference
_cefrCompanionVolume2020 = OfficialCurriculumReference(
  authority: CurriculumAuthority.cefr,
  documentName:
      'Common European Framework of Reference for Languages: '
      'Learning, Teaching, Assessment - Companion Volume',
  documentVersion: '2020',
  url: Uri.parse(
    'https://www.coe.int/en/web/common-european-framework-reference-languages/'
    'cefr-companion-volume-and-its-language-versions',
  ),
  checkedAtIso: '2026-08-26',
);

final OfficialCurriculumReference _niklStandardCurriculum2020 =
    OfficialCurriculumReference(
      authority: CurriculumAuthority.nikl,
      documentName: '한국어 표준 교육과정',
      documentVersion: '문화체육관광부 고시 제2020-54호 (2020-11-27)',
      url: Uri.parse(
        'https://www.korean.go.kr/front/etcData/etcDataView.do?'
        'etc_seq=657&mn_id=208',
      ),
      checkedAtIso: '2026-08-26',
    );

final OfficialCurriculumReference _topikStructureAndLevels =
    OfficialCurriculumReference(
      authority: CurriculumAuthority.topik,
      documentName: 'NIIED TOPIK test structure, domains, and levels',
      documentVersion: 'Last modified 2025-09-17',
      url: Uri.parse(_topikStructureAndLevelsUrl),
      checkedAtIso: '2026-08-26',
    );

final OfficialCurriculumReference _topikListeningTutorial =
    OfficialCurriculumReference(
      authority: CurriculumAuthority.topik,
      documentName: 'TOPIK II listening tutorial - statement matching',
      documentVersion: 'Reviewed 2026-08-26',
      url: Uri.parse(_topikListeningTutorialUrl),
      checkedAtIso: '2026-08-26',
    );

final OfficialCurriculumReference _topikReadingTutorial =
    OfficialCurriculumReference(
      authority: CurriculumAuthority.topik,
      documentName: 'TOPIK II reading tutorial - sequence ordering',
      documentVersion: 'Reviewed 2026-08-26',
      url: Uri.parse(_topikReadingTutorialUrl),
      checkedAtIso: '2026-08-26',
    );

final OfficialCurriculumReference _topikWritingTutorial =
    OfficialCurriculumReference(
      authority: CurriculumAuthority.topik,
      documentName: 'TOPIK II writing tutorial - opinion with two reasons',
      documentVersion: 'Reviewed 2026-08-26',
      url: Uri.parse(_topikWritingTutorialUrl),
      checkedAtIso: '2026-08-26',
    );

const _courseStarts = <({LearnerLevel level, String unitId})>[
  (level: LearnerLevel.a1, unitId: 'a1_01_greetings_hangul'),
  (level: LearnerLevel.a2, unitId: 'a2_01_haeyo_transition'),
  (level: LearnerLevel.b1, unitId: 'b1_01_experience_reasons'),
  (level: LearnerLevel.b2, unitId: 'b2_01_formal_opening'),
  (level: LearnerLevel.c1, unitId: 'c1_01_evidence_public_reasoning'),
  (level: LearnerLevel.c2, unitId: 'c2_01_interpretation_institutions'),
];

/// Promotion authority is intentionally narrower than the full runtime
/// catalog. Adding approved alignment evidence requires both a real bundled
/// id and an explicit review of that id for this gate.
const productionCurriculumPromotionAuthority = CurriculumPromotionAuthority(
  approvedOfficialUrls: {
    CurriculumAuthority.topik: {
      _topikStructureAndLevelsUrl,
      _topikListeningTutorialUrl,
      _topikReadingTutorialUrl,
      _topikWritingTutorialUrl,
    },
  },
  productionContentIds: {
    CurriculumContentKind.courseUnit: {
      'a1_01_greetings_hangul',
      'a2_01_haeyo_transition',
      'b1_01_experience_reasons',
      'b2_01_formal_opening',
      'c1_01_evidence_public_reasoning',
      'c2_01_interpretation_institutions',
    },
    CurriculumContentKind.scenario: {'postpone_plans'},
    CurriculumContentKind.practice: {'grammar_a1_action_location_particle'},
  },
);

final productionCurriculumAlignmentRegistry = CurriculumAlignmentRegistry(
  List.unmodifiable([
    for (final courseStart in _courseStarts)
      CurriculumAlignmentRecord(
        recordId: 'cefr-${courseStart.level.code}-partial',
        authority: CurriculumAuthority.cefr,
        officialReference: _cefrCompanionVolume2020,
        domains: _domainsForLevel(courseStart.level),
        levelOrBand: courseStart.level.display,
        publicTaskTypes: const {},
        contentLinks: [
          CurriculumContentLink(
            kind: CurriculumContentKind.courseUnit,
            contentId: courseStart.unitId,
          ),
        ],
        status: CurriculumAlignmentStatus.partial,
      ),
    for (final courseStart in _courseStarts)
      CurriculumAlignmentRecord(
        recordId: 'nikl-${courseStart.level.code}-partial',
        authority: CurriculumAuthority.nikl,
        officialReference: _niklStandardCurriculum2020,
        domains: _domainsForLevel(courseStart.level),
        levelOrBand: courseStart.level.display,
        publicTaskTypes: const {},
        contentLinks: [
          CurriculumContentLink(
            kind: CurriculumContentKind.courseUnit,
            contentId: courseStart.unitId,
          ),
        ],
        status: CurriculumAlignmentStatus.partial,
      ),
    CurriculumAlignmentRecord(
      recordId: 'topik-listening-statement-matching-gap',
      authority: CurriculumAuthority.topik,
      officialReference: _topikListeningTutorial,
      domains: const {CurriculumLanguageDomain.listening},
      levelOrBand: 'TOPIK II public tutorial',
      publicTaskTypes: const {TopikPublicTaskType.listeningStatementMatching},
      contentLinks: const [],
      status: CurriculumAlignmentStatus.gap,
    ),
    CurriculumAlignmentRecord(
      recordId: 'topik-reading-sequence-ordering-gap',
      authority: CurriculumAuthority.topik,
      officialReference: _topikReadingTutorial,
      domains: const {CurriculumLanguageDomain.reading},
      levelOrBand: 'TOPIK II public tutorial',
      publicTaskTypes: const {TopikPublicTaskType.readingSequenceOrdering},
      contentLinks: const [],
      status: CurriculumAlignmentStatus.gap,
    ),
    CurriculumAlignmentRecord(
      recordId: 'topik-writing-opinion-two-reasons-gap',
      authority: CurriculumAuthority.topik,
      officialReference: _topikWritingTutorial,
      domains: const {CurriculumLanguageDomain.writing},
      levelOrBand: 'TOPIK II public tutorial',
      publicTaskTypes: const {TopikPublicTaskType.writingOpinionWithTwoReasons},
      contentLinks: const [],
      status: CurriculumAlignmentStatus.gap,
    ),
    CurriculumAlignmentRecord(
      recordId: 'topik-speaking-domain-gap',
      authority: CurriculumAuthority.topik,
      officialReference: _topikStructureAndLevels,
      domains: const {CurriculumLanguageDomain.speaking},
      levelOrBand: 'TOPIK speaking assessment domain',
      publicTaskTypes: const {},
      contentLinks: const [],
      status: CurriculumAlignmentStatus.gap,
    ),
  ]),
  promotionAuthority: productionCurriculumPromotionAuthority,
);

final productionCurriculumClaimValidator = CurriculumPublicClaimValidator(
  registry: productionCurriculumAlignmentRegistry,
  topikRequirement: productionTopikCoverageRequirement,
);

Set<CurriculumLanguageDomain> _domainsForLevel(LearnerLevel level) {
  return switch (level) {
    LearnerLevel.a1 => const {
      CurriculumLanguageDomain.reading,
      CurriculumLanguageDomain.speaking,
    },
    LearnerLevel.a2 || LearnerLevel.b2 => const {
      CurriculumLanguageDomain.listening,
      CurriculumLanguageDomain.speaking,
    },
    LearnerLevel.b1 => const {
      CurriculumLanguageDomain.writing,
      CurriculumLanguageDomain.speaking,
    },
    LearnerLevel.c1 || LearnerLevel.c2 => const {
      CurriculumLanguageDomain.reading,
      CurriculumLanguageDomain.writing,
      CurriculumLanguageDomain.speaking,
    },
  };
}
