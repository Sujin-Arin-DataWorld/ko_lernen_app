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
    Iterable<MasteryEvidence> evidenceBefore = const [],
    Iterable<MasteryEvidence> evidenceAfter = const [],
  }) => OnboardingCompanionService.shouldOfferAfterAttempt(
    introPreviewSeen: seen,
    activeCourseUnitId: unitId,
    activeCourseLevel: level,
    evidenceIdsBefore: evidenceBefore.map((item) => item.id),
    evidenceAfter: evidenceAfter,
  );

  test('offers only after a correct eligible answer in the active A1 unit', () {
    expect(shouldOffer(evidenceAfter: [firstSuccess]), isTrue);
    expect(shouldOffer(evidenceAfter: const []), isFalse);
    expect(
      shouldOffer(
        evidenceAfter: [
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
        evidenceAfter: [
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
    expect(shouldOffer(seen: true, evidenceAfter: [firstSuccess]), isFalse);
    expect(shouldOffer(level: 'a2', evidenceAfter: [firstSuccess]), isFalse);
    expect(
      shouldOffer(unitId: 'a1-02', evidenceAfter: [firstSuccess]),
      isFalse,
    );
  });

  test(
    'historical success does not count as success in the current attempt',
    () {
      expect(
        shouldOffer(
          evidenceBefore: [firstSuccess],
          evidenceAfter: [firstSuccess],
        ),
        isFalse,
      );

      final freshSuccess = MasteryEvidence(
        id: 'fresh-current-attempt',
        conceptId: firstSuccess.conceptId,
        contentKind: firstSuccess.contentKind,
        contentId: firstSuccess.contentId,
        courseUnitId: firstSuccess.courseUnitId,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 12),
        courseEligible: true,
      );
      expect(
        shouldOffer(
          evidenceBefore: [firstSuccess],
          evidenceAfter: [firstSuccess, freshSuccess],
        ),
        isTrue,
      );
    },
  );
}
