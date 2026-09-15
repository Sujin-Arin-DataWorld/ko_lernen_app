import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, visibleForTesting, ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../models/scenario_corpus_generation.dart';
import '../models/grammar_study_plan.dart';
import '../data/sori_activity_catalog.dart';
import '../models/sori_stage_progression.dart' show SoriStageTab;

import 'account/account_switch_coordinator.dart' show AccountSwitchJournal;
import 'account/account_transition_journal.dart';
import 'diagnostics_service.dart';
import 'account/cloud_write_session.dart';
import 'catalog_history_lease.dart';
import '../models/learner_level.dart';
import '../models/personal_room.dart';
import 'local_data_lifetime.dart';
import 'media_mutation_lock.dart';
import 'srs_commit_journal.dart';
import 'pack_completion_record.dart';
import 'pack_completion_owner.dart';

part 'pack_completion_storage.dart';
part 'privacy_choice_storage.dart';

/// Mastery-Status eines Vokabel-/Lerneintrags. Aus SRS-Daten abgeleitet,
/// nicht separat persistiert.
enum MasteryState {
  /// Noch nie reviewed — frische Karte.
  fresh,

  /// Erste paar Wiederholungen, kurzes Intervall (≤ 3 Tage).
  learning,

  /// Intervall > 3 Tage, fällig (heute oder früher).
  reviewDue,

  /// Intervall > 3 Tage, sitzt — nicht fällig.
  strong,
}

/// Result of claiming the one-time reward for a listening scenario.
enum ListeningRewardClaimResult { awarded, alreadyClaimed }

class _ListeningRewardClaim {
  const _ListeningRewardClaim({required this.earnedXp, required this.earnedOn});

  final int earnedXp;
  final String earnedOn;

  factory _ListeningRewardClaim.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Listening reward claim must be an object.');
    }
    final earnedXp = value['xp'];
    final earnedOn = value['earnedOn'];
    if (earnedXp is! int || earnedXp <= 0) {
      throw const FormatException('Listening reward XP must be positive.');
    }
    if (earnedOn is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(earnedOn)) {
      throw const FormatException('Listening reward date is invalid.');
    }
    return _ListeningRewardClaim(earnedXp: earnedXp, earnedOn: earnedOn);
  }

  Map<String, Object> toJson() => {'xp': earnedXp, 'earnedOn': earnedOn};
}

class _ScenarioRewardClaim {
  const _ScenarioRewardClaim({required this.scenarioId, required this.reward});

  final String scenarioId;
  final _ListeningRewardClaim reward;

  factory _ScenarioRewardClaim.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['scenarioId'] is! String ||
        (value['scenarioId'] as String).trim().isEmpty) {
      throw const FormatException('Scenario reward claim is invalid.');
    }
    return _ScenarioRewardClaim(
      scenarioId: value['scenarioId'] as String,
      reward: _ListeningRewardClaim.fromJson(value),
    );
  }

  Map<String, Object> toJson() => {
    'scenarioId': scenarioId,
    ...reward.toJson(),
  };
}

class _OrdinaryXpDay {
  const _OrdinaryXpDay({required this.date, required this.xp});

  final String date;
  final int xp;

  factory _OrdinaryXpDay.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['date'] is! String ||
        !Storage._isCanonicalStudyLogDate(value['date'] as String) ||
        value['xp'] is! int) {
      throw const FormatException('Ordinary XP day is invalid.');
    }
    return _OrdinaryXpDay(
      date: value['date'] as String,
      xp: value['xp'] as int,
    );
  }

  Map<String, Object> toJson() => {'date': date, 'xp': xp};
}

/// One award retained while the same completion is retried in this session.
/// A new completion uses a new attempt, even if its XP amount is identical.
class XpAwardAttempt {
  XpAwardAttempt(
    this.amount, {
    DateTime? earnedAt,
    this.dailyCompletionBonus,
    this.kkeunmariWin = false,
  }) : _earnedOn = Storage._isoOf(earnedAt ?? DateTime.now()),
       _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._xpAwardEpoch;

  final int amount;

  /// Null for ordinary awards; zero also records daily completion without bonus.
  final int? dailyCompletionBonus;
  final bool kkeunmariWin;
  int _earnedXp = 0;
  int get earnedXp => _committed ? _earnedXp : 0;
  final String _earnedOn;
  final LocalDataLifetimeLease _lifetime;
  final int _epoch;
  bool _committed = false;

  bool get _isCurrent => _lifetime.isCurrent && _epoch == Storage._xpAwardEpoch;

  Future<void> save() => Storage._enqueueXpRewardMutation(
    () => Storage._saveOrdinaryXpAward(this),
  );
}

class _DailyChallengeState {
  const _DailyChallengeState(this.date, this.streak);
  final String date;
  final int streak;
  factory _DailyChallengeState.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['date'] is! String ||
        !Storage._isCanonicalStudyLogDate(value['date'] as String) ||
        value['streak'] is! int ||
        (value['streak'] as int) < 1) {
      throw const FormatException('Invalid daily challenge state.');
    }
    return _DailyChallengeState(
      value['date'] as String,
      value['streak'] as int,
    );
  }
  Map<String, Object> toJson() => {'date': date, 'streak': streak};
}

/// One personal-best comparison, retained across native acknowledgement loss.
class GameBestAttempt {
  GameBestAttempt(this.id, this.score, {this.higherIsBetter = true})
    : _lifetime = LocalDataLifetime.capture(),
      _epoch = Storage._xpAwardEpoch;
  final String id;
  final int score;
  final bool higherIsBetter;
  final LocalDataLifetimeLease _lifetime;
  final int _epoch;
  bool? _wasNewBest;
  bool _saved = false;
  int? _best;
  int? get best => _saved ? _best : null;
  void _assertCurrent() {
    _lifetime.assertCurrent();
    if (_epoch != Storage._xpAwardEpoch) {
      throw const StaleLocalDataLifetimeException();
    }
  }

  bool _beats(int? previous) =>
      previous == null ||
      (higherIsBetter ? score > previous : score < previous);
  Future<bool> save() =>
      Storage._enqueueXpRewardMutation(() => Storage._saveGameBest(this));
}

class _PendingOrdinaryXpWrite {
  const _PendingOrdinaryXpWrite({
    required this.attempt,
    required this.before,
    required this.encoded,
  });

  final XpAwardAttempt attempt;
  final String before;
  final String encoded;
}

/// One durable value is both the listening-claim record and the XP authority.
/// A crash can therefore never leave "XP written, claim missing" or the
/// inverse. `kl_xp` remains a best-effort compatibility mirror for old builds.
class _XpRewardLedger {
  const _XpRewardLedger({
    required this.totalXp,
    required this.claims,
    this.scenarioClaims = const {},
    this.ordinaryDay,
    this.dailyChallenge,
    this.kkeunmariWins,
  });

  static const int schemaVersion = 1;

  final int totalXp;
  final Map<String, _ListeningRewardClaim> claims;
  final Map<String, _ScenarioRewardClaim> scenarioClaims;
  final _OrdinaryXpDay? ordinaryDay;
  final _DailyChallengeState? dailyChallenge;
  final int? kkeunmariWins;

  factory _XpRewardLedger.decode(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['version'] != schemaVersion ||
        value['totalXp'] is! int ||
        (value['totalXp'] as int) < 0 ||
        value['listeningClaims'] is! Map<String, dynamic>) {
      throw const FormatException('XP reward ledger is invalid.');
    }
    final claims = <String, _ListeningRewardClaim>{};
    for (final entry
        in (value['listeningClaims'] as Map<String, dynamic>).entries) {
      if (entry.key.trim().isEmpty) {
        throw const FormatException('Listening reward ID is empty.');
      }
      claims[entry.key] = _ListeningRewardClaim.fromJson(entry.value);
    }
    final rawScenarios = value.containsKey('scenarioClaims')
        ? value['scenarioClaims']
        : <String, dynamic>{};
    if (rawScenarios is! Map<String, dynamic>) {
      throw const FormatException('Scenario reward claims are invalid.');
    }
    final scenarios = <String, _ScenarioRewardClaim>{};
    for (final entry in rawScenarios.entries) {
      if (entry.key.trim().isEmpty) {
        throw const FormatException('Scenario attempt ID is empty.');
      }
      scenarios[entry.key] = _ScenarioRewardClaim.fromJson(entry.value);
    }
    final wins = value['kkeunmariWins'];
    if (value.containsKey('kkeunmariWins') && (wins is! int || wins < 0)) {
      throw const FormatException('Invalid kkeunmari win count.');
    }
    return _XpRewardLedger(
      kkeunmariWins: wins as int?,
      totalXp: value['totalXp'] as int,
      claims: Map.unmodifiable(claims),
      scenarioClaims: Map.unmodifiable(scenarios),
      ordinaryDay: value.containsKey('ordinaryDay')
          ? _OrdinaryXpDay.fromJson(value['ordinaryDay'])
          : null,
      dailyChallenge: value.containsKey('dailyChallenge')
          ? _DailyChallengeState.fromJson(value['dailyChallenge'])
          : null,
    );
  }

  String encode() {
    final orderedClaims = claims.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final orderedScenarios = scenarioClaims.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      'version': schemaVersion,
      'totalXp': totalXp,
      'listeningClaims': {
        for (final entry in orderedClaims) entry.key: entry.value.toJson(),
      },
      'scenarioClaims': {
        for (final entry in orderedScenarios) entry.key: entry.value.toJson(),
      },
      if (ordinaryDay != null) 'ordinaryDay': ordinaryDay!.toJson(),
      if (dailyChallenge != null) 'dailyChallenge': dailyChallenge!.toJson(),
      if (kkeunmariWins != null) 'kkeunmariWins': kkeunmariWins,
    });
  }

  _XpRewardLedger copyWith({
    int? totalXp,
    Map<String, _ListeningRewardClaim>? claims,
    Map<String, _ScenarioRewardClaim>? scenarioClaims,
    _OrdinaryXpDay? ordinaryDay,
    _DailyChallengeState? dailyChallenge,
    int? kkeunmariWins,
  }) => _XpRewardLedger(
    totalXp: totalXp ?? this.totalXp,
    claims: Map.unmodifiable(claims ?? this.claims),
    scenarioClaims: Map.unmodifiable(scenarioClaims ?? this.scenarioClaims),
    ordinaryDay: ordinaryDay ?? this.ordinaryDay,
    dailyChallenge: dailyChallenge ?? this.dailyChallenge,
    kkeunmariWins: kkeunmariWins ?? this.kkeunmariWins,
  );
}

abstract interface class PreferenceRemovalStore {
  Set<String> getKeys();
  bool containsKey(String key);
  Object? getValue(String key);
  Future<void> reload();
  Future<bool> remove(String key);
  Future<bool> setString(String key, String value);
}

/// Validates and returns a canonical representation of a completed
/// account-deletion checkpoint before strict local cleanup retains it.
typedef AccountDeletionCheckpointCanonicalizer = String Function(String raw);

abstract interface class PreferenceStringStore {
  bool containsKey(String key);
  String? getString(String key);
  Future<void> reload();
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

/// Injectable string-list preference boundary for strict ledger commits.
abstract interface class PreferenceStringListStore {
  bool containsKey(String key);
  List<String>? getStringList(String key);
  Future<void> reload();
  Future<bool> setStringList(String key, List<String> value);
  Future<bool> remove(String key);
}

/// Injectable integer preference boundary for confirmed vocabulary progress.
abstract interface class PreferenceIntStore {
  bool containsKey(String key);
  int? getInt(String key);
  Future<void> reload();
  Future<bool> setInt(String key, int value);
}

/// Outcome of one atomic historical study-log date restore.
enum SrsRecoveryStatus { ready, pending, recovering, retryRequired, blocked }

class SrsRecoveryPendingException implements Exception {
  const SrsRecoveryPendingException();
  @override
  String toString() => 'SRS/history recovery is not confirmed.';
}

enum StudyLogDateRestoreResult {
  written,
  skippedExisting,
  skippedRecoveryValue,
}

/// Outcome of one grammar-plan cloud restore attempt.
enum GrammarPlanRestoreResult { written, skippedExisting, skippedRecoveryValue }

enum _ConfirmedChoiceDomain {
  likedContent('kl_liked_content_v1'),
  vokFavorite('kl_vok_favorites');

  const _ConfirmedChoiceDomain(this.preferenceKey);

  final String preferenceKey;
}

/// One explicit add/remove choice for the two learner favorite lists.
///
/// The item and desired state are frozen at admission so Retry cannot invert a
/// choice or accidentally act on a newly rendered card.
final class ConfirmedLocalChoiceOperation {
  ConfirmedLocalChoiceOperation._(
    this._assertCurrentOwner, {
    required this.itemKey,
    required this.desired,
    required _ConfirmedChoiceDomain domain,
  }) : _domain = domain,
       _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._confirmedChoiceEpoch,
       _revision = Storage._admitConfirmedChoice(domain, itemKey);

  final String itemKey;
  final bool desired;
  final _ConfirmedChoiceDomain _domain;
  final void Function()? _assertCurrentOwner;
  final LocalDataLifetimeLease _lifetime;
  final int _epoch;
  final int _revision;
  Future<bool>? _activeSave;
  bool _completed = false;
  bool _retired = false;

  Future<bool> save() {
    try {
      _assertCurrent();
    } on Object catch (error, stackTrace) {
      return Future<bool>.error(error, stackTrace);
    }
    final active = _activeSave;
    if (active != null) {
      return active;
    }
    if (_completed) {
      return Future<bool>.value(desired);
    }
    late final Future<bool> result;
    result = Storage._saveConfirmedChoice(this).whenComplete(() {
      if (identical(result, _activeSave)) {
        _activeSave = null;
      }
    });
    _activeSave = result;
    return result;
  }

  void _assertCurrent() {
    _assertCurrentOwner?.call();
    if (_retired ||
        !_lifetime.isCurrent ||
        _epoch != Storage._confirmedChoiceEpoch ||
        Storage._learningResetCount > 0 ||
        Storage._confirmedChoiceRevisions[Storage._confirmedChoiceRevisionKey(
              _domain,
              itemKey,
            )] !=
            _revision) {
      throw const StaleLocalDataLifetimeException();
    }
  }

  void retire() {
    _retired = true;
  }
}

class GrammarPlanConflictException implements Exception {
  const GrammarPlanConflictException(this.level);

  final String level;

  @override
  String toString() => 'Grammar plan changed while saving $level.';
}

class GrammarPlanRecoveryValueException implements Exception {
  const GrammarPlanRecoveryValueException();

  @override
  String toString() => 'The stored grammar plan cannot be safely updated.';
}

/// One screen-owned, retryable grammar-plan mutation.
///
/// The accepted semantic target is frozen at admission. Native calls finish on
/// every attempt; a later explicit [save] reconciles an indeterminate reply.
final class GrammarPlanWriteOperation {
  GrammarPlanWriteOperation._({
    required GrammarStudyPlan plan,
    required this.selectedLevel,
    required this.requiresSelectedLevel,
    this._assertCurrentOwner,
  }) : plan = _freezePlan(plan),
       _lifetime = LocalDataLifetime.capture(),
       _revision = Storage._admitGrammarPlanOperation(),
       _baselineRaw = Storage.grammarPlanRawJson,
       _baselineSelectedLevel = Storage.grammarPlanLevel,
       _baselineSelectedLevelRevision =
           Storage._confirmedGrammarPlanLevelRevision;

  factory GrammarPlanWriteOperation.start({
    required GrammarStudyPlan plan,
    void Function()? assertCurrentOwner,
  }) {
    assertCurrentOwner?.call();
    return GrammarPlanWriteOperation._(
      plan: plan,
      selectedLevel: plan.level,
      requiresSelectedLevel: true,
      assertCurrentOwner: assertCurrentOwner,
    );
  }

  factory GrammarPlanWriteOperation.completeDay({
    required GrammarStudyPlan plan,
    void Function()? assertCurrentOwner,
  }) {
    assertCurrentOwner?.call();
    return GrammarPlanWriteOperation._(
      plan: plan,
      selectedLevel: null,
      requiresSelectedLevel: false,
      assertCurrentOwner: assertCurrentOwner,
    );
  }

  final GrammarStudyPlan plan;
  final String? selectedLevel;
  final bool requiresSelectedLevel;
  final void Function()? _assertCurrentOwner;
  final LocalDataLifetimeLease _lifetime;
  final int _revision;
  final String _baselineRaw;
  final String? _baselineSelectedLevel;
  final int _baselineSelectedLevelRevision;
  String? _candidateRaw;
  bool _planConfirmed = false;
  bool _selectedLevelConfirmed = false;
  bool _completed = false;
  bool _retired = false;
  Future<void>? _activeSave;

  Future<void> save() {
    _assertCurrent();
    final active = _activeSave;
    if (active != null) {
      return active;
    }
    if (_completed) {
      return Future<void>.value();
    }
    late final Future<void> result;
    result = Storage._saveGrammarPlanOperation(this).whenComplete(() {
      if (identical(result, _activeSave)) {
        _activeSave = null;
      }
    });
    _activeSave = result;
    return result;
  }

  void retire() {
    _retired = true;
  }

