import '../../data/curriculum_alignment_registry.dart';
import '../../models/curriculum_alignment_contract.dart';

/// Read-only public evidence for the modest CEFR/NIKL onboarding claim.
///
/// The projection contains only official references already present in the
/// alignment registry. Widgets must not duplicate or invent source URLs.
final class OnboardingCurriculumEvidenceProjection {
  OnboardingCurriculumEvidenceProjection._(
    List<OfficialCurriculumReference> references,
  ) : references = List.unmodifiable(references);

  final List<OfficialCurriculumReference> references;
}

abstract final class OnboardingCurriculumEvidenceProjector {
  /// Returns no public evidence unless the registry validates the basic claim.
  ///
  /// This is deliberately fail-closed: malformed records, a missing authority,
  /// or a rejected public claim hides both the claim and its source action.
  static OnboardingCurriculumEvidenceProjection? project({
    CurriculumPublicClaimValidator? validator,
  }) {
    final resolvedValidator = validator ?? productionCurriculumClaimValidator;
    final claimResult = resolvedValidator.validateKind(
      CurriculumPublicClaimKind.cefrNiklReferenced,
    );
    if (!claimResult.isValid) return null;

    final references = <OfficialCurriculumReference>[];
    for (final authority in const [
      CurriculumAuthority.cefr,
      CurriculumAuthority.nikl,
    ]) {
      final matching = resolvedValidator.registry.records.where(
        (record) =>
            record.authority == authority &&
            record.status != CurriculumAlignmentStatus.gap &&
            record.validate().isValid,
      );
      final uniqueReferences = <String, OfficialCurriculumReference>{};
      for (final record in matching) {
        uniqueReferences.putIfAbsent(
          _referenceIdentity(record.officialReference),
          () => record.officialReference,
        );
      }
      if (uniqueReferences.length != 1) return null;
      references.add(uniqueReferences.values.single);
    }

    return OnboardingCurriculumEvidenceProjection._(references);
  }

  static String _referenceIdentity(OfficialCurriculumReference reference) =>
      '${reference.authority.name}\u0000${reference.documentName}\u0000'
      '${reference.documentVersion}\u0000${reference.url}\u0000'
      '${reference.checkedAtIso}';
}
