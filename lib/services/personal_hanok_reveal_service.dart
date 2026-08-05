import '../models/personal_hanok.dart';
import 'storage_service.dart';

/// Stable construction order for the personal Hanok map.
///
/// It is intentionally separate from legacy [HanokStage] order: the legacy
/// sequence still describes the early single-building cinematic, while this
/// order describes full-canvas layers on the personal estate map.
const kPersonalHanokMilestoneOrder = <PersonalHanokMilestone>[
  PersonalHanokMilestone.sotdaeulmun,
  PersonalHanokMilestone.haengrangchae,
  PersonalHanokMilestone.sarangchae,
  PersonalHanokMilestone.anchae,
  PersonalHanokMilestone.daecheongmaru,
  PersonalHanokMilestone.sadang,
  PersonalHanokMilestone.rearGarden,
];

/// Persisted viewing state, deliberately independent from learning progress.
///
/// A learner has already earned the building before this state is touched.
/// The state merely prevents a local visual reveal from being replayed on
/// every map visit.
class PersonalHanokRevealSnapshot {
  final bool isInitialized;
  final Set<PersonalHanokMilestone> seen;

  const PersonalHanokRevealSnapshot.uninitialized()
    : isInitialized = false,
      seen = const <PersonalHanokMilestone>{};

  const PersonalHanokRevealSnapshot.initialized(this.seen)
    : isInitialized = true;
}

/// Pure decision for a personal-Hanok reveal pass.
class PersonalHanokRevealPlan {
  final bool shouldInitialize;
  final List<PersonalHanokMilestone> milestonesToPersist;
  final List<PersonalHanokMilestone> reveals;

  const PersonalHanokRevealPlan._({
    required this.shouldInitialize,
    required this.milestonesToPersist,
    required this.reveals,
  });

  /// Existing learners must not receive a queue of historical construction
  /// films on their first visit after this feature ships. A first pass stores
  /// the current projection quietly; subsequent new pieces are revealed in
  /// their approved construction order.
  factory PersonalHanokRevealPlan.forProjection({
    required PersonalHanokProjection projection,
    required PersonalHanokRevealSnapshot snapshot,
  }) {
    final visible = kPersonalHanokMilestoneOrder
        .where(projection.isUnlocked)
        .toList(growable: false);
    if (!snapshot.isInitialized) {
      return PersonalHanokRevealPlan._(
        shouldInitialize: true,
        milestonesToPersist: visible,
        reveals: const <PersonalHanokMilestone>[],
      );
    }
    return PersonalHanokRevealPlan._(
      shouldInitialize: false,
      milestonesToPersist: const <PersonalHanokMilestone>[],
      reveals: visible
          .where((milestone) => !snapshot.seen.contains(milestone))
          .toList(growable: false),
    );
  }
}

/// Small boundary around local Storage so the map screen remains testable and
/// never needs to know preference-key details.
abstract interface class PersonalHanokRevealStore {
  Future<PersonalHanokRevealSnapshot> load();

  Future<void> initialize(Iterable<PersonalHanokMilestone> milestones);

  Future<void> markSeen(PersonalHanokMilestone milestone);
}

class StoragePersonalHanokRevealStore implements PersonalHanokRevealStore {
  const StoragePersonalHanokRevealStore();

  @override
  Future<PersonalHanokRevealSnapshot> load() async {
    final raw = Storage.personalHanokMilestoneRevealSnapshot;
    if (!raw.isInitialized) {
      return const PersonalHanokRevealSnapshot.uninitialized();
    }
    return PersonalHanokRevealSnapshot.initialized(
      raw.seen.map(_parseMilestone).whereType<PersonalHanokMilestone>().toSet(),
    );
  }

  @override
  Future<void> initialize(Iterable<PersonalHanokMilestone> milestones) =>
      Storage.initializePersonalHanokMilestoneReveals(
        milestones.map((milestone) => milestone.name),
      );

  @override
  Future<void> markSeen(PersonalHanokMilestone milestone) =>
      Storage.markPersonalHanokMilestoneRevealSeen(milestone.name);
}

PersonalHanokMilestone? _parseMilestone(String raw) {
  for (final milestone in PersonalHanokMilestone.values) {
    if (milestone.name == raw) {
      return milestone;
    }
  }
  return null;
}
