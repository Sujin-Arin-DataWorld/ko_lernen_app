import 'onboarding_contract_validation.dart';

enum CurriculumAuthority { cefr, nikl, topik }

enum CurriculumLanguageDomain { listening, reading, writing, speaking }

enum CurriculumAlignmentStatus { mapped, partial, gap, approved }

enum CurriculumContentKind { courseUnit, scenario, practice }

final class OfficialCurriculumReference {
  const OfficialCurriculumReference({
    required this.authority,
    required this.documentName,
    required this.documentVersion,
    required this.url,
    required this.checkedAtIso,
  });

  final CurriculumAuthority authority;
  final String documentName;
  final String documentVersion;
  final Uri url;
  final String checkedAtIso;

  ContractValidationResult validate(String field) {
    final violations = <ContractViolation>[];
    if (documentName.trim().isEmpty || documentVersion.trim().isEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_official_document',
          field: field,
          message: 'Official document name and version are required.',
        ),
      );
    }
    if (!isSecurePublicUrl(url)) {
      violations.add(
        ContractViolation(
          code: 'curriculum.invalid_official_url',
          field: field,
          message: 'Official curriculum sources must use public HTTPS URLs.',
        ),
      );
    }
    if (DateTime.tryParse(checkedAtIso) == null) {
      violations.add(
        ContractViolation(
          code: 'curriculum.invalid_checked_at',
          field: field,
          message: 'Official source review date must be ISO-8601.',
        ),
      );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

final class CurriculumContentLink {
  const CurriculumContentLink({required this.kind, required this.contentId});

  final CurriculumContentKind kind;
  final String contentId;
}

/// Independent allow-list used when an alignment record is promoted to
/// approved TOPIK evidence.
///
/// A record cannot authorize its own source URL or invent a semantic-looking
/// content id. Both values must resolve against production-owned authority.
final class CurriculumPromotionAuthority {
  const CurriculumPromotionAuthority({
    required this.approvedOfficialUrls,
    required this.productionContentIds,
  });

  const CurriculumPromotionAuthority.none()
    : approvedOfficialUrls = const {},
      productionContentIds = const {};

  final Map<CurriculumAuthority, Set<String>> approvedOfficialUrls;
  final Map<CurriculumContentKind, Set<String>> productionContentIds;

  bool resolvesOfficialReference(OfficialCurriculumReference reference) {
    return approvedOfficialUrls[reference.authority]?.contains(
          reference.url.toString(),
        ) ??
        false;
  }

  bool resolvesContentLink(CurriculumContentLink link) {
    return productionContentIds[link.kind]?.contains(link.contentId) ?? false;
  }
}

final class CurriculumAlignmentRecord {
  const CurriculumAlignmentRecord({
    required this.recordId,
    required this.authority,
    required this.officialReference,
    required this.domains,
    required this.levelOrBand,
    required this.publicTaskTypes,
    required this.contentLinks,
    required this.status,
    this.reviewer,
    this.reviewedAtIso,
  });

  final String recordId;
  final CurriculumAuthority authority;
  final OfficialCurriculumReference officialReference;
  final Set<CurriculumLanguageDomain> domains;
  final String levelOrBand;
  final Set<String> publicTaskTypes;
  final List<CurriculumContentLink> contentLinks;
  final CurriculumAlignmentStatus status;
  final String? reviewer;
  final String? reviewedAtIso;

  ContractValidationResult validate({
    CurriculumPromotionAuthority promotionAuthority =
        const CurriculumPromotionAuthority.none(),
  }) {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(recordId)) {
      violations.add(
        ContractViolation(
          code: 'curriculum.invalid_record_id',
          field: recordId,
          message: 'Alignment records require stable semantic ids.',
        ),
      );
    }
    if (authority != officialReference.authority) {
      violations.add(
        ContractViolation(
          code: 'curriculum.authority_mismatch',
          field: recordId,
          message: 'Record and official source authorities must match.',
        ),
      );
    }
    violations.addAll(officialReference.validate(recordId).violations);
    if (domains.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_domain',
          field: recordId,
          message: 'Every record must identify an assessed language domain.',
        ),
      );
    }
    if (levelOrBand.trim().isEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_band',
          field: recordId,
          message: 'Every record must identify its level or band.',
        ),
      );
    }
    if (authority == CurriculumAuthority.topik &&
        status != CurriculumAlignmentStatus.gap &&
        publicTaskTypes.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_topik_task_type',
          field: recordId,
          message: 'TOPIK records must name the public item or task type.',
        ),
      );
    }
    for (final taskType in publicTaskTypes) {
      if (taskType.trim().isEmpty) {
        violations.add(
          ContractViolation(
            code: 'curriculum.empty_task_type',
            field: recordId,
            message: 'Public task types cannot be empty.',
          ),
        );
      }
    }
    for (final link in contentLinks) {
      if (!isStableSemanticId(link.contentId)) {
        violations.add(
          ContractViolation(
            code: 'curriculum.invalid_content_id',
            field: recordId,
            message: 'Linked course evidence needs a semantic id.',
          ),
        );
      }
    }
    if (status == CurriculumAlignmentStatus.gap && contentLinks.isNotEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.gap_has_evidence',
          field: recordId,
          message: 'A gap cannot simultaneously claim linked evidence.',
        ),
      );
    }
    if (status != CurriculumAlignmentStatus.gap && contentLinks.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_content_evidence',
          field: recordId,
          message: 'Mapped records require at least one content link.',
        ),
      );
    }
    if (status == CurriculumAlignmentStatus.approved &&
        ((reviewer?.trim().isEmpty ?? true) ||
            DateTime.tryParse(reviewedAtIso ?? '') == null)) {
      violations.add(
        ContractViolation(
          code: 'curriculum.missing_approval',
          field: recordId,
          message: 'Approved evidence requires reviewer and review date.',
        ),
      );
    }
    if (authority == CurriculumAuthority.topik &&
        status == CurriculumAlignmentStatus.approved) {
      if (!promotionAuthority.resolvesOfficialReference(officialReference)) {
        violations.add(
          ContractViolation(
            code: 'curriculum.unresolved_topik_authority',
            field: recordId,
            message:
                'Approved TOPIK evidence must resolve to an allow-listed '
                'official source URL.',
          ),
        );
      }
      for (final link in contentLinks) {
        if (!promotionAuthority.resolvesContentLink(link)) {
          violations.add(
            ContractViolation(
              code: 'curriculum.unresolved_production_content',
              field: recordId,
              message:
                  'Approved TOPIK evidence must link real production content.',
            ),
          );
        }
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

final class CurriculumAlignmentRegistry {
  const CurriculumAlignmentRegistry(
    this.records, {
    this.promotionAuthority = const CurriculumPromotionAuthority.none(),
  });

  final List<CurriculumAlignmentRecord> records;
  final CurriculumPromotionAuthority promotionAuthority;

  ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    final recordIds = <String>{};
    for (final record in records) {
      violations.addAll(
        record.validate(promotionAuthority: promotionAuthority).violations,
      );
      if (!recordIds.add(record.recordId)) {
        violations.add(
          ContractViolation(
            code: 'curriculum.duplicate_record_id',
            field: record.recordId,
            message: 'Alignment record ids must be unique.',
          ),
        );
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }

  bool hasMappedAuthority(CurriculumAuthority authority) {
    return records.any(
      (record) =>
          record.authority == authority &&
          record.status != CurriculumAlignmentStatus.gap &&
          record.validate(promotionAuthority: promotionAuthority).isValid,
    );
  }

  /// Produces a stable, machine-readable report against the reviewed TOPIK
  /// denominator. Only valid, explicitly approved TOPIK records count as
  /// coverage; mapped, partial, gap, and invalid approved records remain open.
  TopikCoverageGapReport topikCoverageGapReport(
    TopikCoverageRequirement requirement,
  ) {
    final registryResult = validate();
    final requirementResult = requirement.validate();
    final approvedRecords = records.where(
      (record) =>
          record.authority == CurriculumAuthority.topik &&
          record.status == CurriculumAlignmentStatus.approved &&
          record.validate(promotionAuthority: promotionAuthority).isValid,
    );

    final approvedDomains = approvedRecords
        .expand((record) => record.domains)
        .toSet();
    final approvedTaskTypes = approvedRecords
        .expand((record) => record.publicTaskTypes)
        .map(_normalizeTaskType)
        .where((taskType) => taskType.isNotEmpty)
        .toSet();
    final requiredDomains = requirement.domains.toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    final requiredTaskTypes =
        requirement.publicTaskTypes
            .map(_normalizeTaskType)
            .where((taskType) => taskType.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final sortedApprovedDomains = approvedDomains.toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    final sortedApprovedTaskTypes = approvedTaskTypes.toList()..sort();
    final missingDomains = requiredDomains
        .where((domain) => !approvedDomains.contains(domain))
        .toList(growable: false);
    final missingTaskTypes = requiredTaskTypes
        .where((taskType) => !approvedTaskTypes.contains(taskType))
        .toList(growable: false);
    final unresolvedRecordIds =
        records
            .where(
              (record) =>
                  record.authority == CurriculumAuthority.topik &&
                  (record.status != CurriculumAlignmentStatus.approved ||
                      !record
                          .validate(promotionAuthority: promotionAuthority)
                          .isValid),
            )
            .map((record) => record.recordId)
            .toList()
          ..sort();

    return TopikCoverageGapReport(
      registryValid: registryResult.isValid,
      requirementValid: requirementResult.isValid,
      denominatorApproved: requirement.isReviewedComplete,
      requiredDomains: requiredDomains,
      approvedDomains: sortedApprovedDomains,
      missingDomains: missingDomains,
      requiredTaskTypes: requiredTaskTypes,
      approvedTaskTypes: sortedApprovedTaskTypes,
      missingTaskTypes: missingTaskTypes,
      unresolvedRecordIds: unresolvedRecordIds,
    );
  }
}

/// Review state for the official-domain and public-task denominator itself.
///
/// Individual evidence records cannot prove that the denominator is
/// exhaustive. A separate educational review must explicitly approve it.
enum TopikDenominatorReviewStatus { draft, partial, approved }

/// Official TOPIK denominator supplied from the reviewed public specification.
final class TopikCoverageRequirement {
  const TopikCoverageRequirement({
    required this.domains,
    required this.publicTaskTypes,
    this.reviewStatus = TopikDenominatorReviewStatus.partial,
    this.reviewer,
    this.reviewedAtIso,
  });

  final Set<CurriculumLanguageDomain> domains;
  final Set<String> publicTaskTypes;
  final TopikDenominatorReviewStatus reviewStatus;
  final String? reviewer;
  final String? reviewedAtIso;

  bool get isReviewedComplete =>
      reviewStatus == TopikDenominatorReviewStatus.approved &&
      validate().isValid;

  ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    if (domains.isEmpty || publicTaskTypes.isEmpty) {
      violations.add(
        const ContractViolation(
          code: 'curriculum.empty_topik_denominator',
          field: 'topikCoverageRequirement',
          message: 'Complete coverage needs official domains and task types.',
        ),
      );
    }
    if (publicTaskTypes.any((item) => item.trim().isEmpty)) {
      violations.add(
        const ContractViolation(
          code: 'curriculum.empty_topik_task',
          field: 'topikCoverageRequirement',
          message: 'TOPIK denominator task types cannot be empty.',
        ),
      );
    }
    if (reviewStatus == TopikDenominatorReviewStatus.approved &&
        ((reviewer?.trim().isEmpty ?? true) ||
            DateTime.tryParse(reviewedAtIso ?? '') == null)) {
      violations.add(
        const ContractViolation(
          code: 'curriculum.missing_topik_denominator_approval',
          field: 'topikCoverageRequirement',
          message:
              'An approved TOPIK denominator requires reviewer and review date.',
        ),
      );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

/// Deterministic coverage output suitable for release gates and gap reports.
/// Lists are sorted and immutable so repeated runs serialize identically.
final class TopikCoverageGapReport {
  TopikCoverageGapReport({
    required this.registryValid,
    required this.requirementValid,
    required this.denominatorApproved,
    required List<CurriculumLanguageDomain> requiredDomains,
    required List<CurriculumLanguageDomain> approvedDomains,
    required List<CurriculumLanguageDomain> missingDomains,
    required List<String> requiredTaskTypes,
    required List<String> approvedTaskTypes,
    required List<String> missingTaskTypes,
    required List<String> unresolvedRecordIds,
  }) : requiredDomains = List.unmodifiable(requiredDomains),
       approvedDomains = List.unmodifiable(approvedDomains),
       missingDomains = List.unmodifiable(missingDomains),
       requiredTaskTypes = List.unmodifiable(requiredTaskTypes),
       approvedTaskTypes = List.unmodifiable(approvedTaskTypes),
       missingTaskTypes = List.unmodifiable(missingTaskTypes),
       unresolvedRecordIds = List.unmodifiable(unresolvedRecordIds);

  final bool registryValid;
  final bool requirementValid;
  final bool denominatorApproved;
  final List<CurriculumLanguageDomain> requiredDomains;
  final List<CurriculumLanguageDomain> approvedDomains;
  final List<CurriculumLanguageDomain> missingDomains;
  final List<String> requiredTaskTypes;
  final List<String> approvedTaskTypes;
  final List<String> missingTaskTypes;
  final List<String> unresolvedRecordIds;

  bool get isComplete =>
      registryValid &&
      requirementValid &&
      denominatorApproved &&
      missingDomains.isEmpty &&
      missingTaskTypes.isEmpty &&
      unresolvedRecordIds.isEmpty;

  Map<String, Object> toJson() => {
    'registryValid': registryValid,
    'requirementValid': requirementValid,
    'denominatorApproved': denominatorApproved,
    'requiredDomains': requiredDomains.map((domain) => domain.name).toList(),
    'approvedDomains': approvedDomains.map((domain) => domain.name).toList(),
    'missingDomains': missingDomains.map((domain) => domain.name).toList(),
    'requiredTaskTypes': requiredTaskTypes,
    'approvedTaskTypes': approvedTaskTypes,
    'missingTaskTypes': missingTaskTypes,
    'unresolvedRecordIds': unresolvedRecordIds,
  };
}

enum CurriculumPublicClaimKind {
  cefrNiklReferenced,
  comprehensiveTopikCoverage,
  topikOfficialOrCertified,
  passGuarantee,
  topikHundredPercent,
  cefrTopikOneToOne,
}

/// Fail-closed public copy gate. It never treats CEFR and TOPIK as equivalent.
final class CurriculumPublicClaimValidator {
  const CurriculumPublicClaimValidator({
    required this.registry,
    required this.topikRequirement,
  });

  final CurriculumAlignmentRegistry registry;
  final TopikCoverageRequirement topikRequirement;

  ContractValidationResult validateKind(CurriculumPublicClaimKind kind) {
    final registryResult = registry.validate();
    if (!registryResult.isValid) {
      return registryResult;
    }
    switch (kind) {
      case CurriculumPublicClaimKind.topikOfficialOrCertified:
      case CurriculumPublicClaimKind.passGuarantee:
      case CurriculumPublicClaimKind.topikHundredPercent:
      case CurriculumPublicClaimKind.cefrTopikOneToOne:
        return const ContractValidationResult([
          ContractViolation(
            code: 'curriculum.claim_forbidden',
            field: 'publicClaim',
            message: 'This TOPIK claim is forbidden regardless of evidence.',
          ),
        ]);
      case CurriculumPublicClaimKind.cefrNiklReferenced:
        if (!registry.hasMappedAuthority(CurriculumAuthority.cefr) ||
            !registry.hasMappedAuthority(CurriculumAuthority.nikl)) {
          return const ContractValidationResult([
            ContractViolation(
              code: 'curriculum.claim_missing_cefr_nikl_evidence',
              field: 'publicClaim',
              message:
                  'The basic reference claim needs CEFR and NIKL evidence.',
            ),
          ]);
        }
      case CurriculumPublicClaimKind.comprehensiveTopikCoverage:
        final requirementResult = topikRequirement.validate();
        if (!requirementResult.isValid) {
          return requirementResult;
        }
        final report = registry.topikCoverageGapReport(topikRequirement);
        if (!report.isComplete) {
          return const ContractValidationResult([
            ContractViolation(
              code: 'curriculum.claim_incomplete_topik_coverage',
              field: 'publicClaim',
              message: 'Comprehensive TOPIK copy needs all approved evidence.',
            ),
          ]);
        }
    }
    return const ContractValidationResult.valid();
  }

  /// Secondary guard for localized ARB values before release. Product code
  /// should prefer [validateKind], which cannot be bypassed by rewording.
  ContractValidationResult validateLocalizedCopy(String copy) {
    final normalized = copy
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final forbiddenPatterns = <RegExp>[
      RegExp(
        r'(topik.{0,24}(official|certif|공식|인증|offiziell|zertifiz)|'
        r'(official|certif|공식|인증|offiziell|zertifiz).{0,24}topik)',
      ),
      RegExp(
        r'(합격.{0,8}보장|pass.{0,12}guarante|guarante.{0,12}pass|'
        r'bestehensgarantie|bestehen.{0,12}garantiert)',
      ),
      RegExp(r'(topik.{0,24}100\s*%|100\s*%.{0,24}topik)'),
      RegExp(
        r'((cefr.{0,24}topik|topik.{0,24}cefr).{0,24}'
        r'(1\s*:\s*1|one.to.one|일대일|등치|동일|entspricht))',
      ),
    ];
    if (forbiddenPatterns.any((pattern) => pattern.hasMatch(normalized))) {
      return const ContractValidationResult([
        ContractViolation(
          code: 'curriculum.localized_claim_forbidden',
          field: 'localizedCopy',
          message: 'Localized curriculum copy contains a forbidden claim.',
        ),
      ]);
    }
    final impliesCompleteTopikCoverage =
        RegExp(
          r'(topik.{0,40}(빠짐없이|모든.{0,12}영역|all.{0,12}areas))',
        ).hasMatch(normalized) ||
        RegExp(
          r'(alle.{0,12}(bereiche|aufgabentypen).{0,40}topik)',
        ).hasMatch(normalized);
    if (impliesCompleteTopikCoverage) {
      return validateKind(CurriculumPublicClaimKind.comprehensiveTopikCoverage);
    }
    return const ContractValidationResult.valid();
  }
}

String _normalizeTaskType(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
