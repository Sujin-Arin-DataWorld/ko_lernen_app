import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/guide_contract.dart';

typedef GuidePreferencesLoader = Future<SharedPreferences> Function();

@immutable
final class GuideProgressSnapshot {
  GuideProgressSnapshot({
    required Iterable<GuideTopicId> completedTopicIds,
    Iterable<GuideTopicId> openedTopicIds = const [],
    required this.isTodayCardDismissed,
  }) : completedTopicIds = Set.unmodifiable(completedTopicIds),
       openedTopicIds = Set.unmodifiable(openedTopicIds);

  final Set<GuideTopicId> completedTopicIds;
  final Set<GuideTopicId> openedTopicIds;
  final bool isTodayCardDismissed;

  bool isComplete(GuideTopicId topicId) => completedTopicIds.contains(topicId);
  bool hasOpened(GuideTopicId topicId) => openedTopicIds.contains(topicId);
}

/// Durable progress for the optional post-onboarding guide.
///
/// Completion and Today-card visibility intentionally use different keys:
/// dismissing the card is a presentation choice, not evidence that a topic was
/// completed. Key versions are part of the persisted contract, so a future
/// guide revision can migrate without conflating old and new completion rules.
final class GuideProgressService {
  GuideProgressService({GuidePreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const int schemaVersion = 1;

  @visibleForTesting
  static const String completedTopicIdsKey =
      'kl_guide_progress_v1_completed_topic_ids';

  @visibleForTesting
  static const String openedTopicIdsKey =
      'kl_guide_progress_v1_opened_topic_ids';

  @visibleForTesting
  static const String todayCardDismissedKey =
      'kl_guide_progress_v1_today_card_dismissed';

  final GuidePreferencesLoader _preferencesLoader;
  Future<void> _pendingMutation = Future.value();

  Future<GuideProgressSnapshot> load() async {
    await _pendingMutation;
    final preferences = await _preferencesLoader();
    final storedIds =
        preferences.getStringList(completedTopicIdsKey) ?? const [];
    final storedOpenedIds =
        preferences.getStringList(openedTopicIdsKey) ?? const [];
    final completed = <GuideTopicId>{};
    final opened = <GuideTopicId>{};
    for (final topic in GuideTopicId.values) {
      if (storedIds.contains(topic.stableId)) {
        completed.add(topic);
      }
      if (storedOpenedIds.contains(topic.stableId)) {
        opened.add(topic);
      }
    }
    return GuideProgressSnapshot(
      completedTopicIds: completed,
      openedTopicIds: opened,
      isTodayCardDismissed: preferences.getBool(todayCardDismissedKey) ?? false,
    );
  }

  /// Records one explicit topic activation and reports its durable state.
  ///
  /// Concurrent calls are serialized with completion mutations, so exactly
  /// one caller can observe [GuideTopicOpenState.firstOpen]. A later service
  /// instance reads the same versioned key and truthfully reports a reopen.
  Future<GuideTopicOpenState> markTopicOpened(GuideTopicId topicId) =>
      _mutateResult((preferences) async {
        final ids = <String>{...?preferences.getStringList(openedTopicIdsKey)};
        if (!ids.add(topicId.stableId)) {
          return GuideTopicOpenState.reopen;
        }
        final sortedIds = ids.toList()..sort();
        await _requireWrite(
          preferences.setStringList(openedTopicIdsKey, sortedIds),
          openedTopicIdsKey,
        );
        return GuideTopicOpenState.firstOpen;
      });

  Future<void> markTopicCompleted(GuideTopicId topicId) =>
      _mutate((preferences) async {
        final ids = <String>{
          ...?preferences.getStringList(completedTopicIdsKey),
          topicId.stableId,
        }.toList()..sort();
        await _requireWrite(
          preferences.setStringList(completedTopicIdsKey, ids),
          completedTopicIdsKey,
        );
      });

  Future<void> markTopicIncomplete(GuideTopicId topicId) => _mutate((
    preferences,
  ) async {
    final ids = <String>{...?preferences.getStringList(completedTopicIdsKey)}
      ..remove(topicId.stableId);
    final sortedIds = ids.toList()..sort();
    await _requireWrite(
      preferences.setStringList(completedTopicIdsKey, sortedIds),
      completedTopicIdsKey,
    );
  });

  Future<void> dismissTodayCard() => _mutate((preferences) async {
    await _requireWrite(
      preferences.setBool(todayCardDismissedKey, true),
      todayCardDismissedKey,
    );
  });

  Future<void> restoreTodayCard() => _mutate((preferences) async {
    await _requireWrite(
      preferences.setBool(todayCardDismissedKey, false),
      todayCardDismissedKey,
    );
  });

  Future<void> _mutate(
    Future<void> Function(SharedPreferences preferences) operation,
  ) => _mutateResult<void>(operation);

  Future<T> _mutateResult<T>(
    Future<T> Function(SharedPreferences preferences) operation,
  ) {
    final result = _pendingMutation.then((_) async {
      final preferences = await _preferencesLoader();
      return operation(preferences);
    });
    _pendingMutation = result.then<void>((_) {}).catchError((Object _) {});
    return result;
  }

  static Future<void> _requireWrite(Future<bool> write, String key) async {
    if (!await write) {
      throw StateError('Unable to persist guide progress for $key.');
    }
  }
}
