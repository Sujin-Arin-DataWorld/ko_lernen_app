import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/can_do_segment.dart';
import '../models/learner_level.dart';
import 'course_segment_catalog.dart';
import 'curriculum_catalog.dart';
import 'productive_assessment_service.dart';

/// The two catalogs whose exact join makes segment mastery executable.
final class CanonicalCourseSegmentBundle {
  const CanonicalCourseSegmentBundle({
    required this.segments,
    required this.productiveAssessments,
    required this.inheritedContentRoutesByKey,
  });

  final CourseSegmentCatalog segments;
  final ProductiveAssessmentCatalog productiveAssessments;

  /// Exact practice-only lineage. It is not mastery or assessment authority.
  final Map<String, InheritedContentRoute> inheritedContentRoutesByKey;

  InheritedContentRoute? inheritedRouteFor(ContentReference child) =>
      inheritedContentRoutesByKey[child.key];
}

/// Immutable runtime route from a derived practice child to reviewed vocab.
final class InheritedContentRoute {
  const InheritedContentRoute({
    required this.child,
    required this.source,
    required this.sourceVocabId,
    required this.sourceVocabFingerprintSha256,
    required this.level,
    required this.canDoSegmentId,
    required this.courseUnitId,
  });

  final ContentReference child;
  final ContentReference source;
  final String sourceVocabId;
  final String sourceVocabFingerprintSha256;
  final LearnerLevel level;
  final String canDoSegmentId;
  final String courseUnitId;
}

/// Loads the immutable 86-segment core with independent content authorities.
final class CanonicalCourseSegmentLoader {
  static const String segmentAssetPath = 'assets/data/can_do_segments.json';
  static const String contentAuthorityAssetPath =
      'assets/data/can_do_content_authorities.json';
  static const String vocabAssetPath = 'assets/data/korean_vocab.csv';
  static const int supportedAuthoritySchemaVersion = 1;

  const CanonicalCourseSegmentLoader._();

  static Future<CanonicalCourseSegmentBundle> load({
    AssetBundle? bundle,
    CurriculumCatalog? curriculumCatalog,
    ProductiveAssessmentCatalog? productiveAssessmentCatalog,
  }) async {
    if (productiveAssessmentCatalog == null) {
      throw StateError(
        'Approved productive assessment content must be injected before '
        'loading the canonical segment bundle.',
      );
    }
    final assets = bundle ?? rootBundle;
    final curriculum = curriculumCatalog ?? await CurriculumCatalog.load();
    final rawSegments = await assets.loadString(segmentAssetPath);
    final rawAuthorities = await assets.loadString(contentAuthorityAssetPath);
    final rawVocab = await assets.loadString(vocabAssetPath);
    return fromJson(
      segmentJson: _jsonObject(rawSegments, segmentAssetPath),
      contentAuthorityJson: _jsonObject(
        rawAuthorities,
        contentAuthorityAssetPath,
      ),
      curriculumCatalog: curriculum,
      productiveAssessmentCatalog: productiveAssessmentCatalog,
      sourceVocabFingerprintsById: _vocabFingerprints(rawVocab),
    );
  }

  static CanonicalCourseSegmentBundle fromJson({
    required Map<String, dynamic> segmentJson,
    required Map<String, dynamic> contentAuthorityJson,
    required CurriculumCatalog curriculumCatalog,
    required ProductiveAssessmentCatalog productiveAssessmentCatalog,
    required Map<String, String> sourceVocabFingerprintsById,
  }) {
    final authority = _ContentAuthorityAsset.fromJson(contentAuthorityJson);
    final catalog = CourseSegmentCatalog.fromJson(
      segmentJson,
      courseUnits: curriculumCatalog.courseUnits,
      concepts: curriculumCatalog.concepts,
      seedAuthorities: authority.seeds,
      contentAuthorities: authority.references,
      assessmentAuthorities: productiveAssessmentCatalog.authorities,
    );
    _requireExactContentCoverage(
      catalog,
      authority,
      sourceVocabFingerprintsById,
    );
    productiveAssessmentCatalog.bind(catalog);
    final inheritedRoutes = Map<String, InheritedContentRoute>.unmodifiable({
      for (final route in authority.coverage.inherited) route.child.key: route,
    });
    return CanonicalCourseSegmentBundle(
      segments: catalog,
      productiveAssessments: productiveAssessmentCatalog,
      inheritedContentRoutesByKey: inheritedRoutes,
    );
  }

