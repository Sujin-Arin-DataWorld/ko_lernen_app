import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/course_segment_catalog.dart';

void main() {
  group('CourseSegmentCatalog valid contract', () {
    test('loads immutable core track and deterministic denominator', () {
      final catalog = _load(_manifest());

      expect(catalog.schemaVersion, 1);
      expect(catalog.releaseTracks.map((track) => track.id), ['core_2026_v1']);
      expect(
        catalog.findReleaseTrack('core_2026_v1')?.kind,
        ReleaseTrackKind.core,
      );
      expect(catalog.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(catalog.segments, hasLength(86));
      expect(
        catalog.segments.map((segment) => segment.id),
        containsAll([
          'segment_a1_first',
          'segment_a1_second',
          'segment_b1_first',
        ]),
      );
      expect(catalog.publishedSegments, hasLength(86));
      expect(
        () => catalog.releaseTracks.first.editionIds.add('another'),
        throwsUnsupportedError,
      );
      expect(
        () => catalog.segments.first.ownedAssessmentItemIds.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => catalog.denominatorForReleaseTrack('missing'),
        throwsArgumentError,
      );
    });

    test('pins the shipped core profile to six levels and 86 segments', () {
      expect(hanokV1CoreReleasePolicy.releaseTrackId, 'core_2026_v1');
      expect(hanokV1CoreReleasePolicy.segmentCountsByLevel, {
        LearnerLevel.a1: 16,
        LearnerLevel.a2: 16,
        LearnerLevel.b1: 18,
        LearnerLevel.b2: 20,
        LearnerLevel.c1: 8,
        LearnerLevel.c2: 8,
      });
      expect(hanokV1CoreReleasePolicy.totalSegments, 86);
      expect(
        () =>
            hanokV1CoreReleasePolicy.segmentCountsByLevel[LearnerLevel.a1] = 15,
        throwsUnsupportedError,
      );
      final productFixture = _canonicalProductFixture();
      final productCatalog = CourseSegmentCatalog.fromJson(
        productFixture.manifest,
        courseUnits: productFixture.courseUnits,
        concepts: productFixture.concepts,
        seedAuthorities: productFixture.seedAuthorities,
        contentAuthorities: productFixture.contentAuthorities,
        assessmentAuthorities: productFixture.assessmentAuthorities,
      );
      expect(productCatalog.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(productCatalog.editions, hasLength(6));

      final incompleteProductManifest = _partialCoreManifest();
      expect(
        () => CourseSegmentCatalog.fromJson(
          incompleteProductManifest,
          courseUnits: _units,
          concepts: _concepts,
          seedAuthorities: _seedAuthorities,
          contentAuthorities: _contentAuthorities,
          assessmentAuthorities: _assessmentAuthorities,
        ),
        _throwsFormatContaining(
          'published core levels must exactly match the product policy',
        ),
      );
    });

    test('allows an incomplete canonical core only while it remains draft', () {
      final draftManifest = _partialCoreManifest();
      final track = _track(draftManifest, 'core_2026_v1');
      track
        ..['status'] = 'draft'
        ..remove('publishedAt');
      for (final edition in draftManifest['trackEditions'] as List<Object?>) {
        final map = edition as Map<String, dynamic>;
        map
          ..['releaseTrackId'] = 'core_2026_v1'
          ..['status'] = 'draft'
          ..remove('publishedAt');
      }
      for (final segment in draftManifest['segments'] as List<Object?>) {
        final map = segment as Map<String, dynamic>;
        map
          ..['releaseTrackId'] = 'core_2026_v1'
          ..['lifecycle'] = 'draft'
          ..['requiredConceptIds'] = <String>[]
          ..['proofRevision'] = 0
          ..['assessmentRequirements'] = <Object?>[]
          ..['ownedAssessmentItemIds'] = <String>[];
      }

      final catalog = CourseSegmentCatalog.fromJson(
        draftManifest,
        courseUnits: _units,
        concepts: _concepts,
        seedAuthorities: _seedAuthorities,
        contentAuthorities: _contentAuthorities,
        assessmentAuthorities: _assessmentAuthorities,
      );

      expect(
        catalog.findReleaseTrack('core_2026_v1')?.status,
        ReleaseTrackStatus.draft,
      );
      expect(catalog.denominatorForReleaseTrack('core_2026_v1'), 3);
    });

    test('catalog exposes no arbitrary core-policy decoder seam', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final normalizedPath = entity.path.replaceAll('\\', '/');
        if (entity.readAsStringSync().contains(
          'fromJsonWithPolicyForTesting',
        )) {
          offenders.add(normalizedPath);
        }
      }
      expect(offenders, isEmpty);
    });

    test('round-trips exact all-of assessment and release-track fields', () {
      final catalog = _load(_manifest());
      final segment = catalog.findSegment('segment_a1_first')!;
      final requirement = segment.assessmentRequirements.single;

      expect(segment.evidencePolicy, SegmentEvidencePolicy.allOf);
      expect(segment.ownedAssessmentItemIds, ['assess_a1_first']);
      expect(requirement.missionContentLinkId, 'link_a1_first');
      expect(requirement.rubricVersion, 2);
      expect(requirement.minimumScore, .7);
      expect(segment.toJson(), _segment(_manifest(), segment.id));
      expect(
        catalog.releaseTracks.single.toJson(),
        _track(_manifest(), 'core_2026_v1'),
      );
    });

    test('publishes a new ability only in a separate extension track', () {
      final previous = _load(_manifest());
      final manifest = _withA1Extension(_manifest());
      final current = _load(
        manifest,
        assessmentAuthorities: [
          ..._assessmentAuthorities,
          _assessmentAuthority(
            id: 'assess_a1_extension',
            linkId: 'link_a1_extension',
            level: LearnerLevel.a1,
            unitId: 'unit_a1',
            conceptIds: const ['concept_a1_first'],
            mode: SegmentEvidenceMode.connectedProduction,
          ),
        ],
      );

      current.validateEvolutionFrom(previous);

      expect(current.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(current.denominatorForReleaseTrack('a1_extension_2026_v1'), 1);
      expect(
        current.findReleaseTrack('a1_extension_2026_v1')?.kind,
        ReleaseTrackKind.extension,
      );
    });

    test(
      'places every newly non-draft extension after the prior published max',
      () {
        final previousManifest = _withA1Extension(_manifest(), trackOrder: 3);
        final previous = _load(
          previousManifest,
          assessmentAuthorities: _withA1ExtensionAuthority(),
        );
        final secondAuthority = _assessmentAuthority(
          id: 'assess_a1_extension_second',
          linkId: 'link_a1_extension_second',
          level: LearnerLevel.a1,
          unitId: 'unit_a1',
          conceptIds: const ['concept_a1_first'],
          mode: SegmentEvidenceMode.connectedProduction,
        );

        final newlyPublished = _withSecondA1Extension(
          _deepCopy(previousManifest),
          trackOrder: 2,
        );
        expect(
          () => _load(
            newlyPublished,
            assessmentAuthorities: [
              ..._withA1ExtensionAuthority(),
              secondAuthority,
            ],
          ).validateEvolutionFrom(previous),
          _throwsFormatContaining(
            'must be strictly after previous non-draft maximum order 3',
          ),
        );

        final previousWithDraft = _load(
          _withSecondA1Extension(
            _deepCopy(previousManifest),
            trackOrder: 2,
            extensionPublished: false,
          ),
          assessmentAuthorities: _withA1ExtensionAuthority(),
        );
        expect(
          () => _load(
            newlyPublished,
            assessmentAuthorities: [
              ..._withA1ExtensionAuthority(),
              secondAuthority,
            ],
          ).validateEvolutionFrom(previousWithDraft),
          _throwsFormatContaining(
            'must be strictly after previous non-draft maximum order 3',
          ),
        );
      },
    );

    test('revised practice increments only its content-cluster revision', () {
      final previous = _load(_manifest());
      final manifest = _manifest();
      final cluster = _cluster(manifest, 'cluster_a1_first');
      cluster['revision'] = 2;
      (cluster['sourceSeedIds'] as List<Object?>).add('seed_a1_supplement');
      (cluster['contentReferences'] as List<Object?>).add({
        'kind': 'scenario',
        'id': 'scenario_a1_supplement',
      });
      final current = _load(
        manifest,
        seedAuthorities: [
          ..._seedAuthorities,
          const ContentSeedAuthority(
            id: 'seed_a1_supplement',
            level: LearnerLevel.a1,
          ),
        ],
        contentAuthorities: [
          ..._contentAuthorities,
          const ContentReferenceAuthority(
            reference: ContentReference(
              kind: ContentReferenceKind.scenario,
              id: 'scenario_a1_supplement',
            ),
            level: LearnerLevel.a1,
            sourceSeedId: 'seed_a1_supplement',
            courseUnitId: 'unit_a1',
          ),
        ],
      );

      current.validateEvolutionFrom(previous);

      expect(current.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(current.findContentCluster('cluster_a1_first')?.revision, 2);
    });

    test('source-seed provenance is append-only and revisioned', () {
      const supplement = ContentSeedAuthority(
        id: 'seed_a1_supplement',
        level: LearnerLevel.a1,
      );
      final authorities = [..._seedAuthorities, supplement];

      final noBumpManifest = _manifest();
      (_cluster(noBumpManifest, 'cluster_a1_first')['sourceSeedIds']
              as List<Object?>)
          .add(supplement.id);
      expect(
        () => _load(
          noBumpManifest,
          seedAuthorities: authorities,
        ).validateEvolutionFrom(_load(_manifest())),
        _throwsFormatContaining('changes require a revision increase'),
      );

      final previousManifest = _manifest();
      final previousCluster = _cluster(previousManifest, 'cluster_a1_first');
      previousCluster['revision'] = 2;
      (previousCluster['sourceSeedIds'] as List<Object?>).add(supplement.id);
      final currentManifest = _deepCopy(previousManifest);
      final currentCluster = _cluster(currentManifest, 'cluster_a1_first');
      currentCluster['revision'] = 3;
      (currentCluster['sourceSeedIds'] as List<Object?>).removeAt(1);
      expect(
        () => _load(currentManifest, seedAuthorities: authorities)
            .validateEvolutionFrom(
              _load(previousManifest, seedAuthorities: authorities),
            ),
        _throwsFormatContaining('cannot remove or reorder source seed'),
      );
    });

    test('draft-only segment, edition, track, and cluster may disappear', () {
      final previousManifest = _manifest();
      (previousManifest['contentClusters'] as List<Object?>).add(
        _contentClusterJson(
          id: 'cluster_a1_draft',
          level: 'a1',
          referenceKind: 'scenario',
          referenceId: 'scenario_a1_first',
        ),
      );
      (previousManifest['segments'] as List<Object?>).add(
        _draftSegmentJson(
          id: 'segment_a1_draft',
          clusterId: 'cluster_a1_draft',
          editionId: 'edition_a1_draft',
          trackId: 'track_a1_draft',
        ),
      );
      (previousManifest['trackEditions'] as List<Object?>).add({
        'id': 'edition_a1_draft',
        'releaseTrackId': 'track_a1_draft',
        'level': 'a1',
        'segmentIds': ['segment_a1_draft'],
        'status': 'draft',
      });
      (previousManifest['releaseTracks'] as List<Object?>).add({
        'id': 'track_a1_draft',
        'kind': 'extension',
        'order': 2,
        'title': _text('초안 확장'),
        'editionIds': ['edition_a1_draft'],
        'status': 'draft',
      });

      expect(
        () => _load(_manifest()).validateEvolutionFrom(_load(previousManifest)),
        returnsNormally,
      );
    });
  });

  group('typed authority validation', () {
    test('rejects unknown or cross-level source seed provenance', () {
      final wrongLevel = [..._seedAuthorities];
      wrongLevel[0] = ContentSeedAuthority(
        id: wrongLevel[0].id,
        level: LearnerLevel.c1,
      );
      expect(
        () => _load(_manifest(), seedAuthorities: wrongLevel),
        _throwsFormatContaining('source seed "scenario_a1_first" has level c1'),
      );

      final missing = _manifest();
      (_cluster(missing, 'cluster_a1_first')['sourceSeedIds']
              as List<Object?>)[0] =
          'unknown_seed';
      expect(
        () => _load(missing),
        _throwsFormatContaining('unknown source seed "unknown_seed"'),
      );
    });

    test('rejects content authority from another level', () {
      final authorities = [..._contentAuthorities];
      authorities[0] = ContentReferenceAuthority(
        reference: authorities[0].reference,
        level: LearnerLevel.c1,
        sourceSeedId: authorities[0].sourceSeedId,
        courseUnitId: authorities[0].courseUnitId,
      );

      expect(
        () => _load(_manifest(), contentAuthorities: authorities),
        _throwsFormatContaining('has level c1, expected a1'),
      );
    });

    test('requires exact seed and course-unit provenance per reference', () {
      final wrongSeed = [..._contentAuthorities];
      final first = wrongSeed[0];
      wrongSeed[0] = ContentReferenceAuthority(
        reference: first.reference,
        level: first.level,
        sourceSeedId: 'pack_a1_second',
        courseUnitId: first.courseUnitId,
      );
      expect(
        () => _load(_manifest(), contentAuthorities: wrongSeed),
        _throwsFormatContaining('outside sourceSeedIds'),
      );

      final wrongUnit = [..._contentAuthorities];
      wrongUnit[0] = ContentReferenceAuthority(
        reference: first.reference,
        level: first.level,
        sourceSeedId: first.sourceSeedId,
        courseUnitId: 'unit_b1',
      );
      expect(
        () => _load(_manifest(), contentAuthorities: wrongUnit),
        _throwsFormatContaining(
          'belongs to course unit "unit_b1", expected "unit_a1"',
        ),
      );
    });

    test('rejects recognition or non-course-eligible assessment edges', () {
      final recognition = [..._assessmentAuthorities];
      recognition[0] = _copyAuthority(recognition[0], isAssessEdge: false);
      expect(
        () => _load(_manifest(), assessmentAuthorities: recognition),
        _throwsFormatContaining('is not an eligible assess edge'),
      );

      final ineligible = [..._assessmentAuthorities];
      ineligible[0] = _copyAuthority(ineligible[0], courseEligible: false);
      expect(
        () => _load(_manifest(), assessmentAuthorities: ineligible),
        _throwsFormatContaining('is not an eligible assess edge'),
      );
    });

    test('rejects every exact assessment-contract mismatch', () {
      final mismatches = <SegmentAssessmentAuthority>[
        _copyAuthority(_assessmentAuthorities[0], linkId: 'link_wrong'),
        _copyAuthority(_assessmentAuthorities[0], level: LearnerLevel.c1),
        _copyAuthority(_assessmentAuthorities[0], unitId: 'unit_b1'),
        _copyAuthority(
          _assessmentAuthorities[0],
          conceptIds: const ['concept_a1_second'],
        ),
        _copyAuthority(
          _assessmentAuthorities[0],
          mode: SegmentEvidenceMode.dictation,
        ),
        _copyAuthority(_assessmentAuthorities[0], rubricVersion: 3),
        _copyAuthority(_assessmentAuthorities[0], minimumScore: .8),
      ];

      for (final mismatch in mismatches) {
        final authorities = [..._assessmentAuthorities]..[0] = mismatch;
        expect(
          () => _load(_manifest(), assessmentAuthorities: authorities),
          _throwsFormatContaining(
            'does not exactly match its trusted authority',
          ),
        );
      }
    });

    test('rejects invalid minimum score and non-all-of evidence policy', () {
      final badScore = _manifest();
      _requirement(badScore, 'segment_a1_first')['minimumScore'] = .69;
      expect(
        () => _load(badScore),
        _throwsFormatContaining('must be at least 0.7 and at most 1'),
      );

      final weakAuthorities = [..._assessmentAuthorities];
      weakAuthorities[0] = _copyAuthority(
        weakAuthorities[0],
        minimumScore: .69,
      );
      expect(
        () => _load(_manifest(), assessmentAuthorities: weakAuthorities),
        _throwsFormatContaining('must be at least 0.7 and at most 1'),
      );

      final badPolicy = _manifest();
      _segment(badPolicy, 'segment_a1_first')['evidencePolicy'] = 'anyOf';
      expect(
        () => _load(badPolicy),
        _throwsFormatContaining('unknown evidence policy'),
      );
    });

    test('requires current assessments in declared ownership', () {
      final manifest = _manifest();
      _segment(manifest, 'segment_a1_first')['ownedAssessmentItemIds'] =
          <String>[];

      expect(
        () => _load(manifest),
        _throwsFormatContaining('must include current requirements'),
      );
    });
  });

  group('release-track and edition lifecycle', () {
    test('rejects more or fewer than one core track', () {
      final noCore = _manifest();
      _track(noCore, 'core_2026_v1')['kind'] = 'extension';
      expect(
        () => _load(noCore),
        _throwsFormatContaining('must contain exactly one core track'),
      );

      final twoCore = _manifest();
      (twoCore['releaseTracks'] as List<Object?>).add({
        'id': 'another_core',
        'kind': 'core',
        'order': 2,
        'title': _text('두 번째 코어'),
        'editionIds': ['edition_core_a1_v1'],
        'publishedAt': _publishedAt,
        'status': 'published',
      });
      expect(
        () => _load(twoCore),
        _throwsFormatContaining('must contain exactly one core track'),
      );
    });

    test('requires every edition exactly once in one release track', () {
      final missing = _withA1Extension(_manifest());
      (_track(missing, 'a1_extension_2026_v1')['editionIds'] as List<Object?>)
          .clear();
      expect(
        () =>
            _load(missing, assessmentAuthorities: _withA1ExtensionAuthority()),
        _throwsFormatContaining('editionIds: must not be empty'),
      );

      final wrongOwner = _manifest();
      _edition(wrongOwner, 'edition_core_a1_v1')['releaseTrackId'] = 'other';
      expect(
        () => _load(wrongOwner),
        _throwsFormatContaining(
          'release track does not match its track edition',
        ),
      );
    });

    test('enforces segment, edition, and track lifecycle matrix', () {
      final publishedSegmentInRetiredEdition = _manifest();
      _edition(
        publishedSegmentInRetiredEdition,
        'edition_core_a1_v1',
      )['status'] = 'retired';
      expect(
        () => _load(publishedSegmentInRetiredEdition),
        _throwsFormatContaining(
          'published segment is incompatible with retired edition',
        ),
      );

      final publishedEditionInRetiredTrack = _manifest();
      _track(publishedEditionInRetiredTrack, 'core_2026_v1')['status'] =
          'retired';
      expect(
        () => _load(publishedEditionInRetiredTrack),
        _throwsFormatContaining(
          'published edition is incompatible with retired release track',
        ),
      );
    });

    test('rejects locked core membership growth', () {
      final currentManifest = _withA1Extension(
        _manifest(),
        trackId: 'core_2026_v1',
        trackKind: null,
      );
      final core = _track(currentManifest, 'core_2026_v1');
      (core['editionIds'] as List<Object?>).add('edition_a1_extension_v1');
      (currentManifest['releaseTracks'] as List<Object?>).removeWhere(
        (entry) =>
            (entry as Map<String, dynamic>)['id'] == 'a1_extension_2026_v1',
      );
      expect(
        () => _load(
          currentManifest,
          assessmentAuthorities: _withA1ExtensionAuthority(),
        ),
        _throwsFormatContaining('exactly one edition for a1'),
      );
    });

    test(
      'locks release track membership, kind, order, and publication time',
      () {
        for (final mutation in <void Function(Map<String, dynamic>)>[
          (track) => track['kind'] = 'extension',
          (track) => track['order'] = 2,
          (track) => track['publishedAt'] = '2026-08-16T00:00:00.001Z',
          (track) => (track['editionIds'] as List<Object?>).removeLast(),
        ]) {
          final manifest = _manifest();
          mutation(_track(manifest, 'core_2026_v1'));
          CourseSegmentCatalog? current;
          try {
            current = _load(manifest);
          } on FormatException {
            continue;
          }
          expect(
            () => current!.validateEvolutionFrom(_load(_manifest())),
            _throwsFormatContaining('changed immutable publication fields'),
          );
        }
      },
    );
  });

  group('semantic and assessment evolution', () {
    test('freezes Korean can-do but permits localization improvements', () {
      final changedMeaning = _manifest();
      (_segment(changedMeaning, 'segment_a1_first')['canDo']
              as Map<String, dynamic>)['ko'] =
          '전혀 다른 일을 할 수 있다.';
      expect(
        () => _load(changedMeaning).validateEvolutionFrom(_load(_manifest())),
        _throwsFormatContaining('changed immutable Korean can-do'),
      );

      final localization = _manifest();
      (_segment(localization, 'segment_a1_first')['canDo']
              as Map<String, dynamic>)['de'] =
          'Verbesserte Übersetzung.';
      (_segment(localization, 'segment_a1_first')['title']
              as Map<String, dynamic>)['en'] =
          'Improved title';
      expect(
        () => _load(localization).validateEvolutionFrom(_load(_manifest())),
        returnsNormally,
      );
    });

    test('freezes proof identity on every non-draft segment ID', () {
      final previous = _load(_manifest());

      final proofBump = _manifest();
      _segment(proofBump, 'segment_a1_first')['proofRevision'] = 2;
      expect(
        () => _load(proofBump).validateEvolutionFrom(previous),
        _throwsFormatContaining('changed immutable proof identity'),
      );

      final changedRequirement = _manifest();
      _requirement(changedRequirement, 'segment_a1_first')['minimumScore'] = .8;
      final higherAuthorities = [..._assessmentAuthorities];
      higherAuthorities[0] = _copyAuthority(
        higherAuthorities[0],
        minimumScore: .8,
      );
      expect(
        () => _load(
          changedRequirement,
          assessmentAuthorities: higherAuthorities,
        ).validateEvolutionFrom(previous),
        _throwsFormatContaining('changed immutable proof identity'),
      );

      final changedOwnership = _manifest();
      (_segment(changedOwnership, 'segment_a1_first')['ownedAssessmentItemIds']
              as List<Object?>)
          .add('assess_a1_reserved');
      expect(
        () => _load(changedOwnership).validateEvolutionFrom(previous),
        _throwsFormatContaining('changed immutable proof identity'),
      );
    });

    test('keeps historical assessment IDs reserved after replacement', () {
      final replacementManifest = _withA1Replacement(_manifest());
      final reassigned = _withA1Extension(replacementManifest, trackOrder: 3);
      final extension = _segment(reassigned, 'segment_a1_extension');
      extension['assessmentRequirements'] = [
        _requirementJson(
          assessmentId: 'assess_a1_first',
          linkId: 'link_a1_first',
          mode: 'guidedProduction',
        ),
      ];
      extension['ownedAssessmentItemIds'] = ['assess_a1_first'];

      expect(
        () => _load(
          reassigned,
          assessmentAuthorities: _withA1ReplacementAuthority(),
        ),
        _throwsFormatContaining('is already owned by'),
      );
    });
  });

  group('retirement and successor slot satisfaction', () {
    test('preserves old evidence and accepts a replacement successor', () {
      final previous = _load(_manifest());
      final manifest = _withA1Replacement(_manifest());
      final current = _load(
        manifest,
        assessmentAuthorities: _withA1ReplacementAuthority(),
      );

      current.validateEvolutionFrom(previous);

      expect(current.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(current.denominatorForReleaseTrack('a1_replacement_2026_v2'), 0);
      expect(current.publishedSegments, hasLength(86));
      expect(current.assessmentAuthoritySegments, hasLength(87));
      expect(
        current.assessmentAuthoritySegments.map((segment) => segment.id),
        containsAll(['segment_a1_first', 'segment_a1_first_proof_v2']),
      );
      expect(
        current.findReleaseTrack('a1_replacement_2026_v2')?.kind,
        ReleaseTrackKind.replacement,
      );
      expect(
        current.satisfyingSegmentIdsForEditionSlot(
          editionId: 'edition_core_a1_v1',
          segmentId: 'segment_a1_first',
        ),
        ['segment_a1_first', 'segment_a1_first_proof_v2'],
      );
      expect(
        () => current.satisfyingSegmentIdsForEditionSlot(
          editionId: 'edition_a1_replacement_v2',
          segmentId: 'segment_a1_first_proof_v2',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a successor from a different construct lineage', () {
      final manifest = _withA1Replacement(
        _manifest(),
        constructLineageId: 'different_construct',
      );
      final retired = _segment(manifest, 'segment_a1_first');

      expect(
        () => _load(
          manifest,
          assessmentAuthorities: _withA1ReplacementAuthority(),
        ),
        _throwsFormatContaining('preserve the same construct lineage'),
      );
      expect(retired['lifecycle'], 'retired');
    });

    test('one successor cannot replace two immutable edition slots', () {
      final manifest = _withA1Replacement(_manifest());
      final first = _segment(manifest, 'segment_a1_first');
      final second = _segment(manifest, 'segment_a1_second');
      second
        ..['constructLineageId'] = 'segment_a1_first'
        ..['lifecycle'] = 'retired'
        ..['successorSegmentId'] = 'segment_a1_first_proof_v2';

      expect(
        () => _load(
          manifest,
          assessmentAuthorities: _withA1ReplacementAuthority(),
        ),
        _throwsFormatContaining('cannot succeed both'),
      );
      expect(first['successorSegmentId'], 'segment_a1_first_proof_v2');
    });

    test('published records sharing a construct must form one chain', () {
      final manifest = _withA1Replacement(
        _manifest(),
        connectPredecessor: false,
      );

      expect(
        () => _load(
          manifest,
          assessmentAuthorities: _withA1ReplacementAuthority(),
        ),
        _throwsFormatContaining(
          'replacement segment must succeed an existing construct',
        ),
      );
    });

    test('extension cannot duplicate a core construct', () {
      final manifest = _withA1Extension(
        _manifest(),
        constructLineageId: 'segment_a1_first',
      );

      expect(
        () =>
            _load(manifest, assessmentAuthorities: _withA1ExtensionAuthority()),
        _throwsFormatContaining(
          'extension track cannot duplicate an existing construct lineage',
        ),
      );
    });

    test(
      'published construct lineage is immutable across catalog revisions',
      () {
        final currentManifest = _manifest();
        _segment(currentManifest, 'segment_a1_first')['constructLineageId'] =
            'changed_construct';

        expect(
          () =>
              _load(currentManifest).validateEvolutionFrom(_load(_manifest())),
          _throwsFormatContaining('changed immutable identity fields'),
        );
      },
    );

    test('follows the full successor chain across later replacements', () {
      final previous = _load(_manifest());
      final manifest = _withSecondA1Replacement(
        _withA1Replacement(_manifest()),
      );
      final current = _load(
        manifest,
        assessmentAuthorities: _withSecondA1ReplacementAuthority(),
      );

      current.validateEvolutionFrom(previous);

      expect(
        current.satisfyingSegmentIdsForEditionSlot(
          editionId: 'edition_core_a1_v1',
          segmentId: 'segment_a1_first',
        ),
        [
          'segment_a1_first',
          'segment_a1_first_proof_v2',
          'segment_a1_first_proof_v3',
        ],
      );
    });

    test('active retired slot requires a successor', () {
      final manifest = _manifest();
      _segment(manifest, 'segment_a1_first')['lifecycle'] = 'retired';

      expect(
        () => _load(manifest),
        _throwsFormatContaining('requires a successor'),
      );
    });

    test('successor must be published in a newer replacement track', () {
      final sameEdition = _manifest();
      final retired = _segment(sameEdition, 'segment_a1_first');
      retired['lifecycle'] = 'retired';
      retired['successorSegmentId'] = 'segment_a1_second';
      _segment(sameEdition, 'segment_a1_second')
        ..['constructLineageId'] = 'segment_a1_first'
        ..['proofRevision'] = 2;
      expect(
        () => _load(sameEdition),
        _throwsFormatContaining('different replacement edition'),
      );

      final extension = _withA1Extension(
        _manifest(),
        constructLineageId: 'segment_a1_first',
      );
      _segment(extension, 'segment_a1_first')
        ..['lifecycle'] = 'retired'
        ..['successorSegmentId'] = 'segment_a1_extension';
      _segment(extension, 'segment_a1_extension')['proofRevision'] = 2;
      expect(
        () => _load(
          extension,
          assessmentAuthorities: _withA1ExtensionAuthority(),
        ),
        _throwsFormatContaining('newer non-draft replacement track'),
      );

      final draftReplacement = _withA1Replacement(
        _manifest(),
        replacementPublished: false,
      );
      final draftRetired = _segment(draftReplacement, 'segment_a1_first');
      draftRetired['lifecycle'] = 'retired';
      draftRetired['successorSegmentId'] = 'segment_a1_first_proof_v2';
      expect(
        () => _load(
          draftReplacement,
          assessmentAuthorities: _assessmentAuthorities,
        ),
        _throwsFormatContaining('successor must be published'),
      );
    });

    test('a retired whole edition may keep history without a successor', () {
      final manifest = _manifest();
      _edition(manifest, 'edition_core_b1_v1')['status'] = 'retired';
      for (final segment
          in (manifest['segments'] as List<Object?>)
              .cast<Map<String, dynamic>>()) {
        if (segment['trackEditionId'] == 'edition_core_b1_v1') {
          segment['lifecycle'] = 'retired';
        }
      }

      final catalog = _load(manifest);

      expect(
        catalog.satisfyingSegmentIdsForEditionSlot(
          editionId: 'edition_core_b1_v1',
          segmentId: 'segment_b1_first',
        ),
        ['segment_b1_first'],
      );
    });
  });
}

CourseSegmentCatalog _load(
  Map<String, dynamic> manifest, {
  Iterable<ContentSeedAuthority>? seedAuthorities,
  Iterable<ContentReferenceAuthority>? contentAuthorities,
  Iterable<SegmentAssessmentAuthority>? assessmentAuthorities,
}) {
  return CourseSegmentCatalog.fromJson(
    manifest,
    courseUnits: _units,
    concepts: _concepts,
    seedAuthorities: seedAuthorities ?? _seedAuthorities,
    contentAuthorities: contentAuthorities ?? _contentAuthorities,
    assessmentAuthorities: assessmentAuthorities ?? _assessmentAuthorities,
  );
}

final _CatalogFixture _baseFixture = _canonicalProductFixture();
final List<CourseUnit> _units = _baseFixture.courseUnits;
final List<Concept> _concepts = _baseFixture.concepts;
final List<ContentSeedAuthority> _seedAuthorities =
    _baseFixture.seedAuthorities;
final List<ContentReferenceAuthority> _contentAuthorities =
    _baseFixture.contentAuthorities;
final List<SegmentAssessmentAuthority> _assessmentAuthorities =
    _baseFixture.assessmentAuthorities;

List<SegmentAssessmentAuthority> _withA1ExtensionAuthority() => [
  ..._assessmentAuthorities,
  _assessmentAuthority(
    id: 'assess_a1_extension',
    linkId: 'link_a1_extension',
    level: LearnerLevel.a1,
    unitId: 'unit_a1',
    conceptIds: const ['concept_a1_first'],
    mode: SegmentEvidenceMode.connectedProduction,
  ),
];

List<SegmentAssessmentAuthority> _withA1ReplacementAuthority() => [
  ..._assessmentAuthorities,
  _assessmentAuthority(
    id: 'assess_a1_first_proof_v2',
    linkId: 'link_a1_first_proof_v2',
    level: LearnerLevel.a1,
    unitId: 'unit_a1',
    conceptIds: const ['concept_a1_first'],
    mode: SegmentEvidenceMode.connectedProduction,
    rubricVersion: 3,
  ),
];

List<SegmentAssessmentAuthority> _withSecondA1ReplacementAuthority() => [
  ..._withA1ReplacementAuthority(),
  _assessmentAuthority(
    id: 'assess_a1_first_proof_v3',
    linkId: 'link_a1_first_proof_v3',
    level: LearnerLevel.a1,
    unitId: 'unit_a1',
    conceptIds: const ['concept_a1_first'],
    mode: SegmentEvidenceMode.openWriting,
    rubricVersion: 4,
  ),
];

const String _publishedAt = '2026-08-16T00:00:00.000Z';

Map<String, dynamic> _manifest() => _deepCopy(_baseFixture.manifest);

Map<String, dynamic> _partialCoreManifest() => {
  'schemaVersion': 1,
  'contentClusters': <Object?>[
    _contentClusterJson(
      id: 'cluster_a1_first',
      level: 'a1',
      referenceKind: 'scenario',
      referenceId: 'scenario_a1_first',
    ),
    _contentClusterJson(
      id: 'cluster_a1_second',
      level: 'a1',
      referenceKind: 'vocabPack',
      referenceId: 'pack_a1_second',
    ),
    _contentClusterJson(
      id: 'cluster_b1_first',
      level: 'b1',
      referenceKind: 'project',
      referenceId: 'project_b1_first',
    ),
  ],
  'segments': <Object?>[
    _segmentJson(
      id: 'segment_b1_first',
      unitId: 'unit_b1',
      level: 'b1',
      order: 1,
      conceptId: 'concept_b1_first',
      clusterId: 'cluster_b1_first',
      editionId: 'edition_core_b1_v1',
      title: 'B1 능력',
      evidenceMode: 'connectedProduction',
    ),
    _segmentJson(
      id: 'segment_a1_second',
      unitId: 'unit_a1',
      level: 'a1',
      order: 2,
      conceptId: 'concept_a1_second',
      clusterId: 'cluster_a1_second',
      editionId: 'edition_core_a1_v1',
      title: '둘째 능력',
      evidenceMode: 'dictation',
    ),
    _segmentJson(
      id: 'segment_a1_first',
      unitId: 'unit_a1',
      level: 'a1',
      order: 1,
      conceptId: 'concept_a1_first',
      clusterId: 'cluster_a1_first',
      editionId: 'edition_core_a1_v1',
      title: '첫 능력',
      evidenceMode: 'guidedProduction',
    ),
  ],
  'trackEditions': <Object?>[
    {
      'id': 'edition_core_b1_v1',
      'releaseTrackId': 'core_2026_v1',
      'level': 'b1',
      'segmentIds': ['segment_b1_first'],
      'publishedAt': _publishedAt,
      'status': 'published',
    },
    {
      'id': 'edition_core_a1_v1',
      'releaseTrackId': 'core_2026_v1',
      'level': 'a1',
      'segmentIds': ['segment_a1_first', 'segment_a1_second'],
      'publishedAt': _publishedAt,
      'status': 'published',
    },
  ],
  'releaseTracks': <Object?>[
    {
      'id': 'core_2026_v1',
      'kind': 'core',
      'order': 1,
      'title': _text('첫 코어'),
      'editionIds': ['edition_core_a1_v1', 'edition_core_b1_v1'],
      'publishedAt': _publishedAt,
      'status': 'published',
    },
  ],
};

Map<String, dynamic> _withA1Extension(
  Map<String, dynamic> manifest, {
  String trackId = 'a1_extension_2026_v1',
  String? trackKind = 'extension',
  int trackOrder = 2,
  bool extensionPublished = true,
  String? constructLineageId,
}) {
  final editionId = 'edition_a1_extension_v1';
  (manifest['contentClusters'] as List<Object?>).add(
    _contentClusterJson(
      id: 'cluster_a1_extension',
      level: 'a1',
      referenceKind: 'scenario',
      referenceId: 'scenario_a1_first',
    ),
  );
  final segment = _segmentJson(
    id: 'segment_a1_extension',
    unitId: 'unit_a1',
    level: 'a1',
    order: 3,
    conceptId: 'concept_a1_first',
    clusterId: 'cluster_a1_extension',
    editionId: editionId,
    trackId: trackId,
    title: '추가 능력',
    evidenceMode: 'connectedProduction',
    constructLineageId: constructLineageId,
  );
  if (!extensionPublished) {
    segment
      ..['lifecycle'] = 'draft'
      ..['requiredConceptIds'] = <String>[]
      ..['proofRevision'] = 0
      ..['assessmentRequirements'] = <Object?>[]
      ..['ownedAssessmentItemIds'] = <String>[];
  }
  (manifest['segments'] as List<Object?>).add(segment);
  (manifest['trackEditions'] as List<Object?>).add({
    'id': editionId,
    'releaseTrackId': trackId,
    'level': 'a1',
    'segmentIds': ['segment_a1_extension'],
    if (extensionPublished) 'publishedAt': '2026-08-17T00:00:00.000Z',
    'status': extensionPublished ? 'published' : 'draft',
  });
  if (trackKind != null) {
    (manifest['releaseTracks'] as List<Object?>).add({
      'id': trackId,
      'kind': trackKind,
      'order': trackOrder,
      'title': _text('A1 확장'),
      'editionIds': [editionId],
      if (extensionPublished) 'publishedAt': '2026-08-17T00:00:00.000Z',
      'status': extensionPublished ? 'published' : 'draft',
    });
  }
  return manifest;
}

Map<String, dynamic> _withSecondA1Extension(
  Map<String, dynamic> manifest, {
  int trackOrder = 3,
  bool extensionPublished = true,
  String? constructLineageId,
}) {
  const trackId = 'a1_extension_2026_v2';
  const editionId = 'edition_a1_extension_v2';
  (manifest['contentClusters'] as List<Object?>).add(
    _contentClusterJson(
      id: 'cluster_a1_extension_second',
      level: 'a1',
      referenceKind: 'scenario',
      referenceId: 'scenario_a1_first',
    ),
  );
  final segment = _segmentJson(
    id: 'segment_a1_extension_second',
    unitId: 'unit_a1',
    level: 'a1',
    order: 4,
    conceptId: 'concept_a1_first',
    clusterId: 'cluster_a1_extension_second',
    editionId: editionId,
    trackId: trackId,
    title: '두 번째 추가 능력',
    evidenceMode: 'connectedProduction',
    constructLineageId: constructLineageId,
  );
  if (!extensionPublished) {
    segment
      ..['lifecycle'] = 'draft'
      ..['requiredConceptIds'] = <String>[]
      ..['proofRevision'] = 0
      ..['assessmentRequirements'] = <Object?>[]
      ..['ownedAssessmentItemIds'] = <String>[];
  }
  (manifest['segments'] as List<Object?>).add(segment);
  (manifest['trackEditions'] as List<Object?>).add({
    'id': editionId,
    'releaseTrackId': trackId,
    'level': 'a1',
    'segmentIds': ['segment_a1_extension_second'],
    if (extensionPublished) 'publishedAt': '2026-08-18T00:00:00.000Z',
    'status': extensionPublished ? 'published' : 'draft',
  });
  (manifest['releaseTracks'] as List<Object?>).add({
    'id': trackId,
    'kind': 'extension',
    'order': trackOrder,
    'title': _text('A1 두 번째 확장'),
    'editionIds': [editionId],
    if (extensionPublished) 'publishedAt': '2026-08-18T00:00:00.000Z',
    'status': extensionPublished ? 'published' : 'draft',
  });
  return manifest;
}

Map<String, dynamic> _withA1Replacement(
  Map<String, dynamic> manifest, {
  int trackOrder = 2,
  bool replacementPublished = true,
  bool connectPredecessor = true,
  String constructLineageId = 'segment_a1_first',
}) {
  const trackId = 'a1_replacement_2026_v2';
  const editionId = 'edition_a1_replacement_v2';
  const segmentId = 'segment_a1_first_proof_v2';
  (manifest['contentClusters'] as List<Object?>).add(
    _contentClusterJson(
      id: 'cluster_a1_first_proof_v2',
      level: 'a1',
      referenceKind: 'scenario',
      referenceId: 'scenario_a1_first',
    ),
  );
  final segment = _segmentJson(
    id: segmentId,
    unitId: 'unit_a1',
    level: 'a1',
    order: 3,
    conceptId: 'concept_a1_first',
    clusterId: 'cluster_a1_first_proof_v2',
    editionId: editionId,
    trackId: trackId,
    title: '첫 능력 증명 교체',
    evidenceMode: 'connectedProduction',
    constructLineageId: constructLineageId,
  );
  segment['proofRevision'] = 2;
  final requirement =
      (segment['assessmentRequirements'] as List<Object?>).single
          as Map<String, dynamic>;
  requirement['rubricVersion'] = 3;
  if (!replacementPublished) {
    segment
      ..['lifecycle'] = 'draft'
      ..['requiredConceptIds'] = <String>[]
      ..['proofRevision'] = 0
      ..['assessmentRequirements'] = <Object?>[]
      ..['ownedAssessmentItemIds'] = <String>[];
  }
  (manifest['segments'] as List<Object?>).add(segment);
  (manifest['trackEditions'] as List<Object?>).add({
    'id': editionId,
    'releaseTrackId': trackId,
    'level': 'a1',
    'segmentIds': [segmentId],
    if (replacementPublished) 'publishedAt': '2026-08-17T00:00:00.000Z',
    'status': replacementPublished ? 'published' : 'draft',
  });
  (manifest['releaseTracks'] as List<Object?>).add({
    'id': trackId,
    'kind': 'replacement',
    'order': trackOrder,
    'title': _text('A1 증명 교체'),
    'editionIds': [editionId],
    if (replacementPublished) 'publishedAt': '2026-08-17T00:00:00.000Z',
    'status': replacementPublished ? 'published' : 'draft',
  });
  if (connectPredecessor && replacementPublished) {
    _segment(manifest, 'segment_a1_first')
      ..['lifecycle'] = 'retired'
      ..['successorSegmentId'] = segmentId;
  }
  return manifest;
}

Map<String, dynamic> _withSecondA1Replacement(
  Map<String, dynamic> manifest, {
  int trackOrder = 3,
}) {
  const trackId = 'a1_replacement_2026_v3';
  const editionId = 'edition_a1_replacement_v3';
  const segmentId = 'segment_a1_first_proof_v3';
  (manifest['contentClusters'] as List<Object?>).add(
    _contentClusterJson(
      id: 'cluster_a1_first_proof_v3',
      level: 'a1',
      referenceKind: 'scenario',
      referenceId: 'scenario_a1_first',
    ),
  );
  final segment = _segmentJson(
    id: segmentId,
    unitId: 'unit_a1',
    level: 'a1',
    order: 4,
    conceptId: 'concept_a1_first',
    clusterId: 'cluster_a1_first_proof_v3',
    editionId: editionId,
    trackId: trackId,
    title: '첫 능력 증명 두 번째 교체',
    evidenceMode: 'openWriting',
    constructLineageId: 'segment_a1_first',
  );
  segment['proofRevision'] = 3;
  final requirement =
      (segment['assessmentRequirements'] as List<Object?>).single
          as Map<String, dynamic>;
  requirement['rubricVersion'] = 4;
  (manifest['segments'] as List<Object?>).add(segment);
  (manifest['trackEditions'] as List<Object?>).add({
    'id': editionId,
    'releaseTrackId': trackId,
    'level': 'a1',
    'segmentIds': [segmentId],
    'publishedAt': '2026-08-18T00:00:00.000Z',
    'status': 'published',
  });
  (manifest['releaseTracks'] as List<Object?>).add({
    'id': trackId,
    'kind': 'replacement',
    'order': trackOrder,
    'title': _text('A1 두 번째 증명 교체'),
    'editionIds': [editionId],
    'publishedAt': '2026-08-18T00:00:00.000Z',
    'status': 'published',
  });
  _segment(manifest, 'segment_a1_first_proof_v2')
    ..['lifecycle'] = 'retired'
    ..['successorSegmentId'] = segmentId;
  return manifest;
}

Map<String, dynamic> _segmentJson({
  required String id,
  required String unitId,
  required String level,
  required int order,
  required String conceptId,
  required String clusterId,
  required String editionId,
  required String title,
  required String evidenceMode,
  String trackId = 'core_2026_v1',
  String? constructLineageId,
}) {
  final assessmentId = id.replaceFirst('segment_', 'assess_');
  final linkId = id.replaceFirst('segment_', 'link_');
  return {
    'id': id,
    'constructLineageId': constructLineageId ?? id,
    'parentCourseUnitId': unitId,
    'level': level,
    'order': order,
    'title': _text(title),
    'canDo': {
      'ko': '$title을 할 수 있다.',
      'de': '$title auf Deutsch.',
      'en': '$title in English.',
    },
    'requiredConceptIds': [conceptId],
    'contentClusterIds': [clusterId],
    'proofRevision': 1,
    'evidencePolicy': 'allOf',
    'assessmentRequirements': [
      _requirementJson(
        assessmentId: assessmentId,
        linkId: linkId,
        mode: evidenceMode,
      ),
    ],
    'ownedAssessmentItemIds': [assessmentId],
    'releaseTrackId': trackId,
    'trackEditionId': editionId,
    'lifecycle': 'published',
  };
}

Map<String, dynamic> _draftSegmentJson({
  required String id,
  required String clusterId,
  required String editionId,
  required String trackId,
}) => {
  'id': id,
  'constructLineageId': id,
  'parentCourseUnitId': 'unit_a1',
  'level': 'a1',
  'order': 3,
  'title': _text('초안'),
  'canDo': _text('초안 능력'),
  'requiredConceptIds': <String>[],
  'contentClusterIds': [clusterId],
  'proofRevision': 0,
  'evidencePolicy': 'allOf',
  'assessmentRequirements': <Object?>[],
  'ownedAssessmentItemIds': <String>[],
  'releaseTrackId': trackId,
  'trackEditionId': editionId,
  'lifecycle': 'draft',
};

Map<String, dynamic> _requirementJson({
  required String assessmentId,
  required String linkId,
  required String mode,
}) => {
  'assessmentItemId': assessmentId,
  'missionContentLinkId': linkId,
  'evidenceMode': mode,
  'rubricVersion': 2,
  'minimumScore': .7,
};

Map<String, dynamic> _contentClusterJson({
  required String id,
  required String level,
  required String referenceKind,
  required String referenceId,
}) => {
  'id': id,
  'level': level,
  'revision': 1,
  'sourceSeedIds': [referenceId],
  'contentReferences': [
    {'kind': referenceKind, 'id': referenceId},
  ],
};

SegmentAssessmentAuthority _assessmentAuthority({
  required String id,
  required String linkId,
  required LearnerLevel level,
  required String unitId,
  required List<String> conceptIds,
  required SegmentEvidenceMode mode,
  int rubricVersion = 2,
  double minimumScore = .7,
  bool isAssessEdge = true,
  bool courseEligible = true,
}) => SegmentAssessmentAuthority(
  assessmentItemId: id,
  missionContentLinkId: linkId,
  level: level,
  courseUnitId: unitId,
  conceptIds: conceptIds,
  evidenceMode: mode,
  rubricVersion: rubricVersion,
  minimumScore: minimumScore,
  isAssessEdge: isAssessEdge,
  courseEligible: courseEligible,
);

SegmentAssessmentAuthority _copyAuthority(
  SegmentAssessmentAuthority source, {
  String? linkId,
  LearnerLevel? level,
  String? unitId,
  List<String>? conceptIds,
  SegmentEvidenceMode? mode,
  int? rubricVersion,
  double? minimumScore,
  bool? isAssessEdge,
  bool? courseEligible,
}) => _assessmentAuthority(
  id: source.assessmentItemId,
  linkId: linkId ?? source.missionContentLinkId,
  level: level ?? source.level,
  unitId: unitId ?? source.courseUnitId,
  conceptIds: conceptIds ?? source.conceptIds,
  mode: mode ?? source.evidenceMode,
  rubricVersion: rubricVersion ?? source.rubricVersion,
  minimumScore: minimumScore ?? source.minimumScore,
  isAssessEdge: isAssessEdge ?? source.isAssessEdge,
  courseEligible: courseEligible ?? source.courseEligible,
);

CourseUnit _courseUnit(String id, String level, List<String> conceptIds) =>
    CourseUnit(
      id: id,
      level: level,
      order: 1,
      title: CurriculumText.fromJson(_text(id)),
      canDo: CurriculumText.fromJson(_text('$id ability')),
      requiredConceptIds: conceptIds,
    );

Concept _concept(String id, String level) => Concept(
  id: id,
  level: level,
  kind: ConceptKind.situation,
  title: CurriculumText.fromJson(_text(id)),
  explanation: CurriculumText.fromJson(_text('$id explanation')),
);

_CatalogFixture _canonicalProductFixture() {
  final contentClusters = <Object?>[];
  final segments = <Object?>[];
  final editions = <Object?>[];
  final courseUnits = <CourseUnit>[];
  final concepts = <Concept>[];
  final seedAuthorities = <ContentSeedAuthority>[];
  final contentAuthorities = <ContentReferenceAuthority>[];
  final assessmentAuthorities = <SegmentAssessmentAuthority>[];

  for (final entry in hanokV1CoreReleasePolicy.segmentCountsByLevel.entries) {
    final level = entry.key;
    final levelCode = level.code;
    final unitId = 'unit_$levelCode';
    final defaultConceptId = 'concept_$levelCode';
    final editionId = 'edition_core_${levelCode}_v1';
    final segmentIds = <String>[];
    final unitConceptIds = <String>[
      defaultConceptId,
      if (level == LearnerLevel.a1) ...[
        'concept_a1_first',
        'concept_a1_second',
      ],
      if (level == LearnerLevel.b1) 'concept_b1_first',
    ];
    courseUnits.add(_courseUnit(unitId, levelCode, unitConceptIds));
    for (final conceptId in unitConceptIds) {
      concepts.add(_concept(conceptId, levelCode));
    }

    for (var index = 1; index <= entry.value; index++) {
      final suffix = index.toString().padLeft(2, '0');
      var segmentId = 'segment_${levelCode}_$suffix';
      var clusterId = 'cluster_${levelCode}_$suffix';
      var contentId = 'scenario_${levelCode}_$suffix';
      var conceptId = defaultConceptId;
      var referenceKindCode = 'scenario';
      var referenceKind = ContentReferenceKind.scenario;
      var evidenceModeCode = 'guidedProduction';
      var evidenceMode = SegmentEvidenceMode.guidedProduction;
      if (level == LearnerLevel.a1 && index == 1) {
        segmentId = 'segment_a1_first';
        clusterId = 'cluster_a1_first';
        contentId = 'scenario_a1_first';
        conceptId = 'concept_a1_first';
      } else if (level == LearnerLevel.a1 && index == 2) {
        segmentId = 'segment_a1_second';
        clusterId = 'cluster_a1_second';
        contentId = 'pack_a1_second';
        conceptId = 'concept_a1_second';
        referenceKindCode = 'vocabPack';
        referenceKind = ContentReferenceKind.vocabPack;
        evidenceModeCode = 'dictation';
        evidenceMode = SegmentEvidenceMode.dictation;
      } else if (level == LearnerLevel.b1 && index == 1) {
        segmentId = 'segment_b1_first';
        clusterId = 'cluster_b1_first';
        contentId = 'project_b1_first';
        conceptId = 'concept_b1_first';
        referenceKindCode = 'project';
        referenceKind = ContentReferenceKind.project;
        evidenceModeCode = 'connectedProduction';
        evidenceMode = SegmentEvidenceMode.connectedProduction;
      }
      segmentIds.add(segmentId);
      contentClusters.add(
        _contentClusterJson(
          id: clusterId,
          level: levelCode,
          referenceKind: referenceKindCode,
          referenceId: contentId,
        ),
      );
      segments.add(
        _segmentJson(
          id: segmentId,
          unitId: unitId,
          level: levelCode,
          order: index,
          conceptId: conceptId,
          clusterId: clusterId,
          editionId: editionId,
          trackId: 'core_2026_v1',
          title: '$levelCode $suffix',
          evidenceMode: evidenceModeCode,
        ),
      );
      seedAuthorities.add(ContentSeedAuthority(id: contentId, level: level));
      contentAuthorities.add(
        ContentReferenceAuthority(
          reference: ContentReference(kind: referenceKind, id: contentId),
          level: level,
          sourceSeedId: contentId,
          courseUnitId: unitId,
        ),
      );
      assessmentAuthorities.add(
        _assessmentAuthority(
          id: segmentId.replaceFirst('segment_', 'assess_'),
          linkId: segmentId.replaceFirst('segment_', 'link_'),
          level: level,
          unitId: unitId,
          conceptIds: [conceptId],
          mode: evidenceMode,
        ),
      );
    }
    editions.add({
      'id': editionId,
      'releaseTrackId': 'core_2026_v1',
      'level': levelCode,
      'segmentIds': segmentIds,
      'publishedAt': _publishedAt,
      'status': 'published',
    });
  }

  return _CatalogFixture(
    manifest: {
      'schemaVersion': 1,
      'contentClusters': contentClusters,
      'segments': segments,
      'trackEditions': editions,
      'releaseTracks': [
        {
          'id': 'core_2026_v1',
          'kind': 'core',
          'order': 1,
          'title': _text('한옥 V1 코어'),
          'editionIds': [
            for (final level in LearnerLevel.values)
              'edition_core_${level.code}_v1',
          ],
          'publishedAt': _publishedAt,
          'status': 'published',
        },
      ],
    },
    courseUnits: courseUnits,
    concepts: concepts,
    seedAuthorities: seedAuthorities,
    contentAuthorities: contentAuthorities,
    assessmentAuthorities: assessmentAuthorities,
  );
}

class _CatalogFixture {
  final Map<String, dynamic> manifest;
  final List<CourseUnit> courseUnits;
  final List<Concept> concepts;
  final List<ContentSeedAuthority> seedAuthorities;
  final List<ContentReferenceAuthority> contentAuthorities;
  final List<SegmentAssessmentAuthority> assessmentAuthorities;

  const _CatalogFixture({
    required this.manifest,
    required this.courseUnits,
    required this.concepts,
    required this.seedAuthorities,
    required this.contentAuthorities,
    required this.assessmentAuthorities,
  });
}

Map<String, dynamic> _text(String value) => {
  'ko': value,
  'de': '$value DE',
  'en': '$value EN',
};

Map<String, dynamic> _segment(Map<String, dynamic> manifest, String id) =>
    (manifest['segments'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .firstWhere((segment) => segment['id'] == id);

Map<String, dynamic> _requirement(
  Map<String, dynamic> manifest,
  String segmentId,
) => (_segment(manifest, segmentId)['assessmentRequirements'] as List<Object?>)
    .cast<Map<String, dynamic>>()
    .single;

Map<String, dynamic> _cluster(Map<String, dynamic> manifest, String id) =>
    (manifest['contentClusters'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .firstWhere((cluster) => cluster['id'] == id);

Map<String, dynamic> _edition(Map<String, dynamic> manifest, String id) =>
    (manifest['trackEditions'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .firstWhere((edition) => edition['id'] == id);

Map<String, dynamic> _track(Map<String, dynamic> manifest, String id) =>
    (manifest['releaseTracks'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .firstWhere((track) => track['id'] == id);

T _deepCopy<T>(T value) => jsonDecode(jsonEncode(value)) as T;

Matcher _throwsFormatContaining(String fragment) => throwsA(
  isA<FormatException>().having(
    (error) => error.message,
    'message',
    contains(fragment),
  ),
);
