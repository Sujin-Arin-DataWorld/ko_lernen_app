import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/content_feedback.dart';
import 'content_feedback_client.dart';

const int feedbackOutboxMaxItems = 20;
const int feedbackOutboxMaxAttemptCount = 1000000;

enum FeedbackOutboxLocalStatus { pending, blocked }

class ContentFeedbackRetryMetadata {
  const ContentFeedbackRetryMetadata({
    required this.attemptCount,
    this.lastFailure,
  });

  final int attemptCount;
  final ContentFeedbackFailureCategory? lastFailure;

  Map<String, Object?> toJson() => {
    'attemptCount': attemptCount,
    'lastFailure': lastFailure?.name,
  };
}

class ContentFeedbackOutboxItem {
  const ContentFeedbackOutboxItem._({
    required this.submission,
    required this.createdAt,
    required this.ownerUid,
    required this.retry,
    required this.status,
  });

  factory ContentFeedbackOutboxItem.pending({
    required ContentFeedbackSubmission submission,
    required DateTime createdAt,
    required String ownerUid,
  }) {
    final item = ContentFeedbackOutboxItem._(
      submission: submission,
      createdAt: createdAt.toUtc(),
      ownerUid: ownerUid,
      retry: const ContentFeedbackRetryMetadata(attemptCount: 0),
      status: FeedbackOutboxLocalStatus.pending,
    );
    item._validate();
    return item;
  }

  factory ContentFeedbackOutboxItem.fromJson(Map<String, Object?> json) {
    _requireExactKeys(json, const {
      'payload',
      'createdAt',
      'ownerUid',
      'retry',
      'status',
    });
    final rawPayload = _stringKeyedMap(json['payload']);
    final rawRetry = _stringKeyedMap(json['retry']);
    _requireExactKeys(rawRetry, const {'attemptCount', 'lastFailure'});

    final attemptCount = rawRetry['attemptCount'];
    if (attemptCount is! int) throw const FormatException();
    final rawFailure = rawRetry['lastFailure'];
    final lastFailure = rawFailure == null
        ? null
        : _enumByName(ContentFeedbackFailureCategory.values, rawFailure);
    final rawStatus = json['status'];
    final status = _enumByName(FeedbackOutboxLocalStatus.values, rawStatus);
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is! String) throw const FormatException();
    final createdAt = DateTime.tryParse(rawCreatedAt);
    if (createdAt == null || !createdAt.isUtc) throw const FormatException();

    final item = ContentFeedbackOutboxItem._(
      submission: _submissionFromWire(rawPayload),
      createdAt: createdAt,
      ownerUid: _requiredString(json['ownerUid']),
      retry: ContentFeedbackRetryMetadata(
        attemptCount: attemptCount,
        lastFailure: lastFailure,
      ),
      status: status,
    );
    item._validate();
    return item;
  }

  final ContentFeedbackSubmission submission;
  final DateTime createdAt;
  final String ownerUid;
  final ContentFeedbackRetryMetadata retry;
  final FeedbackOutboxLocalStatus status;

  ContentFeedbackOutboxItem recordAttempt() => _copyWith(
    retry: ContentFeedbackRetryMetadata(
      attemptCount: retry.attemptCount < feedbackOutboxMaxAttemptCount
          ? retry.attemptCount + 1
          : feedbackOutboxMaxAttemptCount,
      lastFailure: retry.lastFailure,
    ),
    status: FeedbackOutboxLocalStatus.pending,
  );

  ContentFeedbackOutboxItem recordFailure(
    ContentFeedbackClientFailure failure,
  ) => _copyWith(
    retry: ContentFeedbackRetryMetadata(
      attemptCount: retry.attemptCount,
      lastFailure: failure.category,
    ),
    status: failure.retryable
        ? FeedbackOutboxLocalStatus.pending
        : FeedbackOutboxLocalStatus.blocked,
  );

  Map<String, Object?> toJson() {
    _validate();
    return {
      'payload': submission.toWire(),
      'createdAt': createdAt.toIso8601String(),
      'ownerUid': ownerUid,
      'retry': retry.toJson(),
      'status': status.name,
    };
  }

  ContentFeedbackOutboxItem _copyWith({
    required ContentFeedbackRetryMetadata retry,
    required FeedbackOutboxLocalStatus status,
  }) {
    final item = ContentFeedbackOutboxItem._(
      submission: submission,
      createdAt: createdAt,
      ownerUid: ownerUid,
      retry: retry,
      status: status,
    );
    item._validate();
    return item;
  }

  void _validate() {
    if (!submission.validate().isValid ||
        ownerUid.trim().isEmpty ||
        ownerUid != ownerUid.trim() ||
        ownerUid.length > 128 ||
        !createdAt.isUtc ||
        retry.attemptCount < 0 ||
        retry.attemptCount > feedbackOutboxMaxAttemptCount) {
      throw const FormatException('Invalid feedback outbox item.');
    }
  }
}