  void _assertCurrent() {
    _assertCurrentOwner?.call();
    if (_retired || !_lifetime.isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
    if (Storage._learningResetCount > 0) {
      throw const StaleLocalDataLifetimeException();
    }
  }

  static GrammarStudyPlan _freezePlan(GrammarStudyPlan plan) =>
      GrammarStudyPlan(
        level: plan.level,
        itemsPerDay: plan.itemsPerDay,
        servedIdsByDate: Map<String, List<String>>.unmodifiable({
          for (final entry in plan.servedIdsByDate.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }),
      );
}

/// Injectable boolean preference boundary used by strict onboarding commits.
///
/// SharedPreferences updates its in-memory cache before the platform write is
/// known to have succeeded. Keeping this boundary separate lets tests model a
/// rejected or indeterminate platform write instead of trusting that cache.
abstract interface class PreferenceBoolStore {
  bool containsKey(String key);
  bool? getBool(String key);
  Future<void> reload();
  Future<bool> setBool(String key, bool value);
}

class PreferenceWriteException implements Exception {
  const PreferenceWriteException(this.key, {this.cause});

  final String key;
  final Object? cause;

  @override
  String toString() => 'Preference write failed for $key.';
}

class PreferenceOutcomeUnknownException implements Exception {
  const PreferenceOutcomeUnknownException(this.key, {this.cause});

  final String key;
  final Object? cause;

  @override
  String toString() => 'Preference outcome is unknown for $key.';
}

class _StringPreferenceState {
  const _StringPreferenceState._({required this.isPresent, this.value});

  const _StringPreferenceState.absent() : isPresent = false, value = null;

  final bool isPresent;
  final String? value;

  static _StringPreferenceState read(PreferenceStringStore store, String key) {
    if (!store.containsKey(key)) {
      return const _StringPreferenceState.absent();
    }
    final value = store.getString(key);
    if (value == null) {
      throw StateError('Preference $key is not a string.');
    }
    return _StringPreferenceState._(isPresent: true, value: value);
  }

  @override
  bool operator ==(Object other) =>
      other is _StringPreferenceState &&
      other.isPresent == isPresent &&
      other.value == value;

  @override
  int get hashCode => Object.hash(isPresent, value);
}

class _StringListPreferenceState {
  const _StringListPreferenceState._({required this.isPresent, this.value});

  const _StringListPreferenceState.absent() : isPresent = false, value = null;

  final bool isPresent;
  final List<String>? value;

  static _StringListPreferenceState read(
    PreferenceStringListStore store,
    String key,
  ) {
    if (!store.containsKey(key)) {
      return const _StringListPreferenceState.absent();
    }
    final value = store.getStringList(key);
    if (value == null) {
      throw StateError('Preference $key is not a string list.');
    }
    return _StringListPreferenceState._(
      isPresent: true,
      value: List<String>.unmodifiable(value),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _StringListPreferenceState &&
      other.isPresent == isPresent &&
      _preferenceValueEquals(other.value, value);

  @override
  int get hashCode => Object.hash(isPresent, Object.hashAll(value ?? const []));
}

class _IntPreferenceState {
  const _IntPreferenceState._({required this.isPresent, this.value});

  const _IntPreferenceState.absent() : isPresent = false, value = null;

  final bool isPresent;
  final int? value;

  static _IntPreferenceState read(PreferenceIntStore store, String key) {
    if (!store.containsKey(key)) {
      return const _IntPreferenceState.absent();
    }
    final value = store.getInt(key);
    if (value == null) {
      throw StateError('Preference $key is not an int.');
    }
    return _IntPreferenceState._(isPresent: true, value: value);
  }

  @override
  bool operator ==(Object other) =>
      other is _IntPreferenceState &&
      other.isPresent == isPresent &&
      other.value == value;

  @override
  int get hashCode => Object.hash(isPresent, value);
}

class _BoolPreferenceState {
  const _BoolPreferenceState._({required this.isPresent, this.value});

  const _BoolPreferenceState.absent() : isPresent = false, value = null;

  final bool isPresent;
  final bool? value;

  static _BoolPreferenceState read(PreferenceBoolStore store, String key) {
    if (!store.containsKey(key)) {
      return const _BoolPreferenceState.absent();
    }
    final value = store.getBool(key);
    if (value == null) {
      throw StateError('Preference $key is not a bool.');
    }
    return _BoolPreferenceState._(isPresent: true, value: value);
  }

  @override
  bool operator ==(Object other) =>
      other is _BoolPreferenceState &&
      other.isPresent == isPresent &&
      other.value == value;

  @override
  int get hashCode => Object.hash(isPresent, value);
}

class _PreferenceState {
  const _PreferenceState._({required this.isPresent, this.value});

  const _PreferenceState.absent() : isPresent = false, value = null;

  final bool isPresent;
  final Object? value;

  static _PreferenceState read(PreferenceRemovalStore store, String key) {
    if (!store.containsKey(key)) {
      return const _PreferenceState.absent();
    }
    return _PreferenceState._(isPresent: true, value: store.getValue(key));
  }

  @override
  bool operator ==(Object other) =>
      other is _PreferenceState &&
      other.isPresent == isPresent &&
      _preferenceValueEquals(other.value, value);

  @override
  int get hashCode => Object.hash(isPresent, value);
}

bool _preferenceValueEquals(Object? first, Object? second) {
  if (first is List<String> && second is List<String>) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
  return first == second;
}

class PreferenceResetException implements Exception {
  const PreferenceResetException({
    required this.failedKeys,
    required this.causes,
  });

  final List<String> failedKeys;
  final List<Object> causes;

  @override
  String toString() => 'Preference reset failed for ${failedKeys.join(', ')}.';
}

/// A local reset must never erase any durable account-operation retry key.
///
/// The legacy name remains part of the public error contract, although the
/// fence also protects replacement and account-deletion checkpoints.
class CloudBackupDeletionResetBlockedException implements Exception {
  const CloudBackupDeletionResetBlockedException();

  @override
  String toString() => 'Cloud backup deletion is still pending.';
}

class RecoveredWordClaim {
  const RecoveredWordClaim({
    required this.record,
    required this.discardedLeases,
  });

  final String? record;
  final List<String> discardedLeases;
}

class _SharedPreferenceRemovalStore implements PreferenceRemovalStore {
  const _SharedPreferenceRemovalStore(this.preferences);

  final SharedPreferences preferences;

  @override
  Set<String> getKeys() => preferences.getKeys();

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  Object? getValue(String key) => preferences.get(key);

  @override
  Future<void> reload() => Storage.reloadForPackCompletion(preferences);

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setString(String key, String value) =>
      preferences.setString(key, value);
}

class _SharedPreferenceStringStore implements PreferenceStringStore {
  const _SharedPreferenceStringStore(this.preferences);

  final SharedPreferences preferences;

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  String? getString(String key) => preferences.getString(key);

  @override
  Future<void> reload() => Storage.reloadForPackCompletion(preferences);

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setString(String key, String value) =>
      preferences.setString(key, value);
}

class _SharedPreferenceStringListStore implements PreferenceStringListStore {
  const _SharedPreferenceStringListStore(this.preferences);

  final SharedPreferences preferences;

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  List<String>? getStringList(String key) => preferences.getStringList(key);

  @override
  Future<void> reload() => Storage.reloadForPackCompletion(preferences);

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      preferences.setStringList(key, value);
}

class _SharedPreferenceIntStore implements PreferenceIntStore {
  const _SharedPreferenceIntStore(this.preferences);

  final SharedPreferences preferences;

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  int? getInt(String key) => preferences.getInt(key);

  @override
  Future<void> reload() => Storage.reloadForPackCompletion(preferences);

  @override
  Future<bool> setInt(String key, int value) => preferences.setInt(key, value);
}

class _SharedPreferenceBoolStore implements PreferenceBoolStore {
  const _SharedPreferenceBoolStore(this.preferences);

  final SharedPreferences preferences;

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  bool? getBool(String key) => preferences.getBool(key);

  @override
  Future<void> reload() => Storage.reloadForPackCompletion(preferences);

  @override
  Future<bool> setBool(String key, bool value) =>
      preferences.setBool(key, value);
}

/// Spaced Repetition card state.
/// Felder kurz benannt, damit JSON klein bleibt (viele tausend Vokabeln möglich).
class SrsCard {
  final double ease; // SM-2 Ease-Faktor (1.3 – 3.5)
  final int intervalDays; // aktuelles Intervall
  final String nextReviewIso; // 'YYYY-MM-DD'
  final int reviewCount; // wie oft wiederholt

  const SrsCard({
    required this.ease,
    required this.intervalDays,
    required this.nextReviewIso,
    required this.reviewCount,
  });

  Map<String, dynamic> toJson() => {
    'e': ease,
    'i': intervalDays,
    'n': nextReviewIso,
    'r': reviewCount,
  };

  factory SrsCard.fromJson(Map<String, dynamic> j) => SrsCard(
    ease: (j['e'] as num?)?.toDouble() ?? 2.5,
    intervalDays: (j['i'] as num?)?.toInt() ?? 0,
    nextReviewIso: j['n'] as String? ?? '',
    reviewCount: (j['r'] as num?)?.toInt() ?? 0,
  );
}

/// One actual judgment, retained by a caller that offers persistence retry.
/// A new judgment must use a new attempt; attempts are never serialized.
class SrsReviewAttempt {
  SrsReviewAttempt({
    required this.id,
    required this.gotIt,
    this.recordToStudyLog = true,
  }) : _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._srsAttemptEpoch;

  final String id;
  final bool gotIt;
  final bool recordToStudyLog;
  final LocalDataLifetimeLease _lifetime;
  final int _epoch;
  bool _completed = false;
  String? _judgmentDate;

  bool get _isCurrent =>
      _lifetime.isCurrent && _epoch == Storage._srsAttemptEpoch;

  /// Caller authority ends as soon as reset/replacement is admitted, even
  /// while an immutable storage obligation is still draining.
  bool get isCurrent => _isCurrent && Storage._learningResetCount == 0;

  Future<bool> save() => Storage._enqueueSrsReviewMutation(
    (generation) => Storage._srsReviewTransaction(this, generation: generation),
  );
}

/// One accepted vocabulary-progress decision retained across persistence retry.
///
/// A caller creates this beside its retained SRS attempt and reuses the same
/// instance until [save] returns true. Successfully committed fields are never
/// applied again when a later field in the batch needs recovery.
class VocabProgressAttempt {
  VocabProgressAttempt({
    this.correctDelta = 0,
    this.wrongDelta = 0,
    this.skippedDelta = 0,
    this.cursor,
    this.seenId,
    this.wrongCountId,
  }) : minimumCorrect = null,
       minimumWrong = null,
       minimumSkipped = null,
       absoluteCorrect = null,
       absoluteWrong = null,
       absoluteSkipped = null,
       restoreSeenIds = const <String>[],
       restoreWrongCountJson = null,
       restoreWrongCountOnlyIfEmpty = false,
       assertCurrentWrite = null,
       bypassLearningWriteLock = false,
       isRestore = false,
       assert(correctDelta >= 0),
       assert(wrongDelta >= 0),
       assert(skippedDelta >= 0),
       _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._vocabProgressAttemptEpoch;

  VocabProgressAttempt._absolute({
    this.absoluteCorrect,
    this.absoluteWrong,
    this.absoluteSkipped,
    this.cursor,
    this.bypassLearningWriteLock = false,
  }) : correctDelta = 0,
       wrongDelta = 0,
       skippedDelta = 0,
       seenId = null,
       wrongCountId = null,
       minimumCorrect = null,
       minimumWrong = null,
       minimumSkipped = null,
       restoreSeenIds = const <String>[],
       restoreWrongCountJson = null,
       restoreWrongCountOnlyIfEmpty = false,
       assertCurrentWrite = null,
       isRestore = false,
       _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._vocabProgressAttemptEpoch;

  VocabProgressAttempt._restore({
    this.minimumCorrect,
    this.minimumWrong,
    this.minimumSkipped,
    this.cursor,
    required this.restoreSeenIds,
    this.restoreWrongCountJson,
    this.restoreWrongCountOnlyIfEmpty = true,
    this.assertCurrentWrite,
  }) : correctDelta = 0,
       wrongDelta = 0,
       skippedDelta = 0,
       absoluteCorrect = null,
       absoluteWrong = null,
       absoluteSkipped = null,
       seenId = null,
       wrongCountId = null,
       bypassLearningWriteLock = true,
       isRestore = true,
       _lifetime = LocalDataLifetime.capture(),
       _epoch = Storage._vocabProgressAttemptEpoch;

  final int correctDelta;
  final int wrongDelta;
  final int skippedDelta;
  final int? cursor;
  final String? seenId;
  final String? wrongCountId;
  final int? minimumCorrect;
  final int? minimumWrong;
  final int? minimumSkipped;
  final int? absoluteCorrect;
  final int? absoluteWrong;
  final int? absoluteSkipped;
  final List<String> restoreSeenIds;
  final String? restoreWrongCountJson;
  final bool restoreWrongCountOnlyIfEmpty;
  final void Function()? assertCurrentWrite;
  final bool bypassLearningWriteLock;
  final bool isRestore;
  final LocalDataLifetimeLease _lifetime;
  final int _epoch;

  bool _correctSaved = false;
  bool _wrongSaved = false;
  bool _skippedSaved = false;
  bool _cursorSaved = false;
  bool _seenSaved = false;
  bool _wrongCountSaved = false;
  bool _restoreCursorEligible = false;
  bool _restoreEligibilityCaptured = false;
  bool _completed = false;

  bool get _isCurrent =>
      _lifetime.isCurrent && _epoch == Storage._vocabProgressAttemptEpoch;

  void _assertCurrent() {
    _lifetime.assertCurrent();
    if (_epoch != Storage._vocabProgressAttemptEpoch) {
      throw const StaleLocalDataLifetimeException();
    }
    assertCurrentWrite?.call();
    _lifetime.assertCurrent();
  }

  Future<bool> save() => Storage._enqueueVocabProgressMutation(
    () => Storage._saveVocabProgressAttempt(this),
  );
}

enum _VocabPreferenceKind { integer, string, stringList }

class _PendingVocabPreferenceWrite {
  _PendingVocabPreferenceWrite({
    required this.generation,
    required this.key,
    required this.kind,
    required this.store,
    required this.before,
    required this.after,
    required this.assertOriginCurrent,
    required this._confirm,
  });

  final int generation;
  final String key;
  final _VocabPreferenceKind kind;
  final Object store;
  final Object before;
  final Object after;
  final void Function() assertOriginCurrent;
  final void Function() _confirm;
  bool sharedCacheReloaded = false;

  void confirm() {
    _confirm();
    if (sharedCacheReloaded) {
      Storage._confirmedVocabAfterReloadKeys.add(key);
    }
  }
}

class _PronunciationProgressRecord {
  const _PronunciationProgressRecord({
    required this.count,
    required this.assessmentIds,
    required this.lastScore,
  });

  final int count;
  final List<String> assessmentIds;
  final double lastScore;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 2,
    'count': count,
    'assessmentIds': assessmentIds,
    'lastScore': lastScore,
  };

  static _PronunciationProgressRecord? tryParse(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    try {
      final value = jsonDecode(raw);
      if (value is! Map || value['version'] != 2) {
        return null;
      }
      final count = value['count'];
      final score = value['lastScore'];
      final rawIds = value['assessmentIds'];
      if (count is! int ||
          count < 0 ||
          count > 100 ||
          score is! num ||
          !score.isFinite ||
          rawIds is! List) {
        return null;
      }
      final ids = <String>[];
      for (final value in rawIds) {
        if (value is! String) {
          return null;
        }
        final id = value.trim();
        if (id.isEmpty || id.length > 128 || ids.contains(id)) {
          return null;
        }
        ids.add(id);
      }
      // Legacy recovery can know that more passes were earned than the older
      // split-key journal retained assessment IDs for. IDs are only the
      // duplicate-prevention ledger, so they may trail the authoritative count
      // but must never exceed it.
      if (ids.length > count) {
        return null;
      }
      return _PronunciationProgressRecord(
        count: count,
        assessmentIds: List.unmodifiable(ids),
        lastScore: score.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persistente Speicherung — Lernfortschritt, Spielstand, Einstellungen.
/// Alle Schlüssel mit Präfix `kl_`. iOS und Android automatisch (über
/// `SharedPreferences`, das auf iOS `NSUserDefaults` nutzt).
class Storage {
  static const accountDeletionCheckpointPreferenceKey =
      'kl_account_deletion_journal_v1';
  static const accountDeletionFeedbackActivationCheckpointPreferenceKey =
      'kl_account_deletion_feedback_activation_v1';
  static const cloudBackupDeletionJournalPreferenceKey =
      'kl_cloud_backup_deletion_journal_v1';
  static const _durableAccountJournalPreferenceKeys = <String>{
    AccountSwitchJournal.storageKey,
    AccountTransitionJournal.switchReconciliationStorageKey,
    accountDeletionCheckpointPreferenceKey,
    accountDeletionFeedbackActivationCheckpointPreferenceKey,
    cloudBackupDeletionJournalPreferenceKey,
  };
  static const String _pickerRecoveryMarkerKey = 'kl_picker_recovery_marker_v1';
  static const String _cropRecoveryMarkerKey = 'kl_crop_recovery_marker_v1';
  static const String _recoveredBookLeaseKey = 'kl_recovered_book_lease';
  static const String _recoveredWordLeaseKey = 'kl_recovered_word_lease';
  static const String listeningRewardLedgerPreferenceKey =
      'kl_xp_reward_ledger_v1';
  static const String consentedFirstLearningActionClaimPreferenceKey =
      'kl_consented_first_learning_action_claim_v1';
  static const String _consentedFirstLearningActionClaimValue = 'claimed';
  static const String scenarioCorpusGenerationPreferenceKey =
      'kl_scenario_corpus_generation_v1';

  static SharedPreferences? _prefs;
  static Future<void> _recoveredBookMutation = Future<void>.value();
  static Future<void> _recoveredWordMutation = Future<void>.value();
  static Future<void> _pronunciationProgressMutation = Future<void>.value();
  static Future<void> _catalogHistoryMutation = Future<void>.value();
  static int _catalogHistoryMutationCount = 0;
  static int _catalogHistoryGeneration = 0;
  static int _catalogHistoryResetting = 0;
  static final catalogHistoryChanges = ValueNotifier<int>(0);
  static Future<void> _xpRewardMutation = Future<void>.value();
  static Future<void> _packProgressMutation = Future<void>.value();
  static Future<void> _srsReviewMutation = Future<void>.value();
  static Future<void> _vocabProgressMutation = Future<void>.value();
  static Future<void>? _grammarPlanMutation;
  static Future<void>? _learningResetMutation;
  static Future<void>? _dataMigrationMutation;
  static Future<void> _consentedFirstLearningActionClaimMutation =
      Future<void>.value();
  static int _xpRewardMutationCount = 0;
  static int _xpRewardMutationGeneration = 0;
  static int _learningResetCount = 0;

  /// The migration owns actual native work through its rollback/cleanup.
  /// Register before invoking it so a reset cannot delete beneath that work.
  static Future<T> trackDataMigration<T>({
    required Future<T> Function() action,
    required T Function() onBlocked,
  }) {
    if (_learningResetCount > 0 || _dataMigrationMutation != null) {
      return Future<T>.value(onBlocked());
    }
    final completion = Completer<T>();
    final drain = completion.future.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _dataMigrationMutation = drain;
    unawaited(
      drain.then((_) {
        if (identical(_dataMigrationMutation, drain)) {
          _dataMigrationMutation = null;
        }
      }),
    );
    unawaited(
      Future<T>.sync(
        action,
      ).then<void>(completion.complete, onError: completion.completeError),
    );
    return completion.future;
  }

  static bool _xpRewardWritePending = false;
  static _XpRewardLedger? _confirmedXpRewardLedger;
  static int _xpAwardEpoch = 0;
  static _PendingOrdinaryXpWrite? _pendingOrdinaryXpWrite;
  static Map<String, int>? _confirmedGameBests;
  static bool _gameBestWritePending = false;
  static ({GameBestAttempt attempt, String before, String after})?
  _pendingGameBestWrite;
  static final Map<String, List<String>> _confirmedRewardLists = {};
  static final Set<String> _pendingRewardListKeys = {};
  static int _srsReviewMutationCount = 0;
  static int _srsReviewMutationGeneration = 0;
  static int _srsAttemptEpoch = 0;
  static final srsRecoveryStatus = ValueNotifier(SrsRecoveryStatus.ready);
  static SrsCommitJournal? _srsJournal;
  static ({String before, String after, String evidenceKey})? _srsNormalization;
  static SrsReviewAttempt? _srsJournalAttempt;
  static bool _srsRecoveryInitialized = false;
  static bool _srsRecoveryClosed = false;
  static Future<bool>? _activeSrsRecovery;
  static bool get srsRecoveryPending => _srsRecoveryClosed;

  /// A synchronous capture cannot include a half-committed SRS/history pair.
  static void assertSrsSnapshotReady() {
    if (_srsRecoveryClosed ||
        _srsReviewMutationCount > 0 ||
        _learningResetCount > 0) {
      throw const SrsRecoveryPendingException();
    }
  }

  // Init establishes admission and a confirmed before-view synchronously from
  // the loaded native snapshot. Reconciliation runs only behind first frame.
  static void _initializeSrsRecoveryView() {
    _srsRecoveryInitialized = true;
    if (!(_prefs?.containsKey(SrsCommitJournal.key) ?? false)) {
      return;
    }
    _srsRecoveryClosed = true;
    try {
      _srsJournal = SrsCommitJournal.decode(_prefs!.get(SrsCommitJournal.key));
      srsRecoveryStatus.value = SrsRecoveryStatus.pending;
    } on Object catch (error) {
      _srsJournal = null;
      srsRecoveryStatus.value = SrsRecoveryStatus.blocked;
      debugPrint('Storage: invalid SRS recovery record retained: $error');
    }
    _invalidateSrsCache();
  }

  /// One bounded UI wait; an unresponsive native call retains the serialized
  /// operation and admission fence. Retry never overlaps that native writer.
  static Future<bool> retrySrsRecovery() {
    final active = _activeSrsRecovery;
    if (active != null) {
      return active.timeout(const Duration(seconds: 5), onTimeout: () => false);
    }
    if (!_srsRecoveryClosed) {
      return Future.value(true);
    }
    final operation = _enqueueSrsReviewMutation(_recoverSrsCommit);
    _activeSrsRecovery = operation;
    operation.then((_) {
      if (identical(_activeSrsRecovery, operation)) {
        _activeSrsRecovery = null;
      }
    });
    return operation.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        srsRecoveryStatus.value = SrsRecoveryStatus.retryRequired;
        return false;
      },
    );
  }

  static void _finishSrsRecovery({required bool completed}) {
    if (completed &&
        _learningResetCount == 0 &&
        (_srsJournalAttempt?._isCurrent ?? false)) {
      _srsJournalAttempt!._completed = true;
    }
    _srsJournal = null;
    _srsNormalization = null;
    _srsJournalAttempt = null;
    _srsRecoveryClosed = false;
    _unknownStrictKeys.remove('kl_srs_v1');
    _invalidateSrsCache();
    srsRecoveryStatus.value = SrsRecoveryStatus.ready;
  }

  static bool _srsReplayPrecedenceBlocked(SharedPreferences prefs) =>
      _learningWritesLockReason != null ||
      _durableAccountJournalPreferenceKeys.any(prefs.containsKey) ||
      prefs.containsKey('kl_migration_journal_v1') ||
      prefs.containsKey('kl_migration_backup_v1');

  static Future<bool> _recoverSrsCommit(
    int generation, {
    bool cancelUnapplied = false,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return false;
    }
    final deckStore = _srsPersistenceStoreForTesting ?? _stringStore();
    final historyStore =
        _studyLogStoreForTesting ?? _SharedPreferenceStringListStore(prefs);
    srsRecoveryStatus.value = SrsRecoveryStatus.recovering;
    try {
      await prefs.reload();
      if (generation != _srsReviewMutationGeneration) {
        return false;
      }
      if (_srsReplayPrecedenceBlocked(prefs)) {
        srsRecoveryStatus.value = SrsRecoveryStatus.blocked;
        return false;
      }
      if (_srsNormalization != null) {
        return _recoverSrsNormalization(generation, deckStore);
      }
      final raw = prefs.get(SrsCommitJournal.key);
      if (raw == null) {
        // Removal may have committed before its acknowledgement was lost.
        // Only an in-memory obligation with confirmed final effects can close.
        final journal = _srsJournal;
        if (journal == null) {
          throw const SrsRecoveryPendingException();
        }
        final completed = await _srsEffectsMatch(
          journal,
          deckStore,
          historyStore,
          after: true,
        );
        if (!completed &&
            !await _srsEffectsMatch(
              journal,
              deckStore,
              historyStore,
              after: false,
            )) {
          throw const SrsRecoveryPendingException();
        }
        if (generation != _srsReviewMutationGeneration) {
          return false;
        }
        // A lost intent acknowledgement or a lost pre-effect cancellation
        // reply may leave no journal and exactly the original native values.
        _finishSrsRecovery(completed: completed);
        return completed && _learningResetCount == 0;
      }
      final journal = SrsCommitJournal.decode(raw);
      if (_srsJournal != null && _srsJournal!.encode() != journal.encode()) {
        throw const FormatException('SRS journal changed externally.');
      }
      _srsJournal = journal;
      await deckStore.reload();
      if (journal.recordHistory) {
        await historyStore.reload();
      }
      final deck = _StringPreferenceState.read(deckStore, 'kl_srs_v1').value;
      final history = journal.recordHistory
          ? _StringListPreferenceState.read(
              historyStore,
              journal.historyKey,
            ).value
          : null;
      if ((deck != journal.beforeDeck && deck != journal.afterDeck) ||
          (journal.recordHistory &&
              !_preferenceValueEquals(history, journal.beforeHistory) &&
              !_preferenceValueEquals(history, journal.afterHistory))) {
        throw const FormatException('Conflicting native SRS/history effects.');
      }
      if (generation != _srsReviewMutationGeneration) {
        return false;
      }
      if (deck != journal.afterDeck) {
        try {
          await deckStore.setString('kl_srs_v1', journal.afterDeck);
        } on Object catch (error) {
          debugPrint('Storage: SRS native reply unavailable: $error');
        }
        if (generation != _srsReviewMutationGeneration) {
          await _restoreStaleSrsPrimaryWrite(
            store: deckStore,
            before: journal.beforeDeck == null
                ? const _StringPreferenceState.absent()
                : _StringPreferenceState._(
                    isPresent: true,
                    value: journal.beforeDeck,
                  ),
            attemptedJson: journal.afterDeck,
          );
          return false;
        }
        await deckStore.reload();
        if (_StringPreferenceState.read(deckStore, 'kl_srs_v1').value !=
            journal.afterDeck) {
          // A definitive rejection before either effect can cancel admission.
          // This is never used for unknown reads or an in-flight setter.
          if (cancelUnapplied &&
              await _srsEffectsMatch(
                journal,
                deckStore,
                historyStore,
                after: false,
              )) {
            await _removeSrsJournal(prefs, journal);
            _finishSrsRecovery(completed: false);
          }
          throw const SrsRecoveryPendingException();
        }
      }
      if (_learningWritesLockReason != null) {
        throw const SrsRecoveryPendingException();
      }
      if (journal.recordHistory) {
        // A native/external writer may have changed history while the deck
        // setter was pending. Never overwrite a third value from that window.
        await historyStore.reload();
        final currentHistory = _StringListPreferenceState.read(
          historyStore,
          journal.historyKey,
        ).value;
        if (!_preferenceValueEquals(currentHistory, journal.beforeHistory) &&
            !_preferenceValueEquals(currentHistory, journal.afterHistory)) {
          throw const FormatException('History changed before its effect.');
        }
        if (!_preferenceValueEquals(currentHistory, journal.afterHistory)) {
          try {
            await historyStore.setStringList(
              journal.historyKey,
              journal.afterHistory!,
            );
          } on Object catch (error) {
            debugPrint('Storage: history native reply unavailable: $error');
          }
        }
      }
      if (!await _srsEffectsMatch(
        journal,
        deckStore,
        historyStore,
        after: true,
      )) {
        throw const SrsRecoveryPendingException();
      }
      if (generation != _srsReviewMutationGeneration) {
        return false;
      }
      await _removeSrsJournal(prefs, journal);
      if (generation != _srsReviewMutationGeneration) {
        return false;
      }
      _finishSrsRecovery(completed: true);
      // Separate injected stores need the confirmed deck mirror too.
      _loadSrs(confirmedRaw: journal.afterDeck);
      return _learningResetCount == 0;
    } on Object catch (error) {
      if (generation == _srsReviewMutationGeneration && _srsRecoveryClosed) {
        srsRecoveryStatus.value = error is FormatException || error is TypeError
            ? SrsRecoveryStatus.blocked
            : SrsRecoveryStatus.retryRequired;
      }
      debugPrint('Storage: SRS recovery retained for retry: $error');
      return false;
    }
  }

  static Future<bool> _srsEffectsMatch(
    SrsCommitJournal journal,
    PreferenceStringStore deckStore,
    PreferenceStringListStore historyStore, {
    required bool after,
  }) async {
    await deckStore.reload();
    final deck = _StringPreferenceState.read(deckStore, 'kl_srs_v1').value;
    if (deck != (after ? journal.afterDeck : journal.beforeDeck)) {
      return false;
    }
    if (!journal.recordHistory) {
      return true;
    }
    await historyStore.reload();
    return _preferenceValueEquals(
      _StringListPreferenceState.read(historyStore, journal.historyKey).value,
      after ? journal.afterHistory : journal.beforeHistory,
    );
  }

  /// Structural repair precedes judgment admission. The retained source is
  /// durable evidence; neither this step nor its retry advances a card/history.
  static Future<bool> _recoverSrsNormalization(
    int generation,
    PreferenceStringStore store,
  ) async {
    final repair = _srsNormalization!;
    try {
      await _prefs!.reload();
      if (_srsReplayPrecedenceBlocked(_prefs!) ||
          _prefs!.containsKey(SrsCommitJournal.key)) {
        srsRecoveryStatus.value = SrsRecoveryStatus.blocked;
        return false;
      }
      await store.reload();
      var deck = _StringPreferenceState.read(store, 'kl_srs_v1').value;
      if (deck != repair.before && deck != repair.after) {
        throw const FormatException('SRS changed during structural repair.');
      }
      final evidence = _StringPreferenceState.read(store, repair.evidenceKey);
      if (evidence.isPresent && evidence.value != repair.before) {
        throw const FormatException('SRS retained-copy key already differs.');
      }
      if (generation != _srsReviewMutationGeneration ||
          _learningWritesLockReason != null) {
        return false;
      }
      if (!evidence.isPresent) {
        try {
          await store.setString(repair.evidenceKey, repair.before);
        } on Object catch (error) {
          debugPrint('Storage: SRS retained-copy reply unavailable: $error');
        }
        await store.reload();
        if (_StringPreferenceState.read(store, repair.evidenceKey).value !=
            repair.before) {
          throw const SrsRecoveryPendingException();
        }
      }
      // Preservation may have waited on native I/O. Recheck both the source
      // and transition precedence before any structural overwrite.
      await _prefs!.reload();
      await store.reload();
      if (generation != _srsReviewMutationGeneration ||
          _srsReplayPrecedenceBlocked(_prefs!) ||
          _prefs!.containsKey(SrsCommitJournal.key)) {
        srsRecoveryStatus.value = SrsRecoveryStatus.blocked;
        return false;
      }
      if (_StringPreferenceState.read(store, repair.evidenceKey).value !=
          repair.before) {
        throw const SrsRecoveryPendingException();
      }
      deck = _StringPreferenceState.read(store, 'kl_srs_v1').value;
      if (deck != repair.before && deck != repair.after) {
        throw const FormatException('SRS changed before normalization.');
      }
      if (deck != repair.after) {
        try {
          await store.setString('kl_srs_v1', repair.after);
        } on Object catch (error) {
          debugPrint('Storage: SRS normalization reply unavailable: $error');
        }
      }
      await store.reload();
      if (_StringPreferenceState.read(store, 'kl_srs_v1').value !=
              repair.after ||
          _StringPreferenceState.read(store, repair.evidenceKey).value !=
              repair.before) {
        throw const SrsRecoveryPendingException();
      }
      if (generation != _srsReviewMutationGeneration) {
        return false;
      }
      _finishSrsRecovery(completed: false);
      return true;
    } on Object catch (error) {
      srsRecoveryStatus.value = error is FormatException || error is TypeError
          ? SrsRecoveryStatus.blocked
          : SrsRecoveryStatus.retryRequired;
      debugPrint('Storage: SRS structural repair retained for retry: $error');
      return false;
    }
  }

  static Future<void> _removeSrsJournal(
    SharedPreferences prefs,
    SrsCommitJournal journal,
  ) async {
    await prefs.reload();
    if (prefs.get(SrsCommitJournal.key) != journal.encode()) {
      throw const FormatException('SRS journal changed before retirement.');
    }
    try {
      await prefs.remove(SrsCommitJournal.key);
    } on Object catch (error) {
      debugPrint('Storage: SRS journal removal reply unavailable: $error');
    }
    await prefs.reload();
    if (prefs.containsKey(SrsCommitJournal.key)) {
      throw const SrsRecoveryPendingException();
    }
  }

  static int _vocabProgressMutationCount = 0;
  static int _vocabProgressMutationGeneration = 0;
  static int _vocabProgressAttemptEpoch = 0;
  static int _grammarPlanMutationCount = 0;
  static int _grammarPlanMutationGeneration = 0;
  static int _grammarPlanAdmissionRevision = 0;
  static int _confirmedGrammarPlanLevelRevision = 0;
  static bool _grammarPlanConfirmedViewInitialized = false;
  static String _confirmedGrammarPlanRaw = '';
  static String? _confirmedGrammarPlanLevel;
  static final Set<String> _unconfirmedGrammarPlanLevels = <String>{};
  static final Map<String, int> _confirmedVocabInts = <String, int>{};
  static final Set<String> _confirmedVocabAfterReloadKeys = <String>{};
  // These intervals own actual cache reads, not a logical learning generation.
  // Reset may retire a writer while an old read still targets the same cache.
  static final Map<SharedPreferences, int> _packCompletionReloads =
      Map.identity();
  static List<String>? _confirmedVokSeenIds;
  static String? _confirmedWrongCountRaw;
  static _PendingVocabPreferenceWrite? _pendingVocabPreferenceWrite;
  static final Map<String, _PendingVocabPreferenceWrite>
  _quarantinedVocabPreferenceWrites = <String, _PendingVocabPreferenceWrite>{};
  static final Map<String, _StringListPreferenceState> _confirmedChoiceStates =
      <String, _StringListPreferenceState>{};
  static final Map<String, int> _confirmedChoiceRevisions = <String, int>{};
  static final Map<String, Future<void>> _confirmedChoiceMutations =
      <String, Future<void>>{};
  static int _confirmedChoiceEpoch = 0;
  static int _confirmedChoiceMutationCount = 0;
  static int _confirmedChoiceMutationGeneration = 0;
  // `resetForTesting()` remains synchronous for its many callers, but a new
  // preference boundary must not open while an old SRS transaction can still
  // complete a platform write or its rollback.
  static Future<void>? _srsResetDrainBarrier;
  static bool _srsResetDrainPending = false;
  static final Set<String> _pendingListeningRewardClaims = <String>{};
  static final Set<String> _unknownStrictKeys = <String>{};
  static String? _courseMasteryCache;
  static int _tutorialResetRevision = 0;
  static PreferenceStringStore? _srsPersistenceStoreForTesting;
  static PreferenceStringListStore? _studyLogStoreForTesting;
  static PreferenceStringStore? _grammarPlanStoreForTesting;

  /// In `main()` vor `runApp` aufrufen.
  static Future<void> init() async {
    final resetDrain = _srsResetDrainBarrier;
    if (resetDrain != null) {
      await resetDrain;
      if (identical(resetDrain, _srsResetDrainBarrier)) {
        _srsResetDrainBarrier = null;
        _srsResetDrainPending = false;
      }
    }
    _prefs ??= await SharedPreferences.getInstance();
    PrivacyChoiceStorage.initialize();
    PackCompletionStorage.initialize();
    if (!_srsRecoveryInitialized) {
      _initializeSrsRecoveryView();
    }
  }

  /// Test-only: leert den `_prefs`-Cache, damit ein neuer
  /// `SharedPreferences.setMockInitialValues(...)` plus `Storage.init()`
  /// frische Werte liefert. Im Produktionscode niemals aufrufen.
  @visibleForTesting
  static void resetForTesting() {
    CatalogHistoryLease.resetForTesting();
    final privacyDrain = PrivacyChoiceStorage.drain();
    final privacyHasWrites = PrivacyChoiceStorage._native.isNotEmpty;
    PrivacyChoiceStorage.reset();
    PackCompletionStorage.resetForTesting();
    _packProgressMutation = Future<void>.value();
    _packProgressMutationCount = 0;
    final drains = <Future<void>>[if (privacyHasWrites) privacyDrain];
    final previousResetDrain = _srsResetDrainBarrier;
    if (_srsResetDrainPending && previousResetDrain != null) {
      drains.add(previousResetDrain);
    }
    if (_srsReviewMutationCount > 0) {
      drains.add(
        _srsReviewMutation.then<void>(
          (_) {},
          onError: (Object _, StackTrace __) {},
        ),
      );
    }
    if (_xpRewardMutationCount > 0) {
      drains.add(_xpRewardMutation);
    }
    if (_vocabProgressMutationCount > 0) {
      drains.add(_vocabProgressMutation);
    }
    final grammarPlanMutation = _grammarPlanMutation;
    if (_grammarPlanMutationCount > 0 && grammarPlanMutation != null) {
      drains.add(grammarPlanMutation);
    }
    if (_confirmedChoiceMutationCount > 0) {
      drains.addAll(_confirmedChoiceMutations.values);
    }
    final learningReset = _learningResetMutation;
    if (_dataMigrationMutation case final migration?) {
      drains.add(migration);
    }
    if (_learningResetCount > 0 && learningReset != null) {
      drains.add(
        learningReset.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      );
    }
    if (_catalogHistoryMutationCount > 0) {
      drains.add(_catalogHistoryMutation);
    }
    _catalogHistoryGeneration++;
    if (drains.isEmpty) {
      // Do not carry even a completed Future into the next widget-test
      // fake-async zone. With no old SRS work, init must enter the new
      // SharedPreferences boundary directly in its caller's zone.
      _srsResetDrainBarrier = null;
      _srsResetDrainPending = false;
    } else {
      final resetDrain = Future.wait<void>(drains);
      _srsResetDrainBarrier = resetDrain;
      _srsResetDrainPending = true;
      void clearCompletedDrain() {
        if (identical(resetDrain, _srsResetDrainBarrier)) {
          _srsResetDrainBarrier = null;
          _srsResetDrainPending = false;
        }
      }

      resetDrain.then<void>(
        (_) => clearCompletedDrain(),
        onError: (Object _, StackTrace __) => clearCompletedDrain(),
      );
    }
    _prefs = null;
    _srsRecoveryInitialized = false;
    _srsRecoveryClosed = false;
    _srsJournal = null;
    _srsJournalAttempt = null;
    _activeSrsRecovery = null;
    _srsNormalization = null;
    srsRecoveryStatus.value = SrsRecoveryStatus.ready;
    _invalidateSrsCache();
    // 팩 캐시도 함께 버린다. 안 그러면 앞 테스트가 채운 `_packCache` 가
    // 다음 테스트의 `setMockInitialValues` 를 덮어써 "새 Storage" 라는 이 함수의
    // 계약이 깨진다(격리 회귀에서 실제로 잡혔다).
    _invalidatePackCache();
    _recoveredBookMutation = Future<void>.value();
    _recoveredWordMutation = Future<void>.value();
    _pronunciationProgressMutation = Future<void>.value();
    _catalogHistoryMutation = Future<void>.value();
    _catalogHistoryMutationCount = 0;
    _catalogHistoryResetting = 0;
    _xpRewardMutation = Future<void>.value();
    _srsReviewMutation = Future<void>.value();
    _vocabProgressMutation = Future<void>.value();
    _grammarPlanMutation = null;
    _learningResetMutation = null;
    _consentedFirstLearningActionClaimMutation = Future<void>.value();
    _xpRewardMutationCount = 0;
    _xpRewardMutationGeneration++;
    _learningResetCount = 0;
    _xpRewardWritePending = false;
    _confirmedXpRewardLedger = null;
    _xpAwardEpoch++;
    _pendingOrdinaryXpWrite = null;
    _confirmedGameBests = null;
    _gameBestWritePending = false;
    _pendingGameBestWrite = null;
    _confirmedRewardLists.clear();
    _pendingRewardListKeys.clear();
    _srsReviewMutationCount = 0;
    _srsReviewMutationGeneration++;
    _invalidateSrsAttempts();
    _vocabProgressMutationCount = 0;
    _vocabProgressMutationGeneration++;
    _vocabProgressAttemptEpoch++;
    _grammarPlanMutationCount = 0;
    _grammarPlanMutationGeneration++;
    _grammarPlanAdmissionRevision++;
    _confirmedGrammarPlanLevelRevision = _grammarPlanAdmissionRevision;
    _grammarPlanConfirmedViewInitialized = false;
    _confirmedGrammarPlanRaw = '';
    _confirmedGrammarPlanLevel = null;
    _unconfirmedGrammarPlanLevels.clear();
    _confirmedVocabInts.clear();
    _confirmedVocabAfterReloadKeys.clear();
    _confirmedVokSeenIds = null;
    _confirmedWrongCountRaw = null;
    _pendingVocabPreferenceWrite = null;
    _quarantinedVocabPreferenceWrites.clear();
    _confirmedChoiceEpoch++;
    _confirmedChoiceMutationGeneration++;
    _confirmedChoiceMutationCount = 0;
    _confirmedChoiceMutations.clear();
    _confirmedChoiceRevisions.clear();
    _confirmedChoiceStates.clear();
    _pendingListeningRewardClaims.clear();
    MediaMutationLock.resetForTesting();
    _unknownStrictKeys.clear();
    _srsPersistenceStoreForTesting = null;
    _studyLogStoreForTesting = null;
    _grammarPlanStoreForTesting = null;
    _courseMasteryCache = null;
    _wrongCountCache = null;
    _learningWritesLockReason = null;
    _scenarioStarsCache = null;
    _completedScenariosCache = null;
  }

  /// 이 클래스를 거치지 않고 `SharedPreferences` 가 직접 수정된 뒤 캐시를 버린다.
  ///
  /// 마이그레이션 롤백처럼 저장소를 밖에서 되돌린 경우에 쓴다. [resetForTesting]
  /// 과 달리 `_prefs` 핸들은 유지하므로 재초기화가 필요 없다.
  static void resetCachesAfterExternalWrite() {
    // A draining migration may invalidate caches while deletion still owns
    // the reset fence. Only the reset's finalizer may release that fence.
    PrivacyChoiceStorage.retire(close: _learningResetCount > 0);
    unawaited(PrivacyChoiceStorage.refresh());
    // Cache invalidation cannot release an unresolved recovery obligation.
    if (!_srsRecoveryClosed) {
      _initializeSrsRecoveryView();
    }
    _pendingGameBestWrite = null;
    _confirmedGameBests = null;
    _gameBestWritePending = false;
    _xpAwardEpoch++;
    _pendingOrdinaryXpWrite = null;
    _invalidateSrsAttempts();
    _confirmedXpRewardLedger = null;
    _confirmedRewardLists.clear();
    _vocabProgressAttemptEpoch++;
    _confirmedVocabInts.clear();
    _confirmedVocabAfterReloadKeys.clear();
    _confirmedVokSeenIds = null;
    _confirmedWrongCountRaw = null;
    _pendingVocabPreferenceWrite = null;
    _quarantinedVocabPreferenceWrites.clear();
    _confirmedChoiceEpoch++;
    _confirmedChoiceRevisions.clear();
    _confirmedChoiceStates.clear();
    _grammarPlanConfirmedViewInitialized = false;
    _grammarPlanAdmissionRevision++;
    _confirmedGrammarPlanLevelRevision = _grammarPlanAdmissionRevision;
    _confirmedGrammarPlanRaw = '';
    _confirmedGrammarPlanLevel = null;
    _unconfirmedGrammarPlanLevels.clear();
    _invalidateSrsCache();
    _invalidatePackCache();
    _courseMasteryCache = null;
    _wrongCountCache = null;
    _scenarioStarsCache = null;
    _completedScenariosCache = null;
  }

  // ───────── Generic helpers ─────────
  static int _i(String k) => (PackCompletionStorage.read(k) as int?) ?? 0;
  static String _s(String k) =>
      (PackCompletionStorage.read(k) as String?) ?? '';
  static double _d(String k, [double dflt = 0]) => _prefs?.getDouble(k) ?? dflt;
  static List<String> _l(String k) =>
      (PackCompletionStorage.read(k) as List?)?.cast<String>().toList() ?? [];

  static Future<void> _si(String k, int v) =>
      PackCompletionStorage.trackWrite(k, () async {
        await _prefs?.setInt(k, v);
      });

  static Future<void> _ss(String k, String v) =>
      PackCompletionStorage.trackWrite(k, () async {
        await _prefs?.setString(k, v);
      });

  static int _admitGrammarPlanOperation() {
    if (_learningResetCount > 0) {
      throw const StaleLocalDataLifetimeException();
    }
    _captureGrammarPlanConfirmedView();
    return ++_grammarPlanAdmissionRevision;
  }

  static void _captureGrammarPlanConfirmedView() {
    if (_grammarPlanConfirmedViewInitialized) {
      return;
    }
    try {
      _confirmedGrammarPlanRaw = _s('kl_gram_plan_v1');
    } on Object {
      // A legacy wrong-typed value is recovery data. Keep it on disk for the
      // restore/semantic writer to reject without exposing it as confirmed.
      _confirmedGrammarPlanRaw = '';
    }
    try {
      _confirmedGrammarPlanLevel = _optionalLearnerLevelCode(
        grammarPlanLevelPreferenceKey,
      );
    } on Object {
      _confirmedGrammarPlanLevel = null;
    }
    _grammarPlanConfirmedViewInitialized = true;
  }

  static Future<T> _enqueueGrammarPlanMutation<T>(
    Future<T> Function() mutation,
  ) {
    if (_learningResetCount > 0) {
      return Future<T>.error(const StaleLocalDataLifetimeException());
    }
    final generation = _grammarPlanMutationGeneration;
    final previous = _grammarPlanMutation;
    _grammarPlanMutationCount++;
    late final Future<T> result;
    if (previous == null) {
      try {
        result = mutation();
      } on Object catch (error, stackTrace) {
        result = Future<T>.error(error, stackTrace);
      }
    } else {
      result = previous.then<T>((_) => mutation());
    }
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _grammarPlanMutation = tail;
    tail.whenComplete(() {
      if (generation == _grammarPlanMutationGeneration) {
        _grammarPlanMutationCount--;
        if (identical(tail, _grammarPlanMutation)) {
          _grammarPlanMutation = null;
        }
      }
    });
    return result;
  }

  static Future<T> _enqueueXpRewardMutation<T>(Future<T> Function() mutation) {
    if (_learningResetCount > 0) {
      return Future<T>.error(const StaleLocalDataLifetimeException());
    }
    PackCompletionStorage.assertAdmission();
    final generation = _xpRewardMutationGeneration;
    // SharedPreferences updates its in-memory cache when a setter is invoked,
    // before its returned Future completes. Existing game screens rely on that
    // visibility because several legacy XP calls are intentionally
    // fire-and-forget. Start an idle queue eagerly to preserve that contract;
    // only later mutations wait for the current tail.
    final startsImmediately = _xpRewardMutationCount == 0;
    _xpRewardMutationCount++;

    late final Future<T> result;
    if (startsImmediately) {
      try {
        result = mutation();
      } on Object catch (error, stackTrace) {
        result = Future<T>.error(error, stackTrace);
      }
    } else {
      result = _xpRewardMutation.then<T>((_) => mutation());
    }
    _xpRewardMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    result.then<void>(
      (_) {
        if (generation == _xpRewardMutationGeneration) {
          _xpRewardMutationCount--;
        }
      },
      onError: (Object _, StackTrace __) {
        if (generation == _xpRewardMutationGeneration) {
          _xpRewardMutationCount--;
        }
      },
    );
    return result;
  }

  static Future<bool> _enqueueSrsReviewMutation(
    Future<bool> Function(int generation) mutation,
  ) {
    if (_learningResetCount > 0) {
      return Future<bool>.value(false);
    }
    // Start an idle queue immediately, but expose only the confirmed pair.
    // Overlapping reviews wait for journal settlement or an honest failure;
    // an unresolved obligation retains its independent admission fence.
    final generation = _srsReviewMutationGeneration;
    final startsImmediately = _srsReviewMutationCount == 0;
    _srsReviewMutationCount++;

    Future<bool> runCurrentMutation() {
      if (generation != _srsReviewMutationGeneration) {
        return Future<bool>.value(false);
      }
      try {
        return mutation(generation);
      } on Object catch (error, stackTrace) {
        return Future<bool>.error(error, stackTrace);
      }
    }

    late final Future<bool> result;
    if (startsImmediately) {
      result = runCurrentMutation();
    } else {
      result = _srsReviewMutation.then<bool>((_) => runCurrentMutation());
    }
    _srsReviewMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    result.then<void>(
      (_) {
        if (generation == _srsReviewMutationGeneration) {
          _srsReviewMutationCount--;
        }
      },
      onError: (Object _, StackTrace __) {
        if (generation == _srsReviewMutationGeneration) {
          _srsReviewMutationCount--;
        }
      },
    );
    return result;
  }

  static Future<bool> _enqueueVocabProgressMutation(
    Future<bool> Function() mutation,
  ) {
    if (_learningResetCount > 0) {
      return Future<bool>.error(const StaleLocalDataLifetimeException());
    }
    final generation = _vocabProgressMutationGeneration;
    final startsImmediately = _vocabProgressMutationCount == 0;
    _vocabProgressMutationCount++;

    Future<bool> runCurrentMutation() {
      if (generation != _vocabProgressMutationGeneration) {
        return Future<bool>.error(const StaleLocalDataLifetimeException());
      }
      try {
        return mutation();
      } on Object catch (error, stackTrace) {
        return Future<bool>.error(error, stackTrace);
      }
    }

    late final Future<bool> result;
    if (startsImmediately) {
      result = runCurrentMutation();
    } else {
      result = _vocabProgressMutation.then<bool>((_) => runCurrentMutation());
    }
    _vocabProgressMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    result.then<void>(
      (_) {
        if (generation == _vocabProgressMutationGeneration) {
          _vocabProgressMutationCount--;
        }
      },
      onError: (Object _, StackTrace __) {
        if (generation == _vocabProgressMutationGeneration) {
          _vocabProgressMutationCount--;
        }
      },
    );
    return result;
  }

  static _XpRewardLedger? _readXpRewardLedger({required bool strict}) {
    if (_xpRewardWritePending ||
        _unknownStrictKeys.contains(listeningRewardLedgerPreferenceKey)) {
      if (strict) {
        throw const PreferenceOutcomeUnknownException(
          listeningRewardLedgerPreferenceKey,
        );
      }
      return _confirmedXpRewardLedger;
    }
    final raw = _s(listeningRewardLedgerPreferenceKey);
    if (raw.isEmpty) {
      _confirmedXpRewardLedger = null;
      return null;
    }
    try {
      final ledger = _XpRewardLedger.decode(raw);
      _confirmedXpRewardLedger = ledger;
      return ledger;
    } on Object catch (error) {
      if (strict) {
        throw PreferenceWriteException(
          listeningRewardLedgerPreferenceKey,
          cause: error,
        );
      }
      return null;
    }
  }

  static int _effectiveXpTotal(_XpRewardLedger ledger) {
    // Once present, this confirmed record outranks its best-effort mirror.
    return ledger.totalXp;
  }

  static Future<void> _persistXpRewardLedger(_XpRewardLedger ledger) async {
    _readXpRewardLedger(strict: true);
    _xpRewardWritePending = true;
    try {
      await _ssStrict(listeningRewardLedgerPreferenceKey, ledger.encode());
      _confirmedXpRewardLedger = ledger;
      // The ledger is the commit point; this older-build mirror is auxiliary.
      try {
        await _si('kl_xp', ledger.totalXp);
      } on Object catch (error) {
        debugPrint('Storage: XP compatibility mirror failed: $error');
      }
    } finally {
      _xpRewardWritePending = false;
    }
  }

  static Future<void> _recoverUnknownXpRewardState() async {
    final pending = _pendingOrdinaryXpWrite;
    if (_unknownStrictKeys.contains(listeningRewardLedgerPreferenceKey)) {
      await _refreshUnknownStringKeys(_stringStore(), [
        listeningRewardLedgerPreferenceKey,
      ]);
    }
    if (pending != null) {
      if (!identical(_pendingOrdinaryXpWrite, pending)) {
        throw const StaleLocalDataLifetimeException();
      }
      final raw = _s(listeningRewardLedgerPreferenceKey);
      if (raw == pending.encoded) {
        pending.attempt._committed = true;
      } else if (raw != pending.before) {
        _unknownStrictKeys.add(listeningRewardLedgerPreferenceKey);
        throw const PreferenceOutcomeUnknownException(
          listeningRewardLedgerPreferenceKey,
        );
      }
      _pendingOrdinaryXpWrite = null;
    }
  }

  static Future<void> _mirrorListeningCompletion(String id) async {
    try {
      // The listening claim already owns the reward mutation queue.
      await _writeRewardListEntry('kl_completed_scenarios', id);
    } on Object catch (error) {
      // The canonical ledger claim still makes completedScenarios contain the
      // ID. A later completion can repair this old-format mirror.
      debugPrint('Storage: listening completion mirror failed: $error');
    }
  }

  static Future<void> _ssStrict(
    String key,
    String value, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
    _StringPreferenceState? beforeState,
  }) => PackCompletionStorage.trackWrite(
    key,
    () => _ssStrictImpl(
      key,
      value,
      preferences: preferences,
      assertCurrentWrite: assertCurrentWrite,
      beforeState: beforeState,
    ),
  );

  static Future<void> _ssStrictImpl(
    String key,
    String value, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
    _StringPreferenceState? beforeState,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceStringStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = beforeState ?? await _prepareStringMutation(store, key);
    assertCurrentWrite?.call();
    Object? failure;
    var wrote = false;
    try {
      wrote = await store.setString(key, value);
    } on Object catch (error) {
      failure = error;
    }
    if (wrote) {
      return;
    }
    final after = await _reloadStringState(
      store,
      key,
      operationFailure: failure,
    );
    if (after.isPresent && after.value == value) {
      return;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<void> _siStrict(
    String key,
    int value, {
    PreferenceIntStore? preferences,
    void Function()? assertCurrentWrite,
    _IntPreferenceState? beforeState,
  }) => PackCompletionStorage.trackWrite(
    key,
    () => _siStrictImpl(
      key,
      value,
      preferences: preferences,
      assertCurrentWrite: assertCurrentWrite,
      beforeState: beforeState,
    ),
  );

  static Future<void> _siStrictImpl(
    String key,
    int value, {
    PreferenceIntStore? preferences,
    void Function()? assertCurrentWrite,
    _IntPreferenceState? beforeState,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceIntStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = beforeState ?? await _prepareIntMutation(store, key);
    assertCurrentWrite?.call();
    Object? failure;
    var wrote = false;
    try {
      wrote = await store.setInt(key, value);
    } on Object catch (error) {
      failure = error;
    }
    if (wrote) {
      return;
    }
    final after = await _reloadIntState(store, key, operationFailure: failure);
    if (after.isPresent && after.value == value) {
      return;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<void> _slStrict(
    String key,
    List<String> value, {
    PreferenceStringListStore? preferences,
    void Function()? assertCurrentWrite,
    _StringListPreferenceState? beforeState,
  }) => PackCompletionStorage.trackWrite(
    key,
    () => _slStrictImpl(
      key,
      value,
      preferences: preferences,
      assertCurrentWrite: assertCurrentWrite,
      beforeState: beforeState,
    ),
  );

  static Future<void> _slStrictImpl(
    String key,
    List<String> value, {
    PreferenceStringListStore? preferences,
    void Function()? assertCurrentWrite,
    _StringListPreferenceState? beforeState,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceStringListStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = beforeState ?? await _prepareStringListMutation(store, key);
    assertCurrentWrite?.call();
    Object? failure;
    var wrote = false;
    try {
      wrote = await store.setStringList(key, value);
    } on Object catch (error) {
      failure = error;
    }
    if (wrote) {
      return;
    }
    final after = await _reloadStringListState(
      store,
      key,
      operationFailure: failure,
    );
    if (after.isPresent && _preferenceValueEquals(after.value, value)) {
      return;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<void> _sbStrict(
    String key,
    bool value, {
    PreferenceBoolStore? preferences,
    void Function()? assertCurrentWrite,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceBoolStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = await _prepareBoolMutation(store, key);
    assertCurrentWrite?.call();
    Object? failure;
    var wrote = false;
    try {
      wrote = await store.setBool(key, value);
    } on Object catch (error) {
      failure = error;
    }
    if (wrote) {
      return;
    }
    final after = await _reloadBoolState(store, key, operationFailure: failure);
    if (after.isPresent && after.value == value) {
      return;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<_BoolPreferenceState> _prepareBoolMutation(
    PreferenceBoolStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      await _refreshUnknownBoolKeys(store, [key]);
      // As with strict string writes, the caller must explicitly retry after
      // the indeterminate cache has been refreshed.
      throw PreferenceWriteException(key);
    }
    try {
      return _BoolPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static Future<_IntPreferenceState> _prepareIntMutation(
    PreferenceIntStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      await _refreshUnknownIntKeys(store, [key]);
      throw PreferenceWriteException(key);
    }
    try {
      return _IntPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static Future<void> _refreshUnknownIntKeys(
    PreferenceIntStore store,
    Iterable<String> keys,
  ) async {
    final unknown = keys
        .where(_unknownStrictKeys.contains)
        .toSet()
        .toList(growable: false);
    if (unknown.isEmpty) {
      return;
    }
    try {
      await store.reload();
      for (final key in unknown) {
        _IntPreferenceState.read(store, key);
      }
      _unknownStrictKeys.removeAll(unknown);
    } on Object catch (error) {
      _unknownStrictKeys.addAll(unknown);
      throw PreferenceOutcomeUnknownException(unknown.first, cause: error);
    }
  }

  static Future<_IntPreferenceState> _reloadIntState(
    PreferenceIntStore store,
    String key, {
    Object? operationFailure,
  }) async {
    try {
      await store.reload();
      return _IntPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(
        key,
        cause: operationFailure ?? error,
      );
    }
  }

  static Future<void> _refreshUnknownBoolKeys(
    PreferenceBoolStore store,
    Iterable<String> keys,
  ) async {
    final unknown = keys
        .where(_unknownStrictKeys.contains)
        .toSet()
        .toList(growable: false);
    if (unknown.isEmpty) {
      return;
    }
    try {
      await store.reload();
      for (final key in unknown) {
        _BoolPreferenceState.read(store, key);
      }
      _unknownStrictKeys.removeAll(unknown);
    } on Object catch (error) {
      _unknownStrictKeys.addAll(unknown);
      throw PreferenceOutcomeUnknownException(unknown.first, cause: error);
    }
  }

  static Future<_BoolPreferenceState> _reloadBoolState(
    PreferenceBoolStore store,
    String key, {
    Object? operationFailure,
  }) async {
    try {
      await store.reload();
      return _BoolPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(
        key,
        cause: operationFailure ?? error,
      );
    }
  }

  static Future<_StringPreferenceState> _prepareStringMutation(
    PreferenceStringStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      await _refreshUnknownStringKeys(store, [key]);
      // The caller constructed its requested value before this refresh and may
      // therefore have derived it from the optimistic cache. Abort without
      // writing; an explicit retry must reread the now-refreshed state.
      throw PreferenceWriteException(key);
    }
    try {
      return _StringPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static Future<_StringListPreferenceState> _prepareStringListMutation(
    PreferenceStringListStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      await _refreshUnknownStringListKeys(store, [key]);
    }
    try {
      return _StringListPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static Future<void> _refreshUnknownStringKeys(
    PreferenceStringStore store,
    Iterable<String> keys,
  ) async {
    final unknown = keys
        .where(_unknownStrictKeys.contains)
        .toSet()
        .toList(growable: false);
    if (unknown.isEmpty) {
      return;
    }
    try {
      await store.reload();
      for (final key in unknown) {
        _StringPreferenceState.read(store, key);
      }
      _unknownStrictKeys.removeAll(unknown);
    } on Object catch (error) {
      _unknownStrictKeys.addAll(unknown);
      throw PreferenceOutcomeUnknownException(unknown.first, cause: error);
    }
  }

  static Future<void> _refreshUnknownStringListKeys(
    PreferenceStringListStore store,
    Iterable<String> keys,
  ) async {
    final unknown = keys
        .where(_unknownStrictKeys.contains)
        .toSet()
        .toList(growable: false);
    if (unknown.isEmpty) {
      return;
    }
    try {
      await store.reload();
      for (final key in unknown) {
        _StringListPreferenceState.read(store, key);
      }
      _unknownStrictKeys.removeAll(unknown);
    } on Object catch (error) {
      _unknownStrictKeys.addAll(unknown);
      throw PreferenceOutcomeUnknownException(unknown.first, cause: error);
    }
  }

  static PreferenceStringStore _stringStore([
    PreferenceStringStore? preferences,
  ]) {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceStringStore(_prefs!));
    if (store == null) {
      throw StateError('Storage has not been initialized.');
    }
    return store;
  }

  static Future<void> _prepareStringReadModifyWrite(
    PreferenceStringStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      await _refreshUnknownStringKeys(store, [key]);
      throw PreferenceWriteException(key);
    }
  }

  static Future<_StringPreferenceState> _reloadStringState(
    PreferenceStringStore store,
    String key, {
    Object? operationFailure,
  }) async {
    try {
      await store.reload();
      return _StringPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(
        key,
        cause: operationFailure ?? error,
      );
    }
  }

  static Future<_StringListPreferenceState> _reloadStringListState(
    PreferenceStringListStore store,
    String key, {
    Object? operationFailure,
  }) async {
    try {
      await store.reload();
      return _StringListPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(
        key,
        cause: operationFailure ?? error,
      );
    }
  }

  static Future<String?> _removeStringStrict(
    String key, {
    PreferenceStringStore? preferences,
    bool Function(String value)? matches,
    void Function()? assertCurrentWrite,
  }) => PackCompletionStorage.trackWrite(
    key,
    () => _removeStringStrictImpl(
      key,
      preferences: preferences,
      matches: matches,
      assertCurrentWrite: assertCurrentWrite,
    ),
  );

  static Future<String?> _removeStringStrictImpl(
    String key, {
    PreferenceStringStore? preferences,
    bool Function(String value)? matches,
    void Function()? assertCurrentWrite,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceStringStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = await _prepareStringMutation(store, key);
    if (!before.isPresent) {
      return null;
    }
    final value = before.value!;
    if (matches != null && !matches(value)) {
      return null;
    }
    assertCurrentWrite?.call();
    Object? failure;
    var removed = false;
    try {
      removed = await store.remove(key);
    } on Object catch (error) {
      failure = error;
    }
    if (removed) {
      return value;
    }
    final after = await _reloadStringState(
      store,
      key,
      operationFailure: failure,
    );
    if (!after.isPresent) {
      return value;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<void> _removeValueStrict(
    PreferenceRemovalStore store,
    String key,
  ) async {
    if (_unknownStrictKeys.contains(key)) {
      try {
        await store.reload();
        _unknownStrictKeys.remove(key);
      } on Object catch (error) {
        throw PreferenceOutcomeUnknownException(key, cause: error);
      }
    }
    late final _PreferenceState before;
    try {
      before = _PreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
    if (!before.isPresent) {
      return;
    }
    Object? failure;
    var removed = false;
    try {
      removed = await store.remove(key);
    } on Object catch (error) {
      failure = error;
    }
    if (removed) {
      return;
    }
    late final _PreferenceState after;
    try {
      await store.reload();
      after = _PreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: failure ?? error);
    }
    if (!after.isPresent) {
      return;
    }
    if (after == before) {
      throw PreferenceWriteException(key, cause: failure);
    }
    _unknownStrictKeys.add(key);
    throw PreferenceOutcomeUnknownException(key, cause: failure);
  }

  static Future<void> _writeValueStrict(
    PreferenceRemovalStore store,
    String key,
    String value,
  ) async {
    Object? failure;
    var wrote = false;
    try {
      wrote = await store.setString(key, value);
    } on Object catch (error) {
      failure = error;
    }
    if (wrote) return;
    try {
      await store.reload();
      if (store.getValue(key) == value) return;
    } on Object catch (error) {
      failure ??= error;
    }
    throw PreferenceWriteException(key, cause: failure);
  }

  static Future<void> _sd(String k, double v) async => _prefs?.setDouble(k, v);
  static Future<void> _sl(String k, List<String> v) =>
      PackCompletionStorage.trackWrite(k, () async {
        await _prefs?.setStringList(k, v);
      });

  static bool _b(String k, [bool dflt = false]) => _prefs?.getBool(k) ?? dflt;
  static Future<void> _sb(String k, bool v) async => _prefs?.setBool(k, v);

  // ───────── Benachrichtigungen (M3) — tägliche Lern-Erinnerung ─────────
  static bool get notificationsEnabled => _b('kl_notif_enabled');
  static Future<void> setNotificationsEnabled(bool v) =>
      _sb('kl_notif_enabled', v);
  // Default 19:00 (Abend). getInt maskiert "ungesetzt", daher direkt mit ?? 19.
  static int get notificationHour => _prefs?.getInt('kl_notif_hour') ?? 19;
  static Future<void> setNotificationHour(int v) => _si('kl_notif_hour', v);

  // ───────── Interessen (M5) — Personalisierung des Tageskurses ─────────
  static List<String> get interests => _l('kl_interests');
  static Future<void> setInterests(List<String> v) => _sl('kl_interests', v);

  // ───────── Vokabeln ─────────
  static const _vokCorrectKey = 'kl_vok_correct';
  static const _vokWrongKey = 'kl_vok_wrong';
  static const _vokSkippedKey = 'kl_vok_skipped';
  static const _vokLastIdxKey = 'kl_vok_last_idx';
  static const _vokSeenIdsKey = 'kl_vok_seen_ids';
  static const _wrongCountKey = 'kl_wrong_count_v1';

  static bool _vocabWriteIsUnconfirmed(String key) =>
      _pendingVocabPreferenceWrite?.key == key ||
      _unknownStrictKeys.contains(key);

  static int _readConfirmedVocabInt(String key) {
    if (_vocabWriteIsUnconfirmed(key) ||
        _confirmedVocabAfterReloadKeys.contains(key)) {
      return _confirmedVocabInts[key] ?? 0;
    }
    final value = _i(key);
    _confirmedVocabInts[key] = value;
    return value;
  }

  static int get vokCorrect => _readConfirmedVocabInt(_vokCorrectKey);
  static int get vokWrong => _readConfirmedVocabInt(_vokWrongKey);
  static int get vokSkipped => _readConfirmedVocabInt(_vokSkippedKey);
  static int get vokLastIdx => _readConfirmedVocabInt(_vokLastIdxKey);
  static List<String> get vokSeenIds {
    if (_vocabWriteIsUnconfirmed(_vokSeenIdsKey) ||
        _confirmedVocabAfterReloadKeys.contains(_vokSeenIdsKey)) {
      return List<String>.of(_confirmedVokSeenIds ?? const <String>[]);
    }
    final value = _l(_vokSeenIdsKey);
    _confirmedVokSeenIds = List<String>.unmodifiable(value);
    return List<String>.of(value);
  }

  static Future<void> setVokCorrect(int v) async {
    await _requireVocabProgress(
      VocabProgressAttempt._absolute(absoluteCorrect: v),
    );
  }

  static Future<void> setVokWrong(int v) async {
    await _requireVocabProgress(
      VocabProgressAttempt._absolute(absoluteWrong: v),
    );
  }

  static Future<void> setVokSkipped(int v) async {
    await _requireVocabProgress(
      VocabProgressAttempt._absolute(absoluteSkipped: v),
    );
  }

  static Future<void> setVokLastIdx(int v) async {
    await _requireVocabProgress(VocabProgressAttempt._absolute(cursor: v));
  }

  static Future<void> addVokSeen(String id) async {
    await _requireVocabProgress(VocabProgressAttempt(seenId: id));
  }

  static Future<void> _requireVocabProgress(
    VocabProgressAttempt attempt,
  ) async {
    if (!await attempt.save()) {
      throw const PreferenceWriteException('vocabulary progress');
    }
  }

  static Future<void> restoreVocabularyProgress({
    int? minimumCorrect,
    int? minimumWrong,
    int? minimumSkipped,
    int? cursor,
    Iterable<String> seenIds = const <String>[],
    String? wrongCountJson,
    void Function()? assertCurrentWrite,
  }) async {
    await _requireVocabProgress(
      VocabProgressAttempt._restore(
        minimumCorrect: minimumCorrect,
        minimumWrong: minimumWrong,
        minimumSkipped: minimumSkipped,
        cursor: cursor,
        restoreSeenIds: List<String>.unmodifiable(seenIds),
        restoreWrongCountJson: wrongCountJson,
        assertCurrentWrite: assertCurrentWrite,
      ),
    );
  }

  static Future<bool> _saveVocabProgressAttempt(
    VocabProgressAttempt attempt,
  ) async {
    attempt._assertCurrent();
    if (attempt._completed) {
      return true;
    }
    await _resolvePendingVocabPreferenceWrite();
    attempt._assertCurrent();
    if (!attempt.bypassLearningWriteLock && _learningWritesLockReason != null) {
      return false;
    }

    if (!attempt._restoreEligibilityCaptured && attempt.isRestore) {
      attempt._restoreCursorEligible =
          vokCorrect == 0 &&
          vokWrong == 0 &&
          vokSkipped == 0 &&
          vokLastIdx == 0 &&
          vokSeenIds.isEmpty;
      attempt._restoreEligibilityCaptured = true;
    }

    final shouldWriteCursor =
        attempt.cursor != null &&
        (!attempt.isRestore || attempt._restoreCursorEligible);
    if (!attempt._cursorSaved && shouldWriteCursor) {
      await _writeVocabInt(
        attempt,
        _vokLastIdxKey,
        attempt.cursor!,
        () => attempt._cursorSaved = true,
      );
    } else if (!attempt._cursorSaved) {
      attempt._cursorSaved = true;
    }

    await _applyVocabIntChange(
      attempt,
      key: _vokCorrectKey,
      delta: attempt.correctDelta,
      absolute: attempt.absoluteCorrect,
      minimum: attempt.minimumCorrect,
      isSaved: () => attempt._correctSaved,
      markSaved: () => attempt._correctSaved = true,
    );
    await _applyVocabIntChange(
      attempt,
      key: _vokWrongKey,
      delta: attempt.wrongDelta,
      absolute: attempt.absoluteWrong,
      minimum: attempt.minimumWrong,
      isSaved: () => attempt._wrongSaved,
      markSaved: () => attempt._wrongSaved = true,
    );
    await _applyVocabIntChange(
      attempt,
      key: _vokSkippedKey,
      delta: attempt.skippedDelta,
      absolute: attempt.absoluteSkipped,
      minimum: attempt.minimumSkipped,
      isSaved: () => attempt._skippedSaved,
      markSaved: () => attempt._skippedSaved = true,
    );

    if (!attempt._seenSaved) {
      final additions = <String>[
        if (attempt.seenId case final id?) id,
        ...attempt.restoreSeenIds,
      ];
      final current = vokSeenIds;
      final updated = List<String>.of(current);
      for (final id in additions) {
        if (!updated.contains(id)) {
          updated.add(id);
        }
      }
      if (_preferenceValueEquals(current, updated)) {
        if (additions.isNotEmpty &&
            _quarantinedVocabPreferenceWrites.containsKey(_vokSeenIdsKey)) {
          throw PreferenceOutcomeUnknownException(_vokSeenIdsKey);
        }
        attempt._seenSaved = true;
      } else {
        await _writeVocabStringList(
          attempt,
          _vokSeenIdsKey,
          updated,
          () => attempt._seenSaved = true,
        );
      }
    }

    if (!attempt._wrongCountSaved) {
      if (attempt.wrongCountId case final id?) {
        final updated = Map<String, int>.of(_readWrongCountMap())
          ..update(id, (count) => count + 1, ifAbsent: () => 1);
        await _writeVocabString(
          attempt,
          _wrongCountKey,
          jsonEncode(updated),
          () => attempt._wrongCountSaved = true,
        );
      } else if (attempt.restoreWrongCountJson case final restored?) {
        if (!attempt.restoreWrongCountOnlyIfEmpty ||
            wrongCountRawJson.isEmpty) {
          await _writeVocabString(
            attempt,
            _wrongCountKey,
            restored,
            () => attempt._wrongCountSaved = true,
          );
        } else {
          attempt._wrongCountSaved = true;
        }
      } else {
        attempt._wrongCountSaved = true;
      }
    }

    attempt._assertCurrent();
    attempt._completed = true;
    return true;
  }

  static Future<void> _applyVocabIntChange(
    VocabProgressAttempt attempt, {
    required String key,
    required int delta,
    required int? absolute,
    required int? minimum,
    required bool Function() isSaved,
    required void Function() markSaved,
  }) async {
    if (isSaved()) {
      return;
    }
    final current = _readConfirmedVocabInt(key);
    final target =
        absolute ??
        (minimum == null
            ? current + delta
            : (current < minimum ? minimum : current));
    if (target == current) {
      final hasRequestedChange =
          delta != 0 || absolute != null || minimum != null;
      if (hasRequestedChange &&
          _quarantinedVocabPreferenceWrites.containsKey(key)) {
        throw PreferenceOutcomeUnknownException(key);
      }
      markSaved();
      return;
    }
    await _writeVocabInt(attempt, key, target, markSaved);
  }

  static Future<void> _resolvePendingVocabPreferenceWrite() async {
    final pending = _pendingVocabPreferenceWrite;
    if (pending == null) {
      return;
    }
    if (pending.generation != _vocabProgressMutationGeneration) {
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      _unknownStrictKeys.remove(pending.key);
      throw const StaleLocalDataLifetimeException();
    }
    if (!_vocabPendingOriginIsCurrent(pending)) {
      _quarantineVocabPreferenceWrite(pending);
      return;
    }
    try {
      late final Object current;
      switch (pending.kind) {
        case _VocabPreferenceKind.integer:
          final store = pending.store as PreferenceIntStore;
          await store.reload();
          current = _IntPreferenceState.read(store, pending.key);
          break;
        case _VocabPreferenceKind.string:
          final store = pending.store as PreferenceStringStore;
          await store.reload();
          current = _StringPreferenceState.read(store, pending.key);
          break;
        case _VocabPreferenceKind.stringList:
          final store = pending.store as PreferenceStringListStore;
          await store.reload();
          current = _StringListPreferenceState.read(store, pending.key);
          break;
      }
      if (!_vocabPendingOriginIsCurrent(pending)) {
        _quarantineVocabPreferenceWrite(pending);
        return;
      }
      if (pending.generation != _vocabProgressMutationGeneration) {
        throw const StaleLocalDataLifetimeException();
      }
      final matchesAfter = _vocabPreferenceStateMatches(current, pending.after);
      if (matchesAfter) {
        if (!_vocabPendingOriginIsCurrent(pending)) {
          _quarantineVocabPreferenceWrite(pending);
          return;
        }
        pending.confirm();
      } else if (current != pending.before) {
        _unknownStrictKeys.add(pending.key);
        throw PreferenceOutcomeUnknownException(pending.key);
      }
      if (!_quarantinedVocabPreferenceWrites.containsKey(pending.key)) {
        _unknownStrictKeys.remove(pending.key);
      }
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
    } on StaleLocalDataLifetimeException {
      _unknownStrictKeys.remove(pending.key);
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      rethrow;
    } on PreferenceOutcomeUnknownException {
      rethrow;
    } on Object catch (error) {
      _unknownStrictKeys.add(pending.key);
      throw PreferenceOutcomeUnknownException(pending.key, cause: error);
    }
  }

  static bool _vocabPendingOriginIsCurrent(
    _PendingVocabPreferenceWrite pending,
  ) {
    try {
      pending.assertOriginCurrent();
      return true;
    } on Object {
      return false;
    }
  }

  static void _quarantineVocabPreferenceWrite(
    _PendingVocabPreferenceWrite pending,
  ) {
    _quarantinedVocabPreferenceWrites[pending.key] = pending;
    _unknownStrictKeys.add(pending.key);
    if (identical(pending, _pendingVocabPreferenceWrite)) {
      _pendingVocabPreferenceWrite = null;
    }
  }

  static void _assertVocabPendingOriginAfterNative(
    VocabProgressAttempt attempt,
    _PendingVocabPreferenceWrite pending,
  ) {
    if (!attempt._isCurrent ||
        pending.generation != _vocabProgressMutationGeneration) {
      _unknownStrictKeys.remove(pending.key);
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      throw const StaleLocalDataLifetimeException();
    }
    try {
      pending.assertOriginCurrent();
    } on Object {
      _quarantineVocabPreferenceWrite(pending);
      rethrow;
    }
  }

  static bool _vocabPreferenceStateMatches(Object state, Object value) =>
      switch (state) {
        _IntPreferenceState state => state.isPresent && state.value == value,
        _StringPreferenceState state => state.isPresent && state.value == value,
        _StringListPreferenceState state =>
          state.isPresent && _preferenceValueEquals(state.value, value),
        _ => false,
      };

  static Future<_IntPreferenceState> _prepareVocabIntMutation(
    VocabProgressAttempt attempt,
    PreferenceIntStore store,
    String key,
  ) async {
    final quarantined = _quarantinedVocabPreferenceWrites[key];
    if (quarantined?.kind == _VocabPreferenceKind.integer) {
      attempt._assertCurrent();
      final current = await _reloadIntState(store, key);
      attempt._assertCurrent();
      if (current != quarantined!.before &&
          !_vocabPreferenceStateMatches(current, quarantined.after)) {
        throw PreferenceOutcomeUnknownException(key);
      }
      return current;
    }
    if (_confirmedVocabAfterReloadKeys.contains(key) &&
        !_unknownStrictKeys.contains(key)) {
      return _IntPreferenceState._(
        isPresent: true,
        value: _confirmedVocabInts[key]!,
      );
    }
    return _prepareIntMutation(store, key);
  }

  static Future<_StringPreferenceState> _prepareVocabStringMutation(
    VocabProgressAttempt attempt,
    PreferenceStringStore store,
    String key,
  ) async {
    final quarantined = _quarantinedVocabPreferenceWrites[key];
    if (quarantined?.kind == _VocabPreferenceKind.string) {
      attempt._assertCurrent();
      final current = await _reloadStringState(store, key);
      attempt._assertCurrent();
      if (current != quarantined!.before &&
          !_vocabPreferenceStateMatches(current, quarantined.after)) {
        throw PreferenceOutcomeUnknownException(key);
      }
      return current;
    }
    if (_confirmedVocabAfterReloadKeys.contains(key) &&
        !_unknownStrictKeys.contains(key)) {
      return _StringPreferenceState._(
        isPresent: true,
        value: _confirmedWrongCountRaw!,
      );
    }
    return _prepareStringMutation(store, key);
  }

  static Future<_StringListPreferenceState> _prepareVocabStringListMutation(
    VocabProgressAttempt attempt,
    PreferenceStringListStore store,
    String key,
  ) async {
    final quarantined = _quarantinedVocabPreferenceWrites[key];
    if (quarantined?.kind == _VocabPreferenceKind.stringList) {
      attempt._assertCurrent();
      final current = await _reloadStringListState(store, key);
      attempt._assertCurrent();
      if (current != quarantined!.before &&
          !_vocabPreferenceStateMatches(current, quarantined.after)) {
        throw PreferenceOutcomeUnknownException(key);
      }
      return current;
    }
    if (_confirmedVocabAfterReloadKeys.contains(key) &&
        !_unknownStrictKeys.contains(key)) {
      return _StringListPreferenceState._(
        isPresent: true,
        value: _confirmedVokSeenIds!,
      );
    }
    return _prepareStringListMutation(store, key);
  }

  static Future<void> _writeVocabInt(
    VocabProgressAttempt attempt,
    String key,
    int value,
    void Function() markSaved,
  ) async {
    attempt._assertCurrent();
    final preferences = _prefs;
    if (preferences == null) {
      throw PreferenceWriteException(key);
    }
    final store = _SharedPreferenceIntStore(preferences);
    final before = await _prepareVocabIntMutation(attempt, store, key);
    attempt._assertCurrent();
    _confirmedVocabInts.putIfAbsent(key, () => before.value ?? 0);
    if (before.isPresent && before.value == value) {
      _quarantinedVocabPreferenceWrites.remove(key);
      _unknownStrictKeys.remove(key);
      _confirmedVocabInts[key] = value;
      markSaved();
      return;
    }
    final generation = _vocabProgressMutationGeneration;
    final pending = _PendingVocabPreferenceWrite(
      generation: generation,
      key: key,
      kind: _VocabPreferenceKind.integer,
      store: store,
      before: before,
      after: value,
      assertOriginCurrent: attempt._assertCurrent,
      confirm: () {
        _quarantinedVocabPreferenceWrites.remove(key);
        _unknownStrictKeys.remove(key);
        _confirmedVocabInts[key] = value;
        markSaved();
      },
    );
    pending.sharedCacheReloaded = _packCompletionReloads.containsKey(
      preferences,
    );
    _pendingVocabPreferenceWrite = pending;
    try {
      await _siStrict(
        key,
        value,
        preferences: store,
        beforeState: before,
        assertCurrentWrite: attempt._assertCurrent,
      );
    } on PreferenceOutcomeUnknownException {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      rethrow;
    } on Object {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      rethrow;
    }
    _assertVocabPendingOriginAfterNative(attempt, pending);
    pending.confirm();
    if (identical(pending, _pendingVocabPreferenceWrite)) {
      _pendingVocabPreferenceWrite = null;
    }
  }

  static Future<void> _writeVocabString(
    VocabProgressAttempt attempt,
    String key,
    String value,
    void Function() markSaved,
  ) async {
    attempt._assertCurrent();
    final preferences = _prefs;
    if (preferences == null) {
      throw PreferenceWriteException(key);
    }
    final store = _SharedPreferenceStringStore(preferences);
    final before = await _prepareVocabStringMutation(attempt, store, key);
    attempt._assertCurrent();
    if (key == _wrongCountKey) {
      _confirmedWrongCountRaw ??= before.value ?? '';
    }
    if (before.isPresent && before.value == value) {
      _quarantinedVocabPreferenceWrites.remove(key);
      _unknownStrictKeys.remove(key);
      if (key == _wrongCountKey) {
        _confirmWrongCountRaw(value);
      }
      markSaved();
      return;
    }
    final generation = _vocabProgressMutationGeneration;
    final pending = _PendingVocabPreferenceWrite(
      generation: generation,
      key: key,
      kind: _VocabPreferenceKind.string,
      store: store,
      before: before,
      after: value,
      assertOriginCurrent: attempt._assertCurrent,
      confirm: () {
        _quarantinedVocabPreferenceWrites.remove(key);
        _unknownStrictKeys.remove(key);
        if (key == _wrongCountKey) {
          _confirmWrongCountRaw(value);
        }
        markSaved();
      },
    );
    pending.sharedCacheReloaded = _packCompletionReloads.containsKey(
      preferences,
    );
    _pendingVocabPreferenceWrite = pending;
    try {
      await _ssStrict(
        key,
        value,
        preferences: store,
        beforeState: before,
        assertCurrentWrite: attempt._assertCurrent,
      );
    } on PreferenceOutcomeUnknownException {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      rethrow;
    } on Object {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      rethrow;
    }
    _assertVocabPendingOriginAfterNative(attempt, pending);
    pending.confirm();
    if (identical(pending, _pendingVocabPreferenceWrite)) {
      _pendingVocabPreferenceWrite = null;
    }
  }

  static Future<void> _writeVocabStringList(
    VocabProgressAttempt attempt,
    String key,
    List<String> value,
    void Function() markSaved,
  ) async {
    attempt._assertCurrent();
    final preferences = _prefs;
    if (preferences == null) {
      throw PreferenceWriteException(key);
    }
    final store = _SharedPreferenceStringListStore(preferences);
    final before = await _prepareVocabStringListMutation(attempt, store, key);
    attempt._assertCurrent();
    _confirmedVokSeenIds ??= List<String>.unmodifiable(
      before.value ?? const <String>[],
    );
    if (before.isPresent && _preferenceValueEquals(before.value, value)) {
      _quarantinedVocabPreferenceWrites.remove(key);
      _unknownStrictKeys.remove(key);
      _confirmedVokSeenIds = List<String>.unmodifiable(value);
      markSaved();
      return;
    }
    final generation = _vocabProgressMutationGeneration;
    final pending = _PendingVocabPreferenceWrite(
      generation: generation,
      key: key,
      kind: _VocabPreferenceKind.stringList,
      store: store,
      before: before,
      after: List<String>.unmodifiable(value),
      assertOriginCurrent: attempt._assertCurrent,
      confirm: () {
        _quarantinedVocabPreferenceWrites.remove(key);
        _unknownStrictKeys.remove(key);
        _confirmedVokSeenIds = List<String>.unmodifiable(value);
        markSaved();
      },
    );
    pending.sharedCacheReloaded = _packCompletionReloads.containsKey(
      preferences,
    );
    _pendingVocabPreferenceWrite = pending;
    try {
      await _slStrict(
        key,
        value,
        preferences: store,
        beforeState: before,
        assertCurrentWrite: attempt._assertCurrent,
      );
    } on PreferenceOutcomeUnknownException {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      rethrow;
    } on Object {
      _assertVocabPendingOriginAfterNative(attempt, pending);
      if (identical(pending, _pendingVocabPreferenceWrite)) {
        _pendingVocabPreferenceWrite = null;
      }
      rethrow;
    }
    _assertVocabPendingOriginAfterNative(attempt, pending);
    pending.confirm();
    if (identical(pending, _pendingVocabPreferenceWrite)) {
      _pendingVocabPreferenceWrite = null;
    }
  }

  static String _confirmedChoiceRevisionKey(
    _ConfirmedChoiceDomain domain,
    String itemKey,
  ) => '${domain.preferenceKey}\u0000$itemKey';

  static int _admitConfirmedChoice(
    _ConfirmedChoiceDomain domain,
    String itemKey,
  ) {
    if (_learningResetCount > 0) {
      throw const StaleLocalDataLifetimeException();
    }
    final key = _confirmedChoiceRevisionKey(domain, itemKey);
    final revision = (_confirmedChoiceRevisions[key] ?? 0) + 1;
    _confirmedChoiceRevisions[key] = revision;
    return revision;
  }

  static List<String> _confirmedChoiceList(_ConfirmedChoiceDomain domain) {
    final key = domain.preferenceKey;
    final cached = _confirmedChoiceStates[key];
    if (cached != null) {
      return List<String>.of(cached.value ?? const <String>[]);
    }
    final preferences = _prefs;
    if (preferences == null) {
      return <String>[];
    }
    try {
      final state = _StringListPreferenceState.read(
        _SharedPreferenceStringListStore(preferences),
        key,
      );
      _confirmedChoiceStates[key] = state;
      return List<String>.of(state.value ?? const <String>[]);
    } on Object {
      _unknownStrictKeys.add(key);
      return <String>[];
    }
  }

  static void _publishConfirmedChoice(
    _ConfirmedChoiceDomain domain,
    _StringListPreferenceState state,
  ) {
    _confirmedChoiceStates[domain.preferenceKey] = state;
  }

  static Future<_StringListPreferenceState> _prepareConfirmedChoiceMutation(
    PreferenceStringListStore store,
    _ConfirmedChoiceDomain domain,
  ) async {
    final key = domain.preferenceKey;
    final requiresNativeRefresh = _unknownStrictKeys.contains(key);
    if (requiresNativeRefresh) {
      await _refreshUnknownStringListKeys(store, <String>[key]);
    } else {
      final confirmed = _confirmedChoiceStates[key];
      if (confirmed != null) {
        return confirmed;
      }
    }
    try {
      return _StringListPreferenceState.read(store, key);
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static void _assertConfirmedChoiceCurrentAfterNative(
    ConfirmedLocalChoiceOperation operation,
    String preferenceKey,
  ) {
    try {
      operation._assertCurrent();
    } on StaleLocalDataLifetimeException {
      // The setter was already issued, so its durable outcome can differ from
      // the last confirmed view even when this operation must not publish.
      // Force the next queued/fresh owner to reconcile native state first.
      _unknownStrictKeys.add(preferenceKey);
      rethrow;
    }
  }

  static Future<bool> _saveConfirmedChoice(
    ConfirmedLocalChoiceOperation operation,
  ) {
    operation._assertCurrent();
    final domainKey = operation._domain.preferenceKey;
    final prior = _confirmedChoiceMutations[domainKey];
    final generation = _confirmedChoiceMutationGeneration;
    _confirmedChoiceMutationCount++;
    late final Future<bool> result;
    late final Future<void> tail;
    result = () async {
      if (prior != null) {
        await prior;
      }
      operation._assertCurrent();
      final preferences = _prefs;
      if (preferences == null) {
        throw PreferenceWriteException(domainKey);
      }
      final store = _SharedPreferenceStringListStore(preferences);
      late final _StringListPreferenceState before;
      try {
        before = await _prepareConfirmedChoiceMutation(
          store,
          operation._domain,
        );
      } on Object {
        operation._assertCurrent();
        rethrow;
      }
      operation._assertCurrent();
      final current = before.value ?? const <String>[];
      _publishConfirmedChoice(operation._domain, before);
      final contains = current.contains(operation.itemKey);
      if (contains == operation.desired) {
        operation._completed = true;
        return operation.desired;
      }
      final next = <String>[
        for (final item in current)
          if (item != operation.itemKey) item,
        if (operation.desired) operation.itemKey,
      ];
      try {
        await _slStrict(
          domainKey,
          next,
          preferences: store,
          beforeState: before,
          assertCurrentWrite: operation._assertCurrent,
        );
      } on Object catch (error) {
        _assertConfirmedChoiceCurrentAfterNative(operation, domainKey);
        if (error is PreferenceWriteException) {
          _publishConfirmedChoice(operation._domain, before);
        }
        rethrow;
      }
      _assertConfirmedChoiceCurrentAfterNative(operation, domainKey);
      _publishConfirmedChoice(
        operation._domain,
        _StringListPreferenceState._(
          isPresent: true,
          value: List<String>.unmodifiable(next),
        ),
      );
      operation._completed = true;
      return operation.desired;
    }();
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _confirmedChoiceMutations[domainKey] = tail;
    tail.whenComplete(() {
      if (generation == _confirmedChoiceMutationGeneration) {
        _confirmedChoiceMutationCount--;
        if (identical(tail, _confirmedChoiceMutations[domainKey])) {
          _confirmedChoiceMutations.remove(domainKey);
        }
      }
    });
    return result;
  }

  static ConfirmedLocalChoiceOperation likedContentOperation(
    String key, {
    required bool desired,
    void Function()? assertCurrentOwner,
  }) => ConfirmedLocalChoiceOperation._(
    assertCurrentOwner,
    itemKey: key,
    desired: desired,
    domain: _ConfirmedChoiceDomain.likedContent,
  );

  static ConfirmedLocalChoiceOperation vokFavoriteOperation(
    String id, {
    required bool desired,
    void Function()? assertCurrentOwner,
  }) => ConfirmedLocalChoiceOperation._(
    assertCurrentOwner,
    itemKey: id,
    desired: desired,
    domain: _ConfirmedChoiceDomain.vokFavorite,
  );

  /// Vokabel-Favoriten — Stern-Markierung für gezieltes Wiederholen.
  static List<String> get vokFavorites =>
      _confirmedChoiceList(_ConfirmedChoiceDomain.vokFavorite);
  static bool isVokFavorite(String id) => vokFavorites.contains(id);
  static Future<void> toggleVokFavorite(String id) async {
    await vokFavoriteOperation(id, desired: !isVokFavorite(id)).save();
  }

  static Future<void> setVokFavorite(String id, bool desired) async {
    await vokFavoriteOperation(id, desired: desired).save();
  }

  /// Liked content keys (`kind|id`) — play-later drawer, not the wordbook.
  static List<String> get likedContentKeys =>
      _confirmedChoiceList(_ConfirmedChoiceDomain.likedContent);
  static bool isLikedContent(String key) => likedContentKeys.contains(key);
  static Future<bool> toggleLikedContent(String key) async {
    return likedContentOperation(key, desired: !isLikedContent(key)).save();
  }

  static Future<bool> setLikedContent(String key, bool desired) =>
      likedContentOperation(key, desired: desired).save();

  // ───────── Chosung Quiz ─────────
  static int get chosungCorrect => _i('kl_chosung_correct');
  static int get chosungWrong => _i('kl_chosung_wrong');
  static Future<void> setChosungCorrect(int value) =>
      _si('kl_chosung_correct', value);
  static Future<void> setChosungWrong(int value) =>
      _si('kl_chosung_wrong', value);
  static Future<void> incChosungCorrect() =>
      _si('kl_chosung_correct', chosungCorrect + 1);
  static Future<void> incChosungWrong() =>
      _si('kl_chosung_wrong', chosungWrong + 1);

  // ───────── Wordle ─────────
  static int get wordleWins => _i('kl_wordle_wins');
  static int get wordleLosses => _i('kl_wordle_losses');
  static int get wordleStreak => _i('kl_wordle_streak');
  static int get wordleBestStreak => _i('kl_wordle_best_streak');
  static Future<void> setWordleWins(int value) => _si('kl_wordle_wins', value);
  static Future<void> setWordleLosses(int value) =>
      _si('kl_wordle_losses', value);
  static Future<void> setWordleStreak(int value) =>
      _si('kl_wordle_streak', value);
  static Future<void> setWordleBestStreak(int value) =>
      _si('kl_wordle_best_streak', value);
  static Future<void> incWordleWins() async {
    await _si('kl_wordle_wins', wordleWins + 1);
    final s = wordleStreak + 1;
    await _si('kl_wordle_streak', s);
    if (s > wordleBestStreak) await _si('kl_wordle_best_streak', s);
  }

  static Future<void> incWordleLosses() async {
    await _si('kl_wordle_losses', wordleLosses + 1);
    await _si('kl_wordle_streak', 0);
  }

  // ───────── Hangul 낱자 판정 ─────────
  //
  // 자모는 어휘가 아니라 **SRS 대상이 아니다** — `srsReview`/`incrementWrongCount`
  // 를 쓰면 단어 복습 큐가 오염된다. 문법의 `grammarHard` 와 똑같이 SRS 밖의
  // 단순 집합으로 둔다 (Sori Deck 3.0, 2026-08-18: 한글 카드 탭이 앱 공용
  // 좌=모름/우=앎 계약을 따르게 하면서 필요해진 저장소).
  static List<String> get hangulHard => _l('kl_hangul_hard');

  static Future<void> markHangulHard(String letter) async {
    final list = hangulHard;
    if (!list.contains(letter)) {
      list.add(letter);
      await _sl('kl_hangul_hard', list);
    }
  }

  static Future<void> markHangulEasy(String letter) async {
    final list = hangulHard;
    if (list.contains(letter)) {
      list.remove(letter);
      await _sl('kl_hangul_hard', list);
    }
  }

  // ───────── Grammatik ─────────
  static int get grammarLastIdx => _i('kl_gram_last_idx');
  static List<String> get grammarSeen => _l('kl_gram_seen');
  static List<String> get grammarHard => _l('kl_gram_hard');
  static String get grammarPlanRawJson {
    if (_grammarPlanConfirmedViewInitialized) {
      return _confirmedGrammarPlanRaw;
    }
    return _s('kl_gram_plan_v1');
  }

  static Future<void> setGrammarPlanRawJson(String json) {
    _captureGrammarPlanConfirmedView();
    return _enqueueGrammarPlanMutation(() async {
      await _ssStrict(
        'kl_gram_plan_v1',
        json,
        preferences: _grammarPlanStringStore(),
      );
      _unconfirmedGrammarPlanLevels.clear();
      _confirmedGrammarPlanRaw = json;
    });
  }

  /// §A5 (Fable R1, 2026-09-05): which plan level the grammar-screen
  /// onboarding sheet last started/changed to. Screen state (`_planLevel`)
  /// alone does not survive leaving and reopening the screen, so without this
  /// the plan silently falls back to [userLevelCode] on every fresh visit —
  /// a learner who built a B1 plan would be served A1 again. Null means no
  /// level has ever been chosen, or the stored value is not a valid
  /// [LearnerLevel] code. This never changes [userLevelCode] itself.
  static const String grammarPlanLevelPreferenceKey = 'kl_gram_plan_level_v1';

  static String? get grammarPlanLevel {
    if (_grammarPlanConfirmedViewInitialized) {
      return _confirmedGrammarPlanLevel;
    }
    return _optionalLearnerLevelCode(grammarPlanLevelPreferenceKey);
  }

  static Future<void> setGrammarPlanLevel(String? level) async {
    final normalized = level == null ? null : _requiredLearnerLevelCode(level);
    _captureGrammarPlanConfirmedView();
    final revision = ++_grammarPlanAdmissionRevision;
    await _enqueueGrammarPlanMutation(() async {
      final store = _grammarPlanStringStore();
      final current = await _reloadGrammarPlanSelectedLevelState(store);
      final currentLevel = current.isPresent ? current.value : null;
      if (currentLevel == normalized) {
        _confirmedGrammarPlanLevel = normalized;
        _confirmedGrammarPlanLevelRevision = revision;
        return;
      }
      if (normalized == null) {
        await _removeStringStrict(
          grammarPlanLevelPreferenceKey,
          preferences: store,
          assertCurrentWrite: null,
        );
      } else {
        await _ssStrict(
          grammarPlanLevelPreferenceKey,
          normalized,
          preferences: store,
          beforeState: current,
        );
      }
      _confirmedGrammarPlanLevel = normalized;
      _confirmedGrammarPlanLevelRevision = revision;
    });
  }

  static PreferenceStringStore _grammarPlanStringStore() {
    final store =
        _grammarPlanStoreForTesting ??
        (_prefs == null ? null : _SharedPreferenceStringStore(_prefs!));
    if (store == null) {
      throw const PreferenceWriteException('kl_gram_plan_v1');
    }
    return store;
  }

  static Future<void> _saveGrammarPlanOperation(
    GrammarPlanWriteOperation operation,
  ) => _enqueueGrammarPlanMutation(() async {
    operation._assertCurrent();
    final store = _grammarPlanStringStore();
    if (!operation._planConfirmed) {
      await _saveGrammarPlanLeg(operation, store);
    } else {
      final current = await _reloadGrammarPlanState(store);
      final target = _grammarPlanTargetCanonical(current, operation.plan.level);
      if (target != _grammarPlanCanonical(operation.plan.toJson())) {
        throw GrammarPlanConflictException(operation.plan.level);
      }
      operation._candidateRaw = current.value;
    }
    operation._assertCurrent();
    if (operation.requiresSelectedLevel && !operation._selectedLevelConfirmed) {
      await _saveGrammarPlanSelectedLevelLeg(operation, store);
    }
    operation._assertCurrent();
    _unconfirmedGrammarPlanLevels.remove(operation.plan.level);
    _publishGrammarPlanConfirmedCandidate(operation._candidateRaw!);
    if (operation.requiresSelectedLevel) {
      _confirmedGrammarPlanLevel = operation.selectedLevel;
    }
    operation._completed = true;
  });

  static Future<void> _saveGrammarPlanLeg(
    GrammarPlanWriteOperation operation,
    PreferenceStringStore store,
  ) async {
    final current = await _reloadGrammarPlanState(store);
    final desired = _grammarPlanCanonical(operation.plan.toJson());
    final target = _grammarPlanTargetCanonical(current, operation.plan.level);
    if (target == desired) {
      operation._candidateRaw = current.value;
      operation._planConfirmed = true;
      _unconfirmedGrammarPlanLevels.add(operation.plan.level);
      return;
    }
    final baseline = _grammarPlanTargetCanonicalFromRaw(
      operation._baselineRaw,
      operation.plan.level,
    );
    if (target != baseline) {
      throw GrammarPlanConflictException(operation.plan.level);
    }
    final container = _grammarPlanContainer(current);
    final existingTarget = _grammarPlanValidatedTarget(
      container,
      operation.plan.level,
    );
    container[operation.plan.level] = <String, Object?>{
      ...?existingTarget,
      ...operation.plan.toJson(),
    };
    final candidate = jsonEncode(container);
    operation._candidateRaw = candidate;
    operation._assertCurrent();
    _unconfirmedGrammarPlanLevels.add(operation.plan.level);
    await _ssStrict(
      'kl_gram_plan_v1',
      candidate,
      preferences: store,
      beforeState: current,
      assertCurrentWrite: operation._assertCurrent,
    );
    operation._planConfirmed = true;
  }

  static void _publishGrammarPlanConfirmedCandidate(String candidateRaw) {
    if (_unconfirmedGrammarPlanLevels.isEmpty) {
      _confirmedGrammarPlanRaw = candidateRaw;
      return;
    }
    final candidate = _grammarPlanContainer(
      _StringPreferenceState._(isPresent: true, value: candidateRaw),
    );
    Map<String, Object?> confirmed;
    try {
      confirmed = _confirmedGrammarPlanRaw.isEmpty
          ? <String, Object?>{}
          : _grammarPlanContainer(
              _StringPreferenceState._(
                isPresent: true,
                value: _confirmedGrammarPlanRaw,
              ),
            );
    } on GrammarPlanRecoveryValueException {
      confirmed = <String, Object?>{};
    }
    for (final level in _unconfirmedGrammarPlanLevels) {
      if (confirmed.containsKey(level)) {
        candidate[level] = confirmed[level];
      } else {
        candidate.remove(level);
      }
    }
    if (_grammarPlanCanonical(candidate) == _grammarPlanCanonical(confirmed)) {
      return;
    }
    _confirmedGrammarPlanRaw = jsonEncode(candidate);
  }

  static Future<void> _saveGrammarPlanSelectedLevelLeg(
    GrammarPlanWriteOperation operation,
    PreferenceStringStore store,
  ) async {
    final current = await _reloadGrammarPlanSelectedLevelState(store);
    final desired = operation.selectedLevel;
    final currentLevel = current.isPresent ? current.value : null;
    if (currentLevel == desired) {
      operation._selectedLevelConfirmed = true;
      _confirmedGrammarPlanLevelRevision = operation._revision;
      return;
    }
    if (currentLevel != operation._baselineSelectedLevel) {
      final wasConfirmedByEarlierAdmission =
          _confirmedGrammarPlanLevelRevision >
              operation._baselineSelectedLevelRevision &&
          _confirmedGrammarPlanLevelRevision < operation._revision;
      if (!wasConfirmedByEarlierAdmission) {
        throw GrammarPlanConflictException(operation.plan.level);
      }
    }
    operation._assertCurrent();
    if (desired == null) {
      await _removeStringStrict(
        grammarPlanLevelPreferenceKey,
        preferences: store,
        assertCurrentWrite: operation._assertCurrent,
      );
    } else {
      await _ssStrict(
        grammarPlanLevelPreferenceKey,
        desired,
        preferences: store,
        beforeState: current,
        assertCurrentWrite: operation._assertCurrent,
      );
    }
    operation._selectedLevelConfirmed = true;
    _confirmedGrammarPlanLevelRevision = operation._revision;
  }

  static Future<_StringPreferenceState> _reloadGrammarPlanState(
    PreferenceStringStore store,
  ) async {
    const key = 'kl_gram_plan_v1';
    try {
      await store.reload();
      final state = _StringPreferenceState.read(store, key);
      if (state.isPresent) {
        _grammarPlanContainer(state);
      }
      _unknownStrictKeys.remove(key);
      return state;
    } on GrammarPlanRecoveryValueException {
      rethrow;
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
  }

  static Future<_StringPreferenceState> _reloadGrammarPlanSelectedLevelState(
    PreferenceStringStore store,
  ) async {
    try {
      await store.reload();
      final state = _StringPreferenceState.read(
        store,
        grammarPlanLevelPreferenceKey,
      );
      _unknownStrictKeys.remove(grammarPlanLevelPreferenceKey);
      return state;
    } on Object catch (error) {
      _unknownStrictKeys.add(grammarPlanLevelPreferenceKey);
      throw PreferenceOutcomeUnknownException(
        grammarPlanLevelPreferenceKey,
        cause: error,
      );
    }
  }

  static Map<String, Object?> _grammarPlanContainer(
    _StringPreferenceState state,
  ) {
    if (!state.isPresent || state.value!.trim().isEmpty) {
      return <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(state.value!);
      if (decoded is! Map) {
        throw const GrammarPlanRecoveryValueException();
      }
      return <String, Object?>{
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on GrammarPlanRecoveryValueException {
      rethrow;
    } on Object {
      throw const GrammarPlanRecoveryValueException();
    }
  }

  static String? _grammarPlanTargetCanonical(
    _StringPreferenceState state,
    String level,
  ) {
    final container = _grammarPlanContainer(state);
    final target = _grammarPlanValidatedTarget(container, level);
    if (target == null) {
      return null;
    }
    final decoded = GrammarStudyPlan.fromJson(<String, dynamic>{...target});
    final normalized = decoded.level.isEmpty
        ? decoded.copyWith(level: level)
        : decoded;
    return _grammarPlanCanonical(normalized.toJson());
  }

  static Map<String, Object?>? _grammarPlanValidatedTarget(
    Map<String, Object?> container,
    String level,
  ) {
    final raw = container[level];
    if (raw == null) {
      return null;
    }
    if (raw is! Map) {
      throw const GrammarPlanRecoveryValueException();
    }
    final target = <String, Object?>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
    final storedLevel = target['level'];
    if (storedLevel != null &&
        (storedLevel is! String ||
            (storedLevel.isNotEmpty &&
                storedLevel.toLowerCase() != level.toLowerCase()))) {
      throw const GrammarPlanRecoveryValueException();
    }
    final itemsPerDay = target['itemsPerDay'];
    if (itemsPerDay != null &&
        (itemsPerDay is! num || itemsPerDay.toInt() <= 0)) {
      throw const GrammarPlanRecoveryValueException();
    }
    final served = target['servedIdsByDate'];
    if (served != null && served is! Map) {
      throw const GrammarPlanRecoveryValueException();
    }
    if (served is Map && served.values.any((value) => value is! List)) {
      throw const GrammarPlanRecoveryValueException();
    }
    return target;
  }

  static String? _grammarPlanTargetCanonicalFromRaw(String raw, String level) {
    final state = raw.isEmpty
        ? const _StringPreferenceState.absent()
        : _StringPreferenceState._(isPresent: true, value: raw);
    return _grammarPlanTargetCanonical(state, level);
  }

  static String? _grammarPlanCanonical(Object? value) =>
      value == null ? null : jsonEncode(value);

  /// Strict cloud-restore-only writer. A fresh local value wins after the
  /// reload boundary; the caller's session guard is then checked immediately
  /// before the platform setter.
  static Future<GrammarPlanRestoreResult> setGrammarPlanRawJsonForRestore(
    String json, {
    void Function()? assertCurrentWrite,
  }) {
    _captureGrammarPlanConfirmedView();
    return _enqueueGrammarPlanMutation(() async {
      const key = 'kl_gram_plan_v1';
      final store = _grammarPlanStringStore();

      try {
        if (_unknownStrictKeys.contains(key)) {
          await _refreshUnknownStringKeys(store, [key]);
        } else {
          await store.reload();
        }
      } on PreferenceOutcomeUnknownException {
        rethrow;
      } on Object catch (error) {
        _unknownStrictKeys.add(key);
        throw PreferenceOutcomeUnknownException(key, cause: error);
      }

      late final _StringPreferenceState before;
      try {
        before = _StringPreferenceState.read(store, key);
      } on Object catch (error) {
        debugPrint('Storage: malformed grammar plan during restore: $error');
        return GrammarPlanRestoreResult.skippedRecoveryValue;
      }
      if (before.isPresent && before.value!.isNotEmpty) {
        _publishGrammarPlanConfirmedCandidate(before.value!);
        return GrammarPlanRestoreResult.skippedExisting;
      }
      await _ssStrict(
        key,
        json,
        preferences: store,
        beforeState: before,
        assertCurrentWrite: assertCurrentWrite,
      );
      _unconfirmedGrammarPlanLevels.clear();
      _confirmedGrammarPlanRaw = json;
      return GrammarPlanRestoreResult.written;
    });
  }

  static Future<void> setGrammarLastIdx(int v) => _si('kl_gram_last_idx', v);
  static Future<void> addGrammarSeen(String pattern) async {
    final list = grammarSeen;
    if (!list.contains(pattern)) {
      list.add(pattern);
      await _sl('kl_gram_seen', list);
    }
  }

  static Future<void> markGrammarHard(String pattern) async {
    final list = grammarHard;
    if (!list.contains(pattern)) {
      list.add(pattern);
      await _sl('kl_gram_hard', list);
    }
  }

  static Future<void> markGrammarEasy(String pattern) async {
    final list = grammarHard;
    if (list.contains(pattern)) {
      list.remove(pattern);
      await _sl('kl_gram_hard', list);
    }
  }

  // ───────── Onboarding ─────────
  static bool get hasCompletedOnboarding => _b('kl_onboarding_completed');
  static Future<void> setHasCompletedOnboarding(bool v) =>
      _sb('kl_onboarding_completed', v);
  static Future<void> setHasCompletedOnboardingStrict(
    bool v, {
    PreferenceBoolStore? preferences,
  }) => _sbStrict('kl_onboarding_completed', v, preferences: preferences);

  /// Whether this local app-data lifetime has already consumed the one allowed
  /// attempt to report a consented first learning action.
  ///
  /// The marker deliberately contains no action, purpose, route, or payload.
  /// Any non-empty value fails closed so a malformed future/legacy value cannot
  /// cause a duplicate analytics attempt.
  static bool get hasClaimedConsentedFirstLearningAction =>
      _s(consentedFirstLearningActionClaimPreferenceKey).isNotEmpty;

  /// Durably claims the one local attempt to report a first learning action.
  ///
  /// Callers must check effective analytics consent before invoking this. The
  /// strict write is the commit point and happens before analytics delivery, so
  /// process death cannot turn one observed action into multiple send attempts.
  /// Calls within one isolate are serialized to keep the read/write claim
  /// atomic with respect to other callers of this method.
  static Future<bool> claimConsentedFirstLearningAction() {
    final result = _consentedFirstLearningActionClaimMutation.then((_) async {
      if (hasClaimedConsentedFirstLearningAction) {
        return false;
      }
      await _ssStrict(
        consentedFirstLearningActionClaimPreferenceKey,
        _consentedFirstLearningActionClaimValue,
      );
      return true;
    });
    _consentedFirstLearningActionClaimMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static int get sessionCount => _i('kl_session_count');
  static Future<void> setSessionCount(int v) => _si('kl_session_count', v);

  static String get lastActivityTime =>
      _s('kl_last_activity_time'); // ISO 8601 datetime
  static Future<void> setLastActivityTime(String v) =>
      _ss('kl_last_activity_time', v);
  static Future<void> setLastActivityTimeStrict(
    String v, {
    PreferenceStringStore? preferences,
  }) => _ssStrict('kl_last_activity_time', v, preferences: preferences);

  static int get dailyGoalMinutes => _i('kl_daily_goal_minutes');
  static Future<void> setDailyGoal(int minutes) =>
      _si('kl_daily_goal_minutes', minutes);

  // ───────── Lern-Motivation (서양 학습자 어필 — 왜 배우는가) ─────────
  /// 학습 이유 id (LearnerMotivation.name). 빈 문자열 = 미설정.
  static String get motivation => _s('kl_motivation');
  static Future<void> setMotivation(String id) => _ss('kl_motivation', id);
  static Future<void> setMotivationStrict(
    String id, {
    PreferenceStringStore? preferences,
  }) => _ssStrict('kl_motivation', id, preferences: preferences);

  /// 동기 시트를 이미 물었나(1회 노출 가드).
  static bool get motivationAsked => _b('kl_motivation_asked');
  static Future<void> setMotivationAsked() => _sb('kl_motivation_asked', true);
  static Future<void> setMotivationAskedStrict({
    PreferenceBoolStore? preferences,
  }) => _sbStrict('kl_motivation_asked', true, preferences: preferences);

  // ───────── Tageskurs 전용 카드 주 1회 가드 (디자인 Q2) ─────────
  /// 전용 카드를 노출한 ISO 주('2026-W32'). 같은 주엔 홈 카드 숨김 —
  /// 미션 히어로의 Tageskurs 배지 진입점은 항상 남는다.
  static String get courseCardWeekShown => _s('kl_course_card_week');
  static Future<void> setCourseCardWeekShown(String week) =>
      _ss('kl_course_card_week', week);

  // ───────── Meilensteine (달성 축하 1회 가드) ─────────
  /// 이미 축하한 마일스톤 id 목록(중복 축하 방지).
  static List<String> get celebratedMilestones => _l('kl_milestones');
  static Future<void> markMilestonesCelebrated(List<String> ids) async {
    final list = celebratedMilestones;
    var changed = false;
    for (final id in ids) {
      if (!list.contains(id)) {
        list.add(id);
        changed = true;
      }
    }
    if (changed) {
      await _sl('kl_milestones', list);
    }
  }

  static const String selectedCompanionPreferenceKey =
      'kl_selected_companion_v1';
  static const String companionVisiblePreferenceKey = 'kl_companion_visible_v1';

  static String get preferredMascot =>
      _s('kl_preferred_mascot'); // Legacy mirror: tiger, magpie, or none.
  static Future<void> setPreferredMascot(String mascot) =>
      _ss('kl_preferred_mascot', mascot);
  static Future<void> setPreferredMascotStrict(
    String mascot, {
    PreferenceStringStore? preferences,
  }) => _ssStrict('kl_preferred_mascot', mascot, preferences: preferences);

  /// Explicit V2 identity only. Unlike [selectedCompanion], this never turns a
  /// missing key or a legacy `none` value into an implicit Taego selection.
  static String? get explicitSelectedCompanion {
    final selected = _s(selectedCompanionPreferenceKey);
    return selected == 'tiger' || selected == 'magpie' ? selected : null;
  }

  /// The learner's durable Taego/Joy choice, independent from presentation.
  ///
  /// Legacy installs only have [preferredMascot]. An explicit legacy `none`
  /// means "hidden" rather than "no chosen identity" in V2, so Taego is the
  /// safe migration fallback until the learner chooses again.
  static String get selectedCompanion {
    final selected = explicitSelectedCompanion;
    if (selected != null) {
      return selected;
    }
    final legacy = preferredMascot;
    return legacy == 'magpie' ? 'magpie' : 'tiger';
  }

  static Future<void> setSelectedCompanion(String companion) {
    if (companion != 'tiger' && companion != 'magpie') {
      throw ArgumentError.value(
        companion,
        'companion',
        'must be tiger or magpie',
      );
    }
    return _ss(selectedCompanionPreferenceKey, companion);
  }

  static Future<void> setSelectedCompanionStrict(
    String companion, {
    PreferenceStringStore? preferences,
  }) {
    if (companion != 'tiger' && companion != 'magpie') {
      throw ArgumentError.value(
        companion,
        'companion',
        'must be tiger or magpie',
      );
    }
    return _ssStrict(
      selectedCompanionPreferenceKey,
      companion,
      preferences: preferences,
    );
  }

  /// Whether the selected companion is rendered on personal companion slots.
  /// Missing V2 state preserves the legacy `none` behavior during migration.
  static bool get companionVisible =>
      _prefs?.getBool(companionVisiblePreferenceKey) ??
      preferredMascot != 'none';

  static Future<void> setCompanionVisible(bool visible) =>
      _sb(companionVisiblePreferenceKey, visible);
  static Future<void> setCompanionVisibleStrict(
    bool visible, {
    PreferenceBoolStore? preferences,
  }) => _sbStrict(
    companionVisiblePreferenceKey,
    visible,
    preferences: preferences,
  );

  /// Keep the existing front reading aid until the learner chooses the back.
  static bool get flashcardRomanizationOnFront =>
      _b('kl_flashcard_romanization_front', true);
  static Future<void> setFlashcardRomanizationOnFront(bool value) =>
      _sb('kl_flashcard_romanization_front', value);

  // ───────── App / Streak ─────────
  static String get lastOpenDate => _s('kl_last_open_date'); // 'YYYY-MM-DD'
  static int get streakDays => _i('kl_streak_days');
  static int get bestStreak => _i('kl_best_streak');
  static Future<void> setLastOpenDate(String value) =>
      _ss('kl_last_open_date', value);
  static Future<void> setStreakDays(int value) => _si('kl_streak_days', value);
  static Future<void> setBestStreak(int value) => _si('kl_best_streak', value);

  /// §S3: calendar day (yyyy-MM-dd, local) the Gye life-promise projection
  /// backup ([CourseActivityReporter._scheduleLifePromiseProjectionSync])
  /// last ran, so a second passing checkpoint on the same day skips a
  /// redundant full [CloudSync.backupWithResult] call. `null` = never run.
  static String? get lastLifePromiseBackupDay =>
      _optionalString('kl_last_life_promise_backup_day_v1');
  static Future<void> setLastLifePromiseBackupDay(String day) async {
    final normalized = day.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(day, 'day', 'must not be empty');
    }
    await _ss('kl_last_life_promise_backup_day_v1', normalized);
  }

  /// §S3 (R2/R4 durability gap B): `packId`s [PackSyncQueue] is currently
  /// holding for a Firestore backup mirror flush. Persisted so a process
  /// kill before the queue's status-transition/idle/`flushAll` triggers
  /// fire doesn't lose the write — `PackSyncQueue.flushPendingFromStorage()`
  /// reloads these ids (and their local JSON via [packProgressJson]) at the
  /// next startup once cloud backup is usable again.
  static List<String> get pendingPackSyncIds => _l('kl_pack_sync_pending_v1');
  static Future<void> setPendingPackSyncIds(List<String> ids) =>
      _sl('kl_pack_sync_pending_v1', ids);

  /// Streak-Freeze Tokens. Verdient an jeder 7-Tage-Marke (Cap [kStreakFreezeMax]).
  /// Schützt automatisch genau einen verpassten Tag, damit der Streak überlebt.
  static int get streakFreezes => _i('kl_streak_freezes');
  static String get streakFreezeLastUsed => _s('kl_streak_freeze_last_used');
  static const int kStreakFreezeMax = 2;
  static const int kStreakFreezeRefillDays = 7;

  /// Beim App-Start aufrufen — aktualisiert Streak automatisch.
  /// [now] ist für Tests injizierbar; default = `DateTime.now()`.
  static Future<void> touchStreak({DateTime? now}) async {
    final today = _today(now);
    final last = lastOpenDate;
    if (last == today) return;

    int newStreak = 1;
    int freezes = streakFreezes;
    bool freezeUsed = false;

    if (last.isNotEmpty) {
      final lastDate = DateTime.tryParse(last);
      if (lastDate != null) {
        final diff = DateTime.parse(today).difference(lastDate).inDays;
        if (diff == 1) {
          newStreak = streakDays + 1;
        } else if (diff == 2 && freezes > 0) {
          // Genau ein verpasster Tag → Freeze einsetzen.
          newStreak = streakDays + 1;
          freezes -= 1;
          freezeUsed = true;
        }
      }
    }

    await _ss('kl_last_open_date', today);
    await _si('kl_streak_days', newStreak);
    if (newStreak > bestStreak) await _si('kl_best_streak', newStreak);

    if (newStreak > 0 &&
        newStreak % kStreakFreezeRefillDays == 0 &&
        freezes < kStreakFreezeMax) {
      freezes += 1;
    }
    await _si('kl_streak_freezes', freezes);
    if (freezeUsed) {
      await _ss('kl_streak_freeze_last_used', today);
    }
  }

  static String _today([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// 오늘 ISO 날짜(YYYY-MM-DD). 학습 원장 조회의 공용 기준일이다.
  static String todayIso() => _today();

  /// 특정 달력 날짜의 ISO 키. 학습 원장 날짜 선택의 공용 기준이다.
  static String todayIsoFor(DateTime d) => _isoOf(d);

  // ───────── Einstellungen ─────────
  static String get localeCode => _s('kl_locale'); // 'de', 'en', '' = system
  static Future<void> setLocaleCode(String v) => _ss('kl_locale', v);

  /// Theme-Modus: 'light' / 'dark' / '' = System.
  static String get themeMode => _s('kl_theme_mode');
  static Future<void> setThemeMode(String v) => _ss('kl_theme_mode', v);

  /// Daily Calligraphy — Liste der ISO-Daten (YYYY-MM-DD) an denen geübt wurde.
  static List<String> get calligraphyDates => _l('kl_callig_dates');
  static Future<void> addCalligraphyDate(String iso) async {
    final list = calligraphyDates;
    if (!list.contains(iso)) {
      list.add(iso);
      await _sl('kl_callig_dates', list);
    }
  }

  static bool get calligraphyDoneToday => calligraphyDates.contains(_today());
  static int get calligraphyTotalDays => calligraphyDates.length;

  /// 옛 도장 slug → 현행 slug. 읽는 시점에만 갈아끼운다(쓰기는 이미 새 이름).
  ///
  /// 2026-08-04: `swastika` → `manja`. 그림은 만자문(卍) 격자라 문제없지만,
  /// 이 문자열이 저장값에 남고 `cloud_sync` 로 백업까지 타고 있었다.
  /// 독일어권 대상 앱에서 굳이 남길 이유가 없다.
  static const Map<String, String> _legacyStampSlugs = {'swastika': 'manja'};

  /// 도장첩 — 획득한 단청 도장 motif slug 목록 (DancheongMotif.name).
  /// 옛 slug 는 현행 이름으로 바꿔서 돌려주고, 그 과정에서 생길 수 있는
  /// 중복(옛·새 이름이 둘 다 저장된 경우)은 순서를 지키며 합친다.
  static List<String> get earnedStamps {
    final out = <String>{};
    for (final s in _l('kl_stamps_earned')) {
      out.add(_legacyStampSlugs[s] ?? s);
    }
    return out.toList();
  }

  static Future<void> addEarnedStamp(String motif) async {
    final list = earnedStamps;
    if (!list.contains(motif)) {
      list.add(motif);
      await _sl('kl_stamps_earned', list);
    }
  }

  // ── 사랑방 배치 (ADR-002) ────────────────────────────────────────────
  //
  // 보상 흐름: 퀘스트 완료 → 보자기 꾸러미 → 열어서 선택 → 보유 → 방에 배치.
  // 셋 다 작은 컬렉션이라 SharedPreferences 로 충분하다.

  /// 미개봉 꾸러미 — 값은 지급 출처 퀘스트 id (중복 가능: 같은 퀘스트가
  /// 반복형이면 여러 개 쌓일 수 있으므로 Set 이 아니라 List).
  static List<String> get pendingBoxes => _l('kl_reward_boxes');

  static const String _pronunciationPassCountKey =
      'kl_pronunciation_pass_count_v1';
  static const String _pronunciationAssessmentIdsKey =
      'kl_pronunciation_assessment_ids_v1';
  static const String _pronunciationLastScoreKey =
      'kl_pronunciation_last_score_v1';
  static const String _pronunciationProgressKey =
      'kl_pronunciation_progress_v2';
  static const String _gyeUniqueMemberCountKey =
      'kl_gye_unique_member_count_v1';

  static int get pronunciationPassCount => _readPronunciationProgress().count;
  static List<String> get pronunciationAssessmentIds =>
      _readPronunciationProgress().assessmentIds;
  static double get pronunciationLastScore =>
      _readPronunciationProgress().lastScore;

  static bool get pronunciationConsent =>
      PrivacyChoiceStorage.admitted(PrivacyPurpose.pronunciation);
  static Future<void> setPronunciationConsent(bool value) =>
      PrivacyChoiceStorage.set(PrivacyPurpose.pronunciation, value);

  static Future<bool> recordPronunciationPass(
    String assessmentId,
    double score, {
    PreferenceStringStore? preferences,
  }) {
    final operation = _pronunciationProgressMutation.then((_) async {
      final normalizedId = assessmentId.trim();
      if (normalizedId.isEmpty ||
          normalizedId.length > 128 ||
          !score.isFinite) {
        return false;
      }
      final store =
          preferences ??
          (_prefs == null ? null : _SharedPreferenceStringStore(_prefs!));
      if (store == null) {
        throw PreferenceWriteException(_pronunciationProgressKey);
      }
      await store.reload();
      final current = _readPronunciationProgress(preferences: store);
      if (current.assessmentIds.contains(normalizedId) ||
          current.count >= 100) {
        return false;
      }
      final next = _PronunciationProgressRecord(
        count: current.count + 1,
        assessmentIds: <String>[...current.assessmentIds, normalizedId],
        lastScore: score,
      );
      await _ssStrict(
        _pronunciationProgressKey,
        jsonEncode(next.toJson()),
        preferences: store,
      );
      return true;
    });
    _pronunciationProgressMutation = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  static _PronunciationProgressRecord _readPronunciationProgress({
    PreferenceStringStore? preferences,
  }) {
    final raw =
        preferences?.getString(_pronunciationProgressKey) ??
        _s(_pronunciationProgressKey);
    final decoded = _PronunciationProgressRecord.tryParse(raw);
    if (decoded != null) {
      return decoded;
    }
    final legacyIds = <String>[];
    for (final value in _l(_pronunciationAssessmentIdsKey)) {
      final id = value.trim();
      if (id.isNotEmpty && id.length <= 128 && !legacyIds.contains(id)) {
        legacyIds.add(id);
      }
    }
    final boundedIds = legacyIds.length <= 100
        ? legacyIds
        : legacyIds.sublist(legacyIds.length - 100);
    final recoveredCount = [
      _i(_pronunciationPassCountKey),
      boundedIds.length,
    ].reduce((left, right) => left > right ? left : right).clamp(0, 100);
    return _PronunciationProgressRecord(
      count: recoveredCount,
      assessmentIds: boundedIds,
      lastScore: _d(_pronunciationLastScoreKey),
    );
  }

  static int get gyeUniqueMemberCount => _i(_gyeUniqueMemberCountKey);
  static Future<void> setGyeUniqueMemberCount(int value) =>
      _si(_gyeUniqueMemberCountKey, value < 0 ? 0 : value);

  static Future<void> addPendingBox(String questId) async =>
      _sl('kl_reward_boxes', [...pendingBoxes, questId]);

  /// 검증·복구 서비스가 사용하는 미개봉 꾸러미 전체 교체 경계.
  ///
  /// UI는 이 메서드를 직접 쓰지 않고 [DecorationRewardService]를 통해
  /// 첫 상자를 소비한다. 새 퀘스트 보상이 수령 중 뒤에 추가됐을 때도 서비스가
  /// 해당 suffix를 보존한 완성 목록만 넘긴다.
  static Future<void> setPendingBoxes(List<String> boxes) async =>
      _sl('kl_reward_boxes', List<String>.from(boxes));

  /// 수령 중단 복구용 versioned raw journal. 해석·유효성 검증은
  /// [DecorationRewardService]가 담당하고 Storage는 직렬화 경계만 맡는다.
  static String get decorationRewardClaimJournalRawJson =>
      _s('kl_reward_claim_v1');

  static Future<void> setDecorationRewardClaimJournalRawJson(String json) =>
      _ss('kl_reward_claim_v1', json);

  static Future<void> clearDecorationRewardClaimJournal() async {
    await PackCompletionStorage.trackWrite('kl_reward_claim_v1', () async {
      await _prefs?.remove('kl_reward_claim_v1');
    });
  }

  /// 꾸러미 하나를 소비한다. 없으면 false.
  static Future<bool> consumePendingBox() async {
    final list = pendingBoxes;
    if (list.isEmpty) return false;
    list.removeAt(0);
    await _sl('kl_reward_boxes', list);
    return true;
  }

  /// 보유 장식 — 꾸러미에서 고른 것들. 순서 무의미, 중복 없음.
  static List<String> get ownedDecor => _l('kl_owned_decor');

  static Future<void> addOwnedDecor(String slug) async {
    final list = ownedDecor;
    if (list.contains(slug)) return;
    await _sl('kl_owned_decor', [...list, slug]);
  }

  /// 장식 slug → 획득 시각(ISO 8601). `reward_unused` 계측(며칠째 미배치인지)
  /// 전용 — 소유권 자체의 정본은 여전히 [ownedDecor]다. 클레임 시점에 기록만
  /// 하고 이후 절대 덮어쓰지 않는다(첫 획득 시각이 정답).
  static Map<String, String> get decorEarnedAt {
    final raw = _s('kl_decor_earned_at');
    if (raw.isEmpty) return const <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Object {
      return const <String, String>{};
    }
  }

  static Future<void> recordDecorEarnedAt(String slug, String isoDate) async {
    final current = decorEarnedAt;
    if (current.containsKey(slug)) return;
    await _ss('kl_decor_earned_at', jsonEncode({...current, slug: isoDate}));
  }

  /// `reward_unused`를 하루 한 번만 보내기 위한 dedup 플래그(로컬 날짜, YYYY-MM-DD).
  static String get rewardUnusedLoggedDate =>
      _s('kl_reward_unused_logged_date');
  static Future<void> setRewardUnusedLoggedDate(String isoDate) =>
      _ss('kl_reward_unused_logged_date', isoDate);

  static const String _roomPlacementKey = 'kl_room_placement';
  static const String _roomPlacementsV2Key = 'kl_room_placements_v2';
  static const String _roomLayoutsV3Key = 'kl_room_layouts_v3';

  /// Raw v3 free-layout document. A null value means no v3 authority exists;
  /// an empty/corrupt string remains distinguishable so callers can recover
  /// from v2 without silently treating damaged data as a deliberate empty
  /// room. Parsing and validation belong to [RoomLayoutService].
  static String? get roomLayoutsV3Raw => _prefs?.getString(_roomLayoutsV3Key);

  /// Persists the complete, validated free-layout document in one write.
  ///
  /// The v2 and legacy keys are intentionally left untouched as a rollback
  /// snapshot. New code must never mirror v3 coordinates into the slot schema.
  static Future<void> setRoomLayoutsV3Raw(String json) async {
    final preferences = _prefs;
    if (preferences == null) {
      throw StateError(
        'Storage must be initialized before saving room layouts.',
      );
    }
    final stored = await preferences.setString(_roomLayoutsV3Key, json);
    if (!stored) {
      throw StateError('Room layout persistence was rejected.');
    }
  }

  /// 구버전 사랑방 배치만 읽는다. v2가 없거나 손상됐을 때의 안전한 복구
  /// 재료이므로 삭제하지 않는다.
  static RoomPlacement get _legacyRoomPlacement {
    final raw = _s(_roomPlacementKey);
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final placement = <String, String>{};
      for (final entry in decoded.entries) {
        if (entry.key is String && entry.value is String) {
          placement[entry.key as String] = entry.value as String;
        }
      }
      return placement;
    } catch (_) {
      return const {};
    }
  }

  /// 모든 개인 방의 배치. v2가 한 번도 저장되지 않았을 때만 구 사랑방
  /// 평면 배치를 사랑방 표면으로 감싸 복구한다. 유효한 빈 v2 `{}`는
  /// 의도적인 "전부 비움" 이므로 legacy를 되살리지 않는다.
  ///
  /// 손상된 v2 JSON은 새 상태를 추측하지 않고 마지막으로 읽을 수 있는
  /// 사랑방 legacy 값만 안전하게 보여 준다. 각 표면 안에서 손상된 항목은
  /// 제외하고 유효한 문자열 쌍을 보존한다.
  static RoomPlacements get roomPlacements {
    final raw = _prefs?.getString(_roomPlacementsV2Key);
    if (raw != null) {
      final decoded = _decodeRoomPlacementsV2(raw);
      if (decoded != null) {
        return decoded;
      }
    }

    final legacy = _legacyRoomPlacement;
    return legacy.isEmpty
        ? const {}
        : <PersonalRoomSurface, RoomPlacement>{
            PersonalRoomSurface.sarangbang: legacy,
          };
  }

  static RoomPlacements? _decodeRoomPlacementsV2(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final placements = <PersonalRoomSurface, RoomPlacement>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! Map) {
          continue;
        }
        final surface = PersonalRoomSurface.fromStorageKey(entry.key as String);
        if (surface == null) {
          continue;
        }
        final placement = <String, String>{};
        for (final slot in (entry.value as Map).entries) {
          if (slot.key is String && slot.value is String) {
            placement[slot.key as String] = slot.value as String;
          }
        }
        if (placement.isNotEmpty) {
          placements[surface] = placement;
        }
      }
      return placements;
    } catch (_) {
      return null;
    }
  }

  /// 사랑방 하위 호환 별칭. 새 코드에서는 [roomPlacements]를 사용한다.
  static RoomPlacement get roomPlacement => Map<String, String>.from(
    roomPlacements[PersonalRoomSurface.sarangbang] ?? const {},
  );

  /// 검증된 개인 방 배치 전체를 v2로 저장하고 사랑방은 legacy 키에도
  /// mirror-write한다. 구버전 앱이 사랑방을 가능한 한 정확하게 보여 주면서,
  /// 신버전은 독립 표면의 위치를 잃지 않는다.
  ///
  /// 슬롯·카테고리·소유권 규칙은 [RoomPlacementService]가 담당한다. 이
  /// 메서드는 SharedPreferences 직렬화 경계만 맡는다.
  static Future<void> setRoomPlacements(RoomPlacements placements) async {
    final serializable = <String, Object>{
      for (final entry in placements.entries)
        if (entry.value.isNotEmpty)
          entry.key.storageKey: Map<String, String>.from(entry.value),
    };
    await _ss(_roomPlacementsV2Key, jsonEncode(serializable));
    final sarangbang =
        placements[PersonalRoomSurface.sarangbang] ?? const <String, String>{};
    await _ss(_roomPlacementKey, jsonEncode(sarangbang));
  }

  /// 사랑방 배치 전체 저장의 하위 호환 별칭.
  ///
  /// 모든 다른 표면을 보존하면서 사랑방만 바꾸고, 그 결과를 v2와 legacy에
  /// 동시에 쓴다.
  static Future<void> setRoomPlacement(Map<String, String> placement) async {
    final placements = roomPlacements;
    if (placement.isEmpty) {
      placements.remove(PersonalRoomSurface.sarangbang);
    } else {
      placements[PersonalRoomSurface.sarangbang] = Map<String, String>.from(
        placement,
      );
    }
    await setRoomPlacements(placements);
  }

  /// 슬롯에 장식을 놓는다. [slug] 가 null 이면 비운다.
  /// **같은 장식은 한 번에 한 슬롯에만** — 다른 슬롯에 있었다면 거기서 빠진다.
  static Future<void> placeInSlot(String slotId, String? slug) async {
    final m = Map<String, String>.from(roomPlacement);
    if (slug == null) {
      m.remove(slotId);
    } else {
      m.removeWhere((_, v) => v == slug);
      m[slotId] = slug;
    }
    await setRoomPlacement(m);
  }

  static double get ttsRate => _d('kl_tts_rate', 0.42);
  static Future<void> setTtsRate(double v) => _sd('kl_tts_rate', v);

  /// 전역 사용자 속도 배수 (0.5–1.5, 기본 1.0). [ttsRate](엔진 base)와 별개 —
  /// TtsService 가 모든 발화에 곱한다. UI 는 `TtsSpeedControl`.
  static double get ttsSpeed => _d('kl_tts_speed_v1', 1.0);
  static Future<void> setTtsSpeed(double v) => _sd('kl_tts_speed_v1', v);

  // ── 사운드 (ADR-002 §3-4 확정 키 스킴 — 임의 키명 금지) ──────────────
  // 기본값은 AudioPolicy 가 인자로 넘긴다. 여기서 기본을 박으면 채널 기본값
  // 표(ADR §3-1)와 이중 진실이 된다.
  static bool get sndMaster => _b('kl_snd_master', true);
  static Future<void> setSndMaster(bool v) => _sb('kl_snd_master', v);
  static double get sndMasterVol => _d('kl_snd_master_vol', 1.0);
  static Future<void> setSndMasterVol(double v) => _sd('kl_snd_master_vol', v);
  static bool sndChannelOn(String id, bool dflt) => _b('kl_snd_$id', dflt);
  static Future<void> setSndChannelOn(String id, bool v) =>
      _sb('kl_snd_$id', v);
  static double sndChannelVol(String id, double dflt) =>
      _d('kl_snd_${id}_vol', dflt);
  static Future<void> setSndChannelVol(String id, double v) =>
      _sd('kl_snd_${id}_vol', v);
  static bool get sndDuck => _b('kl_snd_duck', true);
  static Future<void> setSndDuck(bool v) => _sb('kl_snd_duck', v);
  static bool get sndRespectSilent => _b('kl_snd_respect_silent', true);
  static Future<void> setSndRespectSilent(bool v) =>
      _sb('kl_snd_respect_silent', v);

  /// Werbung anzeigen? Default true. User kann in Settings deaktivieren.
  /// 광고 표시 여부. **기본값 false** (2026-08-12) — 앱에 광고 SDK 가 없고
  /// Play Data Safety 에 "광고 없음"으로 신고돼 있다. 설정의 토글은 같은 날
  /// 제거했다. 기본값을 true 로 두면 기존 기기에 남은 `kl_ads_enabled=true`
  /// 때문에 향후 광고를 도입할 때 사용자 동의 없이 기본 ON 이 된다.
  static bool get adsEnabled => _prefs?.getBool('kl_ads_enabled') ?? false;
  static Future<void> setAdsEnabled(bool v) async =>
      _prefs?.setBool('kl_ads_enabled', v);

  /// Intro-Gate (솟을대문) schon gesehen? Erstlauf → volle Animation,
  /// danach kürzere Version.
  static bool get introSeen => _prefs?.getBool('kl_intro_seen') ?? false;
  static Future<void> setIntroSeen() async =>
      _prefs?.setBool('kl_intro_seen', true);

  /// C8 (EU AI Act Art. 50(2)) — wurde die einmalige "KI-Stimme"-Snackbar
  /// beim allerersten TTS-Playback schon gezeigt? `introSeen`-Muster.
  static bool get aiVoiceNoticeShownV1 =>
      _prefs?.getBool('kl_ai_voice_notice_shown_v1') ?? false;
  static Future<void> setAiVoiceNoticeShownV1() async =>
      _prefs?.setBool('kl_ai_voice_notice_shown_v1', true);

  // ───────── 한글 쓰기 판정 강도 ─────────

  /// 한글 Schreiben 탭에서 획순을 엄격히 검사하는가.
  ///
  /// 2026-08-17 테스터(Amor): "일부러 획순을 틀려도 그냥 진행된다." 기본값을
  /// 검사 ON 으로 두되, 자유 필기를 원하면 화면 안에서 칩으로 끌 수 있다
  /// (`stroke_matcher.dart` 에 적힌 관대함 논리는 그 모드로 살아남는다).
  static bool get hangulStrictStrokes =>
      _prefs?.getBool('kl_hangul_strict_strokes') ?? true;
  static Future<void> setHangulStrictStrokes(bool v) =>
      _sb('kl_hangul_strict_strokes', v);

  // ───────── 온보딩 코치마크 1회성 플래그 (Stage 1) ─────────
  // `introSeen` 패턴과 동일. 각각 진입 화면에서 최초 1회 시트 표시.

  /// 책 한 컷 코치마크 표시됨?
  static bool get tutBookSeen => _prefs?.getBool('kl_tut_book') ?? false;
  static Future<void> setTutBookSeen() async =>
      _prefs?.setBool('kl_tut_book', true);

  /// 단어팩 진입 코치마크 표시됨?
  static bool get tutVocabPackSeen =>
      _prefs?.getBool('kl_tut_vocab_pack') ?? false;
  static Future<void> setTutVocabPackSeen() async =>
      _prefs?.setBool('kl_tut_vocab_pack', true);

  /// 단어팩 퀴즈 스테이지 인라인 배너 표시됨?
  static bool get tutPackQuizSeen =>
      _prefs?.getBool('kl_tut_pack_quiz') ?? false;
  static Future<void> setTutPackQuizSeen() async =>
      _prefs?.setBool('kl_tut_pack_quiz', true);

  /// 단어팩 보스 스테이지 인라인 배너 표시됨?
  static bool get tutPackBossSeen =>
      _prefs?.getBool('kl_tut_pack_boss') ?? false;
  static Future<void> setTutPackBossSeen() async =>
      _prefs?.setBool('kl_tut_pack_boss', true);

  /// 홈 투어 스포트라이트 코치마크 표시됨? (Stage A — BottomNav 4탭 + 학습경로)
  /// _prefs 미초기화(테스트/웹 샌드박스 등) 시 true 반환 — 투어 미표시(안전 기본값).
  static bool get tutHomeTourSeen =>
      _prefs == null ? true : (_prefs!.getBool('kl_tut_home_tour') ?? false);
  static Future<void> setTutHomeTourSeen() async =>
      _prefs?.setBool('kl_tut_home_tour', true);

  /// 단어장 추가(북마크) 버튼 첫 노출 코치마크 표시됨? (＋단어장 안내)
  /// _prefs 미초기화 시 true(미표시·안전 기본값).
  static bool get tutWordbookSeen =>
      _prefs == null ? true : (_prefs!.getBool('kl_tut_wordbook') ?? false);
  static Future<void> setTutWordbookSeen() async =>
      _prefs?.setBool('kl_tut_wordbook', true);

  /// 문화어 장식 감상 안내는 이 기기에서 한 번만 보인다.
  /// SharedPreferences 미초기화 환경에서는 표시하지 않는 안전 기본값을 쓴다.
  static bool get culturalObjectHintSeen => _prefs == null
      ? true
      : (_prefs!.getBool('cultural_object_hint_seen_v1') ?? false);
  static Future<void> setCulturalObjectHintSeen() async =>
      _prefs?.setBool('cultural_object_hint_seen_v1', true);

  /// Settings "Kulturhinweise zurücksetzen" (§W-C C5) — shows the one-time
  /// object hint again on the next visit to a scene with inspectable decor.
  static Future<void> resetCulturalObjectHintSeen() async =>
      _prefs?.setBool('cultural_object_hint_seen_v1', false);

  /// 콘텐츠 화면별 사용법 코치마크 — 범용 플래그(`kl_tut_<id>`).
  /// 화면 id 레지스트리: 오타·resetTutorials 누락 방지(ScreenCoachMixin assert).
  static const List<String> kScreenCoachIds = [
    'chosung',
    'wordle',
    'kkeunmari',
    'listening',
    'listening_play',
    'hangul',
    'grammar',
    'smalltalk',
    'scenario',
    'review',
    'legacyVocab',
    'learningPath',
    'bookshelf',
    'cpEdit',
    'cpPlay',
    'cpQuiz',
    'cpMatching',
    'cpTyping',
    'hardWords',
    'wordWeb',
    'dojang',
    'gye',
    'gye_tab',
    'practice_hub',
    'profile',
    'stats',
    'quests',
    'scenarios',
    // Sori Deck 4방향 스와이프 공용 코치 (deck_coach.dart — ScreenCoachMixin
    // 밖의 공용 헬퍼지만 같은 레지스트리로 resetTutorials 커버리지를 받는다).
    'soriDeck',
  ];

  /// 화면 코치마크 표시됨? `_prefs` 미초기화(테스트/웹) 시 true(미표시·안전).
  static bool tutSeen(String id) =>
      _prefs == null ? true : (_prefs!.getBool('kl_tut_$id') ?? false);
  static Future<void> setTutSeen(String id) async =>
      _prefs?.setBool('kl_tut_$id', true);

  /// In-memory revision for process-wide coach guards. The user-facing
  /// Settings reset advances it so helpers outside [ScreenCoachMixin] can
  /// invalidate their session-only suppression without a service→widget
  /// dependency. Test storage teardown intentionally does not impersonate a
  /// user-requested tutorial reset.
  static int get tutorialResetRevision => _tutorialResetRevision;

  /// 온보딩 3장 미리보기 캐러셀 표시됨? (Stage 2)
  static bool get introPreviewSeen =>
      _prefs?.getBool('kl_intro_preview_seen') ?? false;
  static Future<void> setIntroPreviewSeen() async =>
      _prefs?.setBool('kl_intro_preview_seen', true);

  /// 모든 튜토리얼·코치마크 플래그를 false로 리셋 (Settings "안내 다시 보기").
  /// `introSeen`(솟을대문 애니메이션)은 건드리지 않음 — 코치마크와 별도 개념.
  static Future<void> resetTutorials() async {
    await Future.wait([
      _sb('kl_tut_book', false),
      _sb('kl_tut_vocab_pack', false),
      _sb('kl_tut_pack_quiz', false),
      _sb('kl_tut_pack_boss', false),
      _sb('kl_intro_preview_seen', false),
      _sb('kl_tut_home_tour', false),
      _sb('kl_tut_wordbook', false),
      _sb('cultural_object_hint_seen_v1', false),
      for (final id in kScreenCoachIds) _sb('kl_tut_$id', false),
    ]);
    _tutorialResetRevision++;
  }

  /// DSGVO/ToS-Einwilligung beim ersten Start akzeptiert? (Consent-Gate)
  static bool get consentAccepted =>
      _prefs?.getBool('kl_consent_accepted') ?? false;
  static Future<void> setConsentAccepted({PreferenceBoolStore? preferences}) =>
      _sbStrict('kl_consent_accepted', true, preferences: preferences);

  /// Opt-in: anonyme Nutzungsstatistiken (Firebase Analytics).
  /// Default **false** — Erhebung erst nach expliziter Einwilligung
  /// (TTDSG §25 / DSGVO Art. 6). Jederzeit in den Einstellungen widerrufbar.
  static bool get analyticsConsent =>
      PrivacyChoiceStorage.admitted(PrivacyPurpose.analytics);
  static Future<void> setAnalyticsConsent(bool v) =>
      PrivacyChoiceStorage.set(PrivacyPurpose.analytics, v);

  /// Opt-in: Absturzberichte (Firebase Crashlytics). Default **false**.
  static bool get crashConsent =>
      PrivacyChoiceStorage.admitted(PrivacyPurpose.crash);
  static Future<void> setCrashConsent(bool v) =>
      PrivacyChoiceStorage.set(PrivacyPurpose.crash, v);

  /// Der nachgelagerte Analytics/Crash-Opt-in-Dialog wurde bereits einmal
  /// gezeigt? Wird in dem Moment gesetzt, in dem das Sheet nach dem ersten
  /// Erfolg erscheint — damit nie erneut gefragt wird (DSGVO Art. 7, kein
  /// Nagging), unabhängig von der Antwort des Nutzers.
  static bool get consentInviteShown =>
      _prefs?.getBool('kl_consent_invite_shown') ?? false;
  static Future<void> setConsentInviteShown() async =>
      _prefs?.setBool('kl_consent_invite_shown', true);

  /// Platzierungstest im Onboarding absolviert? Nur für die Analytics-Property
  /// has_placement (misst, ob Placement die Retention verbessert). Kein PII.
  static bool get placementTaken =>
      _prefs?.getBool('kl_placement_taken') ?? false;
  static Future<void> setPlacementTaken() async =>
      _prefs?.setBool('kl_placement_taken', true);

  /// Tagesziel heute erreicht gemeldet? Speichert das Datum (yyyy-MM-dd) der
  /// letzten daily_goal_met-Meldung, damit das Event pro Tag genau einmal
  /// feuert (Dedup).
  static String get dailyGoalMetDate =>
      _prefs?.getString('kl_daily_goal_met_date') ?? '';
  static Future<void> setDailyGoalMetDate(String date) async =>
      _prefs?.setString('kl_daily_goal_met_date', date);

  /// True genau einmal pro Tag, sobald die heutige XP das Tagesziel erreicht.
  /// Persistiert das Datum, damit daily_goal_met nicht erneut feuert. Reine
  /// Storage-Logik ohne Analytics-Abhängigkeit.
  static Future<bool> markDailyGoalMetIfReached() async {
    if (xpToday < dailyGoalXp) {
      return false;
    }
    final today = _today();
    if (dailyGoalMetDate == today) {
      return false;
    }
    await setDailyGoalMetDate(today);
    return true;
  }

  /// Geburtsjahr (optional, Alters-Gate für Gye/Community — GDPR-K §8 DSGVO).
  /// 0 = nicht angegeben. Siehe [AgeGateService].
  static int get birthYear => PrivacyChoiceStorage.birthYear;
  static Future<void> setBirthYear(int year) =>
      PrivacyChoiceStorage.setAge(year);

  // ───────── SRS (Spaced Repetition, SM-2 vereinfacht) ─────────
  static Map<String, SrsCard>? _srsCache;

  /// 손상된 `kl_srs_v1` 원본을 옮겨 두는 격리 키.
  ///
  /// 앱은 이 값을 읽지 않는다. 사용자가 직접 손댈 수 없는 학습 이력이므로,
  /// 지우는 대신 남겨 두고 [srsQuarantinedRawJson] 으로 진단·복구에 쓴다.
  static const String srsQuarantinePreferenceKey = 'kl_srs_v1_corrupt_v1';

  /// 이번 실행에서 `kl_srs_v1` 파싱이 실패했는지.
  ///
  /// 서 있는 동안 [_srsReviewTransaction] 는 원본을 덮어쓰지 않는다.
  static bool _srsQuarantined = false;

  /// 파싱은 됐지만 개별 항목이 깨져 버려진 개수. 진단용.
  static int _srsDroppedEntries = 0;

  /// 손상 blob 때문에 SRS 덱을 신뢰할 수 없는 상태인지.
  static bool get srsIsQuarantined => _srsQuarantined;

  /// 마지막 로드에서 버려진 개별 항목 수 (전체 손상이 아닌 부분 손상).
  static int get srsDroppedEntryCount => _srsDroppedEntries;

  /// 격리된 손상 원본. 없으면 빈 문자열.
  static String get srsQuarantinedRawJson => _s(srsQuarantinePreferenceKey);

  /// SRS 덱을 읽는다.
  ///
  /// ⚠️ **손상 시 빈 맵으로 덮어쓰지 않는다.** 예전에는 `catch (_) → {}` 로
  /// 삼킨 뒤 다음 복습 한 번이 그 빈 맵을 `kl_srs_v1` 에 써 버려서, 깨진 blob
  /// 하나로 학습 이력 전체가 조용히 사라졌다. 이제는:
  ///
  /// - **전체 손상**(JSON 자체가 깨짐, 최상위가 Map 이 아님) → 원본을
  ///   [srsQuarantinePreferenceKey] 로 보존하고 [_srsQuarantined] 를 세운다.
  ///   그 뒤 [_srsReviewTransaction] 는 write 를 건너뛴다(fail-closed).
  /// - **부분 손상**(일부 항목만 깨짐) → 읽기에서는 유효한 항목을 보존한다.
  ///   새 판정 전 원본을 엄격히 보존한 뒤 읽힌 카드만 정규화한다.
  ///   보존이나 정규화가 확인되지 않으면 새 판정을 허용하지 않는다.
  static Map<String, SrsCard> _loadSrs({String? confirmedRaw}) {
    if (_srsCache != null) return _srsCache!;
    _srsDroppedEntries = 0;
    final raw = confirmedRaw ?? srsRawJson;
    if (raw.isEmpty) {
      _srsQuarantined = false;
      return _srsCache = {};
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map<String, dynamic>) {
      _quarantineSrs(raw);
      return _srsCache = {};
    }

    final cards = <String, SrsCard>{};
    var dropped = 0;
    decoded.forEach((key, value) {
      if (value is! Map<String, dynamic>) {
        dropped++;
        return;
      }
      try {
        cards[key] = SrsCard.fromJson(value);
      } catch (_) {
        dropped++;
      }
    });

    // 항목이 하나도 안 살아남았는데 원본에는 내용이 있었다면 전체 손상과 같다.
    if (cards.isEmpty && decoded.isNotEmpty) {
      _quarantineSrs(raw);
      return _srsCache = {};
    }

    _srsQuarantined = false;
    _srsDroppedEntries = dropped;
    if (dropped > 0) {
      debugPrint('Storage: SRS 항목 $dropped개가 손상돼 제외됐다 (유효 ${cards.length}개)');
    }
    return _srsCache = cards;
  }

  /// 손상 원본을 격리 키로 옮기고 write 를 잠근다.
  ///
  /// 격리본이 이미 있으면 덮어쓰지 않는다 — 처음 관측한 손상이 원인 진단에
  /// 가장 가깝고, 이후 실행이 그걸 밀어내면 안 된다.
  static void _quarantineSrs(String raw) {
    _srsQuarantined = true;
    _srsDroppedEntries = 0;
    debugPrint('Storage: kl_srs_v1 손상 — 격리 후 쓰기 잠금 (${raw.length} bytes)');
    if (_s(srsQuarantinePreferenceKey).isEmpty) {
      // best-effort. 실패해도 잠금(_srsQuarantined)은 유지된다.
      // ignore: discarded_futures, unawaited_futures
      _ss(srsQuarantinePreferenceKey, raw);
    }
  }

  /// 캐시와 함께 격리 상태도 버린다.
  ///
  /// `kl_srs_v1` 의 **원본이 교체되거나 삭제된 뒤**에만 호출한다(CloudSync 복원,
  /// 계정 교체, 전체 초기화). 다음 [_loadSrs] 가 새 원본을 처음부터 다시 판정한다.
  /// 원본을 그대로 둔 채 이걸 부르면 잠금이 풀려 손상본을 덮어쓸 수 있다.
  static void _invalidateSrsCache() {
    _srsCache = null;
    _srsQuarantined = false;
    _srsDroppedEntries = 0;
  }

  static void _invalidateSrsAttempts() {
    _srsAttemptEpoch++;
  }

  /// 격리를 해제하고 SRS 덱을 빈 상태로 다시 시작한다.
  ///
  /// 사용자가 "복구 불가, 새로 시작"을 **명시적으로** 선택했을 때만 호출한다.
  /// 격리본은 남겨 둔다.
  static Future<void> resetQuarantinedSrs() => setSrsRawJsonStrict('{}');

  /// This runs before the reset drain barrier releases a new [_prefs]. The
  /// captured store is therefore still the old generation's boundary, and no
  /// new legal write can race this conditional rollback.
  static Future<void> _restoreStaleSrsPrimaryWrite({
    required PreferenceStringStore store,
    required _StringPreferenceState before,
    required String attemptedJson,
  }) async {
    try {
      await store.reload();
      final after = _StringPreferenceState.read(store, 'kl_srs_v1');
      if (!after.isPresent || after.value != attemptedJson) {
        return;
      }
      await _writeStringStateStrict(store, 'kl_srs_v1', before);
    } on Object catch (error) {
      // This is test-reset containment only. Do not turn a stale, ignored
      // fire-and-forget completion into an unhandled async error.
      debugPrint('Storage: stale SRS primary repair skipped: $error');
    }
  }

  /// Roh-JSON des SRS-Decks (für CloudSync-Backup). Leer = kein Deck.
  static String get srsRawJson => _srsRecoveryClosed
      ? (_srsNormalization?.before ?? _srsJournal?.beforeDeck ?? '')
      : _s('kl_srs_v1');

  /// SRS-Deck als Roh-JSON setzen (CloudSync-Restore) + Cache invalidieren,
  /// damit der nächste [_loadSrs] neu parst.
  static Future<void> setSrsRawJson(String json) => setSrsRawJsonStrict(json);

  static Future<void> setSrsRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
  }) async {
    _invalidateSrsAttempts();
    final saved = await _enqueueSrsReviewMutation((generation) async {
      if (_srsRecoveryClosed) {
        throw const SrsRecoveryPendingException();
      }
      // The prior admitted journal has settled. Read native state afresh even
      // when this replacement is rejected; its confirmed evidence remains.
      _invalidateSrsCache();
      final store = _stringStore(preferences);
      final before = await _prepareStringMutation(store, 'kl_srs_v1');
      try {
        await _ssStrict(
          'kl_srs_v1',
          json,
          preferences: store,
          beforeState: before,
          assertCurrentWrite: () {
            if (generation != _srsReviewMutationGeneration) {
              throw StateError('stale SRS generation before deck replacement');
            }
          },
        );
        if (generation != _srsReviewMutationGeneration) {
          await _restoreStaleSrsPrimaryWrite(
            store: store,
            before: before,
            attemptedJson: json,
          );
          return false;
        }
        return true;
      } finally {
        _invalidateSrsCache();
        if (_unknownStrictKeys.contains('kl_srs_v1') &&
            generation == _srsReviewMutationGeneration) {
          _loadSrs(confirmedRaw: before.value ?? '');
        }
      }
    });
    if (!saved) {
      throw const PreferenceWriteException('kl_srs_v1');
    }
  }

  static const int _studyLogMaxIdsPerDay = 500;
  static const int _studyLogRetentionDays = 60;
  static const String _studyLogPrefix = 'kl_study_log_v1_';
  static final RegExp _studyLogDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String _studyLogKey(String dateIso) => '$_studyLogPrefix$dateIso';

  /// 명시적으로 판정한 해당 날짜의 SRS id 목록이다.
  static List<String> studyLogIdsFor(String dateIso) {
    if (_srsRecoveryClosed) {
      final journal = _srsJournal;
      if (journal == null) {
        return const [];
      }
      if (journal.recordHistory && journal.date == dateIso) {
        return List<String>.of(journal.beforeHistory ?? const []);
      }
    }
    try {
      return _l(_studyLogKey(dateIso));
    } on Object catch (error) {
      debugPrint('Storage: malformed study-log entry for $dateIso: $error');
      return const [];
    }
  }

  /// 기록이 있는 원장 날짜 목록이다. 달력의 selectable-day predicate에 쓴다.
  static List<String> studyLogDates() {
    final prefs = _prefs;
    if (prefs == null) {
      return const [];
    }
    return prefs
        .getKeys()
        .where((key) => key.startsWith(_studyLogPrefix))
        .map((key) => key.substring(_studyLogPrefix.length))
        .where(_isCanonicalStudyLogDate)
        .where((dateIso) => studyLogIdsFor(dateIso).isNotEmpty)
        .toList()
      ..sort();
  }

  static bool _isCanonicalStudyLogDate(String dateIso) {
    if (!_studyLogDatePattern.hasMatch(dateIso)) {
      return false;
    }
    final parsed = DateTime.tryParse(dateIso);
    return parsed != null && _today(parsed) == dateIso;
  }

  /// Restores one historical ledger entry without changing the SRS deck.
  ///
  /// Cloud restore owns the session-lifetime guard. This helper intentionally
  /// does not consult [_learningWritesLockReason], because a restore is not a
  /// learner-initiated SRS judgment. It nevertheless keeps the ledger's
  /// canonical-date, insertion-order, deduplication, cap, and strict-write
  /// contracts intact.
  static Future<bool> appendStudyLogEntryForRestore(
    String dateIso,
    String id,
  ) => _enqueueSrsReviewMutation((_) async {
    if (_srsRecoveryClosed) {
      throw const SrsRecoveryPendingException();
    }
    if (!_isCanonicalStudyLogDate(dateIso) || id.trim().isEmpty) {
      return false;
    }
    final key = _studyLogKey(dateIso);
    final store =
        _studyLogStoreForTesting ??
        (_prefs == null ? null : _SharedPreferenceStringListStore(_prefs!));
    if (store == null) {
      return false;
    }

    late final List<String> ids;
    try {
      ids = _l(key);
    } on Object catch (error) {
      // A wrong-typed preference is recovery data. Never replace it with an
      // empty-looking list during a restore.
      debugPrint('Storage: malformed study-log entry for $dateIso: $error');
      return false;
    }
    if (ids.contains(id)) {
      return true;
    }
    if (ids.length >= _studyLogMaxIdsPerDay) {
      return false;
    }

    final next = List<String>.from(ids)..add(id);
    await _slStrict(key, next, preferences: store);
    return true;
  });

  /// Restores a validated remote date in one strict preference write.
  ///
  /// This prevents a rejected mid-date write from creating a partial local
  /// date that would later win against the complete cloud source.
  static Future<StudyLogDateRestoreResult> restoreStudyLogDateForRestore(
    String dateIso,
    List<String> remoteIds, {
    void Function()? assertCurrentWrite,
  }) async {
    StudyLogDateRestoreResult? result;
    final saved = await _enqueueSrsReviewMutation((_) async {
      if (_srsRecoveryClosed) {
        throw const SrsRecoveryPendingException();
      }
      result = await _restoreStudyLogDate(
        dateIso,
        remoteIds,
        assertCurrentWrite: assertCurrentWrite,
      );
      return true;
    });
    if (!saved) {
      throw const SrsRecoveryPendingException();
    }
    return result!;
  }

  static Future<StudyLogDateRestoreResult> _restoreStudyLogDate(
    String dateIso,
    List<String> remoteIds, {
    void Function()? assertCurrentWrite,
  }) async {
    if (!_isCanonicalStudyLogDate(dateIso)) {
      throw ArgumentError.value(dateIso, 'dateIso', 'must be canonical');
    }
    final ids = <String>[];
    final seen = <String>{};
    for (final id in remoteIds) {
      if (id.trim().isEmpty || !seen.add(id)) {
        continue;
      }
      ids.add(id);
      if (ids.length == _studyLogMaxIdsPerDay) {
        break;
      }
    }
    if (ids.isEmpty) {
      throw ArgumentError.value(remoteIds, 'remoteIds', 'must contain an ID');
    }

    final key = _studyLogKey(dateIso);
    final store =
        _studyLogStoreForTesting ??
        (_prefs == null ? null : _SharedPreferenceStringListStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    try {
      final initial = _StringListPreferenceState.read(store, key);
      if (initial.isPresent && initial.value!.isNotEmpty) {
        return StudyLogDateRestoreResult.skippedExisting;
      }
    } on Object catch (error) {
      // A wrong-typed preference is recovery data. Never replace it with an
      // empty-looking list during a restore.
      debugPrint('Storage: malformed study-log entry for $dateIso: $error');
      return StudyLogDateRestoreResult.skippedRecoveryValue;
    }

    try {
      if (_unknownStrictKeys.contains(key)) {
        await _refreshUnknownStringListKeys(store, [key]);
      }
      await store.reload();
    } on PreferenceOutcomeUnknownException {
      rethrow;
    } on Object catch (error) {
      _unknownStrictKeys.add(key);
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }

    late final _StringListPreferenceState before;
    try {
      // This synchronous reread follows every awaited preparation boundary.
      // Its state is supplied to _slStrict, so the session guard and setter
      // follow without another await.
      before = _StringListPreferenceState.read(store, key);
    } on Object catch (error) {
      // Wrong-typed local values are recovery data, never an empty ledger.
      debugPrint('Storage: malformed study-log entry for $dateIso: $error');
      return StudyLogDateRestoreResult.skippedRecoveryValue;
    }
    if (before.isPresent && before.value!.isNotEmpty) {
      return StudyLogDateRestoreResult.skippedExisting;
    }
    await _slStrict(
      key,
      ids,
      preferences: store,
      beforeState: before,
      assertCurrentWrite: assertCurrentWrite,
    );
    return StudyLogDateRestoreResult.written;
  }

  @visibleForTesting
  static void setSrsPersistenceStoreForTesting(PreferenceStringStore? store) {
    _srsPersistenceStoreForTesting = store;
  }

  @visibleForTesting
  static void setStudyLogStoreForTesting(PreferenceStringListStore? store) {
    _studyLogStoreForTesting = store;
  }

  @visibleForTesting
  static void setGrammarPlanStoreForTesting(PreferenceStringStore? store) {
    _grammarPlanStoreForTesting = store;
  }

  /// [keepDays]보다 오래된 일별 원장 키를 지운다.
  ///
  /// 시간대가 아니라 달력 날짜로만 비교하므로 정확히 [keepDays]일 전 기록은
  /// 보존된다. 앱 시작과 원장 달력 진입 시 호출한다.
  static Future<void> pruneStudyLog({
    int keepDays = _studyLogRetentionDays,
  }) async {
    await _enqueueSrsReviewMutation((_) async {
      if (_srsRecoveryClosed) {
        return false;
      }
      await _pruneStudyLog(keepDays);
      return true;
    });
  }

  static Future<void> _pruneStudyLog(int keepDays) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(Duration(days: keepDays < 0 ? 0 : keepDays));
    for (final dateIso in studyLogDates()) {
      final parsed = DateTime.tryParse(dateIso);
      if (parsed == null) {
        continue;
      }
      final date = DateTime(parsed.year, parsed.month, parsed.day);
      if (date.isBefore(cutoff)) {
        await prefs.remove(_studyLogKey(dateIso));
      }
    }
  }

  static String _isoOf(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Nach einer Wiederholung aufrufen. `gotIt` = richtig beantwortet?
  ///
  /// Returns true after both immutable native effects and journal retirement
  /// are confirmed. Partial outcomes retain a durable obligation for recovery.
  /// A retained attempt retries that obligation without a second advancement.
  ///
  /// Vereinfachter SM-2:
  /// - Erstes Mal richtig → Intervall 1 Tag
  /// - Zweites Mal richtig → Intervall 3 Tage
  /// - Danach richtig → Intervall × Ease (gerundet, max 365)
  /// - Falsch → Intervall zurück auf 1 Tag, Ease − 0.2
  /// - Richtig → Ease + 0.05 (1.3 ≤ Ease ≤ 3.5)
  static Future<bool> srsReview(
    String id, {
    required bool gotIt,
    bool recordToStudyLog = true,
  }) => SrsReviewAttempt(
    id: id,
    gotIt: gotIt,
    recordToStudyLog: recordToStudyLog,
  ).save();

  static Future<bool> _srsReviewTransaction(
    SrsReviewAttempt attempt, {
    required int generation,
  }) async {
    if (generation != _srsReviewMutationGeneration || !attempt._isCurrent) {
      return false;
    }
    if (attempt._completed) {
      return true;
    }
    if (_srsRecoveryClosed) {
      if (_srsNormalization != null) {
        if (!await _recoverSrsCommit(generation)) {
          return false;
        }
      } else {
        if (!identical(attempt, _srsJournalAttempt)) {
          return false;
        }
        return await _recoverSrsCommit(generation) && attempt.isCurrent;
      }
    }
    if (_learningWritesLockReason != null || _prefs == null) {
      return false;
    }
    final deckStore = _srsPersistenceStoreForTesting ?? _stringStore();
    final historyStore =
        _studyLogStoreForTesting ?? _SharedPreferenceStringListStore(_prefs!);
    try {
      await deckStore.reload();
      var beforeDeck = _StringPreferenceState.read(deckStore, 'kl_srs_v1');
      attempt._judgmentDate ??= _today(DateTime.now());
      final date = attempt._judgmentDate!;
      List<String>? beforeHistory;
      List<String>? afterHistory;
      if (attempt.recordToStudyLog) {
        await historyStore.reload();
        beforeHistory = _StringListPreferenceState.read(
          historyStore,
          _studyLogKey(date),
        ).value;
        if (!SrsCommitJournal.validHistory(beforeHistory)) {
          return false;
        }
        afterHistory = List<String>.of(beforeHistory ?? const []);
        if (!afterHistory.contains(attempt.id)) {
          if (afterHistory.length >= _studyLogMaxIdsPerDay) {
            return false;
          }
          afterHistory.add(attempt.id);
        }
      }
      if (generation != _srsReviewMutationGeneration ||
          !attempt.isCurrent ||
          _learningWritesLockReason != null) {
        return false;
      }
      if (!SrsCommitJournal.validDeck(beforeDeck.value)) {
        _invalidateSrsCache();
        final readable = _loadSrs(confirmedRaw: beforeDeck.value ?? '');
        if (_srsQuarantined || readable.isEmpty) {
          return false;
        }
        final normalized = jsonEncode(
          readable.map((key, card) => MapEntry(key, card.toJson())),
        );
        if (!SrsCommitJournal.validDeck(normalized)) {
          return false;
        }
        await _prefs!.reload();
        if (_srsReplayPrecedenceBlocked(_prefs!) ||
            _prefs!.containsKey(SrsCommitJournal.key) ||
            !attempt.isCurrent) {
          return false;
        }
        final raw = beforeDeck.value!;
        _srsNormalization = (
          before: raw,
          after: normalized,
          evidenceKey:
              '${srsQuarantinePreferenceKey}_${sha256.convert(utf8.encode(raw))}',
        );
        _srsRecoveryClosed = true;
        srsRecoveryStatus.value = SrsRecoveryStatus.pending;
        if (!await _recoverSrsNormalization(generation, deckStore) ||
            !attempt.isCurrent) {
          return false;
        }
        beforeDeck = _StringPreferenceState.read(deckStore, 'kl_srs_v1');
      }
      _invalidateSrsCache();
      final map = Map<String, SrsCard>.of(
        _loadSrs(confirmedRaw: beforeDeck.value ?? ''),
      );
      final old =
          map[attempt.id] ??
          const SrsCard(
            ease: 2.5,
            intervalDays: 0,
            nextReviewIso: '',
            reviewCount: 0,
          );
      final interval = !attempt.gotIt
          ? 1
          : old.intervalDays == 0
          ? 1
          : old.intervalDays == 1
          ? 3
          : (old.intervalDays * old.ease).round().clamp(1, 365);
      map[attempt.id] = SrsCard(
        ease: (old.ease + (attempt.gotIt ? 0.05 : -0.2)).clamp(1.3, 3.5),
        intervalDays: interval,
        nextReviewIso: _isoOf(
          DateTime.parse(date).add(Duration(days: interval)),
        ),
        reviewCount: old.reviewCount + 1,
      );
      final journal = SrsCommitJournal(
        date: date,
        recordHistory: attempt.recordToStudyLog,
        beforeDeck: beforeDeck.value,
        afterDeck: jsonEncode(map.map((k, v) => MapEntry(k, v.toJson()))),
        beforeHistory: beforeHistory == null
            ? null
            : List.unmodifiable(beforeHistory),
        afterHistory: afterHistory == null
            ? null
            : List.unmodifiable(afterHistory),
      );
      // Strict decoding also validates newly admitted records.
      SrsCommitJournal.decode(journal.encode());
      final prefs = _prefs!;
      await prefs.reload();
      if (generation != _srsReviewMutationGeneration ||
          !attempt._isCurrent ||
          _srsReplayPrecedenceBlocked(prefs)) {
        return false;
      }
      if (prefs.containsKey(SrsCommitJournal.key)) {
        _initializeSrsRecoveryView();
        return false;
      }
      _srsRecoveryClosed = true;
      _srsJournal = journal;
      _srsJournalAttempt = attempt;
      srsRecoveryStatus.value = SrsRecoveryStatus.pending;
      try {
        await prefs.setString(SrsCommitJournal.key, journal.encode());
      } on Object catch (error) {
        debugPrint('Storage: SRS intent acknowledgement unavailable: $error');
      }
      await prefs.reload();
      if (prefs.get(SrsCommitJournal.key) != journal.encode()) {
        if (!prefs.containsKey(SrsCommitJournal.key)) {
          _finishSrsRecovery(completed: false);
        }
        return false;
      }
      return await _recoverSrsCommit(generation, cancelUnapplied: true) &&
          attempt.isCurrent;
    } on Object catch (error) {
      if (_srsRecoveryClosed) {
        srsRecoveryStatus.value = SrsRecoveryStatus.retryRequired;
      }
      debugPrint('Storage: SRS commit incomplete: $error');
      return false;
    }
  }

  /// IDs die heute (oder früher) fällig sind. Noch nie gesehen → fällig.
  ///
  /// **Achtung**: Dies liefert ALLE fälligen Karten, inkl. nie gesehener.
  /// Bei Erstanwendung sind das tausende Karten → UX-Stress.
  /// Für die tägliche Lerneinheit lieber [todayNewIds] + [todayReviewIds]
  /// (Phase 1 SRS-UX-Patch in stately-rising-jongga).
  static Set<String> dueIds(Iterable<String> allIds) {
    final map = _loadSrs();
    final today = _today();
    return allIds.where((id) {
      final card = map[id];
      if (card == null) return true;
      return card.nextReviewIso.compareTo(today) <= 0;
    }).toSet();
  }

  // ── Phase 1 SRS-UX-Patch (stately-rising-jongga) ─────────────────────
  //
  // "Heute lernen" = neue Karten (max [max]) + Wiederholungs-Karten
  // (max [max]). Cap verhindert "522 due" Schock-UX bei Erstanwendung.
  //
  // Reihenfolge in [allIds] wird respektiert → CSV-Reihenfolge =
  // Lern-Reihenfolge (kuratiert nach Wichtigkeit / Pack-Order).
  //
  // ─────────────────────────────────────────────────────────────────────

  /// "Heute neu" — nie reviewed Karten, max [max]. Reihenfolge: wie [allIds].
  static List<String> todayNewIds(Iterable<String> allIds, {int max = 10}) {
    if (max <= 0) return const [];
    final map = _loadSrs();
    final out = <String>[];
    for (final id in allIds) {
      if (map[id] == null) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// "Heute Wiederholung" — schon mal reviewed, jetzt fällig, max [max].
  /// Schließt nie-gesehene Karten aus (das sind "neue", siehe [todayNewIds]).
  static List<String> todayReviewIds(Iterable<String> allIds, {int max = 15}) {
    if (max <= 0) return const [];
    final map = _loadSrs();
    final today = _today();
    final out = <String>[];
    for (final id in allIds) {
      final card = map[id];
      if (card == null) continue; // nie gesehen → "neu", nicht "review"
      if (card.reviewCount == 0) continue;
      if (card.nextReviewIso.isEmpty ||
          card.nextReviewIso.compareTo(today) <= 0) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// Tagesziel = Union(todayNewIds, todayReviewIds). Insertion-order erhalten.
  /// Liefert maximal `newMax + reviewMax` IDs.
  static List<String> todayGoalIds(
    Iterable<String> allIds, {
    int newMax = 10,
    int reviewMax = 15,
  }) {
    final fresh = todayNewIds(allIds, max: newMax);
    final review = todayReviewIds(allIds, max: reviewMax);
    final seen = <String>{};
    final out = <String>[];
    for (final id in [...fresh, ...review]) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// Daily goal with separate pools for new and already-reviewed cards.
  ///
  /// [newCandidateIds] is normally the learner's exact CEFR level (plus
  /// learner-owned custom words). [reviewCandidateIds] optionally narrows
  /// which scheduled cards may enter the same daily deck. This lets an
  /// exact-level learning surface keep both its new and review cards at the
  /// learner's current CEFR level instead of reintroducing an A1 starter such
  /// as 안녕하세요 into a C1/C2 "today" deck.
  static List<String> todayGoalIdsForNewPool({
    required Iterable<String> allIds,
    required Iterable<String> newCandidateIds,
    Iterable<String>? reviewCandidateIds,
    int newMax = 10,
    int reviewMax = 15,
  }) {
    final fresh = todayNewIds(newCandidateIds, max: newMax);
    final review = todayReviewIds(reviewCandidateIds ?? allIds, max: reviewMax);
    final seen = <String>{};
    final out = <String>[];
    for (final id in [...fresh, ...review]) {
      if (seen.add(id)) {
        out.add(id);
      }
    }
    return out;
  }

  /// SRS-Status einer einzelnen Karte (z.B. für Debug/Anzeige).
  static SrsCard? srsCard(String id) => _loadSrs()[id];

  /// Anzahl aller Karten die jemals reviewed wurden.
  static int srsTotalReviewed() => _loadSrs().length;

  /// Korean keys of every card that has at least one SRS review.
  static Set<String> get srsReviewedIds => _loadSrs().keys.toSet();

  /// A2: "어려운 단어"(leech) — 반복해도 안 굳는 단어 IDs.
  /// 기준: 3회 이상 복습 + (ease ≤ 1.8 [여러 번 틀림] 또는 간격 ≤ 1일 [계속 리셋]).
  /// [allIds] 순서를 유지. 최대 [max]개.
  static List<String> hardIds(Iterable<String> allIds, {int max = 50}) {
    final map = _loadSrs();
    final out = <String>[];
    for (final id in allIds) {
      final c = map[id];
      if (c == null) continue;
      if (c.reviewCount >= 3 && (c.ease <= 1.8 || c.intervalDays <= 1)) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// Mastery-Status eines Vokabel-Items, abgeleitet aus SRS-Daten.
  /// - [MasteryState.fresh]      → nie reviewed
  /// - [MasteryState.learning]   → reviewed, Intervall ≤ 3 Tage
  /// - [MasteryState.reviewDue]  → Intervall > 3 Tage, fällig (heute/früher)
  /// - [MasteryState.strong]     → Intervall > 3 Tage, noch nicht fällig
  static MasteryState vocabMastery(String id, {DateTime? now}) {
    final card = _loadSrs()[id];
    if (card == null || card.reviewCount == 0) return MasteryState.fresh;
    if (card.intervalDays <= 3) return MasteryState.learning;
    final today = _today(now);
    final due =
        card.nextReviewIso.isEmpty || card.nextReviewIso.compareTo(today) <= 0;
    return due ? MasteryState.reviewDue : MasteryState.strong;
  }

  // ───────── 단어별 오답 카운터 (Extra-Lernset, 2026-08-13) ─────────
  // SRS 는 ease/interval 만 남기고 "몇 번 틀렸는지"는 안 남긴다. 테스터 요청
  // (3회+ 틀린 단어 자동 모음)을 위해 실패 횟수를 명시적으로 영구 저장한다.
  // 키는 SRS 와 같은 한국어 표제어. 저지분 데이터라 SRS 격리(quarantine)까지는
  // 두지 않는다 — 파싱 실패 시 빈 맵으로 관대하게 시작.
  static Map<String, int>? _wrongCountCache;

  static Map<String, int> _decodeWrongCounts(String raw) {
    if (raw.isEmpty) {
      return <String, int>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, int>{};
      }
      final out = <String, int>{};
      decoded.forEach((k, v) {
        if (v is int && v > 0) {
          out[k] = v;
        }
      });
      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  static void _confirmWrongCountRaw(String raw) {
    _confirmedWrongCountRaw = raw;
    _wrongCountCache = _decodeWrongCounts(raw);
  }

  static String _readConfirmedWrongCountRaw() {
    if (_vocabWriteIsUnconfirmed(_wrongCountKey) ||
        _confirmedVocabAfterReloadKeys.contains(_wrongCountKey)) {
      return _confirmedWrongCountRaw ?? '';
    }
    final raw = _s(_wrongCountKey);
    _confirmWrongCountRaw(raw);
    return raw;
  }

  static Map<String, int> _readWrongCountMap() {
    if (_wrongCountCache != null) {
      return _wrongCountCache!;
    }
    return _wrongCountCache = _decodeWrongCounts(_readConfirmedWrongCountRaw());
  }

  static Map<String, int> _loadWrongCounts() {
    return _readWrongCountMap();
  }

  /// 누적 실패 횟수 (모든 리트리벌 실패 — 같은 세션 내 반복 실패도 각각 셈).
  static int wrongCountOf(String id) => _loadWrongCounts()[id] ?? 0;

  /// 실패 1회 기록. `srsReview(gotIt: false)` 를 부르는 지점 옆에 병치한다.
  static Future<void> incrementWrongCount(String id) async {
    await _requireVocabProgress(VocabProgressAttempt(wrongCountId: id));
  }

  /// [threshold]회 이상 틀린 단어 IDs — Extra-Lernset 의 명시적 절반
  /// ([hardIds] 의 leech 휴리스틱과 합집합으로 쓴다). [allIds] 순서 유지.
  ///
  /// 카운터는 감소하지 않으므로, SRS 가 이미 강하다고 판정한 단어
  /// ([MasteryState.strong]) 는 제외한다 — 이것이 자연 졸업 경로.
  static List<String> frequentlyMissedIds(
    Iterable<String> allIds, {
    int threshold = 3,
    int max = 100,
  }) {
    final map = _loadWrongCounts();
    if (map.isEmpty) return const [];
    final out = <String>[];
    for (final id in allIds) {
      if ((map[id] ?? 0) < threshold) continue;
      if (vocabMastery(id) == MasteryState.strong) continue;
      out.add(id);
      if (out.length >= max) break;
    }
    return out;
  }

  /// Roh-JSON (CloudSync-Backup/Export). Leer = nie etwas falsch.
  static String get wrongCountRawJson => _readConfirmedWrongCountRaw();

  /// Roh-JSON setzen (CloudSync-Restore) + Cache invalidieren.
  static Future<void> setWrongCountRawJson(String json) async {
    await _requireVocabProgress(
      VocabProgressAttempt._restore(
        restoreSeenIds: const <String>[],
        restoreWrongCountJson: json,
        restoreWrongCountOnlyIfEmpty: false,
      ),
    );
  }

  // ───────── Szenarien (Phase 5) ─────────
  /// CEFR code from 'a1' through 'c2'. Null means not selected yet.
  /// (Onboarding-Trigger).
  static String? get userLevelCode =>
      LearnerLevel.fromCode(_s('kl_user_level'))?.code;

  static Future<void> setUserLevelCode(String code) =>
      _ss('kl_user_level', _requiredLearnerLevelCode(code));

  // ───────── Kursplatzierung und Kursgraph (v1) ─────────
  // These keys intentionally do not reuse `kl_user_level`: that legacy key
  // still drives old library filters and must remain readable while screens
  // migrate to the course graph. Only an explicit placement mirrors it.
  static const String placementLevelPreferenceKey = 'kl_placement_level_v1';
  static const String browseLevelPreferenceKey = 'kl_browse_level_v1';
  static const String courseUnitPreferenceKey = 'kl_course_unit_v1';
  static const String legacyCourseMasteryPreferenceKey = 'kl_course_mastery_v1';
  static const String courseMasterySnapshotPreferenceKey =
      'kl_course_mastery_v2';
  static const String ilduWorldStatePreferenceKey = 'kl_ildu_world_state_v1';

  /// Backward-compatible spelling for callers that already write the
  /// canonical snapshot. The v1 key is migration input only.
  static const String courseMasteryPreferenceKey =
      courseMasterySnapshotPreferenceKey;

  static String? _optionalString(String key) {
    final value = _s(key).trim();
    return value.isEmpty ? null : value;
  }

  static String? _optionalLearnerLevelCode(String key) =>
      LearnerLevel.fromCode(_optionalString(key))?.code;

  static String _requiredLearnerLevelCode(String code) {
    final level = LearnerLevel.fromCode(code);
    if (level == null) {
      throw ArgumentError.value(code, 'code', 'unsupported learner level');
    }
    return level.code;
  }

  /// Placement comes from the diagnostic or direct start-level selection.
  /// Fallback keeps users of the pre-course app on their existing level until
  /// a new placement has been saved.
  static String? get placementLevelCode =>
      _optionalLearnerLevelCode(placementLevelPreferenceKey) ?? userLevelCode;

  /// Explicit sequential-course placement only. Cloud reconciliation must use
  /// this instead of [placementLevelCode], whose legacy user-level fallback is
  /// library/account state rather than proof that a course has been started.
  static String? get dedicatedCoursePlacementLevelCode =>
      _optionalLearnerLevelCode(placementLevelPreferenceKey);

  /// The library filter never changes the actual course placement or legacy
  /// user level. It is deliberately independent from sequential progress.
  static String? get browseLevelCode =>
      _optionalLearnerLevelCode(browseLevelPreferenceKey);

  /// The one active sequential course mission, independent from a library
  /// level filter and from vocabulary-pack progress.
  static String? get courseUnitId => _optionalString(courseUnitPreferenceKey);

  /// §E4 (2026-09-03): the last Sori Stage catalog activity the learner
  /// actually opened (`ActivityCatalogEntry.id`). Presentation-only "Weiter
  /// mit …" hero promotion — never gates content, so it uses the same
  /// non-strict read/write as [courseUnitId] rather than the strict ledger
  /// helpers reserved for evidence/progress state.
  static const String lastActivityIdPreferenceKey = 'kl_last_activity_id_v1';

  static String? get lastActivityId =>
      _optionalString(lastActivityIdPreferenceKey);

  static Future<void> setLastActivityId(String activityId) async {
    final normalized = activityId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(activityId, 'activityId', 'must not be empty');
    }
    await _ss(lastActivityIdPreferenceKey, normalized);
  }

  static const recentLearnActivityPreferenceKey = 'kl_recent_learn_activity_v1';
  static const recentGamesActivityPreferenceKey = 'kl_recent_games_activity_v1';

  static String _catalogHistoryKey(SoriStageTab tab) => switch (tab) {
    SoriStageTab.learn => recentLearnActivityPreferenceKey,
    SoriStageTab.games => recentGamesActivityPreferenceKey,
    _ => throw ArgumentError.value(tab, 'tab', 'must be Learn or Games'),
  };

  /// Device-local presentation history, never course progress or a resume claim.
  /// Persist the owner UID so a completed old-account write stays invisible
  /// after a switch, even when its platform Future completes late.
  static String? recentCatalogActivityId(SoriStageTab tab) {
    final session = cloudWriteSessionController.current;
    if (session != null && session.mode != CloudWriteMode.ready) {
      return null;
    }
    final raw = _optionalString(_catalogHistoryKey(tab));
    if (raw == null) {
      return null;
    }
    try {
      final value = jsonDecode(raw);
      if (value is! Map || value['uid'] != session?.uid) {
        return null;
      }
      final id = value['id'];
      return soriActivityCatalog.any(
            (entry) => entry.id == id && entry.tab == tab,
          )
          ? id as String
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _enqueueCatalogHistory(
    CatalogHistoryLease lease,
    Future<void> Function() action,
  ) {
    if (_learningResetCount > 0 ||
        _catalogHistoryResetting > 0 ||
        !lease.isCurrent) {
      return Future<void>.value();
    }
    final generation = _catalogHistoryGeneration;
    final immediate = _catalogHistoryMutationCount == 0;
    _catalogHistoryMutationCount++;
    Future<void> run() async {
      try {
        if (generation != _catalogHistoryGeneration || !lease.isCurrent) {
          return;
        }
        await init();
        if (generation != _catalogHistoryGeneration ||
            _learningResetCount > 0 ||
            _catalogHistoryResetting > 0 ||
            !lease.isCurrent) {
          return;
        }
        await action();
        if (generation == _catalogHistoryGeneration && lease.isCurrent) {
          catalogHistoryChanges.value++;
        }
      } catch (error, stackTrace) {
        // A preference failure must never block an accepted activity launch.
        unawaited(
          DiagnosticsService.reportSwallowed(
            'storage_service.catalog_history_mutation',
            error,
            stackTrace,
          ),
        );
      } finally {
        if (generation == _catalogHistoryGeneration) {
          _catalogHistoryMutationCount--;
        }
      }
    }

    return _catalogHistoryMutation = immediate
        ? run()
        : _catalogHistoryMutation.then((_) => run());
  }

  /// Lazy, idempotent migration outside build. A newer tab launch wins because
  /// this rechecks the same serialized queue immediately before the setter.
  static Future<void> initializeCatalogHistory({CatalogHistoryLease? lease}) {
    final captured = lease ?? CatalogHistoryLease.capture();
    return _enqueueCatalogHistory(captured, () async {
      final legacy = lastActivityId;
      if (legacy == null) {
        return;
      }
      final matches = soriActivityCatalog.where((entry) => entry.id == legacy);
      // Consume the unowned legacy source before the owned write. If identity
      // changes during either platform operation, it cannot later migrate into
      // a different account as though it were that account's history.
      await _prefs!.remove(lastActivityIdPreferenceKey);
      if (!captured.isCurrent || matches.isEmpty) {
        return;
      }
      final entry = matches.single;
      if (recentCatalogActivityId(entry.tab) == null) {
        await _prefs!.setString(
          _catalogHistoryKey(entry.tab),
          jsonEncode({'id': entry.id, 'uid': captured.session?.uid}),
        );
      }
    });
  }

  /// Call only after Navigator accepts the route, with a pre-await lease.
  static Future<void> recordCatalogActivity(
    String activityId, {
    CatalogHistoryLease? lease,
  }) {
    final matches = soriActivityCatalog.where(
      (entry) => entry.id == activityId,
    );
    if (matches.isEmpty) {
      return Future<void>.value();
    }
    final entry = matches.single;
    final captured = lease ?? CatalogHistoryLease.capture();
    return _enqueueCatalogHistory(captured, () async {
      await _prefs!.setString(
        _catalogHistoryKey(entry.tab),
        jsonEncode({'id': entry.id, 'uid': captured.session?.uid}),
      );
    });
  }

  /// Canonical v2 JSON owned by [CourseMasteryService]. Storage does not parse
  /// it so the service can reject malformed or catalog-incompatible evidence.
  static String get courseMasterySnapshotRawJson =>
      _courseMasteryCache ?? _s(courseMasterySnapshotPreferenceKey);

  static const _courseMasteryStateKeys = <String>{
    courseMasterySnapshotPreferenceKey,
    placementLevelPreferenceKey,
    courseUnitPreferenceKey,
    browseLevelPreferenceKey,
    'kl_user_level',
  };

  /// Allows an empty placement capture to avoid loading the course catalog
  /// unless its preference boundary actually needs recovery.
  static bool get hasUnconfirmedCourseMasteryState =>
      _courseMasteryStateKeys.any(_unknownStrictKeys.contains);

  /// Synchronous course readers cannot resolve an uncertain platform cache.
  /// Keep them closed until the course owner confirms the durable state.
  static void assertCourseMasteryStateConfirmed() {
    for (final key in _courseMasteryStateKeys) {
      if (_unknownStrictKeys.contains(key)) {
        throw PreferenceOutcomeUnknownException(key);
      }
    }
  }

  /// Confirms an uncertain course transaction before a new candidate is built.
  /// Returns whether the caller must discard its loaded graph and read again.
  /// This only reads durable state; it never replays or rolls back an action.
  static Future<bool> confirmCourseMasteryState({
    PreferenceStringStore? preferences,
  }) async {
    if (!hasUnconfirmedCourseMasteryState) {
      return false;
    }
    final store = _stringStore(preferences);
    await _refreshUnknownStringKeys(store, _courseMasteryStateKeys);
    try {
      final canonical = _StringPreferenceState.read(
        store,
        courseMasterySnapshotPreferenceKey,
      );
      _courseMasteryCache = canonical.value ?? '';
    } on Object catch (error) {
      _unknownStrictKeys.add(courseMasterySnapshotPreferenceKey);
      throw PreferenceOutcomeUnknownException(
        courseMasterySnapshotPreferenceKey,
        cause: error,
      );
    }
    return true;
  }

  /// Retained as a read-only migration source. No production code writes it.
  static String get legacyCourseMasteryRawJson =>
      _s(legacyCourseMasteryPreferenceKey);

  /// Compatibility alias for callers that previously read the single snapshot
  /// value. It now returns only the canonical v2 state.
  static String get courseMasteryRawJson => courseMasterySnapshotRawJson;

  static String get ilduWorldStateRawJson => _s(ilduWorldStatePreferenceKey);

  static Future<void> setIlDuWorldStateRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
  }) => _ssStrict(
    ilduWorldStatePreferenceKey,
    json,
    preferences: preferences,
    assertCurrentWrite: assertCurrentWrite,
  );

  static Future<void> setPlacementLevelCode(String code) =>
      PackCompletionStorage.trackWrite(placementLevelPreferenceKey, () async {
        final normalized = _requiredLearnerLevelCode(code);
        await _ss(placementLevelPreferenceKey, normalized);
        // Compatibility mirror only. Browse-level writes must not do this.
        await setUserLevelCode(normalized);
      });

  /// Reconciliation-only course mirror write. The root account/library level
  /// has its own merge semantics and must not be overwritten by course restore.
  static Future<void> setDedicatedCoursePlacementLevelCode(String code) async {
    final normalized = _requiredLearnerLevelCode(code);
    await _ss(placementLevelPreferenceKey, normalized);
  }

  static Future<void> setBrowseLevelCode(String code) async {
    final normalized = _requiredLearnerLevelCode(code);
    await _ss(browseLevelPreferenceKey, normalized);
  }

  static Future<void> setBrowseLevelCodeStrict(
    String code, {
    PreferenceStringStore? preferences,
  }) async {
    final normalized = _requiredLearnerLevelCode(code);
    await _ssStrict(
      browseLevelPreferenceKey,
      normalized,
      preferences: preferences,
    );
  }

  static Future<void> setCourseUnitId(String unitId) async {
    final normalized = unitId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(unitId, 'unitId', 'must not be empty');
    }
    await _ss(courseUnitPreferenceKey, normalized);
  }

  /// Clears only the course placement mirror; the legacy library level stays
  /// untouched because it has independent browse semantics.
  static Future<void> clearPlacementLevelCode() =>
      _removeStringStrict(placementLevelPreferenceKey);

  /// Clears only the active-course mirror after a canonical snapshot records
  /// that no mission is active.
  static Future<void> clearCourseUnitId() =>
      _removeStringStrict(courseUnitPreferenceKey);

  static Future<void> setCourseMasterySnapshotRawJson(
    String json, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
  }) => PackCompletionStorage.trackWrite(
    courseMasterySnapshotPreferenceKey,
    () async {
      // The cache changes only after strict storage confirms the requested value.
      await _ssStrict(
        courseMasterySnapshotPreferenceKey,
        json,
        preferences: preferences,
        assertCurrentWrite: assertCurrentWrite,
      );
      _courseMasteryCache = json;
    },
  );

  /// Replaces the canonical course graph and its scalar compatibility mirrors
  /// as one recoverable local operation.
  ///
  /// SharedPreferences has no multi-key transaction. The scalar mirrors are
  /// therefore written first and the canonical snapshot is the final commit
  /// marker. If any write is rejected, every attempted key is restored to its
  /// captured value before the failure is returned. A rollback whose outcome
  /// cannot be confirmed fails closed as [PreferenceOutcomeUnknownException].
  static Future<void> setCourseMasteryStateAtomically({
    required String canonicalSnapshotJson,
    required String? placementLevelCode,
    String? browseLevelCode,
    required String? currentCourseUnitId,
    required bool mirrorLegacyUserLevel,
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
  }) => PackCompletionStorage.trackWrite(
    courseMasterySnapshotPreferenceKey,
    () async {
      if (canonicalSnapshotJson.trim().isEmpty) {
        throw ArgumentError.value(
          canonicalSnapshotJson,
          'canonicalSnapshotJson',
          'must not be empty',
        );
      }
      final placement = placementLevelCode == null
          ? null
          : _requiredLearnerLevelCode(placementLevelCode);
      final unit = currentCourseUnitId?.trim();
      if (unit != null && unit.isEmpty) {
        throw ArgumentError.value(
          currentCourseUnitId,
          'currentCourseUnitId',
          'must not be empty',
        );
      }
      final browse = browseLevelCode == null
          ? null
          : _requiredLearnerLevelCode(browseLevelCode);

      final store = _stringStore(preferences);
      final targets = <String, String?>{
        placementLevelPreferenceKey: placement,
        if (mirrorLegacyUserLevel && placement != null)
          'kl_user_level': placement,
        if (browse != null) browseLevelPreferenceKey: browse,
        courseUnitPreferenceKey: unit,
        // The validated graph is the commit marker and must remain last.
        courseMasterySnapshotPreferenceKey: canonicalSnapshotJson,
      };
      final before = <String, _StringPreferenceState>{};
      for (final key in targets.keys) {
        before[key] = await _prepareStringMutation(store, key);
      }
      assertCurrentWrite?.call();

      final attempted = <String>[];
      Object? primaryFailure;
      StackTrace? primaryStack;
      try {
        for (final entry in targets.entries) {
          final target = entry.value == null
              ? const _StringPreferenceState.absent()
              : _StringPreferenceState._(isPresent: true, value: entry.value);
          if (before[entry.key] == target) continue;
          attempted.add(entry.key);
          await _writeStringStateStrict(store, entry.key, target);
        }
        _courseMasteryCache = canonicalSnapshotJson;
        return;
      } on Object catch (error, stack) {
        primaryFailure = error;
        primaryStack = stack;
      }

      final rollbackFailures = <Object>[];
      try {
        await _refreshUnknownStringKeys(store, attempted);
      } on Object catch (error) {
        rollbackFailures.add(error);
      }
      for (final key in attempted.reversed) {
        try {
          final current = _StringPreferenceState.read(store, key);
          final original = before[key]!;
          if (current != original) {
            await _writeStringStateStrict(store, key, original);
          }
        } on Object catch (error) {
          rollbackFailures.add(error);
        }
      }
      if (rollbackFailures.isNotEmpty) {
        _unknownStrictKeys.addAll(attempted);
        _courseMasteryCache = null;
        throw PreferenceOutcomeUnknownException(
          attempted.isEmpty
              ? courseMasterySnapshotPreferenceKey
              : attempted.last,
          cause: <Object>[primaryFailure, ...rollbackFailures],
        );
      }
      Error.throwWithStackTrace(primaryFailure, primaryStack);
    },
  );

  static Future<void> _writeStringStateStrict(
    PreferenceStringStore store,
    String key,
    _StringPreferenceState state,
  ) async {
    if (state.isPresent) {
      await _ssStrict(key, state.value!, preferences: store);
    } else {
      await _removeStringStrict(key, preferences: store);
    }
  }

  /// Compatibility writer for existing callers. It writes v2, never the
  /// read-only v1 migration key.
  static Future<void> setCourseMasteryRawJson(
    String json, {
    PreferenceStringStore? preferences,
  }) async {
    await setCourseMasterySnapshotRawJson(json, preferences: preferences);
  }

  /// Test-only: forgets the in-memory mirror; mocked preferences remain the
  /// persistence boundary so a subsequent [Storage.init] can exercise reload.
  @visibleForTesting
  static void resetCourseMasteryForTesting() {
    _courseMasteryCache = null;
  }

  /// XP-Gesamtpunkte. Level = (xp / 100) + 1.
  static Future<void> get packCompletionXpDrain => _xpRewardMutation;

  /// A native reload can replace a setter's optimistic cache before its reply.
  /// Mark both existing and newly admitted writes throughout the actual read.
  /// Only their native confirmation may retain a value; getter observations
  /// and a caller timeout never acquire or release this authority.
  static Future<void> reloadForPackCompletion(
    SharedPreferences preferences,
  ) async {
    _packCompletionReloads.update(
      preferences,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    try {
      if (identical(preferences, _prefs)) {
        _pendingVocabPreferenceWrite?.sharedCacheReloaded = true;
      }
      await preferences.reload();
    } finally {
      final remaining = _packCompletionReloads[preferences]! - 1;
      if (remaining == 0) {
        _packCompletionReloads.remove(preferences);
      } else {
        _packCompletionReloads[preferences] = remaining;
      }
    }
  }

  static void refreshPackCompletionCaches() {
    _invalidatePackCache();
    _courseMasteryCache = null;
    _confirmedXpRewardLedger = null;
    _confirmedRewardLists.clear();
  }

  static int get xp {
    final ledger = _readXpRewardLedger(strict: false);
    return ledger == null ? _i('kl_xp') : _effectiveXpTotal(ledger);
  }

  static int get xpLevel => (xp ~/ 100) + 1;
  static int get xpToNext => 100 - (xp % 100);
  static Future<void> setXp(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'XP cannot be negative.');
    }
    // An explicit balance restore supersedes older session-local awards.
    _xpAwardEpoch++;
    return _enqueueXpRewardMutation(() async {
      if (_unknownStrictKeys.contains(listeningRewardLedgerPreferenceKey)) {
        await _recoverUnknownXpRewardState();
      }
      final ledger =
          _readXpRewardLedger(strict: true) ??
          _XpRewardLedger(totalXp: _i('kl_xp'), claims: const {});
      await _persistXpRewardLedger(ledger.copyWith(totalXp: value));
    });
  }

  static Future<void> addXp(int amount) => XpAwardAttempt(amount).save();

  static _OrdinaryXpDay? _ordinaryXpDay(_XpRewardLedger ledger) {
    if (ledger.ordinaryDay != null) {
      return ledger.ordinaryDay;
    }
    final date = _s('kl_xp_today_date');
    return _isCanonicalStudyLogDate(date)
        ? _OrdinaryXpDay(date: date, xp: _i('kl_xp_today_raw'))
        : null;
  }

  static _XpRewardLedger _ordinaryXpAfter(
    _XpRewardLedger ledger,
    int earnedXp,
    String earnedOn, {
    _DailyChallengeState? daily,
    int? wins,
  }) {
    final total = ledger.totalXp + earnedXp;
    if (total < 0) {
      throw ArgumentError.value(earnedXp, 'amount', 'XP cannot be negative.');
    }
    final previous = _ordinaryXpDay(ledger);
    final _OrdinaryXpDay day;
    if (previous == null || previous.date.compareTo(earnedOn) < 0) {
      day = _OrdinaryXpDay(date: earnedOn, xp: earnedXp);
    } else if (previous.date == earnedOn) {
      day = _OrdinaryXpDay(date: previous.date, xp: previous.xp + earnedXp);
    } else {
      // A retry from an earlier day may change total XP, but cannot replace
      // the newer day's already-earned amount.
      day = previous;
    }
    return ledger.copyWith(
      totalXp: total,
      ordinaryDay: day,
      dailyChallenge: daily,
      kkeunmariWins: wins,
    );
  }

  /// Prepared inside terminal admission after the ordinary reward owner drains.
  static String preparePackCompletionXp(int amount, String earnedOn) {
    final ledger =
        _readXpRewardLedger(strict: true) ??
        _XpRewardLedger(totalXp: _i('kl_xp'), claims: const {});
    return _ordinaryXpAfter(
      ledger,
      amount,
      earnedOn,
      daily: ledger.dailyChallenge,
      wins: ledger.kkeunmariWins,
    ).encode();
  }

  static Future<void> _saveOrdinaryXpAward(XpAwardAttempt attempt) async {
    if (!attempt._isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
    if (attempt._committed ||
        (attempt.amount == 0 &&
            attempt.dailyCompletionBonus == null &&
            !attempt.kkeunmariWin)) {
      return;
    }
    if (_unknownStrictKeys.contains(listeningRewardLedgerPreferenceKey)) {
      await _recoverUnknownXpRewardState();
    }
    if (!attempt._isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
    if (attempt._committed) {
      return;
    }
    final ledger =
        _readXpRewardLedger(strict: true) ??
        _XpRewardLedger(totalXp: _i('kl_xp'), claims: const {});
    var wins = ledger.kkeunmariWins;
    if (attempt.kkeunmariWin) {
      final previousWins = wins ?? _i('kl_kkeunmari_wins');
      if (previousWins < 0) {
        throw const FormatException('Invalid legacy kkeunmari win count.');
      }
      wins = previousWins + 1;
    }
    var earnedXp = attempt.amount;
    var daily = ledger.dailyChallenge;
    final dailyBonus = attempt.dailyCompletionBonus;
    if (dailyBonus != null) {
      if (dailyBonus < 0 || attempt.amount < 0) {
        throw ArgumentError('Daily challenge rewards must be nonnegative.');
      }
      final last = daily?.date ?? _s('kl_daily_last');
      if (last.isNotEmpty && !_isCanonicalStudyLogDate(last)) {
        throw const FormatException('Invalid legacy daily challenge date.');
      }
      final legacyStreak = daily?.streak ?? _i('kl_daily_streak');
      // Old split writes could save the date but lose its streak value.
      final streak = legacyStreak < 1 ? 1 : legacyStreak;
      if (last.isEmpty || last.compareTo(attempt._earnedOn) < 0) {
        final earnedDate = DateTime.parse(attempt._earnedOn);
        final yesterday = _isoOf(
          DateTime(earnedDate.year, earnedDate.month, earnedDate.day - 1),
        );
        daily = _DailyChallengeState(
          attempt._earnedOn,
          last == yesterday ? streak + 1 : 1,
        );
        earnedXp += dailyBonus;
      } else if (daily == null && _isCanonicalStudyLogDate(last)) {
        daily = _DailyChallengeState(last, streak < 1 ? 1 : streak);
      }
    }
    final updated = _ordinaryXpAfter(
      ledger,
      earnedXp,
      attempt._earnedOn,
      daily: daily,
      wins: wins,
    );
    attempt._earnedXp = earnedXp;
    final pending = _PendingOrdinaryXpWrite(
      attempt: attempt,
      before: _s(listeningRewardLedgerPreferenceKey),
      encoded: updated.encode(),
    );
    _pendingOrdinaryXpWrite = pending;
    var unknown = false;
    try {
      await _persistXpRewardLedger(updated);
      if (!attempt._isCurrent) {
        throw const StaleLocalDataLifetimeException();
      }
      attempt._committed = true;
    } on PreferenceOutcomeUnknownException {
      unknown = true;
      rethrow;
    } finally {
      if (!unknown && identical(_pendingOrdinaryXpWrite, pending)) {
        _pendingOrdinaryXpWrite = null;
      }
    }
  }

  /// Claims the first-completion listening reward exactly once.
  ///
  /// The in-memory reservation happens before the first await, preventing two
  /// callbacks in the same isolate from entering the durable mutation. All XP
  /// writes share one queue so different scenario claims cannot overwrite each
  /// other after an await. Existing `kl_completed_scenarios` entries are
  /// intentionally treated as already rewarded; there is no retroactive XP.
  static Future<ListeningRewardClaimResult> claimListeningCompletionReward({
    required String scenarioId,
    required int earnedXp,
    DateTime? now,
  }) {
    final id = scenarioId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(scenarioId, 'scenarioId', 'ID is empty.');
    }
    if (earnedXp <= 0) {
      throw ArgumentError.value(
        earnedXp,
        'earnedXp',
        'Reward XP must be positive.',
      );
    }
    if (_pendingListeningRewardClaims.contains(id) ||
        completedScenarios.contains(id)) {
      return Future.value(ListeningRewardClaimResult.alreadyClaimed);
    }

    _pendingListeningRewardClaims.add(id);
    final result = _enqueueXpRewardMutation(() async {
      await _recoverUnknownXpRewardState();
      if (_unknownStrictKeys.contains('kl_completed_scenarios')) {
        await _prepareStringListMutation(
          _SharedPreferenceStringListStore(_prefs!),
          'kl_completed_scenarios',
        );
        _completedScenariosCache = null;
      }
      final persistedCompleted = _l('kl_completed_scenarios');
      if (persistedCompleted.contains(id)) {
        return ListeningRewardClaimResult.alreadyClaimed;
      }

      final current =
          _readXpRewardLedger(strict: true) ??
          _XpRewardLedger(totalXp: _i('kl_xp'), claims: const {});
      if (current.claims.containsKey(id)) {
        // §W2-Task4 fix round 1: 무조건 무효화 — 원장에는 이미 클레임이 있으므로
        // completedScenarios(원장 머지)는 지금 당장 이 id 를 반영해야 한다.
        // _mirrorListeningCompletion 이 (아래 try/catch 로) 로컬 리스트 쓰기
        // 실패를 삼켜도, 캐시 자체를 지우면 다음 읽기가 원장에서 다시 머지해
        // 자가치유한다 — 캐시 이전 코드의 동작을 복원한다.
        _completedScenariosCache = null;
        await _mirrorListeningCompletion(id);
        return ListeningRewardClaimResult.alreadyClaimed;
      }

      final claims = Map<String, _ListeningRewardClaim>.from(current.claims)
        ..[id] = _ListeningRewardClaim(
          earnedXp: earnedXp,
          earnedOn: _isoOf(now ?? DateTime.now()),
        );
      final updated = current.copyWith(
        totalXp: _effectiveXpTotal(current) + earnedXp,
        claims: claims,
      );
      await _persistXpRewardLedger(updated);
      // §W2-Task4 fix round 1: 위와 동일한 이유 — 원장 클레임이 막 저장됐으므로
      // completedScenarios 캐시를 mirror 결과와 무관하게 무효화한다.
      _completedScenariosCache = null;
      await _mirrorListeningCompletion(id);
      return ListeningRewardClaimResult.awarded;
    });
    return result.whenComplete(() {
      _pendingListeningRewardClaims.remove(id);
    });
  }

  /// A single durable value couples one scenario attempt's reward and XP.
  /// Retrying the same attempt cannot pay twice, even after a lost native reply.
  /// A genuine replay uses a new attempt ID and retains the existing XP policy.
  static Future<void> claimScenarioCompletionReward({
    required String attemptId,
    required String scenarioId,
    required int earnedXp,
    DateTime? now,
  }) {
    if (attemptId.trim().isEmpty || scenarioId.trim().isEmpty || earnedXp < 0) {
      throw ArgumentError(
        'A scenario reward needs valid IDs and non-negative XP.',
      );
    }
    if (earnedXp == 0) {
      return Future<void>.value();
    }
    return _enqueueXpRewardMutation(() async {
      await _recoverUnknownXpRewardState();
      final current =
          _readXpRewardLedger(strict: true) ??
          _XpRewardLedger(totalXp: _i('kl_xp'), claims: const {});
      final existing = current.scenarioClaims[attemptId];
      if (existing != null) {
        if (existing.scenarioId != scenarioId ||
            existing.reward.earnedXp != earnedXp) {
          throw ArgumentError('A scenario attempt cannot change its reward.');
        }
        return;
      }
      final claims =
          Map<String, _ScenarioRewardClaim>.from(current.scenarioClaims)
            ..[attemptId] = _ScenarioRewardClaim(
              scenarioId: scenarioId,
              reward: _ListeningRewardClaim(
                earnedXp: earnedXp,
                earnedOn: _isoOf(now ?? DateTime.now()),
              ),
            );
      await _persistXpRewardLedger(
        current.copyWith(
          totalXp: _effectiveXpTotal(current) + earnedXp,
          scenarioClaims: claims,
        ),
      );
    });
  }

  // ───────── Tagesziel (일일 목표 진행 — 리텐션 모멘텀) ─────────
  /// 오늘 획득한 XP(자정 리셋). 저장 날짜가 오늘이 아니면 0.
  static int get xpToday {
    final today = _isoOf(DateTime.now());
    final ledger = _readXpRewardLedger(strict: false);
    final day = ledger?.ordinaryDay;
    final ordinaryXp = xpTodayValue(
      day?.date ?? _s('kl_xp_today_date'),
      day?.xp ?? _i('kl_xp_today_raw'),
      today,
    );
    final listeningXp = ledger?.claims.values
        .where((claim) => claim.earnedOn == today)
        .fold<int>(0, (total, claim) => total + claim.earnedXp);
    final scenarioXp = ledger?.scenarioClaims.values
        .where((claim) => claim.reward.earnedOn == today)
        .fold<int>(0, (total, claim) => total + claim.reward.earnedXp);
    return ordinaryXp + (listeningXp ?? 0) + (scenarioXp ?? 0);
  }

  /// 순수 함수(테스트 대상) — 저장 날짜가 오늘이면 raw, 아니면 0(자정 리셋).
  @visibleForTesting
  static int xpTodayValue(String storedDate, int storedRaw, String today) =>
      storedDate == today ? storedRaw : 0;

  /// 일일 목표 XP — 온보딩 분 목표(dailyGoalMinutes)에서 파생(3 XP/분), 미설정 시 30.
  static int get dailyGoalXp {
    final m = dailyGoalMinutes;
    return m > 0 ? m * 3 : 30;
  }

  // ── Persönliche Bestleistung pro Spiel (Highscore) ──────────────────
  // Eine JSON-Map gameId -> best (int). Selbst-Wettbewerb, KEINE Ranglisten.
  static Map<String, int> get _gameBests {
    if (_gameBestWritePending || _unknownStrictKeys.contains('kl_game_best')) {
      return _confirmedGameBests ?? const {};
    }
    final raw = _s('kl_game_best');
    if (raw.isEmpty) {
      return _confirmedGameBests = const {};
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _confirmedGameBests = Map.unmodifiable(
        m.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    } catch (_) {
      return {};
    }
  }

  static int gameBest(String id) => _gameBests[id] ?? 0;

  /// Speichert nur, wenn besser. Gibt `true` zurück, wenn es ein neuer Rekord
  /// war. [higherIsBetter]=false für zeit-/versuchsbasierte Spiele
  /// (kleinerer Wert = besser).
  static Future<bool> recordGameBest(
    String id,
    int value, {
    bool higherIsBetter = true,
  }) => GameBestAttempt(id, value, higherIsBetter: higherIsBetter).save();

  static Future<bool> _saveGameBest(GameBestAttempt attempt) async {
    attempt._assertCurrent();
    if (attempt._saved) {
      return attempt._wasNewBest!;
    }
    const key = 'kl_game_best';
    final store = _stringStore();
    await _refreshUnknownStringKeys(store, [key]);
    final pending = _pendingGameBestWrite;
    if (pending != null) {
      final native = store.getString(key) ?? '';
      if (native == pending.after) {
        pending.attempt._saved = true;
        pending.attempt._best = pending.attempt.score;
      } else if (native == pending.before) {
        pending.attempt._wasNewBest = null;
      } else {
        _unknownStrictKeys.add(key);
        throw const PreferenceOutcomeUnknownException(key);
      }
      _pendingGameBestWrite = null;
    }
    attempt._assertCurrent();
    if (attempt._saved) {
      return attempt._wasNewBest!;
    }
    final before = await _prepareStringMutation(store, key);
    attempt._assertCurrent();
    final raw = before.value ?? '';
    // Malformed recovery data must not be replaced by an empty-looking map.
    final current = raw.isEmpty
        ? <String, int>{}
        : (jsonDecode(raw) as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          );
    _confirmedGameBests = Map.unmodifiable(current);
    attempt._wasNewBest ??= attempt._beats(current[attempt.id]);
    if (attempt._beats(current[attempt.id])) {
      final updated = Map<String, int>.of(current)
        ..[attempt.id] = attempt.score;
      final write = (attempt: attempt, before: raw, after: jsonEncode(updated));
      _pendingGameBestWrite = write;
      _gameBestWritePending = true;
      var unknown = false;
      try {
        await _ssStrict(
          key,
          jsonEncode(updated),
          preferences: store,
          beforeState: before,
          assertCurrentWrite: attempt._assertCurrent,
        );
        attempt._assertCurrent();
        _confirmedGameBests = Map.unmodifiable(updated);
        current[attempt.id] = attempt.score;
      } on PreferenceOutcomeUnknownException {
        unknown = true;
        rethrow;
      } on PreferenceWriteException {
        // A confirmed rejection did not establish a record. Compare again
        // if another round has updated this game before the user retries.
        attempt._wasNewBest = null;
        rethrow;
      } finally {
        _gameBestWritePending = false;
        if (!unknown && _pendingGameBestWrite == write) {
          _pendingGameBestWrite = null;
        }
      }
    }
    attempt._assertCurrent();
    attempt._best = current[attempt.id];
    attempt._saved = true;
    return attempt._wasNewBest!;
  }

  // ── Tages-Challenge (오늘의 도전) — täglicher Selbst-Streak ──────────
  // Datums-Seed-Puzzle (alle Nutzer:innen bekommen dasselbe Tagesset).
  // Selbst-Wettbewerb (Streak), KEINE Rangliste.
  static String get dailyChallengeLastDone =>
      _readXpRewardLedger(strict: false)?.dailyChallenge?.date ??
      _s('kl_daily_last');
  static int get dailyChallengeStreak =>
      _readXpRewardLedger(strict: false)?.dailyChallenge?.streak ??
      _i('kl_daily_streak');

  static bool dailyChallengeDoneToday({DateTime? now}) =>
      dailyChallengeLastDone == _isoOf(now ?? DateTime.now());

  /// Markiert die heutige Tages-Challenge als erledigt und pflegt den
  /// Selbst-Streak: gestern erledigt → +1, sonst Reset auf 1; heute schon
  /// erledigt → no-op (kein Doppel-Bonus).
  static Future<void> markDailyChallengeDone({DateTime? now}) =>
      XpAwardAttempt(0, earnedAt: now, dailyCompletionBonus: 0).save();

  /// 계 피드에 마지막으로 broadcast 한 레벨 (2픽 levelUp 중복 방지).
  static int get lastGyeLevel => _i('kl_gye_level');
  static Future<void> setLastGyeLevel(int v) => _si('kl_gye_level', v);

  /// Sterne pro Szenario (0–3). Speichert nur Verbesserungen.
  /// §W2-Task4: 빌드 경로(scenarios_list_screen.dart)에서 재호출되므로
  /// in-memory 캐시 — 쓰기 시점(setScenarioStars)에만 무효화된다.
  static Map<String, int>? _scenarioStarsCache;

  static Map<String, int> get scenarioStars {
    final cached = _scenarioStarsCache;
    if (cached != null) {
      return cached;
    }
    if (_unknownStrictKeys.contains('kl_scenario_stars')) {
      return const {};
    }
    final raw = _s('kl_scenario_stars');
    Map<String, int> parsed;
    if (raw.isEmpty) {
      parsed = const {};
    } else {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        parsed = m.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        parsed = const {};
      }
    }
    final unmodifiable = Map<String, int>.unmodifiable(parsed);
    _scenarioStarsCache = unmodifiable;
    return unmodifiable;
  }

  static Future<void> setScenarioStars(String id, int stars) {
    if (id.trim().isEmpty || stars < 0 || stars > 3) {
      throw ArgumentError(
        'Scenario stars need an ID and a value from zero to three.',
      );
    }
    return _enqueueXpRewardMutation(() async {
      const key = 'kl_scenario_stars';
      final store = _stringStore();
      await _refreshUnknownStringKeys(store, [key]);
      final before = await _prepareStringMutation(store, key);
      final raw = before.value ?? '';
      final current = raw.isEmpty
          ? <String, int>{}
          : (jsonDecode(raw) as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toInt()),
            );
      _scenarioStarsCache = Map.unmodifiable(current);
      // Zero-star completion remains recorded; replays can only improve it.
      if (!current.containsKey(id) || current[id]! < stars) {
        final updated = Map<String, int>.of(current)..[id] = stars;
        await _ssStrict(
          key,
          jsonEncode(updated),
          preferences: store,
          beforeState: before,
        );
        _scenarioStarsCache = Map.unmodifiable(updated);
      }
    });
  }

  /// §W2-Task4: `completedScenarios` 는 로컬 리스트 + XP 보상 원장의 클레임
  /// id 를 병합한다 — 원장 디코드(`_readXpRewardLedger`)가 실제 파싱 비용이라
  /// 결과를 캐싱한다. `addCompletedScenario` 가 무효화한다. 원장 자체가
  /// 다른 경로(예: 리스닝 보상 클레임)로 바뀌는 경우는 이 캐시 범위 밖이라
  /// 다음 프로세스 시작 전까지 반영이 늦을 수 있다 — 기존에도 클레임은
  /// `addCompletedScenario` 를 함께 호출하는 경로로만 완료 표시를 남겼다.
  static List<String>? _completedScenariosCache;

  static List<String> get completedScenarios {
    final cached = _completedScenariosCache;
    if (cached != null) {
      return cached;
    }
    final completed = List<String>.of(_rewardList('kl_completed_scenarios'));
    // XP claims are permanent financial/reward history. After a scenario
    // corpus migration they must not resurrect old completion progress.
    if (scenarioCorpusGeneration != ScenarioCorpusGeneration.legacy) {
      return completed;
    }
    final claims = _readXpRewardLedger(strict: false)?.claims.keys;
    if (claims != null) {
      for (final id in claims) {
        if (!completed.contains(id)) {
          completed.add(id);
        }
      }
    }
    final unmodifiable = List<String>.unmodifiable(completed);
    _completedScenariosCache = unmodifiable;
    return unmodifiable;
  }

  static Future<void> addCompletedScenario(String id) =>
      _enqueueXpRewardMutation(
        () => _writeRewardListEntry('kl_completed_scenarios', id),
      );

  static List<String> _rewardList(String key) =>
      _unknownStrictKeys.contains(key) || _pendingRewardListKeys.contains(key)
      ? (_confirmedRewardLists[key] ?? const [])
      : _l(key);

  static Future<void> _writeRewardListEntry(String key, String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Reward ID is empty.');
    }
    final prefs = _prefs;
    if (prefs == null) {
      throw PreferenceWriteException(key);
    }
    final store = _SharedPreferenceStringListStore(prefs);
    final before = await _prepareStringListMutation(store, key);
    final current = List<String>.of(before.value ?? const []);
    _confirmedRewardLists[key] = List.unmodifiable(current);
    _pendingRewardListKeys.add(key);
    try {
      if (!current.contains(id)) {
        final updated = [...current, id];
        await _slStrict(key, updated, preferences: store, beforeState: before);
        _confirmedRewardLists[key] = List.unmodifiable(updated);
      }
    } finally {
      _pendingRewardListKeys.remove(key);
      if (key == 'kl_completed_scenarios') {
        _completedScenariosCache = null;
      }
    }
  }

  static String get scenarioCorpusGeneration {
    final value = _s(scenarioCorpusGenerationPreferenceKey).trim();
    return value.isEmpty ? ScenarioCorpusGeneration.legacy : value;
  }

  /// Clears only scenario completion and stars when a new approved corpus
  /// generation becomes active. The immutable XP ledger, SRS, notes,
  /// account data, and Hanok placement are deliberately untouched.
  /// The generation marker is written last, making an interrupted migration
  /// safely repeatable.
  static Future<bool> migrateScenarioProgressGeneration(
    String targetGeneration,
  ) async {
    final target = targetGeneration.trim();
    if (target.isEmpty) {
      throw ArgumentError.value(
        targetGeneration,
        'targetGeneration',
        'Generation must not be empty.',
      );
    }
    final current = scenarioCorpusGeneration;
    if (current == target) {
      return false;
    }
    // A rollback build may still read a newer durable marker. Never turn that
    // into a destructive downgrade or re-enable legacy XP-claim mirroring.
    if (current != ScenarioCorpusGeneration.legacy &&
        target == ScenarioCorpusGeneration.legacy) {
      return false;
    }
    await _slStrict('kl_completed_scenarios', const []);
    _completedScenariosCache = null;
    await _ssStrict('kl_scenario_stars', jsonEncode(<String, int>{}));
    _scenarioStarsCache = null;
    await _ssStrict(scenarioCorpusGenerationPreferenceKey, target);
    return true;
  }

  static List<String> get earnedBadges =>
      List.unmodifiable(_rewardList('kl_earned_badges'));
  static Future<void> earnBadge(String id) => _enqueueXpRewardMutation(
    () => _writeRewardListEntry('kl_earned_badges', id),
  );

  // ── Phase 2 (stately-rising-jongga) ── Pack-Fortschritt (lokal) ──────
  //
  // Lokale Source of Truth — überlebt offline. FirestoreProgressService
  // synct asynchron im Hintergrund (best-effort).
  //
  // Speicherformat: JSON-encoded Map<packId, PackProgress.toJson()>.
  // Schlüssel: `kl_pack_progress_v1` — Versionierung im Namen, damit
  // spätere Schema-Migrationen unterscheidbar bleiben.
  //
  // Hier wird absichtlich KEIN `PackProgress` importiert — Storage darf
  // keine model-Abhängigkeit haben (zirkulär bei Tests). Stattdessen
  // raw JSON Maps; `PackProgressService` dekodiert.
  // ─────────────────────────────────────────────────────────────────────

  static int _packProgressMutationCount = 0;

  static Future<void> get packCompletionPackDrain => _packProgressMutation;

  static Future<void> _enqueuePackProgressMutation(
    Future<void> Function() work,
  ) {
    PackCompletionStorage.assertAdmission();
    final immediate = _packProgressMutationCount++ == 0;
    final operation = immediate
        ? Future<void>.sync(work)
        : _packProgressMutation.then((_) => work());
    operation.then<void>(
      (_) {
        _packProgressMutationCount--;
      },
      onError: (Object _, StackTrace __) {
        _packProgressMutationCount--;
      },
    );
    _packProgressMutation = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  static const String _packProgressKey = 'kl_pack_progress_v1';
  static Map<String, dynamic>? _packCache;

  /// 손상된 `kl_pack_progress_v1` 원본을 옮겨 두는 격리 키.
  static const String packProgressQuarantinePreferenceKey =
      'kl_pack_progress_v1_corrupt_v1';

  /// 이번 실행에서 팩 진행도 파싱이 실패했는지. 서 있는 동안 write 를 막는다.
  static bool _packQuarantined = false;

  /// 손상 blob 때문에 팩 진행도를 신뢰할 수 없는 상태인지.
  static bool get packProgressIsQuarantined => _packQuarantined;

  /// 격리된 손상 원본. 없으면 빈 문자열.
  static String get packProgressQuarantinedRawJson =>
      _s(packProgressQuarantinePreferenceKey);

  /// 저장된 팩 진행도 원본 JSON. 캐시를 거치지 않으므로 "실제로 디스크에 뭐가
  /// 있는지"를 봐야 하는 회귀 테스트·진단에서 쓴다.
  static String get packProgressJsonRaw => _s(_packProgressKey);

  /// 팩 진행도를 읽는다.
  ///
  /// ⚠️ [_loadSrs] 와 **같은 무음 소실 버그**가 여기에도 있었다. `catch (_) → {}`
  /// 로 삼킨 뒤 [setPackProgressJson] 한 번이 그 빈 캐시에 팩 하나만 얹어
  /// 저장해서, 깨진 blob 하나로 61팩 진행도가 통째로 사라졌다.
  /// 전체 손상은 격리 후 write 잠금, 부분 손상은
  /// 유효 항목 보존.
  static Map<String, Map<String, dynamic>> _loadPackJson() {
    if (_packCache != null) {
      return _packCache!.map(
        (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
      );
    }
    final raw = _s(_packProgressKey);
    if (raw.isEmpty) {
      _packQuarantined = false;
      _packCache = <String, dynamic>{};
      return const <String, Map<String, dynamic>>{};
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map<String, dynamic>) {
      _quarantinePackProgress(raw);
      _packCache = <String, dynamic>{};
      return const <String, Map<String, dynamic>>{};
    }

    final packs = <String, dynamic>{};
    var dropped = 0;
    decoded.forEach((key, value) {
      if (value is Map) {
        packs[key] = value;
      } else {
        dropped++;
      }
    });

    if (packs.isEmpty && decoded.isNotEmpty) {
      _quarantinePackProgress(raw);
      _packCache = <String, dynamic>{};
      return const <String, Map<String, dynamic>>{};
    }

    if (dropped > 0) {
      debugPrint('Storage: 팩 진행도 $dropped개가 손상돼 제외됐다 (유효 ${packs.length}개)');
    }
    _packQuarantined = false;
    _packCache = packs;
    return packs.map((k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()));
  }

  /// 손상 원본을 격리 키로 옮기고 write 를 잠근다. 격리본이 이미 있으면 유지.
  static void _quarantinePackProgress(String raw) {
    _packQuarantined = true;
    debugPrint(
      'Storage: $_packProgressKey 손상 — 격리 후 쓰기 잠금 (${raw.length} bytes)',
    );
    if (_s(packProgressQuarantinePreferenceKey).isEmpty) {
      // ignore: discarded_futures, unawaited_futures
      _ss(packProgressQuarantinePreferenceKey, raw);
    }
  }

  /// 팩 진행도 캐시와 격리 상태를 함께 버린다.
  ///
  /// `kl_pack_progress_v1` 의 **원본이 교체되거나 삭제된 뒤**에만 호출한다.
  static void _invalidatePackCache() {
    _packCache = null;
    _packQuarantined = false;
  }

  /// 격리를 해제하고 팩 진행도를 빈 상태로 다시 시작한다.
  /// 사용자가 명시적으로 "새로 시작"을 택했을 때만. 격리본은 남긴다.
  static Future<void> resetQuarantinedPackProgress() async {
    await PackCompletionStorage.retire();
    _packQuarantined = false;
    _packCache = <String, dynamic>{};
    await _ss(_packProgressKey, jsonEncode(const <String, dynamic>{}));
  }

  /// 손상 격리 또는 스키마 다운그레이드 잠금 때문에 학습 진행도 write 를
  /// 건너뛰어야 하는지.
  static bool _packWritesBlocked() {
    if (_learningWritesLockReason != null) {
      debugPrint(
        'Storage: 학습 쓰기 잠금($_learningWritesLockReason) — '
        '$_packProgressKey 쓰기를 건너뛴다',
      );
      return true;
    }
    if (_packQuarantined) {
      debugPrint('Storage: 팩 진행도 격리 상태 — $_packProgressKey 쓰기를 건너뛴다');
      return true;
    }
    return false;
  }

  // ───────── 학습 데이터 전역 쓰기 잠금 ─────────

  static String? _learningWritesLockReason;

  /// 학습 데이터 write 가 잠겨 있으면 그 사유, 아니면 null.
  static String? get learningWritesLockReason => _learningWritesLockReason;

  /// 학습 데이터(SRS 덱·단어팩 진행도) write 를 잠근다.
  ///
  /// 쓰임새는 **스키마 다운그레이드**다 — 사용자가 최신 버전을 쓴 뒤 옛 APK 를
  /// 설치하면, 옛 코드가 자기가 이해하지 못하는 새 포맷 위에 옛 포맷을 써서
  /// 데이터를 망가뜨릴 수 있다. 그때 읽기는 허용하되 쓰기만 막는다.
  ///
  /// ⚠️ **범위**: SRS 덱(`kl_srs_v1`), 단어팩 진행도(`kl_pack_progress_v1`),
  /// 공유 어휘 진행도를 막는다. 스트릭·XP 같은 다른 스칼라 키와 클라우드 복원
  /// 경로는 막지 않는다 — 복원은 원본을 통째로 교체하므로 오히려 회복 수단이다.
  static void lockLearningWrites(String reason) {
    _learningWritesLockReason = reason;
    debugPrint('Storage: 학습 데이터 쓰기 잠금 — $reason');
  }

  /// 잠금을 해제한다. 마이그레이션이 정상 완료됐을 때만.
  static void unlockLearningWrites() {
    _learningWritesLockReason = null;
  }

  /// JSON-rohdaten eines Packs (null wenn nie gespeichert).
  /// Nutze `PackProgressService.get()` für typisierte Objekte.
  static Map<String, dynamic>? packProgressJson(String packId) {
    final map = _loadPackJson();
    return map[packId];
  }

  /// Alle Pack-Fortschritte als Raw-JSON. Für Bulk-load (Grid-Screen).
  static Map<String, Map<String, dynamic>> allPackProgressJson() =>
      _loadPackJson();

  /// Pack-Fortschritt schreiben (overwrite). Aufrufer ist verantwortlich
  /// für Merge-Logik (PackProgressService).
  static Future<void> setPackProgressJson(
    String packId,
    Map<String, dynamic> json,
  ) => _enqueuePackProgressMutation(() async {
    // ⚠️ 먼저 로드한다. 예전에는 `_packCache ?? {}` 로 시작해서, 캐시가 아직
    // 비어 있는 콜드 스타트에 이 함수가 먼저 불리면 **저장된 나머지 팩 진행도를
    // 통째로 덮어썼다**(읽기 전 쓰기 = 전면 손실). 로드는 캐시가 있으면 no-op 다.
    _loadPackJson();
    final cache = _packCache ?? <String, dynamic>{};
    cache[packId] = json;
    _packCache = cache;
    if (_packWritesBlocked()) {
      return;
    }
    await _ss(_packProgressKey, jsonEncode(cache));
  });

  /// Mehrere Packs gleichzeitig schreiben (Migration / Cloud-restore).
  static Future<void> setManyPackProgressJson(
    Map<String, Map<String, dynamic>> entries,
  ) => _enqueuePackProgressMutation(() async {
    // 위와 같은 이유로 먼저 로드한다.
    _loadPackJson();
    final cache = _packCache ?? <String, dynamic>{};
    cache.addAll(entries);
    _packCache = cache;
    if (_packWritesBlocked()) {
      return;
    }
    await _ss(_packProgressKey, jsonEncode(cache));
  });

  static Future<void> setAllPackProgressJsonStrict(
    Map<String, Map<String, dynamic>> entries, {
    PreferenceStringStore? preferences,
  }) => PackCompletionStorage.trackWrite(_packProgressKey, () async {
    final encoded = jsonEncode(entries);
    await _ssStrict(_packProgressKey, encoded, preferences: preferences);
    // 원본을 통째로 교체하는 복원 경로다 — 손상 격리를 여기서 해제한다.
    _packQuarantined = false;
    _packCache = {
      for (final entry in entries.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    };
  });

  /// Test-only: Pack-Cache invalidieren.
  @visibleForTesting
  static void resetPackProgressForTesting() {
    _invalidatePackCache();
  }

  // ── Phase 5.1 (stately-rising-jongga) ── Custom Packs ───────────────
  //
  // CustomPack JSON map: { packId: { name, sourcePageId, words: [...], ... } }
  // ────────────────────────────────────────────────────────────────────

  static String get customPacksRawJson => _s('kl_custom_packs_v1');
  static Future<void> setCustomPacksRawJson(String json) =>
      _ss('kl_custom_packs_v1', json);
  static Future<void> setCustomPacksRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
  }) => _ssStrict('kl_custom_packs_v1', json, preferences: preferences);

  // ── Phase 5 (stately-rising-jongga) ── 책 한 컷 / Bookshelf Storage ──
  //
  // Raw JSON string in SharedPreferences. Bookshelf-Service liest/parst.
  // ────────────────────────────────────────────────────────────────────
  static String get bookshelfRawJson => _s('kl_bookshelf_v1');
  static Future<void> setBookshelfRawJson(String json) =>
      _ss('kl_bookshelf_v1', json);
  static Future<void> setBookshelfRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
  }) => _ssStrict('kl_bookshelf_v1', json, preferences: preferences);

  // ── Typed study bookmarks ─────────────────────────────────────────
  // Owned by TypedStudyBookmarkStore. Storage intentionally exposes only the
  // raw blob so schema validation and fail-closed migration stay in one place.
  static const String typedStudyBookmarksPreferenceKey =
      'kl_typed_study_bookmarks_v1';
  static String get typedStudyBookmarksRawJson =>
      _s(typedStudyBookmarksPreferenceKey);
  static Future<void> setTypedStudyBookmarksRawJson(
    String json, {
    PreferenceStringStore? preferences,
  }) => _ssStrict(
    typedStudyBookmarksPreferenceKey,
    json,
    preferences: preferences,
  );

  static String get pickerRecoveryMarkerJson => _s(_pickerRecoveryMarkerKey);
  static String get cropRecoveryMarkerJson => _s(_cropRecoveryMarkerKey);
  static String get recoveredBookLease => _s(_recoveredBookLeaseKey);
  static String get recoveredWordLease => _s(_recoveredWordLeaseKey);

  static bool get hasMediaRecoveryMarker =>
      pickerRecoveryMarkerJson.isNotEmpty || cropRecoveryMarkerJson.isNotEmpty;

  static Future<void> refreshMediaRecoveryMarkers({
    PreferenceStringStore? preferences,
  }) async {
    await _refreshUnknownStringKeys(_stringStore(preferences), const [
      _pickerRecoveryMarkerKey,
      _cropRecoveryMarkerKey,
    ]);
  }

  static Future<void> refreshRecoveredMediaRecords({
    PreferenceStringStore? preferences,
  }) async {
    await _refreshUnknownStringKeys(_stringStore(preferences), const [
      _recoveredBookLeaseKey,
      _recoveredWordLeaseKey,
    ]);
  }

  static Future<void> markPickerLaunch({
    required String purpose,
    required String workflowId,
    String? attemptId,
  }) => _ssStrict(
    _pickerRecoveryMarkerKey,
    jsonEncode({
      'purpose': purpose,
      'workflowId': workflowId,
      if (attemptId != null) 'attemptId': attemptId,
    }),
  );

  static Future<void> clearPickerLaunch({
    PreferenceStringStore? preferences,
  }) async {
    await _removeStringStrict(
      _pickerRecoveryMarkerKey,
      preferences: preferences,
    );
  }

  static Future<void> markCropLaunch({required String workflowId}) =>
      _ssStrict(_cropRecoveryMarkerKey, jsonEncode({'workflowId': workflowId}));

  static Future<void> clearCropLaunch({
    PreferenceStringStore? preferences,
  }) async {
    await _removeStringStrict(_cropRecoveryMarkerKey, preferences: preferences);
  }

  static Future<String?> setRecoveredBookLease(
    String value, {
    PreferenceStringStore? preferences,
  }) => _serializeRecoveredBookMutation(() async {
    final store = _stringStore(preferences);
    await _prepareStringReadModifyWrite(store, _recoveredBookLeaseKey);
    final previous = store.getString(_recoveredBookLeaseKey) ?? '';
    await _ssStrict(_recoveredBookLeaseKey, value, preferences: store);
    return previous.isEmpty ? null : previous;
  });
  static Future<List<String>> setRecoveredWordLease(
    String value, {
    PreferenceStringStore? preferences,
  }) => _serializeRecoveredWordMutation(() async {
    final store = _stringStore(preferences);
    await _prepareStringReadModifyWrite(store, _recoveredWordLeaseKey);
    final record = _recoveredWordRecord(value);
    final workflowId = record['workflowId'] as String;
    final records = _recoveredWordRecords(
      store.getString(_recoveredWordLeaseKey) ?? '',
    );
    final discarded = <String>[];
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 2));
    for (final entry in records.entries.toList()) {
      if (_recoveredWordRecordExpired(entry.value, cutoff)) {
        records.remove(entry.key);
        discarded.add(entry.value['lease'] as String);
      }
    }
    final previous = records.remove(workflowId);
    if (previous != null && previous['lease'] != record['lease']) {
      discarded.add(previous['lease'] as String);
    }
    record['createdAt'] = DateTime.now().toUtc().toIso8601String();
    records[workflowId] = record;
    while (records.length > 8) {
      final removed = records.remove(records.keys.first);
      if (removed != null && removed['lease'] != record['lease']) {
        discarded.add(removed['lease'] as String);
      }
    }
    await _ssStrict(
      _recoveredWordLeaseKey,
      jsonEncode(records),
      preferences: store,
    );
    return List<String>.unmodifiable(discarded.toSet());
  });
  static Future<void> clearRecoveredBookLease() =>
      _serializeRecoveredBookMutation(
        () => _removeStrictIfPresent(_recoveredBookLeaseKey),
      );

  static Future<String?> claimRecoveredBookLease({
    PreferenceStringStore? preferences,
    String? expectedLease,
  }) => _serializeRecoveredBookMutation(() async {
    bool matches(String source) {
      if (expectedLease == null) {
        return true;
      }
      try {
        final decoded = jsonDecode(source);
        return decoded is Map && decoded['lease'] == expectedLease;
      } on Object {
        return false;
      }
    }

    return _removeStringStrict(
      _recoveredBookLeaseKey,
      preferences: preferences,
      matches: matches,
    );
  });

  static Future<RecoveredWordClaim> claimRecoveredWordLease(
    String workflowId, {
    PreferenceStringStore? preferences,
  }) => _serializeRecoveredWordMutation(() async {
    final store = _stringStore(preferences);
    await _prepareStringReadModifyWrite(store, _recoveredWordLeaseKey);
    final records = _recoveredWordRecords(
      store.getString(_recoveredWordLeaseKey) ?? '',
    );
    final discarded = <String>[];
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 2));
    for (final entry in records.entries.toList()) {
      if (_recoveredWordRecordExpired(entry.value, cutoff)) {
        records.remove(entry.key);
        discarded.add(entry.value['lease'] as String);
      }
    }
    final record = records.remove(workflowId);
    if (record != null || discarded.isNotEmpty) {
      if (records.isEmpty) {
        await _removeStringStrict(_recoveredWordLeaseKey, preferences: store);
      } else {
        await _ssStrict(
          _recoveredWordLeaseKey,
          jsonEncode(records),
          preferences: store,
        );
      }
    }
    return RecoveredWordClaim(
      record: record == null ? null : jsonEncode(record),
      discardedLeases: List<String>.unmodifiable(discarded.toSet()),
    );
  });

  static bool _recoveredWordRecordExpired(
    Map<String, dynamic> record,
    DateTime cutoff,
  ) {
    final createdAt = DateTime.tryParse(record['createdAt'] as String? ?? '');
    return createdAt == null || createdAt.toUtc().isBefore(cutoff);
  }

  static Map<String, Map<String, dynamic>> _recoveredWordRecords(
    String source,
  ) {
    if (source.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return <String, Map<String, dynamic>>{};
      }
      if (decoded['workflowId'] is String && decoded['lease'] is String) {
        final record = _recoveredWordRecord(source);
        return {record['workflowId'] as String: record};
      }
      final records = <String, Map<String, dynamic>>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! Map) {
          continue;
        }
        final record = Map<String, dynamic>.from(entry.value as Map);
        if (record['workflowId'] == entry.key && record['lease'] is String) {
          records[entry.key as String] = record;
        }
      }
      return records;
    } on Object {
      return <String, Map<String, dynamic>>{};
    }
  }

  static Map<String, dynamic> _recoveredWordRecord(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map ||
        decoded['workflowId'] is! String ||
        (decoded['workflowId'] as String).isEmpty ||
        decoded['lease'] is! String ||
        (decoded['lease'] as String).isEmpty) {
      throw const FormatException('Invalid recovered word record.');
    }
    return {
      'workflowId': decoded['workflowId'] as String,
      'lease': decoded['lease'] as String,
      if (decoded['createdAt'] is String)
        'createdAt': decoded['createdAt'] as String,
    };
  }

  static Future<T> _serializeRecoveredWordMutation<T>(
    Future<T> Function() operation,
  ) {
    final result = _recoveredWordMutation.then((_) => operation());
    _recoveredWordMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static Future<T> _serializeRecoveredBookMutation<T>(
    Future<T> Function() operation,
  ) {
    final result = _recoveredBookMutation.then((_) => operation());
    _recoveredBookMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static Future<void> _removeStrictIfPresent(String key) async {
    await _removeStringStrict(key);
  }

  /// Tagessperre für "책 한 컷" Analyse-Aufrufe — DeepL Free 한도 보호.
  /// Speichert `<isoDate>:<count>`.
  static const int kBookSnapDailyLimit = 20;

  static int bookSnapCountToday() {
    final raw = _s('kl_book_snap_quota');
    final today = _today();
    if (raw.isEmpty) return 0;
    final parts = raw.split(':');
    if (parts.length != 2) return 0;
    if (parts[0] != today) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  static Future<void> incBookSnapCountToday() async {
    final today = _today();
    final cur = bookSnapCountToday();
    await _ss('kl_book_snap_quota', '$today:${cur + 1}');
  }

  static bool get bookSnapQuotaReached =>
      bookSnapCountToday() >= kBookSnapDailyLimit;

  // ── Phase 4 (stately-rising-jongga) ── Kkeunmari-Wins Counter ───────
  //
  // Wird in `kkeunmari_screen._endGame()` inkrementiert bei Sieg
  // (tigerStuck / deadEnd). Quest `q_punggyeong` braucht ≥ 10.
  static int get kkeunmariWins =>
      _readXpRewardLedger(strict: false)?.kkeunmariWins ??
      _i('kl_kkeunmari_wins');
  static Future<void> incKkeunmariWins() =>
      XpAwardAttempt(0, kkeunmariWin: true).save();

  // ── Phase 4 (stately-rising-jongga) ── Quest-Abschluss-Persistenz ────
  //
  // Format: JSON Map<questId, ISO-Timestamp>. Storage gewinnt von Quest-
  // Tracker — beim ersten Erreichen des Targets wird hier markiert; die
  // Marke verschwindet nicht mehr (auch wenn der Counter später sinkt,
  // z.B. nach Reset).
  static const String _questCompletedKey = 'kl_quests_completed_v1';

  static Map<String, String> get questCompletions {
    final raw = _s(_questCompletedKey);
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return const {};
    }
  }

  static bool hasQuestCompleted(String id) => questCompletions.containsKey(id);

  static Future<void> markQuestCompleted(String id, {DateTime? at}) async {
    final map = Map<String, String>.from(questCompletions);
    if (map.containsKey(id)) return; // idempotent
    map[id] = (at ?? DateTime.now().toUtc()).toIso8601String();
    await _ss(_questCompletedKey, jsonEncode(map));
  }

  // ── Phase 3 (stately-rising-jongga) ── Gesehene Hanok-Stages ─────────
  //
  // Liste der bereits "gesehenen" HanokStage-Namen (z.B. ['empty',
  // 'foundation']). Wird vom HanokCinematic-Widget gelesen, um die
  // Übergangsszene nur einmal pro Stage auszuspielen.
  // ─────────────────────────────────────────────────────────────────────

  // ── Personal Hanok map construction-reveal ledger ──────────────────────
  //
  // This is deliberately a local UX ledger, never a learning-progress or
  // reward source. A missing key is meaningful: the first map visit quietly
  // baselines existing construction so an upgraded learner is not shown a
  // backlog of historic building animations.
  // ───────── Reset ─────────
  static Future<void> resetAll({PreferenceRemovalStore? preferences}) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceRemovalStore(_prefs!));
    if (store == null) return;
    await _withLearningReset(() async {
      // Reload after admitted native writes settle, so their new keys remain
      // visible to deletion even if they were absent before their reply.
      await _assertDurableAccountResetAllowed(
        store,
        allowJournalPreservingReset: true,
      );
      await PackCompletionStorage.retire(preferences: store);
      await _retireSrsJournalForReset(store);
      LocalDataLifetime.invalidate();
      try {
        final keys = store.getKeys();
        for (final k in keys) {
          if (k.startsWith('kl_') &&
              !_durableAccountJournalPreferenceKeys.contains(k)) {
            await store.remove(k);
          }
        }
      } finally {
        // Account/local deletion must never leave a removed course graph or
        // wrong-answer history reachable through optimistic in-memory mirrors.
        resetCachesAfterExternalWrite();
      }
    });
  }

  /// Account-deletion reset that verifies every app-owned preference removal.
  ///
  /// When supplied, [canonicalizeAccountDeletionCheckpoint] is the sole
  /// exception to the durable-journal reset fence. It must reject anything
  /// except the completed deletion checkpoint that local cleanup is resuming.
  static Future<void> resetAllStrict({
    PreferenceRemovalStore? preferences,
    AccountDeletionCheckpointCanonicalizer?
    canonicalizeAccountDeletionCheckpoint,
  }) async {
    final store = preferences ?? _preferenceRemovalStore();
    await _withLearningReset(() async {
      await _assertDurableAccountResetAllowed(
        store,
        allowAccountDeletionCheckpoint:
            canonicalizeAccountDeletionCheckpoint != null,
      );
      await PackCompletionStorage.retire(preferences: store);
      await _retireSrsJournalForReset(store);
      // Invalidate before checkpoint canonicalization and preference removal.
      LocalDataLifetime.invalidate();
      final failedKeys = <String>[];
      final causes = <Object>[];
      final canonicalCheckpointKeys = <String>[];
      if (canonicalizeAccountDeletionCheckpoint case final canonicalize?) {
        canonicalCheckpointKeys.addAll(
          <String>[
            accountDeletionCheckpointPreferenceKey,
            accountDeletionFeedbackActivationCheckpointPreferenceKey,
          ].where(store.containsKey),
        );
        if (canonicalCheckpointKeys.isEmpty) {
          throw const FormatException('Missing account deletion checkpoint.');
        }
        for (final checkpointKey in canonicalCheckpointKeys) {
          String canonicalCheckpoint;
          try {
            final raw = store.getValue(checkpointKey);
            if (raw is! String || raw.isEmpty) {
              throw const FormatException(
                'Missing account deletion checkpoint.',
              );
            }
            canonicalCheckpoint = canonicalize(raw);
            if (canonicalCheckpoint.isEmpty) {
              throw const FormatException('Empty account deletion checkpoint.');
            }
          } catch (error, stackTrace) {
            try {
              await _removeValueStrict(store, checkpointKey);
            } catch (removalError) {
              throw PreferenceResetException(
                failedKeys: <String>[checkpointKey],
                causes: <Object>[error, removalError],
              );
            }
            Error.throwWithStackTrace(error, stackTrace);
          }
          await _writeValueStrict(store, checkpointKey, canonicalCheckpoint);
        }
      }
      final keys =
          {...store.getKeys(), ..._unknownStrictKeys}
              .where(
                (key) =>
                    key.startsWith('kl_') &&
                    !_durableAccountJournalPreferenceKeys.contains(key),
              )
              .toList()
            ..sort();

      try {
        for (final key in keys) {
          try {
            await _removeValueStrict(store, key);
          } catch (error) {
            failedKeys.add(key);
            causes.add(error);
          }
        }
      } finally {
        resetCachesAfterExternalWrite();
      }

      if (failedKeys.isNotEmpty) {
        throw PreferenceResetException(
          failedKeys: List.unmodifiable(failedKeys),
          causes: List.unmodifiable(causes),
        );
      }
    });
  }

  /// Drain admitted reward/SRS/vocabulary writes before deletion and reject new admissions.
  /// This prevents a delayed native completion from restoring erased progress.
  static Future<void> _withLearningReset(Future<void> Function() reset) {
    if (_learningResetCount > 0) {
      return Future<void>.error(
        StateError('A learning-data reset is already in progress.'),
      );
    }
    final generation = _xpRewardMutationGeneration;
    _learningResetCount = 1;
    PrivacyChoiceStorage.retire(close: true);
    _invalidateSrsAttempts();
    late final Future<void> operation;
    operation = () async {
      try {
        await Future.wait([
          if (_dataMigrationMutation case final migration?) migration,
          PrivacyChoiceStorage.drain(),
          if (_packProgressMutationCount > 0) _packProgressMutation,
          if (PackCompletionStorage.hasNativeWrites)
            PackCompletionStorage.drainNative(),
          if (_xpRewardMutationCount > 0) _xpRewardMutation,
          if (_srsReviewMutationCount > 0) _srsReviewMutation,
          if (_vocabProgressMutationCount > 0) _vocabProgressMutation,
          if (_grammarPlanMutationCount > 0 && _grammarPlanMutation != null)
            _grammarPlanMutation!,
          if (_confirmedChoiceMutationCount > 0)
            ..._confirmedChoiceMutations.values,
          if (_catalogHistoryMutationCount > 0) _catalogHistoryMutation,
        ]);
        _catalogHistoryResetting++;
        try {
          await reset();
        } finally {
          _catalogHistoryResetting--;
          catalogHistoryChanges.value++;
        }
      } finally {
        if (generation == _xpRewardMutationGeneration) {
          _learningResetCount = 0;
          // Session-only resets and failed deletion also release their privacy
          // fence through fresh local authority, never the retired callback.
          PrivacyChoiceStorage.retire();
          unawaited(PrivacyChoiceStorage.refresh());
        }
        if (identical(operation, _learningResetMutation)) {
          _learningResetMutation = null;
        }
      }
    }();
    _learningResetMutation = operation;
    return operation;
  }

  static PreferenceRemovalStore _preferenceRemovalStore() {
    final preferences = _prefs;
    if (preferences == null) {
      throw StateError('Storage has not been initialized.');
    }
    return _SharedPreferenceRemovalStore(preferences);
  }

  // Destructive owner operations retire replay authority before touching data.
  // Unlike ordinary confirmed reads, reset may discard a malformed journal.
  static Future<void> _retireSrsJournalForReset(
    PreferenceRemovalStore store,
  ) async {
    await store.reload();
    if (store.containsKey(SrsCommitJournal.key)) {
      try {
        await store.remove(SrsCommitJournal.key);
      } on Object catch (error) {
        debugPrint('Storage: reset journal removal reply unavailable: $error');
      }
      await store.reload();
      if (store.containsKey(SrsCommitJournal.key)) {
        throw const SrsRecoveryPendingException();
      }
    }
    _finishSrsRecovery(completed: false);
  }

  static Future<void> _assertDurableAccountResetAllowed(
    PreferenceRemovalStore store, {
    bool allowAccountDeletionCheckpoint = false,
    bool allowJournalPreservingReset = false,
  }) async {
    try {
      await store.reload();
    } catch (_) {
      // A stale preference cache must fail closed rather than risk deleting a
      // journal created immediately before this reset call.
      throw const CloudBackupDeletionResetBlockedException();
    }
    if (allowJournalPreservingReset) {
      // A journal-preserving wipe never removes durable account journals, so
      // deletion-type journals may keep resuming after the local reset. The
      // one exception is an active account switch (pending switch journal or
      // its reconciliation journal): mid-merge the local data IS the
      // reconciliation source, and wiping it could upload emptied state into
      // the target account.
      if (_hasActiveAccountSwitchJournal(store)) {
        throw const CloudBackupDeletionResetBlockedException();
      }
      return;
    }
    final hasBlockingJournal =
        _hasActiveAccountSwitchJournal(store) ||
        store.containsKey(cloudBackupDeletionJournalPreferenceKey) ||
        (!allowAccountDeletionCheckpoint &&
            (store.containsKey(accountDeletionCheckpointPreferenceKey) ||
                store.containsKey(
                  accountDeletionFeedbackActivationCheckpointPreferenceKey,
                )));
    if (hasBlockingJournal) {
      throw const CloudBackupDeletionResetBlockedException();
    }
  }

  static bool _hasActiveAccountSwitchJournal(PreferenceRemovalStore store) =>
      store.containsKey(AccountSwitchJournal.storageKey) ||
      store.containsKey(
        AccountTransitionJournal.switchReconciliationStorageKey,
      );

  static Future<void> resetSession() async {
    await _withLearningReset(() async {
      // Game-Punkte zurücksetzen, Streak/Profil-Daten bleiben.
      await _resolvePendingVocabPreferenceWrite();
      _vocabProgressAttemptEpoch++;
      final reset = VocabProgressAttempt._absolute(
        absoluteCorrect: 0,
        absoluteWrong: 0,
        absoluteSkipped: 0,
        cursor: 0,
        bypassLearningWriteLock: true,
      );
      await _saveVocabProgressAttempt(reset);
      var seenSaved = false;
      await _writeVocabStringList(
        reset,
        _vokSeenIdsKey,
        const <String>[],
        () => seenSaved = true,
      );
      assert(seenSaved);
    });
  }
}