  static void _requireExactContentCoverage(
    CourseSegmentCatalog catalog,
    _ContentAuthorityAsset authority,
    Map<String, String> sourceVocabFingerprintsById,
  ) {
    final expectedSeedIds = <String>{
      for (final cluster in catalog.contentClusters) ...cluster.sourceSeedIds,
    };
    final authoritySeedIds = authority.seeds.map((seed) => seed.id).toSet();
    if (!_sameSet(expectedSeedIds, authoritySeedIds)) {
      throw const FormatException(
        'Content seed authorities must exactly cover canonical clusters.',
      );
    }
    final expectedReferenceKeys = <String>{
      for (final cluster in catalog.contentClusters)
        for (final reference in cluster.contentReferences) reference.key,
    };
    final authorityReferenceKeys = authority.references
        .map((item) => item.reference.key)
        .toSet();
    if (!_sameSet(expectedReferenceKeys, authorityReferenceKeys)) {
      throw const FormatException(
        'Content reference authorities must exactly cover canonical clusters.',
      );
    }
    _validateCoverageAudit(catalog, authority, sourceVocabFingerprintsById);
  }

  static void _validateCoverageAudit(
    CourseSegmentCatalog catalog,
    _ContentAuthorityAsset authority,
    Map<String, String> sourceVocabFingerprintsById,
  ) {
    final directCounts = <ContentReferenceKind, int>{
      for (final kind in ContentReferenceKind.values) kind: 0,
    };
    final directByKey = <String, ContentReferenceAuthority>{};
    for (final item in authority.references) {
      directCounts[item.reference.kind] =
          directCounts[item.reference.kind]! + 1;
      directByKey[item.reference.key] = item;
    }
    if (!_sameCountMap(directCounts, authority.coverage.directCounts)) {
      throw const FormatException(
        r'$.coverage.directReferenceCounts does not match contentReferences.',
      );
    }

    final inheritedCounts = <ContentReferenceKind, int>{
      ContentReferenceKind.cloze: 0,
      ContentReferenceKind.satz: 0,
    };
    for (final inherited in authority.coverage.inherited) {
      if (directByKey.containsKey(inherited.child.key)) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: child is also direct: '
          '${inherited.child.key}',
        );
      }
      inheritedCounts[inherited.child.kind] =
          inheritedCounts[inherited.child.kind]! + 1;
      final sourceAuthority = directByKey[inherited.source.key];
      if (sourceAuthority == null ||
          inherited.source.kind != ContentReferenceKind.vocabPack) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: unknown vocab-pack source '
          '${inherited.source.key}',
        );
      }
      if (sourceAuthority.level != inherited.level ||
          sourceAuthority.courseUnitId != inherited.courseUnitId) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: source authority mismatch '
          'for ${inherited.child.key}',
        );
      }
      if (sourceVocabFingerprintsById[inherited.sourceVocabId] !=
          inherited.sourceVocabFingerprintSha256) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: source vocab fingerprint '
          'mismatch for ${inherited.child.key}',
        );
      }
      final segment = catalog.findSegment(inherited.canDoSegmentId);
      if (segment == null ||
          segment.level != inherited.level ||
          segment.parentCourseUnitId != inherited.courseUnitId) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: segment ownership mismatch '
          'for ${inherited.child.key}',
        );
      }
      final ownsSource = segment.contentClusterIds.any((clusterId) {
        final cluster = catalog.findContentCluster(clusterId)!;
        return cluster.contentReferences.any(
          (reference) => reference.key == inherited.source.key,
        );
      });
      if (!ownsSource) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: segment does not own source '
          'for ${inherited.child.key}',
        );
      }
    }
    if (!_sameCountMap(inheritedCounts, authority.coverage.inheritedCounts)) {
      throw const FormatException(
        r'$.coverage.inheritedReferenceCounts does not match lineage rows.',
      );
    }

    final inheritedKeys = authority.coverage.inherited
        .map((item) => item.child.key)
        .toSet();
    for (final childId in authority.coverage.directOverrideChildIds) {
      final key = '${ContentReferenceKind.cloze.code}:$childId';
      if (!directByKey.containsKey(key) || inheritedKeys.contains(key)) {
        throw FormatException(
          r'$.coverage.directOverrideChildIds: invalid direct override '
          '"$childId"',
        );
      }
    }
    final directAbClozeCount = authority.references.where((item) {
      return item.reference.kind == ContentReferenceKind.cloze &&
          item.level.rank <= LearnerLevel.b2.rank;
    }).length;
    if (authority.coverage.explicitNonDerivedClozeCount !=
        directAbClozeCount - authority.coverage.directOverrideChildIds.length) {
      throw const FormatException(
        r'$.coverage.explicitNonDerivedClozeCount does not match direct '
        'A1-B2 Cloze lineage.',
      );
    }
    _validateSmalltalkRoutingAudit(catalog, authority, directByKey);
  }

  static void _validateSmalltalkRoutingAudit(
    CourseSegmentCatalog catalog,
    _ContentAuthorityAsset authority,
    Map<String, ContentReferenceAuthority> directByKey,
  ) {
    final audit = authority.coverage.smalltalkAudit;
    if (audit.unresolvedAmbiguousIds.isNotEmpty) {
      throw const FormatException(
        r'$.coverage.smalltalkRoutingAudit has unresolved ambiguous IDs.',
      );
    }
    final partitions = <Set<String>>[
      audit.exactRouteOverrideIds,
      audit.categoryFallbackIds,
      audit.courseUnitFallbackIds,
    ];
    final seen = <String>{};
    for (final partition in partitions) {
      for (final id in partition) {
        if (!seen.add(id)) {
          throw FormatException(
            r'$.coverage.smalltalkRoutingAudit: duplicate routed ID "$id"',
          );
        }
      }
    }
    final expected = authority.references
        .where(
          (item) =>
              item.reference.kind == ContentReferenceKind.smalltalk &&
              item.level.rank <= LearnerLevel.b2.rank,
        )
        .map((item) => item.reference.id)
        .toSet();
    if (!_sameSet(seen, expected)) {
      throw const FormatException(
        r'$.coverage.smalltalkRoutingAudit does not partition A1-B2 phrases.',
      );
    }
    final decisionIds = audit.phraseDecisions
        .map((item) => item.phraseId)
        .toSet();
    if (!_sameSet(decisionIds, expected)) {
      throw const FormatException(
        r'$.coverage.smalltalkRoutingAudit.phraseDecisions does not cover '
        'A1-B2 phrases.',
      );
    }
    for (final decision in audit.phraseDecisions) {
      final expectedSource =
          audit.exactRouteOverrideIds.contains(decision.phraseId)
          ? 'exactOverride'
          : audit.categoryFallbackIds.contains(decision.phraseId)
          ? 'categoryFallback'
          : 'courseUnitFallback';
      if (decision.routingSource != expectedSource) {
        throw FormatException(
          r'$.coverage.smalltalkRoutingAudit.phraseDecisions: routing source '
          'mismatch for "${decision.phraseId}"',
        );
      }
      final authorityItem = directByKey['smalltalk:${decision.phraseId}'];
      final segment = catalog.findSegment(decision.canDoSegmentId);
      if (authorityItem == null ||
          segment == null ||
          authorityItem.courseUnitId != segment.parentCourseUnitId ||
          decision.canDoFingerprintSha256 != _segmentFingerprint(segment)) {
        throw FormatException(
          r'$.coverage.smalltalkRoutingAudit.phraseDecisions: target mismatch '
          'for "${decision.phraseId}"',
        );
      }
      final ownsPhrase = segment.contentClusterIds.any((clusterId) {
        return catalog
            .findContentCluster(clusterId)!
            .contentReferences
            .any(
              (reference) =>
                  reference.kind == ContentReferenceKind.smalltalk &&
                  reference.id == decision.phraseId,
            );
      });
      if (!ownsPhrase) {
        throw FormatException(
          r'$.coverage.smalltalkRoutingAudit.phraseDecisions: segment does not '
          'own "${decision.phraseId}"',
        );
      }
    }
    for (final override in audit.legacyCourseUnitOverrides) {
      if (!audit.exactRouteOverrideIds.contains(override.id) ||
          override.legacyCourseUnitId == override.courseUnitId) {
        throw FormatException(
          r'$.coverage.smalltalkRoutingAudit.legacyCourseUnitOverrides: '
          'invalid override "${override.id}"',
        );
      }
      final authorityItem = directByKey['smalltalk:${override.id}'];
      final segment = catalog.findSegment(override.canDoSegmentId);
      if (authorityItem == null ||
          segment == null ||
          authorityItem.courseUnitId != override.courseUnitId ||
          segment.parentCourseUnitId != override.courseUnitId) {
        throw FormatException(
          r'$.coverage.smalltalkRoutingAudit.legacyCourseUnitOverrides: '
          'target mismatch for "${override.id}"',
        );
      }
    }
  }
}

