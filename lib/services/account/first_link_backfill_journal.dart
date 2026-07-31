import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Write-ahead receipt for data copied immediately after a same-UID anonymous
/// account becomes durable.
///
/// This deliberately remains an ordinary `kl_` preference rather than a
/// protected durable-account journal. A user-requested device reset or
/// completed account-deletion cleanup is an explicit local-data discard, so
/// it intentionally removes this retry receipt. Ordinary process death and
/// app restart do not call either reset path and therefore retain it.
@immutable
class FirstDurableLinkBackfillJournal {
  FirstDurableLinkBackfillJournal({
    required this.uid,
    required this.token,
    required this.bookshelfPending,
    required this.packProgressPending,
  }) {
    _validate();
  }

  FirstDurableLinkBackfillJournal.pending({
    required String uid,
    required String token,
  }) : this(
         uid: uid,
         token: token,
         bookshelfPending: true,
         packProgressPending: true,
       );

  static const currentVersion = 1;
  static const storageKey = 'kl_first_durable_link_backfill_v1';
  static const _keys = <String>{
    'version',
    'uid',
    'token',
    'bookshelfPending',
    'packProgressPending',
  };
  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final RegExp _controlCharacterPattern = RegExp(r'[\x00-\x1F\x7F]');

  final String uid;
  final String token;
  final bool bookshelfPending;
  final bool packProgressPending;

  bool get isComplete => !bookshelfPending && !packProgressPending;

  /// Stable Firestore operation identifier for the bookshelf component.
  ///
  /// It lets an activation retry recognize a generation that reached the
  /// server just before this local receipt update could be persisted.
  String get operationId => 'first-link:$token';

  FirstDurableLinkBackfillJournal markBookshelfCompleted() {
    if (!bookshelfPending) return this;
    return FirstDurableLinkBackfillJournal(
      uid: uid,
      token: token,
      bookshelfPending: false,
      packProgressPending: packProgressPending,
    );
  }

  FirstDurableLinkBackfillJournal markPackProgressCompleted() {
    if (!packProgressPending) return this;
    return FirstDurableLinkBackfillJournal(
      uid: uid,
      token: token,
      bookshelfPending: bookshelfPending,
      packProgressPending: false,
    );
  }

  factory FirstDurableLinkBackfillJournal.fromJson(Map<String, dynamic> json) {
    if (json.length != _keys.length || !json.keys.toSet().containsAll(_keys)) {
      throw const FormatException('Invalid first durable-link receipt.');
    }
    final version = json['version'];
    final uid = json['uid'];
    final token = json['token'];
    final bookshelfPending = json['bookshelfPending'];
    final packProgressPending = json['packProgressPending'];
    if (version != currentVersion ||
        uid is! String ||
        token is! String ||
        bookshelfPending is! bool ||
        packProgressPending is! bool) {
      throw const FormatException('Invalid first durable-link receipt.');
    }
    return FirstDurableLinkBackfillJournal(
      uid: uid,
      token: token,
      bookshelfPending: bookshelfPending,
      packProgressPending: packProgressPending,
    );
  }

  Map<String, Object> toJson() {
    _validate();
    return <String, Object>{
      'version': currentVersion,
      'uid': uid,
      'token': token,
      'bookshelfPending': bookshelfPending,
      'packProgressPending': packProgressPending,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is FirstDurableLinkBackfillJournal &&
        other.uid == uid &&
        other.token == token &&
        other.bookshelfPending == bookshelfPending &&
        other.packProgressPending == packProgressPending;
  }

  @override
  int get hashCode =>
      Object.hash(uid, token, bookshelfPending, packProgressPending);

  void _validate() {
    if (uid.isEmpty ||
        uid.trim() != uid ||
        uid.length > 128 ||
        _controlCharacterPattern.hasMatch(uid) ||
        !_tokenPattern.hasMatch(token)) {
      throw const FormatException('Invalid first durable-link receipt.');
    }
  }
}

abstract interface class FirstDurableLinkBackfillJournalStore {
  Future<FirstDurableLinkBackfillJournal?> read();

  /// Writes [journal] only when no receipt exists already.
  Future<bool> createIfAbsent(FirstDurableLinkBackfillJournal journal);

  /// Replaces the receipt only when it remains exactly [expected].
  Future<bool> replaceIfCurrent({
    required FirstDurableLinkBackfillJournal expected,
    required FirstDurableLinkBackfillJournal next,
  });

  /// Clears the receipt only when it remains exactly [expected].
  Future<bool> clearIfCurrent(FirstDurableLinkBackfillJournal expected);
}

/// SharedPreferences implementation with process-local serialization and
/// read-back checks. The token and both pending flags are compared, so an old
/// completion receipt cannot clear a newer retry record.
class SharedPreferencesFirstDurableLinkBackfillJournalStore
    implements FirstDurableLinkBackfillJournalStore {
  const SharedPreferencesFirstDurableLinkBackfillJournalStore();

  static Future<void> _mutationTail = Future<void>.value();

  @override
  Future<bool> clearIfCurrent(FirstDurableLinkBackfillJournal expected) {
    return _serialized(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = await _readUnlocked(preferences);
      if (current != expected) return false;

      await preferences.remove(FirstDurableLinkBackfillJournal.storageKey);
      await preferences.reload();
      final remaining = preferences.getString(
        FirstDurableLinkBackfillJournal.storageKey,
      );
      return remaining == null;
    });
  }

  @override
  Future<bool> createIfAbsent(FirstDurableLinkBackfillJournal journal) {
    return _serialized(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = await _readUnlocked(preferences);
      if (current != null) return false;
      return _writeAndVerifyUnlocked(preferences, journal);
    });
  }

  @override
  Future<FirstDurableLinkBackfillJournal?> read() {
    return _serialized(() async {
      final preferences = await SharedPreferences.getInstance();
      return _readUnlocked(preferences);
    });
  }

  @override
  Future<bool> replaceIfCurrent({
    required FirstDurableLinkBackfillJournal expected,
    required FirstDurableLinkBackfillJournal next,
  }) {
    return _serialized(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = await _readUnlocked(preferences);
      if (current != expected) return false;
      return _writeAndVerifyUnlocked(preferences, next);
    });
  }

  static Future<FirstDurableLinkBackfillJournal?> _readUnlocked(
    SharedPreferences preferences,
  ) async {
    await preferences.reload();
    final encoded = preferences.getString(
      FirstDurableLinkBackfillJournal.storageKey,
    );
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Invalid first durable-link receipt.');
    }
    return FirstDurableLinkBackfillJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static Future<bool> _writeAndVerifyUnlocked(
    SharedPreferences preferences,
    FirstDurableLinkBackfillJournal expected,
  ) async {
    final written = await preferences.setString(
      FirstDurableLinkBackfillJournal.storageKey,
      jsonEncode(expected.toJson()),
    );
    if (!written) {
      throw StateError('First durable-link receipt was not persisted.');
    }
    final current = await _readUnlocked(preferences);
    return current == expected;
  }

  static Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}
