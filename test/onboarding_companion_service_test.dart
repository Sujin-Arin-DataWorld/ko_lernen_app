import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/onboarding_companion_service.dart';

void main() {
  final firstSuccess = MasteryEvidence(
    conceptId: 'concept-a',
    contentKind: CurriculumContentKind.vocab,
    contentId: 'vocab-a',
    courseUnitId: 'a1-01',
    isCorrect: true,
    occurredAt: DateTime.utc(2026, 8, 10),
    courseEligible: true,
  );

  bool shouldOffer({
    bool seen = false,
    String? unitId = 'a1-01',
    String? level = 'a1',
    Iterable<MasteryEvidence> evidence = const [],
  }) => OnboardingCompanionService.shouldOffer(
    introPreviewSeen: seen,
    activeCourseUnitId: unitId,
    activeCourseLevel: level,
    evidence: evidence,
  );

  test('offers only after a correct eligible answer in the active A1 unit', () {
    expect(shouldOffer(evidence: [firstSuccess]), isTrue);
    expect(shouldOffer(evidence: const []), isFalse);
    expect(
      shouldOffer(
        evidence: [
          MasteryEvidence(
            conceptId: 'concept-a',
            contentKind: CurriculumContentKind.vocab,
            contentId: 'vocab-a',
            courseUnitId: 'a1-01',
            isCorrect: false,
            occurredAt: DateTime.utc(2026, 8, 10),
            courseEligible: true,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      shouldOffer(
        evidence: [
          MasteryEvidence(
            conceptId: 'concept-a',
            contentKind: CurriculumContentKind.vocab,
            contentId: 'vocab-a',
            courseUnitId: 'a1-01',
            isCorrect: true,
            occurredAt: DateTime.utc(2026, 8, 10),
            courseEligible: false,
          ),
        ],
      ),
      isFalse,
    );
  });

  test('does not offer again, outside A1, or for a different unit', () {
    expect(shouldOffer(seen: true, evidence: [firstSuccess]), isFalse);
    expect(shouldOffer(level: 'a2', evidence: [firstSuccess]), isFalse);
    expect(shouldOffer(unitId: 'a1-02', evidence: [firstSuccess]), isFalse);
  });
}