final class _ContentAuthorityAsset {
  _ContentAuthorityAsset({
    required this.seeds,
    required this.references,
    required this.coverage,
  });

  factory _ContentAuthorityAsset.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      required: const {
        'schemaVersion',
        'sourceSeeds',
        'contentReferences',
        'coverage',
      },
      path: r'$',
    );
    if (json['schemaVersion'] !=
        CanonicalCourseSegmentLoader.supportedAuthoritySchemaVersion) {
      throw FormatException(
        r'$.schemaVersion: unsupported content authority schema '
        '${json['schemaVersion']}',
      );
    }
    final rawSeeds = _list(json['sourceSeeds'], r'$.sourceSeeds');
    final rawReferences = _list(
      json['contentReferences'],
      r'$.contentReferences',
    );
    final seedIds = <String>{};
    final referenceKeys = <String>{};
    final seeds = <ContentSeedAuthority>[];
    final references = <ContentReferenceAuthority>[];
    for (var index = 0; index < rawSeeds.length; index++) {
      final path =
          r'$.sourceSeeds'
          '[$index]';
      final row = _map(rawSeeds[index], path);
      _requireKeys(row, required: const {'id', 'level'}, path: path);
      final id = _id(row['id'], '$path.id');
      if (!seedIds.add(id)) {
        throw FormatException('$path.id: duplicate source seed "$id"');
      }
      seeds.add(
        ContentSeedAuthority(
          id: id,
          level: _level(row['level'], '$path.level'),
        ),
      );
    }
    for (var index = 0; index < rawReferences.length; index++) {
      final path =
          r'$.contentReferences'
          '[$index]';
      final row = _map(rawReferences[index], path);
      _requireKeys(
        row,
        required: const {'kind', 'id', 'level', 'sourceSeedId', 'courseUnitId'},
        path: path,
      );
      final rawKind = _string(row['kind'], '$path.kind');
      final kind = ContentReferenceKindX.tryFromCode(rawKind);
      if (kind == null) {
        throw FormatException('$path.kind: unknown content kind "$rawKind"');
      }
      final reference = ContentReference(
        kind: kind,
        id: _id(row['id'], '$path.id'),
      );
      if (!referenceKeys.add(reference.key)) {
        throw FormatException(
          '$path: duplicate content authority "${reference.key}"',
        );
      }
      references.add(
        ContentReferenceAuthority(
          reference: reference,
          level: _level(row['level'], '$path.level'),
          sourceSeedId: _id(row['sourceSeedId'], '$path.sourceSeedId'),
          courseUnitId: _id(row['courseUnitId'], '$path.courseUnitId'),
        ),
      );
    }
    return _ContentAuthorityAsset(
      seeds: List.unmodifiable(seeds),
      references: List.unmodifiable(references),
      coverage: _ContentCoverage.fromJson(
        _map(json['coverage'], r'$.coverage'),
      ),
    );
  }

  final List<ContentSeedAuthority> seeds;
  final List<ContentReferenceAuthority> references;
  final _ContentCoverage coverage;
}

