/// Review-only inventory of surfaces that may be tested with snap physics.
///
/// This data is deliberately inert: nothing in the runtime reads this list to
/// select [FeedPhysics.snap]. Promotion is a separate, physical-device gate.
class FeedPhysicsCandidate {
  FeedPhysicsCandidate({
    required this.screenId,
    required this.route,
    required List<String> axesExercised,
    required this.nestedScrollRisk,
    required List<String> activeControls,
  }) : axesExercised = List.unmodifiable(axesExercised),
       activeControls = List.unmodifiable(activeControls);

  /// Stable screen identifier used by the device-review checklist.
  final String screenId;

  /// Route that opens the candidate surface.
  final String route;

  /// Gesture axes to exercise during physical-device review.
  final List<String> axesExercised;

  /// Why the candidate needs nested-scroll attention during review.
  final String nestedScrollRisk;

  /// Controls whose hit targets and semantics must survive snap review.
  final List<String> activeControls;

  /// Candidates are never approved by inventory alone.
  final bool approvedForSnap = false;

  // Short aliases keep the inventory convenient for checklist tooling while
  // retaining the explicit field names above as the contract documentation.
  String get id => screenId;
  List<String> get axes => axesExercised;
}

/// The seven W5-A surfaces awaiting Jin's separate physical-device gate.
///
/// This is an unmodifiable outer list, and each candidate defensively copies
/// its metadata collections. It has no runtime consumer by design.
final List<FeedPhysicsCandidate> feedPhysicsCandidates = List.unmodifiable([
  FeedPhysicsCandidate(
    screenId: 'custom_pack_play_screen',
    route: '/custom_pack/play',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: ['flip', 'like', 'share', 'know', 'hard', 'skip'],
  ),
  FeedPhysicsCandidate(
    screenId: 'grammar_screen',
    route: '/grammar',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: [
      'flip',
      'like',
      'bookmark',
      'know',
      'hard',
      'skip',
      'previous',
    ],
  ),
  FeedPhysicsCandidate(
    screenId: 'hangul_screen',
    route: '/hangul',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: [
      'flip',
      'like',
      'share',
      'know',
      'hard',
      'skip',
      'previous',
    ],
  ),
  FeedPhysicsCandidate(
    screenId: 'legacy_vocab_screen',
    route: '/vocab/legacy',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: [
      'flip',
      'like',
      'bookmark',
      'share',
      'know',
      'hard',
      'skip',
      'previous',
    ],
  ),
  FeedPhysicsCandidate(
    screenId: 'review_session_screen',
    route: '/review',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: [
      'speech',
      'flip',
      'like',
      'bookmark',
      'share',
      'know',
      'hard',
      'skip',
      'previous',
    ],
  ),
  FeedPhysicsCandidate(
    screenId: 'smalltalk_screen',
    route: '/smalltalk',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'phrase-content',
    activeControls: ['flip', 'like', 'bookmark', 'previous', 'next'],
  ),
  FeedPhysicsCandidate(
    screenId: 'vocab_pack_screen',
    route: '/vocab/pack',
    axesExercised: ['vertical', 'horizontal'],
    nestedScrollRisk: 'card-content',
    activeControls: [
      'flip',
      'like',
      'bookmark',
      'share',
      'know',
      'hard',
      'skip',
    ],
  ),
]);
