import 'onboarding_contract_validation.dart';

enum HeritageAvailability { preview, live, completed }

enum HeritageSourceYearBasis { published, updated, accessed }

enum HeritageUseAuthority {
  koglType1,
  citationOnly,
  separatelyApproved,
  unknown,
}

final class HeritageLicenseReference {
  const HeritageLicenseReference({
    required this.authority,
    required this.displayName,
    this.termsUrl,
    this.approvalEvidenceId,
  });

  final HeritageUseAuthority authority;
  final String displayName;
  final Uri? termsUrl;
  final String? approvalEvidenceId;

  ContractValidationResult validate(
    String field, {
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    if (displayName.trim().isEmpty) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_license_name',
          field: field,
          message: 'Every source must state its reuse authority.',
        ),
      );
    }
    if (authority == HeritageUseAuthority.unknown) {
      violations.add(
        ContractViolation(
          code: 'heritage.unknown_license',
          field: field,
          message: 'Unknown reuse authority is not publishable.',
        ),
      );
    }
    if (authority == HeritageUseAuthority.koglType1 &&
        (termsUrl == null || !isSecurePublicUrl(termsUrl!))) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_kogl_terms',
          field: field,
          message: 'KOGL Type 1 reuse must link its official terms.',
        ),
      );
    }
    if (authority == HeritageUseAuthority.separatelyApproved) {
      final evidenceId = approvalEvidenceId?.trim();
      if (evidenceId == null || !isStableSemanticId(evidenceId)) {
        violations.add(
          ContractViolation(
            code: 'heritage.missing_license_approval_evidence',
            field: field,
            message: 'Separately approved reuse requires a stable evidence id.',
          ),
        );
      } else if (!publicationAuthority.resolvesLicenseApproval(evidenceId)) {
        violations.add(
          ContractViolation(
            code: 'heritage.unresolved_license_approval_evidence',
            field: field,
            message:
                'Separately approved reuse must resolve to reviewed evidence.',
          ),
        );
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

final class HeritageSourceReference {
  const HeritageSourceReference({
    required this.institution,
    required this.sourceYear,
    required this.yearBasis,
    required this.title,
    required this.url,
    required this.author,
    required this.license,
    required this.checkedAtIso,
  });

  final String institution;
  final int sourceYear;
  final HeritageSourceYearBasis yearBasis;
  final String title;
  final Uri url;
  final String author;
  final HeritageLicenseReference license;
  final String checkedAtIso;

  ContractValidationResult validate(
    String field, {
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    if (institution.trim().isEmpty ||
        title.trim().isEmpty ||
        author.trim().isEmpty ||
        sourceYear < 1900) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_attribution',
          field: field,
          message: 'Institution, year, title, and author are required.',
        ),
      );
    }
    if (!isSecurePublicUrl(url)) {
      violations.add(
        ContractViolation(
          code: 'heritage.invalid_source_url',
          field: field,
          message: 'Heritage references must use a public HTTPS URL.',
        ),
      );
    }
    if (DateTime.tryParse(checkedAtIso) == null) {
      violations.add(
        ContractViolation(
          code: 'heritage.invalid_checked_at',
          field: field,
          message: 'The source review date must be ISO-8601.',
        ),
      );
    }
    violations.addAll(
      license
          .validate(field, publicationAuthority: publicationAuthority)
          .violations,
    );
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

enum HeritageAssetReviewStatus { none, approved, pendingReview, rejected }

final class HeritageAssetAuthority {
  const HeritageAssetAuthority.none()
    : status = HeritageAssetReviewStatus.none,
      runtimeAssetPath = null,
      authorityVersion = null,
      approvedBy = null,
      approvedAtIso = null;

  const HeritageAssetAuthority({
    required this.status,
    required this.runtimeAssetPath,
    required this.authorityVersion,
    required this.approvedBy,
    required this.approvedAtIso,
  });

  final HeritageAssetReviewStatus status;
  final String? runtimeAssetPath;
  final String? authorityVersion;
  final String? approvedBy;
  final String? approvedAtIso;

  bool get hasRuntimeAsset => runtimeAssetPath?.trim().isNotEmpty ?? false;

  ContractValidationResult validate(
    String field, {
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    final path = runtimeAssetPath?.replaceAll('\\', '/').toLowerCase();
    if (path != null &&
        (path.contains('/pending_review/') ||
            path.startsWith('pending_review/') ||
            path.contains('/pending-review/') ||
            path.contains('/assets_pending/'))) {
      violations.add(
        ContractViolation(
          code: 'heritage.pending_review_asset',
          field: field,
          message: 'Pending-review assets cannot be referenced at runtime.',
        ),
      );
    }
    switch (status) {
      case HeritageAssetReviewStatus.none:
        if (hasRuntimeAsset ||
            authorityVersion != null ||
            approvedBy != null ||
            approvedAtIso != null) {
          violations.add(
            ContractViolation(
              code: 'heritage.none_asset_has_authority_data',
              field: field,
              message: 'An absent asset must not carry approval metadata.',
            ),
          );
        }
      case HeritageAssetReviewStatus.approved:
        if (!hasRuntimeAsset ||
            (authorityVersion?.trim().isEmpty ?? true) ||
            (approvedBy?.trim().isEmpty ?? true) ||
            DateTime.tryParse(approvedAtIso ?? '') == null) {
          violations.add(
            ContractViolation(
              code: 'heritage.incomplete_asset_approval',
              field: field,
              message: 'Runtime assets require versioned approval evidence.',
            ),
          );
        }
        if (hasRuntimeAsset &&
            !publicationAuthority.isBundledAsset(runtimeAssetPath!)) {
          violations.add(
            ContractViolation(
              code: 'heritage.asset_not_bundled',
              field: field,
              message: 'Approved heritage assets must resolve in the bundle.',
            ),
          );
        }
        if (!publicationAuthority.resolvesAssetApproval(this)) {
          violations.add(
            ContractViolation(
              code: 'heritage.unresolved_asset_approval',
              field: field,
              message: 'Runtime asset metadata must match reviewed authority.',
            ),
          );
        }
      case HeritageAssetReviewStatus.pendingReview:
      case HeritageAssetReviewStatus.rejected:
        violations.add(
          ContractViolation(
            code: 'heritage.unapproved_runtime_asset',
            field: field,
            message: 'Only approved or absent assets may enter a descriptor.',
          ),
        );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

enum LearningBeatBindingStatus { unassigned, approved }

final class LearningBeatBinding {
  const LearningBeatBinding.unassigned()
    : status = LearningBeatBindingStatus.unassigned,
      beatMapId = null,
      version = null,
      approvedBy = null,
      approvedAtIso = null;

  const LearningBeatBinding({
    required this.status,
    required this.beatMapId,
    required this.version,
    required this.approvedBy,
    required this.approvedAtIso,
  });

  final LearningBeatBindingStatus status;
  final String? beatMapId;
  final String? version;
  final String? approvedBy;
  final String? approvedAtIso;

  bool get isApproved {
    return status == LearningBeatBindingStatus.approved &&
        (beatMapId?.trim().isNotEmpty ?? false) &&
        (version?.trim().isNotEmpty ?? false) &&
        (approvedBy?.trim().isNotEmpty ?? false) &&
        DateTime.tryParse(approvedAtIso ?? '') != null;
  }

  ContractValidationResult validate(
    String field, {
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    if (status == LearningBeatBindingStatus.unassigned) {
      if (beatMapId != null ||
          version != null ||
          approvedBy != null ||
          approvedAtIso != null) {
        return ContractValidationResult([
          ContractViolation(
            code: 'heritage.unassigned_binding_has_authority_data',
            field: field,
            message: 'An unassigned beat map cannot carry approval metadata.',
          ),
        ]);
      }
      return const ContractValidationResult.valid();
    }
    if (!isApproved) {
      return ContractValidationResult([
        ContractViolation(
          code: 'heritage.incomplete_learning_beat_approval',
          field: field,
          message: 'Approved beat maps require complete versioned evidence.',
        ),
      ]);
    }
    if (!publicationAuthority.resolvesLearningBeatMap(this)) {
      return ContractValidationResult([
        ContractViolation(
          code: 'heritage.unresolved_learning_beat_map',
          field: field,
          message: 'Approved beat-map metadata must resolve to reviewed data.',
        ),
      ]);
    }
    return const ContractValidationResult.valid();
  }
}

final class HeritageAssetApprovalEvidence {
  const HeritageAssetApprovalEvidence({
    required this.runtimeAssetPath,
    required this.authorityVersion,
    required this.approvedBy,
    required this.approvedAtIso,
  });

  final String runtimeAssetPath;
  final String authorityVersion;
  final String approvedBy;
  final String approvedAtIso;

  bool matches(HeritageAssetAuthority candidate) {
    return _normalizedAssetPath(runtimeAssetPath) ==
            _normalizedAssetPath(candidate.runtimeAssetPath ?? '') &&
        authorityVersion == candidate.authorityVersion &&
        approvedBy == candidate.approvedBy &&
        approvedAtIso == candidate.approvedAtIso;
  }
}

final class HeritageLearningBeatMapEvidence {
  const HeritageLearningBeatMapEvidence({
    required this.beatMapId,
    required this.version,
    required this.approvedBy,
    required this.approvedAtIso,
    required this.evidenceBeatIds,
  });

  final String beatMapId;
  final String version;
  final String approvedBy;
  final String approvedAtIso;
  final Set<String> evidenceBeatIds;

  bool matches(LearningBeatBinding candidate) {
    return beatMapId == candidate.beatMapId &&
        version == candidate.version &&
        approvedBy == candidate.approvedBy &&
        approvedAtIso == candidate.approvedAtIso &&
        evidenceBeatIds.isNotEmpty &&
        evidenceBeatIds.every(isStableSemanticId);
  }
}

final class HeritageLicenseApprovalEvidence {
  const HeritageLicenseApprovalEvidence({
    required this.evidenceId,
    required this.evidenceUrl,
    required this.approvedBy,
    required this.approvedAtIso,
  });

  final String evidenceId;
  final Uri evidenceUrl;
  final String approvedBy;
  final String approvedAtIso;

  bool get isVerifiable =>
      isStableSemanticId(evidenceId) &&
      isSecurePublicUrl(evidenceUrl) &&
      approvedBy.trim().isNotEmpty &&
      DateTime.tryParse(approvedAtIso) != null;
}

/// Publication authority is supplied independently from a journey descriptor.
/// Descriptor metadata alone can never make an asset, license, or beat map
/// publishable.
final class HeritagePublicationAuthority {
  const HeritagePublicationAuthority({
    required this.bundledRuntimeAssetPaths,
    required this.assetApprovals,
    required this.learningBeatMaps,
    required this.separatelyApprovedLicenses,
  });

  const HeritagePublicationAuthority.none()
    : bundledRuntimeAssetPaths = const {},
      assetApprovals = const [],
      learningBeatMaps = const [],
      separatelyApprovedLicenses = const [];

  final Set<String> bundledRuntimeAssetPaths;
  final List<HeritageAssetApprovalEvidence> assetApprovals;
  final List<HeritageLearningBeatMapEvidence> learningBeatMaps;
  final List<HeritageLicenseApprovalEvidence> separatelyApprovedLicenses;

  bool isBundledAsset(String path) {
    final normalized = _normalizedAssetPath(path);
    return bundledRuntimeAssetPaths.any(
      (candidate) => _normalizedAssetPath(candidate) == normalized,
    );
  }

  bool resolvesAssetApproval(HeritageAssetAuthority candidate) {
    return assetApprovals.any((approval) => approval.matches(candidate));
  }

  bool resolvesLearningBeatMap(LearningBeatBinding candidate) {
    return learningBeatMaps.any((map) => map.matches(candidate));
  }

  HeritageLearningBeatMapEvidence? beatMapFor(LearningBeatBinding candidate) {
    for (final map in learningBeatMaps) {
      if (map.matches(candidate)) return map;
    }
    return null;
  }

  bool resolvesLicenseApproval(String evidenceId) {
    return separatelyApprovedLicenses.any(
      (approval) => approval.evidenceId == evidenceId && approval.isVerifiable,
    );
  }
}

final class EstateProgressSnapshot {
  const EstateProgressSnapshot({
    required this.completedEvidenceBeatIds,
    required this.decorationInventoryIds,
  });

  const EstateProgressSnapshot.empty()
    : completedEvidenceBeatIds = const {},
      decorationInventoryIds = const {};

  final Set<String> completedEvidenceBeatIds;
  final Set<String> decorationInventoryIds;
}

final class EstateChapter {
  const EstateChapter({
    required this.estateId,
    required this.officialName,
    required this.availability,
    required this.sources,
    required this.assetAuthority,
    required this.learningBeatBinding,
    required this.progress,
    required this.cultureStoryLocalizationKey,
  });

  final String estateId;
  final String officialName;
  final HeritageAvailability availability;
  final List<HeritageSourceReference> sources;
  final HeritageAssetAuthority assetAuthority;
  final LearningBeatBinding learningBeatBinding;
  final EstateProgressSnapshot progress;
  final String cultureStoryLocalizationKey;

  ContractValidationResult validate({
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(estateId)) {
      violations.add(
        ContractViolation(
          code: 'heritage.invalid_estate_id',
          field: estateId,
          message: 'Estate ids must be stable semantic identifiers.',
        ),
      );
    }
    if (officialName.trim().isEmpty) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_official_name',
          field: estateId,
          message: 'An estate needs its official source name.',
        ),
      );
    }
    if (!isDartLocalizationKey(cultureStoryLocalizationKey)) {
      violations.add(
        ContractViolation(
          code: 'heritage.invalid_story_localization_key',
          field: estateId,
          message: 'Cultural story copy must come from localization.',
        ),
      );
    }
    if (sources.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_sources',
          field: estateId,
          message: 'A heritage chapter cannot publish without a source.',
        ),
      );
    }
    for (var index = 0; index < sources.length; index += 1) {
      violations.addAll(
        sources[index]
            .validate(
              '$estateId.sources[$index]',
              publicationAuthority: publicationAuthority,
            )
            .violations,
      );
    }
    violations.addAll(
      assetAuthority
          .validate(
            '$estateId.asset',
            publicationAuthority: publicationAuthority,
          )
          .violations,
    );
    violations.addAll(
      learningBeatBinding
          .validate(
            '$estateId.learningBeatBinding',
            publicationAuthority: publicationAuthority,
          )
          .violations,
    );
    if (availability != HeritageAvailability.preview &&
        assetAuthority.status != HeritageAssetReviewStatus.approved) {
      violations.add(
        ContractViolation(
          code: 'heritage.live_without_approved_asset',
          field: estateId,
          message: 'Live or completed chapters need an approved runtime asset.',
        ),
      );
    }
    if (availability != HeritageAvailability.preview &&
        publicationAuthority.beatMapFor(learningBeatBinding) == null) {
      violations.add(
        ContractViolation(
          code: 'heritage.live_without_approved_binding',
          field: estateId,
          message: 'Live chapters need an approved learning-to-beat mapping.',
        ),
      );
    }
    final resolvedBeatMap = publicationAuthority.beatMapFor(
      learningBeatBinding,
    );
    if (availability != HeritageAvailability.preview &&
        resolvedBeatMap != null &&
        !resolvedBeatMap.evidenceBeatIds.containsAll(
          progress.completedEvidenceBeatIds,
        )) {
      violations.add(
        ContractViolation(
          code: 'heritage.unresolved_progress_beat',
          field: estateId,
          message: 'Completed evidence beats must exist in the approved map.',
        ),
      );
    }
    for (final id in {
      ...progress.completedEvidenceBeatIds,
      ...progress.decorationInventoryIds,
    }) {
      if (!isStableSemanticId(id)) {
        violations.add(
          ContractViolation(
            code: 'heritage.invalid_progress_id',
            field: estateId,
            message: 'Progress and inventory ids must remain semantic.',
          ),
        );
      }
    }
    if (estateId == HeritageJourneyCatalog.ilduGotaekEstateId &&
        (availability != HeritageAvailability.preview ||
            assetAuthority.hasRuntimeAsset)) {
      violations.add(
        ContractViolation(
          code: 'heritage.ildu_preview_only',
          field: estateId,
          message:
              'Ildu Gotaek stays asset-free preview until separately approved.',
        ),
      );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

enum HeritageProgressDisplayUnit {
  previewOnly,
  milestones,
  constructionSteps,
  evidenceBeats,
}

/// One runtime descriptor selects the progress vocabulary shown to users.
final class HeritageJourneyDescriptor {
  const HeritageJourneyDescriptor({
    required this.descriptorVersion,
    required this.displayUnit,
    required this.totalDisplayUnits,
    required this.chapters,
  });

  final String descriptorVersion;
  final HeritageProgressDisplayUnit displayUnit;
  final int? totalDisplayUnits;
  final List<EstateChapter> chapters;

  ContractValidationResult validate({
    HeritagePublicationAuthority publicationAuthority =
        const HeritagePublicationAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(descriptorVersion)) {
      violations.add(
        ContractViolation(
          code: 'heritage.invalid_descriptor_version',
          field: descriptorVersion,
          message: 'Descriptor versions must be semantic and stable.',
        ),
      );
    }
    if (chapters.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'heritage.empty_journey',
          field: descriptorVersion,
          message: 'A journey descriptor needs at least one chapter.',
        ),
      );
    }
    if (displayUnit == HeritageProgressDisplayUnit.previewOnly) {
      if (totalDisplayUnits != null ||
          chapters.any(
            (chapter) => chapter.availability != HeritageAvailability.preview,
          )) {
        violations.add(
          ContractViolation(
            code: 'heritage.preview_progress_mismatch',
            field: descriptorVersion,
            message: 'Preview journeys cannot imply live progress totals.',
          ),
        );
      }
    } else if ((totalDisplayUnits ?? 0) <= 0) {
      violations.add(
        ContractViolation(
          code: 'heritage.missing_progress_total',
          field: descriptorVersion,
          message: 'Live progress vocabulary needs one positive runtime total.',
        ),
      );
    }
    final estateIds = <String>{};
    for (final chapter in chapters) {
      violations.addAll(
        chapter.validate(publicationAuthority: publicationAuthority).violations,
      );
      if (!estateIds.add(chapter.estateId)) {
        violations.add(
          ContractViolation(
            code: 'heritage.duplicate_estate_id',
            field: chapter.estateId,
            message: 'Estate ids must be unique within a journey.',
          ),
        );
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

String _normalizedAssetPath(String value) =>
    value.trim().replaceAll('\\', '/').toLowerCase();

abstract final class HeritageJourneyCatalog {
  static const ilduGotaekEstateId = 'ildu-gotaek';

  static final ilduGotaekPreview = HeritageJourneyDescriptor(
    descriptorVersion: 'ildu-preview-v1',
    displayUnit: HeritageProgressDisplayUnit.previewOnly,
    totalDisplayUnits: null,
    chapters: [
      EstateChapter(
        estateId: ilduGotaekEstateId,
        officialName: '함양 일두고택',
        availability: HeritageAvailability.preview,
        sources: [
          HeritageSourceReference(
            institution: '국가유산청',
            sourceYear: 2026,
            yearBasis: HeritageSourceYearBasis.accessed,
            title: '함양 일두고택 국가유산 상세',
            url: Uri.parse(
              'https://heritage.go.kr/heri/cul/culSelectDetail.do?ccbaAsno=0001860000000&ccbaCpno=1483801860000&ccbaCtcd=38&ccbaKdcd=18&pageNo=1_1_1_0',
            ),
            author: '국가유산청',
            license: const HeritageLicenseReference(
              authority: HeritageUseAuthority.citationOnly,
              displayName: 'Citation only; reuse rights not asserted',
            ),
            checkedAtIso: '2026-08-26',
          ),
          HeritageSourceReference(
            institution: '한국관광공사',
            sourceYear: 2026,
            yearBasis: HeritageSourceYearBasis.accessed,
            title: '함양 일두고택 촬영지 상세',
            url: Uri.parse(
              'https://korean.visitkorea.or.kr/detail/rem_detail.do?cotid=15a9cb58-9217-49d5-b21b-a1457c14918c',
            ),
            author: '한국관광공사',
            license: const HeritageLicenseReference(
              authority: HeritageUseAuthority.citationOnly,
              displayName: 'Citation only; reuse rights not asserted',
            ),
            checkedAtIso: '2026-08-26',
          ),
        ],
        assetAuthority: const HeritageAssetAuthority.none(),
        learningBeatBinding: const LearningBeatBinding.unassigned(),
        progress: const EstateProgressSnapshot.empty(),
        cultureStoryLocalizationKey: 'heritageIlDuGotaekStory',
      ),
    ],
  );
}