final class _ContentCoverage {
  _ContentCoverage({
    required this.directCounts,
    required this.inheritedCounts,
    required this.inherited,
    required this.explicitNonDerivedClozeCount,
    required this.directOverrideChildIds,
    required this.smalltalkAudit,
  });

  factory _ContentCoverage.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      required: const {
        'directReferenceCounts',
        'inheritedReferenceCounts',
        'inheritedContentReferences',
        'inheritanceRules',
        'explicitNonDerivedClozeCount',
        'directOverrideChildIds',
        'smalltalkRoutingAudit',
        'uncoveredSourceIds',
      },
      path: r'$.coverage',
    );
    final uncovered = _stringSet(
      json['uncoveredSourceIds'],
      r'$.coverage.uncoveredSourceIds',
    );
    if (uncovered.isNotEmpty) {
      throw const FormatException(
        r'$.coverage.uncoveredSourceIds must be empty.',
      );
    }
    _validateInheritanceRules(json['inheritanceRules']);

    final rawInherited = _list(
      json['inheritedContentReferences'],
      r'$.coverage.inheritedContentReferences',
    );
    final inherited = <InheritedContentRoute>[];
    final childKeys = <String>{};
    for (var index = 0; index < rawInherited.length; index++) {
      final item = _inheritedContentRouteFromJson(
        _map(
          rawInherited[index],
          r'$.coverage.inheritedContentReferences'
          '[$index]',
        ),
        r'$.coverage.inheritedContentReferences'
        '[$index]',
      );
      if (!childKeys.add(item.child.key)) {
        throw FormatException(
          r'$.coverage.inheritedContentReferences: duplicate child '
          '"${item.child.key}"',
        );
      }
      inherited.add(item);
    }

    return _ContentCoverage(
      directCounts: _countMap(
        json['directReferenceCounts'],
        r'$.coverage.directReferenceCounts',
        ContentReferenceKind.values.toSet(),
      ),
      inheritedCounts: _countMap(
        json['inheritedReferenceCounts'],
        r'$.coverage.inheritedReferenceCounts',
        const {ContentReferenceKind.cloze, ContentReferenceKind.satz},
      ),
      inherited: List.unmodifiable(inherited),
      explicitNonDerivedClozeCount: _nonNegativeInt(
        json['explicitNonDerivedClozeCount'],
        r'$.coverage.explicitNonDerivedClozeCount',
      ),
      directOverrideChildIds: _idSet(
        json['directOverrideChildIds'],
        r'$.coverage.directOverrideChildIds',
      ),
      smalltalkAudit: _SmalltalkRoutingAudit.fromJson(
        _map(
          json['smalltalkRoutingAudit'],
          r'$.coverage.smalltalkRoutingAudit',
        ),
      ),
    );
  }

  final Map<ContentReferenceKind, int> directCounts;
  final Map<ContentReferenceKind, int> inheritedCounts;
  final List<InheritedContentRoute> inherited;
  final int explicitNonDerivedClozeCount;
  final Set<String> directOverrideChildIds;
  final _SmalltalkRoutingAudit smalltalkAudit;
}

