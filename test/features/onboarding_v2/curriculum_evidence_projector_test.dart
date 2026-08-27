import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/curriculum_alignment_registry.dart';
import 'package:ko_lernen_app/features/onboarding_v2/curriculum_evidence_projector.dart';
import 'package:ko_lernen_app/models/curriculum_alignment_contract.dart';

void main() {
  test('production projection exposes only registry CEFR and NIKL sources', () {
    final projection = OnboardingCurriculumEvidenceProjector.project();

    expect(projection, isNotNull);
    expect(
      projection!.references.map((reference) => reference.authority),
      const [CurriculumAuthority.cefr, CurriculumAuthority.nikl],
    );
    expect(
      projection.references.every(
        (reference) => productionCurriculumAlignmentRegistry.records.any(
          (record) => identical(record.officialReference, reference),
        ),
      ),
      isTrue,
    );
    expect(
      projection.references.map((reference) => reference.url).toSet(),
      hasLength(2),
    );
  });

  test('projection fails closed when the basic public claim is rejected', () {
    const invalidRegistry = CurriculumAlignmentRegistry([]);
    final invalidValidator = CurriculumPublicClaimValidator(
      registry: invalidRegistry,
      topikRequirement: productionTopikCoverageRequirement,
    );

    expect(
      invalidValidator
          .validateKind(CurriculumPublicClaimKind.cefrNiklReferenced)
          .isValid,
      isFalse,
    );
    expect(
      OnboardingCurriculumEvidenceProjector.project(
        validator: invalidValidator,
      ),
      isNull,
    );
  });
}