abstract interface class FeedbackOutboxStore {
  Future<List<ContentFeedbackOutboxItem>> read();
  Future<void> write(List<ContentFeedbackOutboxItem> items);
  Future<void> clear();
}

abstract interface class FeedbackSecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterFeedbackSecureStorage implements FeedbackSecureStorage {
  FlutterFeedbackSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);
}

class SecureFeedbackOutboxStore implements FeedbackOutboxStore {
  SecureFeedbackOutboxStore({FeedbackSecureStorage? storage})
    : _storage = storage ?? FlutterFeedbackSecureStorage();

  static const String storageKey = 'kl_tester_feedback_outbox_v1';

  final FeedbackSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: storageKey);

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.isEmpty) return const [];

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      await clear();
      return const [];
    }
    if (decoded is! List) {
      await clear();
      return const [];
    }

    final valid = <ContentFeedbackOutboxItem>[];
    final feedbackIds = <String>{};
    var discarded = false;
    for (final rawItem in decoded) {
      if (valid.length == feedbackOutboxMaxItems) {
        discarded = true;
        continue;
      }
      try {
        final item = ContentFeedbackOutboxItem.fromJson(
          _stringKeyedMap(rawItem),
        );
        if (!feedbackIds.add(item.submission.feedbackId)) {
          discarded = true;
          continue;
        }
        valid.add(item);
      } catch (_) {
        discarded = true;
      }
    }
    if (discarded) await write(valid);
    return List.unmodifiable(valid);
  }

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> items) async {
    if (items.length > feedbackOutboxMaxItems) {
      throw StateError('Feedback outbox is full.');
    }
    final ids = <String>{};
    final encoded = <Map<String, Object?>>[];
    for (final item in items) {
      final json = item.toJson();
      if (!ids.add(item.submission.feedbackId)) {
        throw StateError('Feedback outbox contains duplicate IDs.');
      }
      encoded.add(json);
    }
    if (encoded.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(key: storageKey, value: jsonEncode(encoded));
  }
}