InheritedContentRoute _inheritedContentRouteFromJson(
  Map<String, dynamic> json,
  String path,
) {
  _requireKeys(
    json,
    required: const {
      'kind',
      'id',
      'sourceKind',
      'sourceId',
      'sourceVocabId',
      'sourceVocabFingerprintSha256',
      'level',
      'canDoSegmentId',
      'courseUnitId',
    },
    path: path,
  );
  final childKind = _contentKind(json['kind'], '$path.kind');
  if (childKind != ContentReferenceKind.cloze &&
      childKind != ContentReferenceKind.satz) {
    throw FormatException('$path.kind: only cloze and satz may inherit');
  }
  final sourceKind = _contentKind(json['sourceKind'], '$path.sourceKind');
  if (sourceKind != ContentReferenceKind.vocabPack) {
    throw FormatException('$path.sourceKind: must be vocabPack');
  }
  return InheritedContentRoute(
    child: ContentReference(kind: childKind, id: _id(json['id'], '$path.id')),
    source: ContentReference(
      kind: sourceKind,
      id: _id(json['sourceId'], '$path.sourceId'),
    ),
    sourceVocabId: _id(json['sourceVocabId'], '$path.sourceVocabId'),
    sourceVocabFingerprintSha256: _sha256(
      json['sourceVocabFingerprintSha256'],
      '$path.sourceVocabFingerprintSha256',
    ),
    level: _level(json['level'], '$path.level'),
    canDoSegmentId: _id(json['canDoSegmentId'], '$path.canDoSegmentId'),
    courseUnitId: _id(json['courseUnitId'], '$path.courseUnitId'),
  );
}

final class _SmalltalkRoutingAudit {
  _SmalltalkRoutingAudit({
    required this.exactRouteOverrideIds,
    required this.categoryFallbackIds,
    required this.courseUnitFallbackIds,
    required this.legacyCourseUnitOverrides,
    required this.phraseDecisions,
    required this.unresolvedAmbiguousIds,
  });

