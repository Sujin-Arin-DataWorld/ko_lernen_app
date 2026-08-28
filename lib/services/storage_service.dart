import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'account/account_transition_journal.dart';
import '../models/learner_level.dart';
import '../models/personal_room.dart';
import 'local_data_lifetime.dart';
import 'media_mutation_lock.dart';

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

/// One durable value is both the listening-claim record and the XP authority.
/// A crash can therefore never leave "XP written, claim missing" or the
/// inverse. `kl_xp` remains a best-effort compatibility mirror for old builds.
class _XpRewardLedger {
  const _XpRewardLedger({required this.totalXp, required this.claims});

  static const int schemaVersion = 1;

  final int totalXp;
  final Map<String, _ListeningRewardClaim> claims;

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
    return _XpRewardLedger(
      totalXp: value['totalXp'] as int,
      claims: Map.unmodifiable(claims),
    );
  }

  String encode() {
    final orderedClaims = claims.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      'version': schemaVersion,
      'totalXp': totalXp,
      'listeningClaims': {
        for (final entry in orderedClaims) entry.key: entry.value.toJson(),
      },
    });
  }

  _XpRewardLedger copyWith({
    int? totalXp,
    Map<String, _ListeningRewardClaim>? claims,
  }) => _XpRewardLedger(
    totalXp: totalXp ?? this.totalXp,
    claims: Map.unmodifiable(claims ?? this.claims),
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
  Future<void> reload() => preferences.reload();

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
  Future<void> reload() => preferences.reload();

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
  Future<void> reload() => preferences.reload();

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      preferences.setStringList(key, value);
}

class _SharedPreferenceBoolStore implements PreferenceBoolStore {
  const _SharedPreferenceBoolStore(this.preferences);

  final SharedPreferences preferences;

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  bool? getBool(String key) => preferences.getBool(key);

  @override
  Future<void> reload() => preferences.reload();

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
    AccountTransitionJournal.storageKey,
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

  static SharedPreferences? _prefs;
  static Future<void> _recoveredBookMutation = Future<void>.value();
  static Future<void> _recoveredWordMutation = Future<void>.value();
  static Future<void> _pronunciationProgressMutation = Future<void>.value();
  static Future<void> _xpRewardMutation = Future<void>.value();
  static Future<void> _srsReviewMutation = Future<void>.value();
  static Future<void> _consentedFirstLearningActionClaimMutation =
      Future<void>.value();
  static int _xpRewardMutationCount = 0;
  static int _srsReviewMutationCount = 0;
  static int _srsReviewMutationGeneration = 0;
  // `resetForTesting()` remains synchronous for its many callers, but a new
  // preference boundary must not open while an old SRS transaction can still
  // complete a platform write or its rollback.
  static Future<void> _srsResetDrainBarrier = Future<void>.value();
  static final Set<String> _pendingListeningRewardClaims = <String>{};
  static final Set<String> _unknownStrictKeys = <String>{};
  static String? _courseMasteryCache;
  static int _tutorialResetRevision = 0;
  static PreferenceStringStore? _srsPersistenceStoreForTesting;
  static PreferenceStringListStore? _studyLogStoreForTesting;

  /// In `main()` vor `runApp` aufrufen.
  static Future<void> init() async {
    await _srsResetDrainBarrier;
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Test-only: leert den `_prefs`-Cache, damit ein neuer
  /// `SharedPreferences.setMockInitialValues(...)` plus `Storage.init()`
  /// frische Werte liefert. Im Produktionscode niemals aufrufen.
  @visibleForTesting
  static void resetForTesting() {
    final oldSrsDrain = _srsReviewMutation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _srsResetDrainBarrier = Future.wait<void>([
      _srsResetDrainBarrier,
      oldSrsDrain,
    ]);
    _prefs = null;
    _invalidateSrsCache();
    // 팩 캐시도 함께 버린다. 안 그러면 앞 테스트가 채운 `_packCache` 가
    // 다음 테스트의 `setMockInitialValues` 를 덮어써 "새 Storage" 라는 이 함수의
    // 계약이 깨진다(격리 회귀에서 실제로 잡혔다).
    _invalidatePackCache();
    _recoveredBookMutation = Future<void>.value();
    _recoveredWordMutation = Future<void>.value();
    _pronunciationProgressMutation = Future<void>.value();
    _xpRewardMutation = Future<void>.value();
    _srsReviewMutation = Future<void>.value();
    _consentedFirstLearningActionClaimMutation = Future<void>.value();
    _xpRewardMutationCount = 0;
    _srsReviewMutationCount = 0;
    _srsReviewMutationGeneration++;
    _pendingListeningRewardClaims.clear();
    MediaMutationLock.resetForTesting();
    _unknownStrictKeys.clear();
    _srsPersistenceStoreForTesting = null;
    _studyLogStoreForTesting = null;
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
    _invalidateSrsCache();
    _invalidatePackCache();
    _courseMasteryCache = null;
    _wrongCountCache = null;
    _scenarioStarsCache = null;
    _completedScenariosCache = null;
  }

  // ───────── Generic helpers ─────────
  static int _i(String k) => _prefs?.getInt(k) ?? 0;
  static String _s(String k) => _prefs?.getString(k) ?? '';
  static double _d(String k, [double dflt = 0]) => _prefs?.getDouble(k) ?? dflt;
  static List<String> _l(String k) => _prefs?.getStringList(k) ?? [];

  static Future<void> _si(String k, int v) async => _prefs?.setInt(k, v);
  static Future<void> _ss(String k, String v) async => _prefs?.setString(k, v);

  static Future<T> _enqueueXpRewardMutation<T>(Future<T> Function() mutation) {
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
      (_) => _xpRewardMutationCount--,
      onError: (Object _, StackTrace __) => _xpRewardMutationCount--,
    );
    return result;
  }

