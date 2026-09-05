import 'dart:convert';

/// A validated server assertion, not a client-side entitlement decision.
///
/// Elapsed cache age must be measured independently of these UTC timestamps.
/// Nothing in this model authorizes server-side AI calls.
class AccessSnapshot {
  const AccessSnapshot._({
    required this.ownerUid,
    required this.environment,
    required this.revision,
    required this.source,
    required this.contentAccess,
    required this.aiPolicyId,
    required this.bookDailyLimit,
    required this.pronunciationDailyLimit,
    required this.serverNow,
    required this.accessUntil,
    required this.offlineUntil,
    required this.nextResetAt,
  });

  factory AccessSnapshot.fromJson(Map<String, dynamic> json) {
    Never invalid() => throw const FormatException('Invalid access snapshot.');
    String string(String key) {
      final value = json[key];
      if (value is! String) {
        invalid();
      }
      return value;
    }

    int integer(String key) {
      final value = json[key];
      if (value is! int || value < 0 || value > 9007199254740991) {
        invalid();
      }
      return value;
    }

    if (json['schemaVersion'] != 1) {
      invalid();
    }
    final uid = string('ownerUid');
    final environment = string('environment');
    final revision = string('revision');
    final source = string('source');
    final content = string('contentAccess');
    final policy = string('aiPolicyId');
    final book = integer('bookDailyLimit');
    final pronunciation = integer('pronunciationDailyLimit');
    final serverNow = integer('serverNow');
    final offlineUntil = integer('offlineUntil');
    final nextReset = integer('nextResetAt');
    final accessUntil = json['accessUntil'] == null
        ? null
        : integer('accessUntil');
    if (uid.isEmpty ||
        utf8.encode(uid).length > 128 ||
        uid == '.' ||
        uid == '..' ||
        RegExp(r'[\x00-\x20\x7f/]').hasMatch(uid) ||
        !const {'PRODUCTION', 'SANDBOX'}.contains(environment) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(revision) ||
        !const {
          'free',
          'free_launch',
          'subscription',
          'closed_tester_lifetime',
        }.contains(source) ||
        nextReset != (serverNow ~/ _dayMillis + 1) * _dayMillis) {
      invalid();
    }

    if (policy != 'premium_v1' ||
        book != 20 ||
        pronunciation != 50 ||
        content != 'all' ||
        offlineUntil < serverNow) {
      invalid();
    }
    if (source == 'subscription') {
      if (accessUntil == null ||
          accessUntil <= serverNow ||
          offlineUntil <= serverNow ||
          offlineUntil > accessUntil ||
          offlineUntil - serverNow > 3 * _dayMillis) {
        invalid();
      }
    } else if (source == 'closed_tester_lifetime') {
      if (accessUntil != null ||
          offlineUntil <= serverNow ||
          offlineUntil - serverNow > 30 * _dayMillis) {
        invalid();
      }
    } else if (accessUntil != null || offlineUntil != serverNow) {
      invalid();
    }
    return AccessSnapshot._(
      ownerUid: uid,
      environment: environment,
      revision: revision,
      source: source,
      contentAccess: content,
      aiPolicyId: policy,
      bookDailyLimit: book,
      pronunciationDailyLimit: pronunciation,
      serverNow: serverNow,
      accessUntil: accessUntil,
      offlineUntil: offlineUntil,
      nextResetAt: nextReset,
    );
  }

  static const _dayMillis = 86400000;
  final String ownerUid;
  final String environment;
  final String revision;
  final String source;
  final String contentAccess;
  final String aiPolicyId;
  final int bookDailyLimit;
  final int pronunciationDailyLimit;
  final int serverNow;
  final int? accessUntil;
  final int offlineUntil;
  final int nextResetAt;

  bool get hasAllContent => contentAccess == 'all';
  bool get hasPremium =>
      source == 'subscription' || source == 'closed_tester_lifetime';

  bool canUseOffline(Duration age) =>
      !age.isNegative && age.inMilliseconds < offlineUntil - serverNow;

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'ownerUid': ownerUid,
    'environment': environment,
    'revision': revision,
    'source': source,
    'contentAccess': contentAccess,
    'aiPolicyId': aiPolicyId,
    'bookDailyLimit': bookDailyLimit,
    'pronunciationDailyLimit': pronunciationDailyLimit,
    'serverNow': serverNow,
    'accessUntil': accessUntil,
    'offlineUntil': offlineUntil,
    'nextResetAt': nextResetAt,
  };
}