  factory _SmalltalkRoutingAudit.fromJson(Map<String, dynamic> json) {
    const path = r'$.coverage.smalltalkRoutingAudit';
    _requireKeys(
      json,
      required: const {
        'exactRouteOverrideIds',
        'categoryFallbackIds',
        'courseUnitFallbackIds',
        'legacyCourseUnitOverrides',
        'phraseDecisions',
        'unresolvedAmbiguousIds',
      },
      path: path,
    );
    final rawOverrides = _list(
      json['legacyCourseUnitOverrides'],
      '$path.legacyCourseUnitOverrides',
    );
    final overrides = <_LegacySmalltalkUnitOverride>[];
    final overrideIds = <String>{};
    for (var index = 0; index < rawOverrides.length; index++) {
      final itemPath = '$path.legacyCourseUnitOverrides[$index]';
      final item = _LegacySmalltalkUnitOverride.fromJson(
        _map(rawOverrides[index], itemPath),
        itemPath,
      );
      if (!overrideIds.add(item.id)) {
        throw FormatException('$itemPath.id: duplicate override "${item.id}"');
      }
      overrides.add(item);
    }
    final rawDecisions = _list(
      json['phraseDecisions'],
      '$path.phraseDecisions',
    );
    final decisions = <_SmalltalkPhraseDecision>[];
    final decisionIds = <String>{};
    for (var index = 0; index < rawDecisions.length; index++) {
      final itemPath = '$path.phraseDecisions[$index]';
      final item = _SmalltalkPhraseDecision.fromJson(
        _map(rawDecisions[index], itemPath),
        itemPath,
      );
      if (!decisionIds.add(item.phraseId)) {
        throw FormatException(
          '$itemPath.phraseId: duplicate decision "${item.phraseId}"',
        );
      }
      decisions.add(item);
    }
    return _SmalltalkRoutingAudit(
      exactRouteOverrideIds: _idSet(
        json['exactRouteOverrideIds'],
        '$path.exactRouteOverrideIds',
      ),
      categoryFallbackIds: _idSet(
        json['categoryFallbackIds'],
        '$path.categoryFallbackIds',
      ),
      courseUnitFallbackIds: _idSet(
        json['courseUnitFallbackIds'],
        '$path.courseUnitFallbackIds',
      ),
      legacyCourseUnitOverrides: List.unmodifiable(overrides),
      phraseDecisions: List.unmodifiable(decisions),
      unresolvedAmbiguousIds: _idSet(
        json['unresolvedAmbiguousIds'],
        '$path.unresolvedAmbiguousIds',
      ),
    );
  }

  final Set<String> exactRouteOverrideIds;
  final Set<String> categoryFallbackIds;
  final Set<String> courseUnitFallbackIds;
  final List<_LegacySmalltalkUnitOverride> legacyCourseUnitOverrides;
  final List<_SmalltalkPhraseDecision> phraseDecisions;
  final Set<String> unresolvedAmbiguousIds;
}

final class _SmalltalkPhraseDecision {
  const _SmalltalkPhraseDecision({
    required this.phraseId,
    required this.phraseFingerprintSha256,
    required this.routingSource,
    required this.canDoSegmentId,
    required this.canDoFingerprintSha256,
    required this.semanticStatus,
    required this.reasonCode,
    required this.reviewRevision,
  });

  factory _SmalltalkPhraseDecision.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    _requireKeys(
      json,
      required: const {
        'phraseId',
        'phraseFingerprintSha256',
        'routingSource',
        'canDoSegmentId',
        'canDoFingerprintSha256',
        'semanticStatus',
        'reasonCode',
        'reviewRevision',
      },
      path: path,
    );
    final routingSource = _string(json['routingSource'], '$path.routingSource');
    if (!const {
      'exactOverride',
      'categoryFallback',
      'courseUnitFallback',
    }.contains(routingSource)) {
      throw FormatException('$path.routingSource: unsupported source');
    }
    final semanticStatus = _string(
      json['semanticStatus'],
      '$path.semanticStatus',
    );
    if (!const {
      'approved',
      'bestAvailable',
      'exactMapped',
    }.contains(semanticStatus)) {
      throw FormatException(
        '$path.semanticStatus: unsupported semantic review status',
      );
    }
    final reasonCode = _string(json['reasonCode'], '$path.reasonCode');
    final expectedReason = switch (semanticStatus) {
      'approved' => 'topicAndFunctionMatch',
      'bestAvailable' => 'closestPublishedCoreSegment',
      _ => 'explicitSemanticRoute',
    };
    if (reasonCode != expectedReason) {
      throw FormatException('$path.reasonCode: does not match semantic status');
    }
    return _SmalltalkPhraseDecision(
      phraseId: _id(json['phraseId'], '$path.phraseId'),
      phraseFingerprintSha256: _sha256(
        json['phraseFingerprintSha256'],
        '$path.phraseFingerprintSha256',
      ),
      routingSource: routingSource,
      canDoSegmentId: _id(json['canDoSegmentId'], '$path.canDoSegmentId'),
      canDoFingerprintSha256: _sha256(
        json['canDoFingerprintSha256'],
        '$path.canDoFingerprintSha256',
      ),
      semanticStatus: semanticStatus,
      reasonCode: reasonCode,
      reviewRevision: _positiveInt(
        json['reviewRevision'],
        '$path.reviewRevision',
      ),
    );
  }

  final String phraseId;
  final String phraseFingerprintSha256;
  final String routingSource;
  final String canDoSegmentId;
  final String canDoFingerprintSha256;
  final String semanticStatus;
  final String reasonCode;
  final int reviewRevision;
}

