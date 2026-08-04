import 'hanok_stage.dart';
import '../services/hanok_stage_service.dart';

/// Stable construction and landscape pieces in the personal Hanok world.
///
/// This is intentionally separate from the legacy [HanokStage] enum: stages
/// keep their existing cinematic contract, while these values describe which
/// pieces can be composed on the canonical 4:3 estate map.
enum PersonalHanokMilestone {
  sotdaeulmun,
  haengrangchae,
  sarangchae,
  anchae,
  daecheongmaru,
  sadang,
  rearGarden,
  rearPond,
  rearBridge,
  pavilion,
  jangdokdae,
  lanterns,
}

/// Semantic destinations on the personal estate map.
enum PersonalHanokZone {
  sarangbang,
  daecheongmaru,
  haengrangchae,
  anchae,
  huwon,
  sadang,
  gyeRoad,
}

/// A fractional rectangle on the fixed 4:3 master-map canvas.
///
/// It is deliberately framework-free so catalog/progress tests do not depend
/// on rendering or Flutter geometry classes.
class PersonalHanokRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const PersonalHanokRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Derived, zero-write state for the personal Hanok map.
///
/// Existing users are migrated simply by recalculating from their already
/// earned pack ratios. No reward, CourseMastery, room placement, or cloud
/// state is read or changed here.
class PersonalHanokProjection {
  final HanokStage legacyStage;
  final Set<PersonalHanokMilestone> unlocked;

  const PersonalHanokProjection._({
    required this.legacyStage,
    required this.unlocked,
  });

  static const Set<PersonalHanokMilestone> constructionMilestones = {
    PersonalHanokMilestone.sotdaeulmun,
    PersonalHanokMilestone.haengrangchae,
    PersonalHanokMilestone.sarangchae,
    PersonalHanokMilestone.anchae,
    PersonalHanokMilestone.daecheongmaru,
    PersonalHanokMilestone.sadang,
    PersonalHanokMilestone.rearGarden,
  };

  /// Uses the wide map only after the legacy B1 gate boundary.
  bool get usesCompoundMap =>
      unlocked.contains(PersonalHanokMilestone.sotdaeulmun);

  bool get isConstructionComplete =>
      unlocked.containsAll(constructionMilestones);

  double get constructionFraction =>
      constructionMilestones.where(unlocked.contains).length /
      constructionMilestones.length;

  bool isUnlocked(PersonalHanokMilestone milestone) =>
      unlocked.contains(milestone);

  factory PersonalHanokProjection.from(LevelRatios ratios) {
    final a1 = _unit(ratios.a1);
    final a2 = _unit(ratios.a2);
    final b1 = _unit(ratios.b1);
    final b2 = _unit(ratios.b2);
    final legacyStage = computeStage(
      a1Ratio: a1,
      a2Ratio: a2,
      b1Ratio: b1,
      b2Ratio: b2,
    );
    final unlocked = <PersonalHanokMilestone>{};

    // Retain the existing cascade semantics: no later level can construct a
    // compound piece before all preceding study stages are truly complete.
    if (a1 < 1 || a2 < 1) {
      return PersonalHanokProjection._(
        legacyStage: legacyStage,
        unlocked: Set.unmodifiable(unlocked),
      );
    }
    if (b1 >= .25) {
      unlocked.add(PersonalHanokMilestone.sotdaeulmun);
    }
    if (b1 >= .5) {
      unlocked.add(PersonalHanokMilestone.haengrangchae);
    }
    if (b1 < 1) {
      return PersonalHanokProjection._(
        legacyStage: legacyStage,
        unlocked: Set.unmodifiable(unlocked),
      );
    }

    unlocked.add(PersonalHanokMilestone.sarangchae);
    if (b2 >= .25) {
      unlocked.add(PersonalHanokMilestone.anchae);
    }
    if (b2 >= .5) {
      unlocked.add(PersonalHanokMilestone.daecheongmaru);
    }
    if (b2 >= .75) {
      unlocked.add(PersonalHanokMilestone.sadang);
    }
    if (b2 >= 1) {
      unlocked.addAll(const {
        PersonalHanokMilestone.rearGarden,
        PersonalHanokMilestone.rearPond,
        PersonalHanokMilestone.rearBridge,
        PersonalHanokMilestone.pavilion,
        PersonalHanokMilestone.jangdokdae,
        PersonalHanokMilestone.lanterns,
      });
    }
    return PersonalHanokProjection._(
      legacyStage: legacyStage,
      unlocked: Set.unmodifiable(unlocked),
    );
  }
}

double _unit(double value) => value.clamp(0.0, 1.0).toDouble();
