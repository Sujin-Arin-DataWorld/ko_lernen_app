import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/curriculum_alignment_registry.dart';
import 'package:ko_lernen_app/models/curriculum_alignment_contract.dart';

void main() {
  group('CurriculumAlignmentRecord', () {
    test(
      'approved records require reviewer, review date, and content evidence',
      () {
        final record = _record(
          recordId: 'topik-listening',
          authority: CurriculumAuthority.topik,
          domains: const {CurriculumLanguageDomain.listening},
          taskTypes: const {'dialogue response'},
          status: CurriculumAlignmentStatus.approved,
          contentLinks: const [],
        );

        final result = record.validate();
        expect(result.hasCode('curriculum.missing_content_evidence'), isTrue);
        expect(result.hasCode('curriculum.missing_approval'), isTrue);
      },
    );

    test(
      'approved TOPIK evidence rejects arbitrary HTTPS and synthetic ids',
      () {
        final registry = CurriculumAlignmentRegistry([
          _record(
            recordId: 'topik-forged-promotion',
            authority: CurriculumAuthority.topik,
            domains: const {CurriculumLanguageDomain.listening},
            taskTypes: const {'dialogue response'},
            status: CurriculumAlignmentStatus.approved,
            contentLinks: const [
              CurriculumContentLink(
                kind: CurriculumContentKind.practice,
                contentId: 'practice.synthetic-topik-item',
              ),
            ],
            reviewer: 'curriculum-reviewer',
            reviewedAtIso: '2026-08-26',
          ),
        ], promotionAuthority: _testTopikPromotionAuthority);

        final result = registry.validate();

        expect(result.hasCode('curriculum.unresolved_topik_authority'), isTrue);
        expect(
          result.hasCode('curriculum.unresolved_production_content'),
          isTrue,
        );
      },
    );

    test('approved TOPIK evidence resolves reviewed URL and production id', () {
      final registry = CurriculumAlignmentRegistry([
        _approvedTopik(
          recordId: 'topik-production-evidence',
          domains: const {CurriculumLanguageDomain.listening},
          taskTypes: const {'dialogue response'},
        ),
      ], promotionAuthority: _testTopikPromotionAuthority);

      expect(registry.validate().isValid, isTrue);
    });
  });

  group('CurriculumPublicClaimValidator', () {
    test(
      'basic CEFR and NIKL reference requires mapped evidence from both',
      () {
        final validator = CurriculumPublicClaimValidator(
          registry: CurriculumAlignmentRegistry([
            _record(
              recordId: 'cefr-a1-speaking',
              authority: CurriculumAuthority.cefr,
              domains: const {CurriculumLanguageDomain.speaking},
              taskTypes: const {},
              status: CurriculumAlignmentStatus.mapped,
              contentLinks: const [
                CurriculumContentLink(
                  kind: CurriculumContentKind.courseUnit,
                  contentId: 'course.a1-intro',
                ),
              ],
            ),
          ]),
          topikRequirement: const TopikCoverageRequirement(
            domains: {CurriculumLanguageDomain.listening},
            publicTaskTypes: {'dialogue response'},
          ),
        );

        final result = validator.validateKind(
          CurriculumPublicClaimKind.cefrNiklReferenced,
        );
        expect(result.isValid, isFalse);
        expect(
          result.hasCode('curriculum.claim_missing_cefr_nikl_evidence'),
          isTrue,
        );
      },
    );

    test(
      'comprehensive TOPIK claim fails when one official type is uncovered',
      () {
        final validator = CurriculumPublicClaimValidator(
          registry: CurriculumAlignmentRegistry([
            _approvedTopik(
              recordId: 'topik-listening',
              domains: const {CurriculumLanguageDomain.listening},
              taskTypes: const {'dialogue response'},
            ),
          ], promotionAuthority: _testTopikPromotionAuthority),
          topikRequirement: const TopikCoverageRequirement(
            domains: {
              CurriculumLanguageDomain.listening,
              CurriculumLanguageDomain.reading,
            },
            publicTaskTypes: {'dialogue response', 'text comprehension'},
          ),
        );

        final result = validator.validateKind(
          CurriculumPublicClaimKind.comprehensiveTopikCoverage,
        );
        expect(result.isValid, isFalse);
        expect(
          result.hasCode('curriculum.claim_incomplete_topik_coverage'),
          isTrue,
        );
      },
    );

    test('comprehensive TOPIK claim passes only with reviewed denominator', () {
      final validator = CurriculumPublicClaimValidator(
        registry: CurriculumAlignmentRegistry([
          _approvedTopik(
            recordId: 'topik-listening',
            domains: const {CurriculumLanguageDomain.listening},
            taskTypes: const {'dialogue response'},
          ),
          _approvedTopik(
            recordId: 'topik-reading',
            domains: const {CurriculumLanguageDomain.reading},
            taskTypes: const {'text comprehension'},
          ),
        ], promotionAuthority: _testTopikPromotionAuthority),
        topikRequirement: const TopikCoverageRequirement(
          domains: {
            CurriculumLanguageDomain.listening,
            CurriculumLanguageDomain.reading,
          },
          publicTaskTypes: {'dialogue response', 'text comprehension'},
          reviewStatus: TopikDenominatorReviewStatus.approved,
          reviewer: 'topik-denominator-reviewer',
          reviewedAtIso: '2026-08-26',
        ),
      );

      expect(
        validator
            .validateKind(CurriculumPublicClaimKind.comprehensiveTopikCoverage)
            .isValid,
        isTrue,
      );
    });

    test(
      'comprehensive TOPIK claim stays locked without denominator approval',
      () {
        final validator = CurriculumPublicClaimValidator(
          registry: CurriculumAlignmentRegistry([
            _approvedTopik(
              recordId: 'topik-listening',
              domains: const {CurriculumLanguageDomain.listening},
              taskTypes: const {'dialogue response'},
            ),
          ], promotionAuthority: _testTopikPromotionAuthority),
          topikRequirement: const TopikCoverageRequirement(
            domains: {CurriculumLanguageDomain.listening},
            publicTaskTypes: {'dialogue response'},
          ),
        );

        final result = validator.validateKind(
          CurriculumPublicClaimKind.comprehensiveTopikCoverage,
        );
        expect(result.isValid, isFalse);
        expect(
          result.hasCode('curriculum.claim_incomplete_topik_coverage'),
          isTrue,
        );
      },
    );

    test('approved TOPIK denominator requires reviewer and review date', () {
      const requirement = TopikCoverageRequirement(
        domains: {CurriculumLanguageDomain.listening},
        publicTaskTypes: {'dialogue response'},
        reviewStatus: TopikDenominatorReviewStatus.approved,
      );

      expect(
        requirement.validate().hasCode(
          'curriculum.missing_topik_denominator_approval',
        ),
        isTrue,
      );
      expect(requirement.isReviewedComplete, isFalse);
    });

    test(
      'official, pass guarantee, 100%, and 1:1 claims are always forbidden',
      () {
        final validator = CurriculumPublicClaimValidator(
          registry: const CurriculumAlignmentRegistry([]),
          topikRequirement: const TopikCoverageRequirement(
            domains: {},
            publicTaskTypes: {},
          ),
        );

        for (final kind in [
          CurriculumPublicClaimKind.topikOfficialOrCertified,
          CurriculumPublicClaimKind.passGuarantee,
          CurriculumPublicClaimKind.topikHundredPercent,
          CurriculumPublicClaimKind.cefrTopikOneToOne,
        ]) {
          expect(
            validator.validateKind(kind).isValid,
            isFalse,
            reason: kind.name,
          );
        }
      },
    );

    test(
      'localized copy guard catches forbidden Korean and English wording',
      () {
        final validator = CurriculumPublicClaimValidator(
          registry: const CurriculumAlignmentRegistry([]),
          topikRequirement: const TopikCoverageRequirement(
            domains: {},
            publicTaskTypes: {},
          ),
        );

        expect(
          validator.validateLocalizedCopy('TOPIK 공식 인증 과정').isValid,
          isFalse,
        );
        expect(
          validator.validateLocalizedCopy('A 100% TOPIK course').isValid,
          isFalse,
        );
        expect(
          validator
              .validateLocalizedCopy('CEFR and TOPIK are a 1:1 match')
              .isValid,
          isFalse,
        );
      },
    );

    test('release ARBs contain no forbidden TOPIK claims', () {
      const validator = CurriculumPublicClaimValidator(
        registry: CurriculumAlignmentRegistry([]),
        topikRequirement: TopikCoverageRequirement(
          domains: {},
          publicTaskTypes: {},
        ),
      );

      for (final path in const ['lib/l10n/app_de.arb', 'lib/l10n/app_en.arb']) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Missing release ARB: $path');
        final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final entry in arb.entries) {
          if (entry.key.startsWith('@') || entry.value is! String) {
            continue;
          }
          final result = validator.validateLocalizedCopy(entry.value as String);
          expect(
            result.isValid,
            isTrue,
            reason:
                '$path:${entry.key} contains a forbidden TOPIK claim: '
                '${result.violations.map((violation) => violation.code).join(', ')}',
          );
        }
      }
    });
  });

  group('production curriculum alignment registry', () {
    test('validates with conservative partial and gap records', () {
      final result = productionCurriculumAlignmentRegistry.validate();

      expect(result.violations, isEmpty);
      expect(
        productionCurriculumAlignmentRegistry.records
            .where((record) => record.authority == CurriculumAuthority.cefr)
            .length,
        6,
      );
      expect(
        productionCurriculumAlignmentRegistry.records
            .where((record) => record.authority == CurriculumAuthority.nikl)
            .length,
        6,
      );
      expect(
        productionCurriculumAlignmentRegistry.records
            .where((record) => record.authority == CurriculumAuthority.topik)
            .every((record) => record.status == CurriculumAlignmentStatus.gap),
        isTrue,
      );
    });

    test('every production course-unit link exists in curriculum manifest', () {
      final manifest =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final manifestUnitIds = (manifest['courseUnits'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((unit) => unit['id'] as String)
          .toSet();
      final linkedUnitIds = productionCurriculumAlignmentRegistry.records
          .expand((record) => record.contentLinks)
          .where((link) => link.kind == CurriculumContentKind.courseUnit)
          .map((link) => link.contentId)
          .toSet();

      expect(
        linkedUnitIds,
        containsAll(<String>{
          'a1_01_greetings_hangul',
          'a2_01_haeyo_transition',
          'b1_01_experience_reasons',
          'b2_01_formal_opening',
          'c1_01_evidence_public_reasoning',
          'c2_01_interpretation_institutions',
        }),
      );
      for (final unitId in linkedUnitIds) {
        expect(
          manifestUnitIds,
          contains(unitId),
          reason: 'Missing curriculum_manifest course unit: $unitId',
        );
      }
    });

    test('promotion allow-list contains only resolvable production ids', () {
      final manifest =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final courseUnitIds = (manifest['courseUnits'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((unit) => unit['id'] as String)
          .toSet();
      final authorityData =
          jsonDecode(
                File(
                  'assets/data/can_do_content_authorities.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final runtimeContentIds =
          (authorityData['contentReferences'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((reference) => reference['id'] as String)
              .toSet();

      for (final entry
          in productionCurriculumPromotionAuthority
              .productionContentIds
              .entries) {
        final resolvable = entry.key == CurriculumContentKind.courseUnit
            ? courseUnitIds
            : runtimeContentIds;
        expect(
          resolvable,
          containsAll(entry.value),
          reason: 'Unresolved production ${entry.key.name} promotion id',
        );
      }
    });

    test(
      'basic CEFR/NIKL claim passes but comprehensive TOPIK stays locked',
      () {
        expect(
          productionCurriculumClaimValidator
              .validateKind(CurriculumPublicClaimKind.cefrNiklReferenced)
              .isValid,
          isTrue,
        );
        final topikResult = productionCurriculumClaimValidator.validateKind(
          CurriculumPublicClaimKind.comprehensiveTopikCoverage,
        );
        expect(topikResult.isValid, isFalse);
        expect(
          topikResult.hasCode('curriculum.claim_incomplete_topik_coverage'),
          isTrue,
        );
      },
    );

    test(
      'TOPIK gap report is deterministic and exposes the full denominator',
      () {
        final first = productionCurriculumAlignmentRegistry
            .topikCoverageGapReport(productionTopikCoverageRequirement);
        final second = productionCurriculumAlignmentRegistry
            .topikCoverageGapReport(productionTopikCoverageRequirement);

        expect(first.toJson(), second.toJson());
        expect(first.isComplete, isFalse);
        expect(first.registryValid, isTrue);
        expect(first.requirementValid, isTrue);
        expect(first.denominatorApproved, isFalse);
        expect(first.approvedDomains, isEmpty);
        expect(first.approvedTaskTypes, isEmpty);
        expect(first.missingDomains, const [
          CurriculumLanguageDomain.listening,
          CurriculumLanguageDomain.reading,
          CurriculumLanguageDomain.writing,
          CurriculumLanguageDomain.speaking,
        ]);
        expect(first.missingTaskTypes, const [
          TopikPublicTaskType.listeningStatementMatching,
          TopikPublicTaskType.readingSequenceOrdering,
          TopikPublicTaskType.writingOpinionWithTwoReasons,
        ]);
        expect(
          first.unresolvedRecordIds,
          orderedEquals(<String>[
            'topik-listening-statement-matching-gap',
            'topik-reading-sequence-ordering-gap',
            'topik-speaking-domain-gap',
            'topik-writing-opinion-two-reasons-gap',
          ]),
        );
      },
    );

    test('production gate rejects every forbidden claim kind', () {
      for (final kind in const [
        CurriculumPublicClaimKind.topikOfficialOrCertified,
        CurriculumPublicClaimKind.passGuarantee,
        CurriculumPublicClaimKind.topikHundredPercent,
        CurriculumPublicClaimKind.cefrTopikOneToOne,
      ]) {
        final result = productionCurriculumClaimValidator.validateKind(kind);
        expect(result.isValid, isFalse, reason: kind.name);
        expect(result.hasCode('curriculum.claim_forbidden'), isTrue);
      }
    });

    test('production references preserve the reviewed primary sources', () {
      final urls = productionCurriculumAlignmentRegistry.records
          .map((record) => record.officialReference.url.toString())
          .toSet();
      expect(
        urls,
        contains(
          'https://www.coe.int/en/web/common-european-framework-reference-languages/'
          'cefr-companion-volume-and-its-language-versions',
        ),
      );
      expect(
        urls,
        contains(
          'https://www.korean.go.kr/front/etcData/etcDataView.do?'
          'etc_seq=657&mn_id=208',
        ),
      );
      expect(
        urls,
        contains('https://www.niied.go.kr/web/niied/contents/niied_topik'),
      );
      expect(
        urls.where((url) => url.contains('topik.go.kr/asset/vendor/tutorial')),
        hasLength(3),
      );
    });
  });
}

CurriculumAlignmentRecord _approvedTopik({
  required String recordId,
  required Set<CurriculumLanguageDomain> domains,
  required Set<String> taskTypes,
}) {
  return _record(
    recordId: recordId,
    authority: CurriculumAuthority.topik,
    domains: domains,
    taskTypes: taskTypes,
    status: CurriculumAlignmentStatus.approved,
    contentLinks: [
      const CurriculumContentLink(
        kind: CurriculumContentKind.practice,
        contentId: _testPracticeId,
      ),
    ],
    reviewer: 'curriculum-reviewer',
    reviewedAtIso: '2026-08-26',
    referenceUrl: _testTopikUrl,
  );
}

CurriculumAlignmentRecord _record({
  required String recordId,
  required CurriculumAuthority authority,
  required Set<CurriculumLanguageDomain> domains,
  required Set<String> taskTypes,
  required CurriculumAlignmentStatus status,
  required List<CurriculumContentLink> contentLinks,
  String? reviewer,
  String? reviewedAtIso,
  String? referenceUrl,
}) {
  return CurriculumAlignmentRecord(
    recordId: recordId,
    authority: authority,
    officialReference: OfficialCurriculumReference(
      authority: authority,
      documentName: '${authority.name} official document',
      documentVersion: '2026',
      url: Uri.parse(referenceUrl ?? 'https://example.org/${authority.name}'),
      checkedAtIso: '2026-08-26',
    ),
    domains: domains,
    levelOrBand: 'test-band',
    publicTaskTypes: taskTypes,
    contentLinks: contentLinks,
    status: status,
    reviewer: reviewer,
    reviewedAtIso: reviewedAtIso,
  );
}

const _testTopikUrl =
    'https://www.topik.go.kr/asset/vendor/tutorial/exam2/listen_exam.html';
const _testPracticeId = 'grammar_a1_action_location_particle';
const _testTopikPromotionAuthority = CurriculumPromotionAuthority(
  approvedOfficialUrls: {
    CurriculumAuthority.topik: {_testTopikUrl},
  },
  productionContentIds: {
    CurriculumContentKind.practice: {_testPracticeId},
  },
);