final class _LegacySmalltalkUnitOverride {
  const _LegacySmalltalkUnitOverride({
    required this.id,
    required this.legacyCourseUnitId,
    required this.courseUnitId,
    required this.canDoSegmentId,
  });

  factory _LegacySmalltalkUnitOverride.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    _requireKeys(
      json,
      required: const {
        'id',
        'legacyCourseUnitId',
        'courseUnitId',
        'canDoSegmentId',
      },
      path: path,
    );
    return _LegacySmalltalkUnitOverride(
      id: _id(json['id'], '$path.id'),
      legacyCourseUnitId: _id(
        json['legacyCourseUnitId'],
        '$path.legacyCourseUnitId',
      ),
      courseUnitId: _id(json['courseUnitId'], '$path.courseUnitId'),
      canDoSegmentId: _id(json['canDoSegmentId'], '$path.canDoSegmentId'),
    );
  }

  final String id;
  final String legacyCourseUnitId;
  final String courseUnitId;
  final String canDoSegmentId;
}

Map<String, dynamic> _jsonObject(String raw, String path) {
  final decoded = jsonDecode(raw);
  return _map(decoded, path);
}

Map<String, dynamic> _map(Object? raw, String path) {
  if (raw is! Map) {
    throw FormatException('$path: must be an object');
  }
  return raw.map((key, value) {
    if (key is! String) {
      throw FormatException('$path: keys must be strings');
    }
    return MapEntry(key, value);
  });
}

List<Object?> _list(Object? raw, String path) {
  if (raw is! List) {
    throw FormatException('$path: must be an array');
  }
  return List<Object?>.from(raw);
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_.-]*$');

String _id(Object? raw, String path) {
  final value = _string(raw, path);
  if (!_idPattern.hasMatch(value)) {
    throw FormatException('$path: must match [a-z0-9][a-z0-9_.-]*');
  }
  return value;
}

String _string(Object? raw, String path) {
  if (raw is! String || raw.isEmpty || raw.trim() != raw) {
    throw FormatException('$path: must be a nonempty, trimmed string');
  }
  return raw;
}

LearnerLevel _level(Object? raw, String path) {
  final code = _string(raw, path);
  final level = LearnerLevel.fromCode(code);
  if (level == null || level.code != code) {
    throw FormatException('$path: unknown learner level "$code"');
  }
  return level;
}

ContentReferenceKind _contentKind(Object? raw, String path) {
  final code = _string(raw, path);
  final kind = ContentReferenceKindX.tryFromCode(code);
  if (kind == null || kind.code != code) {
    throw FormatException('$path: unknown content kind "$code"');
  }
  return kind;
}

int _nonNegativeInt(Object? raw, String path) {
  if (raw is! int || raw < 0) {
    throw FormatException('$path: must be a non-negative integer');
  }
  return raw;
}

int _positiveInt(Object? raw, String path) {
  final value = _nonNegativeInt(raw, path);
  if (value == 0) {
    throw FormatException('$path: must be positive');
  }
  return value;
}

final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

String _sha256(Object? raw, String path) {
  final value = _string(raw, path);
  if (!_sha256Pattern.hasMatch(value)) {
    throw FormatException('$path: must be a lowercase SHA-256 digest');
  }
  return value;
}

String _segmentFingerprint(CanDoSegment segment) {
  final payload = <String, dynamic>{
    'canDo': <String, String>{
      'de': segment.canDo.de,
      'en': segment.canDo.en,
      'ko': segment.canDo.ko,
    },
    'title': <String, String>{
      'de': segment.title.de,
      'en': segment.title.en,
      'ko': segment.title.ko,
    },
  };
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

Map<String, String> _vocabFingerprints(String raw) {
  final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(normalized);
  if (table.length < 2) {
    throw const FormatException('korean_vocab.csv must contain data rows.');
  }
  final headers = table.first
      .map((value) => value.toString())
      .toList(growable: false);
  if (headers.isNotEmpty) {
    headers[0] = headers[0].replaceFirst('\uFEFF', '');
  }
  final idIndex = headers.indexOf('id');
  if (idIndex < 0) {
    throw const FormatException('korean_vocab.csv must contain an id column.');
  }
  final result = <String, String>{};
  for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
    final values = table[rowIndex];
    if (values.every((value) => value.toString().isEmpty)) {
      continue;
    }
    if (values.length != headers.length) {
      throw FormatException(
        'korean_vocab.csv row ${rowIndex + 1} has the wrong column count.',
      );
    }
    final row = <String, String>{
      for (var index = 0; index < headers.length; index++)
        headers[index]: values[index].toString(),
    };
    final id = row[headers[idIndex]]!;
    if (id.isEmpty || result.containsKey(id)) {
      throw FormatException(
        'korean_vocab.csv row ${rowIndex + 1} has an invalid duplicate ID.',
      );
    }
    result[id] = _jsonFingerprint(row);
  }
  return Map.unmodifiable(result);
}