ContentFeedbackSubmission _submissionFromWire(Map<String, Object?> wire) {
  _requireExactKeys(
    wire,
    const {
      'schemaVersion',
      'feedbackId',
      'completionId',
      'contentType',
      'contentId',
      'contentLabel',
      'level',
      'scoreSummary',
      'category',
      'message',
      'issueArea',
      'contentSignal',
      'contentFocus',
      'expectedOutcome',
      'actualOutcome',
      'bugFrequency',
      'bugImpact',
      'experienceSignal',
      'experienceFocus',
      'appVersion',
      'platform',
      'locale',
      'betaMissionId',
    },
    optional: const {
      'level',
      'issueArea',
      'contentSignal',
      'contentFocus',
      'expectedOutcome',
      'actualOutcome',
      'bugFrequency',
      'bugImpact',
      'experienceSignal',
      'experienceFocus',
      'betaMissionId',
    },
  );
  if (wire['schemaVersion'] != contentFeedbackSchemaVersion) {
    throw const FormatException();
  }
  final category = _enumByName(FeedbackCategory.values, wire['category']);
  final issueArea = wire.containsKey('issueArea')
      ? _enumByName(FeedbackIssueArea.values, wire['issueArea'])
      : null;
  final contentSignal = wire.containsKey('contentSignal')
      ? _enumByWireName(
          FeedbackContentSignal.values,
          wire['contentSignal'],
          (value) => value.wireName,
        )
      : null;
  final contentFocus = wire.containsKey('contentFocus')
      ? _enumByName(FeedbackContentFocus.values, wire['contentFocus'])
      : null;
  final expectedOutcome = wire.containsKey('expectedOutcome')
      ? _requiredString(wire['expectedOutcome'])
      : null;
  final actualOutcome = wire.containsKey('actualOutcome')
      ? _requiredString(wire['actualOutcome'])
      : null;
  final bugFrequency = wire.containsKey('bugFrequency')
      ? _enumByWireName(
          FeedbackBugFrequency.values,
          wire['bugFrequency'],
          (value) => value.wireName,
        )
      : null;
  final bugImpact = wire.containsKey('bugImpact')
      ? _enumByWireName(
          FeedbackBugImpact.values,
          wire['bugImpact'],
          (value) => value.wireName,
        )
      : null;
  final experienceSignal = wire.containsKey('experienceSignal')
      ? _enumByWireName(
          FeedbackExperienceSignal.values,
          wire['experienceSignal'],
          (value) => value.wireName,
        )
      : null;
  final experienceFocus = wire.containsKey('experienceFocus')
      ? _enumByWireName(
          FeedbackExperienceFocus.values,
          wire['experienceFocus'],
          (value) => value.wireName,
        )
      : null;
  final submission = ContentFeedbackSubmission(
    feedbackId: _requiredString(wire['feedbackId']),
    context: ContentFeedbackContext(
      completionId: _requiredString(wire['completionId']),
      contentType: _requiredString(wire['contentType']),
      contentId: _requiredString(wire['contentId']),
      contentLabel: _requiredString(wire['contentLabel']),
      level: wire.containsKey('level') ? _requiredString(wire['level']) : null,
      scoreSummary: _requiredString(wire['scoreSummary']),
    ),
    draft: ContentFeedbackDraft(
      category: category,
      message: _requiredString(wire['message']),
      issueArea: issueArea,
      contentSignal: contentSignal,
      contentFocus: contentFocus,
      expectedOutcome: expectedOutcome,
      actualOutcome: actualOutcome,
      bugFrequency: bugFrequency,
      bugImpact: bugImpact,
      experienceSignal: experienceSignal,
      experienceFocus: experienceFocus,
    ),
    appVersion: _requiredString(wire['appVersion']),
    platform: _requiredString(wire['platform']),
    locale: _requiredString(wire['locale']),
    betaMissionId: wire.containsKey('betaMissionId')
        ? _requiredString(wire['betaMissionId'])
        : null,
  );
  if (!submission.validate().isValid) throw const FormatException();
  return submission;
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map) throw const FormatException();
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String || result.containsKey(entry.key)) {
      throw const FormatException();
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _requireExactKeys(
  Map<String, Object?> value,
  Set<String> allowed, {
  Set<String> optional = const {},
}) {
  if (value.keys.any((key) => !allowed.contains(key)) ||
      allowed.difference(optional).any((key) => !value.containsKey(key))) {
    throw const FormatException();
  }
}

String _requiredString(Object? value) {
  if (value is! String) throw const FormatException();
  return value;
}

T _enumByName<T extends Enum>(List<T> values, Object? raw) {
  return _enumByWireName(values, raw, (value) => value.name);
}

T _enumByWireName<T>(
  List<T> values,
  Object? raw,
  String Function(T value) wireName,
) {
  if (raw is! String) throw const FormatException();
  for (final value in values) {
    if (wireName(value) == raw) return value;
  }
  throw const FormatException();
}
