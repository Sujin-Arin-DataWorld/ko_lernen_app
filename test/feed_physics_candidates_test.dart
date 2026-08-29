import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/feed_physics_candidates.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

void main() {
  const expectedIds = <String>[
    'custom_pack_play_screen',
    'grammar_screen',
    'hangul_screen',
    'legacy_vocab_screen',
    'review_session_screen',
    'smalltalk_screen',
    'vocab_pack_screen',
  ];

  test('manifest contains exactly the seven snap candidates', () {
    expect(
      feedPhysicsCandidates.map((candidate) => candidate.screenId).toList(),
      expectedIds,
    );
    expect(
      feedPhysicsCandidates.map((candidate) => candidate.screenId).toSet(),
      hasLength(expectedIds.length),
    );
  });

  test('candidate metadata is complete and remains behind the device gate', () {
    for (final candidate in feedPhysicsCandidates) {
      expect(candidate.route, isNotEmpty);
      expect(candidate.axesExercised, isNotEmpty);
      expect(candidate.activeControls, isNotEmpty);
      expect(candidate.nestedScrollRisk.trim(), isNotEmpty);
      expect(candidate.approvedForSnap, isFalse);
    }
  });

  test('manifest collections are immutable', () {
    expect(
      () => feedPhysicsCandidates.add(feedPhysicsCandidates.first),
      throwsUnsupportedError,
    );
    expect(
      () => feedPhysicsCandidates.first.axesExercised.add('diagonal'),
      throwsUnsupportedError,
    );
    expect(
      () => feedPhysicsCandidates.first.activeControls.add('promote'),
      throwsUnsupportedError,
    );
  });

  test(
    'feed keeps legacy physics unless a caller explicitly opts into snap',
    () {
      expect(
        const SoriContentFeed(child: SizedBox()).physics,
        FeedPhysics.legacy,
      );
      expect(
        const SoriContentFeed(
          physics: FeedPhysics.snap,
          child: SizedBox(),
        ).physics,
        FeedPhysics.snap,
      );
    },
  );

  test('listing a candidate does not authorize snap physics', () {
    for (final candidate in feedPhysicsCandidates) {
      expect(candidate.approvedForSnap, isFalse);
      expect(
        SoriContentFeed(
          key: ValueKey(candidate.screenId),
          child: const SizedBox(),
        ).physics,
        FeedPhysics.legacy,
      );
    }
  });
}