String _jsonFingerprint(Object? value) {
  final canonical = jsonEncode(_canonicalizeJson(value));
  return sha256.convert(utf8.encode(canonical)).toString();
}

Object? _canonicalizeJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalizeJson(value[key]),
    };
  }
  if (value is List) {
    return [for (final item in value) _canonicalizeJson(item)];
  }
  return value;
}

Set<String> _idSet(Object? raw, String path) {
  final result = <String>{};
  final items = _list(raw, path);
  for (var index = 0; index < items.length; index++) {
    final id = _id(items[index], '$path[$index]');
    if (!result.add(id)) {
      throw FormatException('$path[$index]: duplicate ID "$id"');
    }
  }
  return Set.unmodifiable(result);
}

Set<String> _stringSet(Object? raw, String path) {
  final result = <String>{};
  final items = _list(raw, path);
  for (var index = 0; index < items.length; index++) {
    final value = _string(items[index], '$path[$index]');
    if (!result.add(value)) {
      throw FormatException('$path[$index]: duplicate value "$value"');
    }
  }
  return Set.unmodifiable(result);
}

Map<ContentReferenceKind, int> _countMap(
  Object? raw,
  String path,
  Set<ContentReferenceKind> expectedKinds,
) {
  final json = _map(raw, path);
  _requireKeys(
    json,
    required: {for (final kind in expectedKinds) kind.code},
    path: path,
  );
  return Map.unmodifiable({
    for (final kind in expectedKinds)
      kind: _nonNegativeInt(json[kind.code], '$path.${kind.code}'),
  });
}

void _validateInheritanceRules(Object? raw) {
  const path = r'$.coverage.inheritanceRules';
  final rules = _list(raw, path);
  if (rules.length != 2) {
    throw const FormatException('$path: must contain exactly two rules');
  }
  final seenChildren = <ContentReferenceKind>{};
  for (var index = 0; index < rules.length; index++) {
    final itemPath = '$path[$index]';
    final row = _map(rules[index], itemPath);
    _requireKeys(
      row,
      required: const {'childKind', 'sourceKind', 'levels', 'join'},
      path: itemPath,
    );
    final child = _contentKind(row['childKind'], '$itemPath.childKind');
    if ((child != ContentReferenceKind.cloze &&
            child != ContentReferenceKind.satz) ||
        !seenChildren.add(child)) {
      throw FormatException('$itemPath.childKind: invalid or duplicate child');
    }
    if (_contentKind(row['sourceKind'], '$itemPath.sourceKind') !=
        ContentReferenceKind.vocabPack) {
      throw FormatException('$itemPath.sourceKind: must be vocabPack');
    }
    final levels = _list(row['levels'], '$itemPath.levels')
        .asMap()
        .entries
        .map((entry) => _level(entry.value, '$itemPath.levels[${entry.key}]'))
        .toList(growable: false);
    const expectedLevels = [
      LearnerLevel.a1,
      LearnerLevel.a2,
      LearnerLevel.b1,
      LearnerLevel.b2,
    ];
    if (levels.length != expectedLevels.length ||
        !levels.asMap().entries.every(
          (entry) => entry.value == expectedLevels[entry.key],
        )) {
      throw FormatException('$itemPath.levels: must be ordered A1-B2');
    }
    final expectedJoin = child == ContentReferenceKind.cloze
        ? 'same_level_unique_pack_example_or_reviewed_vocab_override'
        : 'same_level_exact_example_or_unique_vocab_term_pack';
    if (_string(row['join'], '$itemPath.join') != expectedJoin) {
      throw FormatException('$itemPath.join: unsupported lineage rule');
    }
  }
}

void _requireKeys(
  Map<String, dynamic> map, {
  required Set<String> required,
  required String path,
}) {
  final actual = map.keys.toSet();
  final missing = required.difference(actual).toList()..sort();
  final unknown = actual.difference(required).toList()..sort();
  if (missing.isNotEmpty) {
    throw FormatException('$path: missing keys ${missing.join(', ')}');
  }
  if (unknown.isNotEmpty) {
    throw FormatException('$path: unknown keys ${unknown.join(', ')}');
  }
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameCountMap(
  Map<ContentReferenceKind, int> left,
  Map<ContentReferenceKind, int> right,
) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}