  static Future<bool> _enqueueSrsReviewMutation(
    Future<bool> Function(int generation) mutation,
  ) {
    // SRS callers intentionally fire-and-forget in several game screens. As
    // with XP, start the idle queue immediately so their in-memory card is
    // visible at once, while every overlapping review waits for the complete
    // prior decision, rollback, and optional ledger outcome.
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

  static _XpRewardLedger? _readXpRewardLedger({required bool strict}) {
    final raw = _s(listeningRewardLedgerPreferenceKey);
    if (raw.isEmpty) {
      return null;
    }
    try {
      return _XpRewardLedger.decode(raw);
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
    final compatibilityMirror = _i('kl_xp');
    return compatibilityMirror > ledger.totalXp
        ? compatibilityMirror
        : ledger.totalXp;
  }

  static Future<void> _persistXpRewardLedger(_XpRewardLedger ledger) async {
    await _ssStrict(listeningRewardLedgerPreferenceKey, ledger.encode());
    // The ledger above is the commit point. This mirror is only for an older
    // app build that does not understand the ledger yet.
    try {
      await _si('kl_xp', ledger.totalXp);
    } on Object catch (error) {
      debugPrint('Storage: XP compatibility mirror failed: $error');
    }
  }

  static Future<void> _mirrorListeningCompletion(String id) async {
    try {
      await addCompletedScenario(id);
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

  static Future<void> _slStrict(
    String key,
    List<String> value, {
    PreferenceStringListStore? preferences,
    void Function()? assertCurrentWrite,
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceStringListStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = await _prepareStringListMutation(store, key);
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
  }) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceBoolStore(_prefs!));
    if (store == null) {
      throw PreferenceWriteException(key);
    }
    final before = await _prepareBoolMutation(store, key);
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
  static Future<void> _sl(String k, List<String> v) async =>
      _prefs?.setStringList(k, v);

  static bool _b(String k, [bool dflt = false]) => _prefs?.getBool(k) ?? dflt;
  static Future<void> _sb(String k, bool v) async => _prefs?.setBool(k, v);

  // ───────── Premium / Abo (RevenueCat-Cache) ─────────
  // `premiumCached` spiegelt das echte RevenueCat-Entitlement (offline-fähig,
  // bei jedem CustomerInfo-Update aktualisiert). `devPremiumOverride` ist ein
  // lokaler Test-Schalter (Settings → Debug), um Gating + Paywall ohne
  // Dashboard-Setup zu prüfen — verändert NICHT den echten Kaufstatus.
  static bool get premiumCached => _b('kl_premium_cached');
  static Future<void> setPremiumCached(bool v) => _sb('kl_premium_cached', v);

  static bool get devPremiumOverride => _b('kl_premium_dev_override');
  static Future<void> setDevPremiumOverride(bool v) =>
      _sb('kl_premium_dev_override', v);

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
  static int get vokCorrect => _i('kl_vok_correct');
  static int get vokWrong => _i('kl_vok_wrong');
  static int get vokSkipped => _i('kl_vok_skipped');
  static int get vokLastIdx => _i('kl_vok_last_idx');
  static List<String> get vokSeenIds => _l('kl_vok_seen_ids');

  static Future<void> setVokCorrect(int v) => _si('kl_vok_correct', v);
  static Future<void> setVokWrong(int v) => _si('kl_vok_wrong', v);
  static Future<void> setVokSkipped(int v) => _si('kl_vok_skipped', v);
  static Future<void> setVokLastIdx(int v) => _si('kl_vok_last_idx', v);
  static Future<void> addVokSeen(String id) async {
    final list = vokSeenIds;
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_vok_seen_ids', list);
    }
  }

  /// Vokabel-Favoriten — Stern-Markierung für gezieltes Wiederholen.
  static List<String> get vokFavorites => _l('kl_vok_favorites');
  static bool isVokFavorite(String id) => vokFavorites.contains(id);
  static Future<void> toggleVokFavorite(String id) async {
    final list = vokFavorites;
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _sl('kl_vok_favorites', list);
  }

  /// Liked content keys (`kind|id`) — play-later drawer, not the wordbook.
  static List<String> get likedContentKeys => _l('kl_liked_content_v1');
  static bool isLikedContent(String key) => likedContentKeys.contains(key);
  static Future<bool> toggleLikedContent(String key) async {
    final list = likedContentKeys;
    final liked = list.contains(key);
    if (liked) {
      list.remove(key);
    } else {
      list.add(key);
    }
    await _sl('kl_liked_content_v1', list);
    return !liked;
  }

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
  static String get grammarPlanRawJson => _s('kl_gram_plan_v1');
  static Future<void> setGrammarPlanRawJson(String json) =>
      _ss('kl_gram_plan_v1', json);

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

  // ───────── App / Streak ─────────
  static String get lastOpenDate => _s('kl_last_open_date'); // 'YYYY-MM-DD'
  static int get streakDays => _i('kl_streak_days');
  static int get bestStreak => _i('kl_best_streak');
  static Future<void> setLastOpenDate(String value) =>
      _ss('kl_last_open_date', value);
  static Future<void> setStreakDays(int value) => _si('kl_streak_days', value);
  static Future<void> setBestStreak(int value) => _si('kl_best_streak', value);

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

  static const String _pronunciationConsentKey = 'kl_pronunciation_consent_v1';
  static bool get pronunciationConsent =>
      _prefs?.getBool(_pronunciationConsentKey) ?? false;
  static Future<void> setPronunciationConsent(bool value) async =>
      _prefs?.setBool(_pronunciationConsentKey, value);

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
    await _prefs?.remove('kl_reward_claim_v1');
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
      _prefs?.getBool('kl_analytics_consent') ?? false;
  static Future<void> setAnalyticsConsent(bool v) async =>
      _prefs?.setBool('kl_analytics_consent', v);

  /// Opt-in: Absturzberichte (Firebase Crashlytics). Default **false**.
  static bool get crashConsent => _prefs?.getBool('kl_crash_consent') ?? false;
  static Future<void> setCrashConsent(bool v) async =>
      _prefs?.setBool('kl_crash_consent', v);

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
  static int get birthYear => _prefs?.getInt('kl_birth_year') ?? 0;
  static Future<void> setBirthYear(int year) async =>
      _prefs?.setInt('kl_birth_year', year);

  // ───────── SRS (Spaced Repetition, SM-2 vereinfacht) ─────────
  static Map<String, SrsCard>? _srsCache;

  /// 손상된 `kl_srs_v1` 원본을 옮겨 두는 격리 키.
  ///
  /// 앱은 이 값을 읽지 않는다. 사용자가 직접 손댈 수 없는 학습 이력이므로,
  /// 지우는 대신 남겨 두고 [srsQuarantinedRawJson] 으로 진단·복구에 쓴다.
  static const String srsQuarantinePreferenceKey = 'kl_srs_v1_corrupt_v1';

  /// 이번 실행에서 `kl_srs_v1` 파싱이 실패했는지.
  ///
  /// 서 있는 동안 [_persistSrs] 는 원본을 덮어쓰지 않는다.
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
  ///   그 뒤 [_persistSrs] 는 write 를 건너뛴다(fail-closed).
  /// - **부분 손상**(일부 항목만 깨짐) → 유효한 항목은 보존하고 깨진 항목만
  ///   버린다. `roomPlacement` 정규화와 같은 정책이며, 이 경우는 정상 write 를
  ///   허용해 남은 덱이 계속 갱신되게 한다.
  static Map<String, SrsCard> _loadSrs() {
    if (_srsCache != null) return _srsCache!;
    _srsDroppedEntries = 0;
    final raw = _s('kl_srs_v1');
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

  /// 격리를 해제하고 SRS 덱을 빈 상태로 다시 시작한다.
  ///
  /// 사용자가 "복구 불가, 새로 시작"을 **명시적으로** 선택했을 때만 호출한다.
  /// 격리본은 남겨 둔다.
  static Future<void> resetQuarantinedSrs() async {
    _srsQuarantined = false;
    _srsDroppedEntries = 0;
    _srsCache = {};
    await _ss('kl_srs_v1', jsonEncode(const <String, dynamic>{}));
  }

  static Future<bool> _persistSrs({required int generation}) async {
    if (_learningWritesLockReason != null) {
      debugPrint(
        'Storage: 학습 쓰기 잠금($_learningWritesLockReason) — kl_srs_v1 쓰기를 건너뛴다',
      );
      return false;
    }
    if (_srsQuarantined) {
      // 손상된 원본 위에 빈/부분 덱을 쓰면 복구 가능성이 사라진다.
      debugPrint('Storage: SRS 격리 상태 — kl_srs_v1 쓰기를 건너뛴다');
      return false;
    }
    if (_prefs == null) {
      return false;
    }
    final store =
        _srsPersistenceStoreForTesting ?? _SharedPreferenceStringStore(_prefs!);
    final json =
        _srsCache?.map((k, v) => MapEntry(k, v.toJson())) ??
        const <String, dynamic>{};
    final encoded = jsonEncode(json);
    final before = await _prepareStringMutation(store, 'kl_srs_v1');
    await _ssStrict(
      'kl_srs_v1',
      encoded,
      preferences: store,
      beforeState: before,
      // Check at the last synchronous point before issuing the platform
      // setter. A reset that happens earlier therefore has no write to undo.
      assertCurrentWrite: () {
        if (generation != _srsReviewMutationGeneration) {
          throw StateError('stale SRS generation before primary write');
        }
      },
    );
    if (generation != _srsReviewMutationGeneration) {
      await _restoreStaleSrsPrimaryWrite(
        store: store,
        before: before,
        attemptedJson: encoded,
      );
      return false;
    }
    return true;
  }

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
  static String get srsRawJson => _s('kl_srs_v1');

  /// SRS-Deck als Roh-JSON setzen (CloudSync-Restore) + Cache invalidieren,
  /// damit der nächste [_loadSrs] neu parst.
  static Future<void> setSrsRawJson(String json) async {
    await _ss('kl_srs_v1', json);
    _invalidateSrsCache();
  }

  static Future<void> setSrsRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
  }) async {
    await _ssStrict('kl_srs_v1', json, preferences: preferences);
    _invalidateSrsCache();
  }

  static const int _studyLogMaxIdsPerDay = 500;
  static const int _studyLogRetentionDays = 60;
  static const String _studyLogPrefix = 'kl_study_log_v1_';
  static final RegExp _studyLogDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String _studyLogKey(String dateIso) => '$_studyLogPrefix$dateIso';

  /// 명시적으로 판정한 해당 날짜의 SRS id 목록이다.
  static List<String> studyLogIdsFor(String dateIso) {
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

  static Future<bool> _appendStudyLogEntry(
    String id, {
    required String dateIso,
    required int generation,
  }) async {
    if (_learningWritesLockReason != null) {
      return false;
    }
    late final List<String> ids;
    try {
      ids = _l(_studyLogKey(dateIso));
    } on Object catch (error) {
      debugPrint('Storage: malformed study-log entry for $dateIso: $error');
      return false;
    }
    if (ids.contains(id)) {
      return true;
    }
    if (ids.length >= _studyLogMaxIdsPerDay) {
      return false;
    }
    ids.add(id);
    final key = _studyLogKey(dateIso);
    final store =
        _studyLogStoreForTesting ??
        (_prefs == null ? null : _SharedPreferenceStringListStore(_prefs!));
    if (store == null) {
      return false;
    }
    late final _StringListPreferenceState before;
    try {
      before = _StringListPreferenceState.read(store, key);
      await _slStrict(
        key,
        ids,
        preferences: store,
        assertCurrentWrite: () {
          if (generation != _srsReviewMutationGeneration) {
            throw StateError('stale SRS generation before study-log write');
          }
        },
      );
      if (generation != _srsReviewMutationGeneration) {
        await _restoreStaleStudyLogWrite(
          store: store,
          key: key,
          before: before,
          attemptedIds: ids,
        );
        return false;
      }
      return true;
    } on Object catch (error) {
      debugPrint('Storage: study-log persistence incomplete for $id: $error');
      return false;
    }
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
  ) async {
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
  }

  /// The reset drain barrier prevents a new preference boundary from opening
  /// while this conditional rollback settles.
  static Future<void> _restoreStaleStudyLogWrite({
    required PreferenceStringListStore store,
    required String key,
    required _StringListPreferenceState before,
    required List<String> attemptedIds,
  }) async {
    try {
      await store.reload();
      final after = _StringListPreferenceState.read(store, key);
      if (!after.isPresent ||
          !_preferenceValueEquals(after.value, attemptedIds)) {
        return;
      }
      if (before.isPresent) {
        await _slStrict(key, before.value!, preferences: store);
      } else {
        final removed = await store.remove(key);
        if (!removed) {
          await store.reload();
          if (_StringListPreferenceState.read(store, key).isPresent) {
            throw PreferenceWriteException(key);
          }
        }
      }
    } on Object catch (error) {
      debugPrint('Storage: stale study-log repair skipped: $error');
    }
  }

  @visibleForTesting
  static void setSrsPersistenceStoreForTesting(PreferenceStringStore? store) {
    _srsPersistenceStoreForTesting = store;
  }

  @visibleForTesting
  static void setStudyLogStoreForTesting(PreferenceStringListStore? store) {
    _studyLogStoreForTesting = store;
  }

  /// [keepDays]보다 오래된 일별 원장 키를 지운다.
  ///
  /// 시간대가 아니라 달력 날짜로만 비교하므로 정확히 [keepDays]일 전 기록은
  /// 보존된다. 앱 시작과 원장 달력 진입 시 호출한다.
  static Future<void> pruneStudyLog({
    int keepDays = _studyLogRetentionDays,
  }) async {
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
  /// Liefert nur dann `true`, wenn die SRS-Änderung dauerhaft geschrieben und
  /// der optionale Tages-Eintrag verarbeitet wurde. SRS und Tages-Log liegen
  /// in getrennten Preference-Keys und können daher nicht atomar committed
  /// werden: Ist SRS erfolgreich, der Hilfs-Log aber nicht, bleibt SRS bewusst
  /// erhalten und die Methode meldet `false`. Ein späteres gleiches Urteil
  /// repariert den fehlenden deduplizierten Tages-Eintrag. Bestehende
  /// fire-and-forget-Aufrufer erhalten dabei keine neue async Exception.
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
  }) => _enqueueSrsReviewMutation(
    (generation) => _srsReviewTransaction(
      id,
      gotIt: gotIt,
      recordToStudyLog: recordToStudyLog,
      generation: generation,
    ),
  );

  static Future<bool> _srsReviewTransaction(
    String id, {
    required bool gotIt,
    required bool recordToStudyLog,
    required int generation,
  }) async {
    if (generation != _srsReviewMutationGeneration) {
      return false;
    }
    final map = _loadSrs();
    final hadPreviousCard = map.containsKey(id);
    final previousCard = map[id];
    final old =
        map[id] ??
        const SrsCard(
          ease: 2.5,
          intervalDays: 0,
          nextReviewIso: '',
          reviewCount: 0,
        );
    final now = DateTime.now();
    final judgmentDate = _today(now);

    final SrsCard updated;
    if (gotIt) {
      final newInterval = old.intervalDays == 0
          ? 1
          : old.intervalDays == 1
          ? 3
          : (old.intervalDays * old.ease).round().clamp(1, 365);
      updated = SrsCard(
        ease: (old.ease + 0.05).clamp(1.3, 3.5),
        intervalDays: newInterval,
        nextReviewIso: _isoOf(now.add(Duration(days: newInterval))),
        reviewCount: old.reviewCount + 1,
      );
    } else {
      updated = SrsCard(
        ease: (old.ease - 0.2).clamp(1.3, 3.5),
        intervalDays: 1,
        nextReviewIso: _isoOf(now.add(const Duration(days: 1))),
        reviewCount: old.reviewCount + 1,
      );
    }
    map[id] = updated;
    bool persisted;
    try {
      persisted = await _persistSrs(generation: generation);
    } on Object catch (error) {
      _restoreSrsCacheEntry(
        map,
        id,
        hadPreviousCard: hadPreviousCard,
        previousCard: previousCard,
      );
      debugPrint('Storage: SRS persistence incomplete for $id: $error');
      return false;
    }
    if (generation != _srsReviewMutationGeneration) {
      return false;
    }
    if (!persisted) {
      _restoreSrsCacheEntry(
        map,
        id,
        hadPreviousCard: hadPreviousCard,
        previousCard: previousCard,
      );
      return false;
    }
    if (!recordToStudyLog) {
      return true;
    }
    final ledgerRecorded = await _appendStudyLogEntry(
      id,
      dateIso: judgmentDate,
      generation: generation,
    );
    if (generation != _srsReviewMutationGeneration) {
      return false;
    }
    if (!ledgerRecorded) {
      // Der SRS-Write ist die primäre Autorität. Da das tägliche Log in einem
      // separaten Key liegt, ist hier kein atomarer Rollback möglich; wir
      // melden den unvollständigen Hilfs-Write ohne fire-and-forget-Aufrufer
      // mit einer neuen Exception zu belasten.
      debugPrint('Storage: study-log result incomplete for $id');
      return false;
    }
    return true;
  }

  /// Stellt die vor dem versuchten Urteil unveränderliche Kartenreferenz
  /// wieder her. [SrsCard] ist immutable; daher genügt der Snapshot ohne Kopie.
  static void _restoreSrsCacheEntry(
    Map<String, SrsCard> map,
    String id, {
    required bool hadPreviousCard,
    required SrsCard? previousCard,
  }) {
    if (hadPreviousCard) {
      map[id] = previousCard!;
    } else {
      map.remove(id);
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

  static Map<String, int> _loadWrongCounts() {
    if (_wrongCountCache != null) return _wrongCountCache!;
    final raw = _s('kl_wrong_count_v1');
    if (raw.isEmpty) return _wrongCountCache = {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _wrongCountCache = {};
      final out = <String, int>{};
      decoded.forEach((k, v) {
        if (v is int && v > 0) {
          out[k] = v;
        }
      });
      return _wrongCountCache = out;
    } catch (_) {
      return _wrongCountCache = {};
    }
  }

  static Future<void> _persistWrongCounts() async {
    if (_learningWritesLockReason != null) {
      debugPrint(
        'Storage: 학습 쓰기 잠금($_learningWritesLockReason) — kl_wrong_count_v1 쓰기를 건너뛴다',
      );
      return;
    }
    await _ss(
      'kl_wrong_count_v1',
      jsonEncode(_wrongCountCache ?? const <String, int>{}),
    );
  }

  /// 누적 실패 횟수 (모든 리트리벌 실패 — 같은 세션 내 반복 실패도 각각 셈).
  static int wrongCountOf(String id) => _loadWrongCounts()[id] ?? 0;

  /// 실패 1회 기록. `srsReview(gotIt: false)` 를 부르는 지점 옆에 병치한다.
  static Future<void> incrementWrongCount(String id) async {
    final map = _loadWrongCounts();
    map[id] = (map[id] ?? 0) + 1;
    await _persistWrongCounts();
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
  static String get wrongCountRawJson => _s('kl_wrong_count_v1');

  /// Roh-JSON setzen (CloudSync-Restore) + Cache invalidieren.
  static Future<void> setWrongCountRawJson(String json) async {
    await _ss('kl_wrong_count_v1', json);
    _wrongCountCache = null;
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
  static const String hanokStatePreferenceKey = 'kl_hanok_state_v1';
  static const String hanokCutoverPreferenceKey = 'kl_hanok_cutover_v2';

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

  /// Canonical v2 JSON owned by [CourseMasteryService]. Storage does not parse
  /// it so the service can reject malformed or catalog-incompatible evidence.
  static String get courseMasterySnapshotRawJson =>
      _courseMasteryCache ?? _s(courseMasterySnapshotPreferenceKey);

  /// Retained as a read-only migration source. No production code writes it.
  static String get legacyCourseMasteryRawJson =>
      _s(legacyCourseMasteryPreferenceKey);

  /// Compatibility alias for callers that previously read the single snapshot
  /// value. It now returns only the canonical v2 state.
  static String get courseMasteryRawJson => courseMasterySnapshotRawJson;

  /// Presentation-only Living Hanok V1 state.
  ///
  /// Earned grants are intentionally not stored here. They are projected from
  /// canonical productive CourseMastery evidence by the Hanok domain service.
  static String get hanokStateRawJson => _s(hanokStatePreferenceKey);

  static String get hanokCutoverRawValue => _s(hanokCutoverPreferenceKey);

  static Future<void> setHanokStateRawJsonStrict(
    String json, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
  }) => _ssStrict(
    hanokStatePreferenceKey,
    json,
    preferences: preferences,
    assertCurrentWrite: assertCurrentWrite,
  );

  static Future<void> setHanokCutoverRawValueStrict(
    String value, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
  }) => _ssStrict(
    hanokCutoverPreferenceKey,
    value,
    preferences: preferences,
    assertCurrentWrite: assertCurrentWrite,
  );

  /// Removes only presentation ledgers superseded by Living Hanok V1.
  /// Room-v3 layouts, owned decorations, Gye, CourseMastery, SRS, and stamps
  /// deliberately remain untouched.
  static Future<void> clearLegacyHanokPresentationState() async {
    final preferences = _prefs;
    if (preferences == null) {
      throw PreferenceWriteException(hanokStatePreferenceKey);
    }
    final store = _SharedPreferenceRemovalStore(preferences);
    await _removeValueStrict(store, 'kl_hanok_stages_seen_v1');
    await _removeValueStrict(store, _personalHanokMilestonesSeenKey);
  }

  static Future<void> setPlacementLevelCode(String code) async {
    final normalized = _requiredLearnerLevelCode(code);
    await _ss(placementLevelPreferenceKey, normalized);
    // Compatibility mirror only. Browse-level writes must not do this.
    await setUserLevelCode(normalized);
  }

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
  }) async {
    // The cache changes only after strict storage confirms the requested value.
    await _ssStrict(
      courseMasterySnapshotPreferenceKey,
      json,
      preferences: preferences,
      assertCurrentWrite: assertCurrentWrite,
    );
    _courseMasteryCache = json;
  }

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
  }) async {
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
        attempted.isEmpty ? courseMasterySnapshotPreferenceKey : attempted.last,
        cause: <Object>[primaryFailure, ...rollbackFailures],
      );
    }
    Error.throwWithStackTrace(primaryFailure, primaryStack);
  }

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
    return _enqueueXpRewardMutation(() async {
      final ledger = _readXpRewardLedger(strict: true);
      if (ledger == null) {
        await _si('kl_xp', value);
        return;
      }
      await _persistXpRewardLedger(ledger.copyWith(totalXp: value));
    });
  }

  static Future<void> addXp(int amount) {
    return _enqueueXpRewardMutation(() async {
      final ledger = _readXpRewardLedger(strict: true);
      if (ledger == null) {
        final updated = _i('kl_xp') + amount;
        if (updated < 0) {
          throw ArgumentError.value(amount, 'amount', 'XP cannot be negative.');
        }
        await _si('kl_xp', updated);
      } else {
        final updated = _effectiveXpTotal(ledger) + amount;
        if (updated < 0) {
          throw ArgumentError.value(amount, 'amount', 'XP cannot be negative.');
        }
        await _persistXpRewardLedger(ledger.copyWith(totalXp: updated));
      }
      await _bumpXpToday(amount);
    });
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

  // ───────── Tagesziel (일일 목표 진행 — 리텐션 모멘텀) ─────────
  /// 오늘 획득한 XP(자정 리셋). 저장 날짜가 오늘이 아니면 0.
  static int get xpToday {
    final today = _isoOf(DateTime.now());
    final ordinaryXp = xpTodayValue(
      _s('kl_xp_today_date'),
      _i('kl_xp_today_raw'),
      today,
    );
    final listeningXp = _readXpRewardLedger(strict: false)?.claims.values
        .where((claim) => claim.earnedOn == today)
        .fold<int>(0, (total, claim) => total + claim.earnedXp);
    return ordinaryXp + (listeningXp ?? 0);
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

  static Future<void> _bumpXpToday(int amount) async {
    final today = _isoOf(DateTime.now());
    if (_s('kl_xp_today_date') != today) {
      await _ss('kl_xp_today_date', today);
      await _si('kl_xp_today_raw', amount);
    } else {
      await _si('kl_xp_today_raw', _i('kl_xp_today_raw') + amount);
    }
  }

  // ── Persönliche Bestleistung pro Spiel (Highscore) ──────────────────
  // Eine JSON-Map gameId -> best (int). Selbst-Wettbewerb, KEINE Ranglisten.
  static Map<String, int> get _gameBests {
    final raw = _s('kl_game_best');
    if (raw.isEmpty) {
      return {};
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
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
  }) async {
    final map = _gameBests;
    final cur = map[id];
    final better = cur == null || (higherIsBetter ? value > cur : value < cur);
    if (!better) {
      return false;
    }
    map[id] = value;
    await _ss('kl_game_best', jsonEncode(map));
    return true;
  }

  // ── Tages-Challenge (오늘의 도전) — täglicher Selbst-Streak ──────────
  // Datums-Seed-Puzzle (alle Nutzer:innen bekommen dasselbe Tagesset).
  // Selbst-Wettbewerb (Streak), KEINE Rangliste.
  static String get dailyChallengeLastDone => _s('kl_daily_last');
  static int get dailyChallengeStreak => _i('kl_daily_streak');

  static bool dailyChallengeDoneToday({DateTime? now}) =>
      dailyChallengeLastDone == _isoOf(now ?? DateTime.now());

  /// Markiert die heutige Tages-Challenge als erledigt und pflegt den
  /// Selbst-Streak: gestern erledigt → +1, sonst Reset auf 1; heute schon
  /// erledigt → no-op (kein Doppel-Bonus).
  static Future<void> markDailyChallengeDone({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final today = _isoOf(n);
    if (dailyChallengeLastDone == today) {
      return;
    }
    final yesterday = _isoOf(n.subtract(const Duration(days: 1)));
    final newStreak = dailyChallengeLastDone == yesterday
        ? dailyChallengeStreak + 1
        : 1;
    await _ss('kl_daily_last', today);
    await _si('kl_daily_streak', newStreak);
  }

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

  static Future<void> setScenarioStars(String id, int stars) async {
    final current = scenarioStars;
    final alreadyRecorded = current.containsKey(id);
    // 0성 최초 완료도 반드시 기록돼야 한다 — 완료 여부(=키 존재) 자체가
    // 코스 체크포인트 "0/2→1/2" 판정의 입력이다(지시서 4.15). 이후 재도전은
    // 여전히 단조 증가만 허용(더 낮은 점수로 덮어쓰지 않음).
    if (!alreadyRecorded || (current[id] ?? 0) < stars) {
      final updated = Map<String, int>.of(current)..[id] = stars;
      _scenarioStarsCache = Map<String, int>.unmodifiable(updated);
      await _ss('kl_scenario_stars', jsonEncode(updated));
    }
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
    final completed = _l('kl_completed_scenarios');
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

  static Future<void> addCompletedScenario(String id) async {
    final list = _l('kl_completed_scenarios');
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_completed_scenarios', list);
      _completedScenariosCache = null;
    }
  }

  static List<String> get earnedBadges => _l('kl_earned_badges');
  static Future<void> earnBadge(String id) async {
    final list = earnedBadges;
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_earned_badges', list);
    }
  }

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
  /// 정책은 SRS 와 동일하다 — 전체 손상은 격리 후 write 잠금, 부분 손상은
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
  /// ⚠️ **범위**: SRS 덱(`kl_srs_v1`)과 단어팩 진행도(`kl_pack_progress_v1`) 두
  /// blob 만 막는다. 스트릭·XP 같은 스칼라 키와 클라우드 복원(`*Strict`) 경로는
  /// 막지 않는다 — 복원은 원본을 통째로 교체하므로 오히려 회복 수단이다.
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
  ) async {
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
  }

  /// Mehrere Packs gleichzeitig schreiben (Migration / Cloud-restore).
  static Future<void> setManyPackProgressJson(
    Map<String, Map<String, dynamic>> entries,
  ) async {
    // 위와 같은 이유로 먼저 로드한다.
    _loadPackJson();
    final cache = _packCache ?? <String, dynamic>{};
    cache.addAll(entries);
    _packCache = cache;
    if (_packWritesBlocked()) {
      return;
    }
    await _ss(_packProgressKey, jsonEncode(cache));
  }

  static Future<void> setAllPackProgressJsonStrict(
    Map<String, Map<String, dynamic>> entries, {
    PreferenceStringStore? preferences,
  }) async {
    final encoded = jsonEncode(entries);
    await _ssStrict(_packProgressKey, encoded, preferences: preferences);
    // 원본을 통째로 교체하는 복원 경로다 — 손상 격리를 여기서 해제한다.
    _packQuarantined = false;
    _packCache = {
      for (final entry in entries.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    };
  }

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
  static int get kkeunmariWins => _i('kl_kkeunmari_wins');
  static Future<void> incKkeunmariWins() =>
      _si('kl_kkeunmari_wins', kkeunmariWins + 1);

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

  static List<String> get seenHanokStages => _l('kl_hanok_stages_seen_v1');

  static bool hasSeenHanokStage(String stageName) =>
      seenHanokStages.contains(stageName);

  static Future<void> markHanokStageSeen(String stageName) async {
    final list = seenHanokStages;
    if (list.contains(stageName)) return;
    list.add(stageName);
    await _sl('kl_hanok_stages_seen_v1', list);
  }

  // ── Personal Hanok map construction-reveal ledger ──────────────────────
  //
  // This is deliberately a local UX ledger, never a learning-progress or
  // reward source. A missing key is meaningful: the first map visit quietly
  // baselines existing construction so an upgraded learner is not shown a
  // backlog of historic building animations.
  static const String _personalHanokMilestonesSeenKey =
      'kl_personal_hanok_milestones_seen_v1';

  static ({bool isInitialized, List<String> seen})
  get personalHanokMilestoneRevealSnapshot => (
    isInitialized:
        _prefs?.containsKey(_personalHanokMilestonesSeenKey) ?? false,
    seen: _l(_personalHanokMilestonesSeenKey),
  );

  static Future<void> initializePersonalHanokMilestoneReveals(
    Iterable<String> milestones,
  ) async {
    if (_prefs?.containsKey(_personalHanokMilestonesSeenKey) ?? false) {
      return;
    }
    final seen = <String>[];
    for (final milestone in milestones) {
      if (!seen.contains(milestone)) {
        seen.add(milestone);
      }
    }
    await _sl(_personalHanokMilestonesSeenKey, seen);
  }

  static Future<void> markPersonalHanokMilestoneRevealSeen(
    String milestone,
  ) async {
    final snapshot = personalHanokMilestoneRevealSnapshot;
    final seen = List<String>.from(snapshot.seen);
    if (seen.contains(milestone)) {
      return;
    }
    seen.add(milestone);
    await _sl(_personalHanokMilestonesSeenKey, seen);
  }

  // ───────── Reset ─────────
  static Future<void> resetAll({PreferenceRemovalStore? preferences}) async {
    final store =
        preferences ??
        (_prefs == null ? null : _SharedPreferenceRemovalStore(_prefs!));
    if (store == null) return;
    await _assertDurableAccountResetAllowed(
      store,
      allowJournalPreservingReset: true,
    );
    // Invalidate admitted remote restores before the first deletion. A late
    // remote response must belong to the old data lifetime and fail closed.
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
    await _assertDurableAccountResetAllowed(
      store,
      allowAccountDeletionCheckpoint:
          canonicalizeAccountDeletionCheckpoint != null,
    );
    // This is deliberately synchronous and precedes checkpoint
    // canonicalization as well as preference removal. Even a partially
    // failing strict reset must never leave an old restore lease writable.
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
            throw const FormatException('Missing account deletion checkpoint.');
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
  }

  static PreferenceRemovalStore _preferenceRemovalStore() {
    final preferences = _prefs;
    if (preferences == null) {
      throw StateError('Storage has not been initialized.');
    }
    return _SharedPreferenceRemovalStore(preferences);
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
      // one exception is an active replacement transition: mid-merge the
      // local data IS the reconciliation source, and wiping it could upload
      // emptied state into the target account.
      if (store.containsKey(AccountTransitionJournal.storageKey)) {
        throw const CloudBackupDeletionResetBlockedException();
      }
      return;
    }
    final hasBlockingJournal =
        store.containsKey(AccountTransitionJournal.storageKey) ||
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

  static Future<void> resetSession() async {
    // Game-Punkte zurücksetzen, Streak/Profil-Daten bleiben
    await _si('kl_vok_correct', 0);
    await _si('kl_vok_wrong', 0);
    await _si('kl_vok_skipped', 0);
    await _si('kl_vok_last_idx', 0);
    await _sl('kl_vok_seen_ids', []);
  }
}
