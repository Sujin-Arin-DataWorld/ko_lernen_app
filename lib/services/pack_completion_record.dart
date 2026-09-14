import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Local terminal obligation only. No learner session or SRS authority is stored.
final class PackCompletionRecord {
  PackCompletionRecord({
    required this.id,
    required this.owner,
    required this.occurredAt,
    required this.earnedOn,
    required this.packId,
    required this.level,
    required this.contentHash,
    required this.quizCorrect,
    required this.quizTotal,
    required this.bossCorrect,
    required this.bossTotal,
    required this.wordCount,
    required this.xp,
    required this.justCleared,
    required this.nextPackId,
    required this.stampMotif,
    required this.courseContext,
    required this.before,
    required this.boss,
    required this.after,
    this.settled = false,
  });

  static const key = 'kl_pack_completion_v1';
  static const ownerKey = 'kl_pack_completion_owner_v1';
  static const maxBytes = 2 * 1024 * 1024;
  static const _recordKeys = <String>{
    'version',
    'policy',
    'id',
    'owner',
    'occurredAt',
    'earnedOn',
    'packId',
    'level',
    'contentHash',
    'quizCorrect',
    'quizTotal',
    'bossCorrect',
    'bossTotal',
    'wordCount',
    'xp',
    'justCleared',
    'nextPackId',
    'stampMotif',
    'courseContext',
    'before',
    'boss',
    'after',
    'settled',
    'digest',
  };
  static const packKey = 'kl_pack_progress_v1';
  static const xpKey = 'kl_xp_reward_ledger_v1';
  static const stampKey = 'kl_stamps_earned';
  static const boxKey = 'kl_reward_boxes';
  static const courseKeys = <String>[
    'kl_placement_level_v1',
    'kl_user_level',
    'kl_course_unit_v1',
    'kl_course_mastery_v2',
  ];
  static const stateKeys = <String>{
    packKey,
    xpKey,
    stampKey,
    boxKey,
    ...courseKeys,
    'kl_xp',
    'kl_xp_today_date',
    'kl_xp_today_raw',
    'kl_reward_claim_v1',
    'kl_course_mastery_v1',
  };
  static const writeOrder = <String>[
    packKey,
    ...courseKeys,
    xpKey,
    stampKey,
    boxKey,
  ];

  final String id, owner, occurredAt, earnedOn, packId, level, contentHash;
  final int quizCorrect, quizTotal, bossCorrect, bossTotal, wordCount, xp;
  final bool justCleared, settled;
  final String? nextPackId;
  final String stampMotif;
  final Map<String, String>? courseContext;
  final Map<String, Object?> before, after;
  final String boss;

  double get bossAccuracy => bossTotal == 0 ? 1 : bossCorrect / bossTotal;

  static String digest(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();

  Map<String, Object?> toJson({bool? settled}) => {
    'version': 1,
    'policy': 1,
    'id': id,
    'owner': owner,
    'occurredAt': occurredAt,
    'earnedOn': earnedOn,
    'packId': packId,
    'level': level,
    'contentHash': contentHash,
    'quizCorrect': quizCorrect,
    'quizTotal': quizTotal,
    'bossCorrect': bossCorrect,
    'bossTotal': bossTotal,
    'wordCount': wordCount,
    'xp': xp,
    'justCleared': justCleared,
    'nextPackId': nextPackId,
    'stampMotif': stampMotif,
    'courseContext': courseContext,
    'before': before,
    'boss': boss,
    'after': after,
    'settled': settled ?? this.settled,
  };

  String encode({bool? settled}) {
    final body = toJson(settled: settled);
    final raw = jsonEncode({...body, 'digest': digest(body)});
    if (utf8.encode(raw).length > maxBytes) {
      throw const FormatException('Pack completion exceeds its local bound.');
    }
    return raw;
  }

  factory PackCompletionRecord.decode(String raw) {
    if (utf8.encode(raw).length > maxBytes) {
      throw const FormatException('Oversized pack completion.');
    }
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data.length != _recordKeys.length ||
        !_recordKeys.containsAll(data.keys) ||
        data['version'] != 1 ||
        data['policy'] != 1) {
      throw const FormatException('Unsupported pack completion.');
    }
    final body = Map<String, dynamic>.of(data)..remove('digest');
    if (data['digest'] != digest(body)) {
      throw const FormatException('Changed pack completion.');
    }
    String text(String name, {int max = 128}) {
      final value = data[name];
      if (value is! String ||
          value.isEmpty ||
          value.trim() != value ||
          utf8.encode(value).length > max) {
        throw FormatException('Invalid pack completion $name.');
      }
      return value;
    }

    int count(String name, int max) {
      final value = data[name];
      if (value is! int || value < 0 || value > max) {
        throw FormatException('Invalid pack completion $name.');
      }
      return value;
    }

    final words = count('wordCount', 256);
    final quizTotal = count('quizTotal', words);
    final bossTotal = count('bossTotal', words);
    final quizCorrect = count('quizCorrect', quizTotal);
    final bossCorrect = count('bossCorrect', bossTotal);
    if (words == 0 ||
        quizTotal + bossTotal != words ||
        data['xp'] != words * 5 + bossCorrect * 10 ||
        data['justCleared'] is! bool ||
        data['settled'] is! bool ||
        (data['nextPackId'] != null && data['nextPackId'] is! String)) {
      throw const FormatException('Invalid pack completion result.');
    }
    final occurred = text('occurredAt');
    final date = text('earnedOn');
    final parsed = DateTime.tryParse(occurred);
    if (parsed == null ||
        !parsed.isUtc ||
        parsed.toIso8601String() != occurred ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        DateTime.tryParse(date)?.toIso8601String().substring(0, 10) != date) {
      throw const FormatException('Invalid original pack date.');
    }
    Map<String, Object?> states(String name) {
      final values = data[name];
      if (values is! Map<String, dynamic> ||
          values.length != stateKeys.length ||
          !stateKeys.containsAll(values.keys)) {
        throw const FormatException('Invalid pack completion states.');
      }
      for (final entry in values.entries) {
        final value = entry.value;
        if (value == null) {
          continue;
        }
        if (entry.key == stampKey || entry.key == boxKey) {
          if (value is! List || value.any((v) => v is! String)) {
            throw const FormatException('Invalid reward list.');
          }
        } else if (entry.key == 'kl_xp' || entry.key == 'kl_xp_today_raw') {
          if (value is! int || value < 0) {
            throw const FormatException('Invalid legacy XP.');
          }
        } else if (value is! String) {
          throw const FormatException('Invalid native string.');
        }
      }
      return Map.unmodifiable({
        for (final entry in values.entries)
          entry.key: entry.value is List
              ? List<String>.unmodifiable((entry.value as List).cast<String>())
              : entry.value,
      });
    }

    final before = states('before');
    final after = states('after');
    for (final key in stateKeys.difference(writeOrder.toSet())) {
      if (jsonEncode(before[key]) != jsonEncode(after[key])) {
        throw const FormatException('Read-only authority changed.');
      }
    }
    final identity = text('id');
    if (!RegExp(
      r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
    ).hasMatch(identity)) {
      throw const FormatException('Invalid completion identity.');
    }
    final next = data['nextPackId'];
    if (next != null &&
        (next.isEmpty ||
            next.trim() != next ||
            utf8.encode(next as String).length > 128)) {
      throw const FormatException('Invalid next pack identity.');
    }
    if (data['courseContext'] == null &&
        courseKeys.any(
          (key) => jsonEncode(before[key]) != jsonEncode(after[key]),
        )) {
      throw const FormatException('Free-browse completion changes course.');
    }
    final hash = text('contentHash');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid content fingerprint.');
    }
    final boss = text('boss', max: maxBytes);
    if (jsonDecode(boss) is! Map ||
        after[packKey] is! String ||
        jsonDecode(after[packKey]! as String) is! Map) {
      throw const FormatException('Invalid pack transition.');
    }
    final course = data['courseContext'];
    if (course != null &&
        (course is! Map ||
            course.length != 4 ||
            !const {
              'unit',
              'link',
              'content',
              'kind',
            }.containsAll(course.keys) ||
            course.values.any(
              (v) => v is! String || v.isEmpty || utf8.encode(v).length > 128,
            ) ||
            course['kind'] != 'vocab')) {
      throw const FormatException('Invalid course provenance.');
    }
    return PackCompletionRecord(
      id: identity,
      owner: text('owner', max: 1024),
      occurredAt: occurred,
      earnedOn: date,
      packId: text('packId'),
      level: text('level'),
      contentHash: hash,
      quizCorrect: quizCorrect,
      quizTotal: quizTotal,
      bossCorrect: bossCorrect,
      bossTotal: bossTotal,
      wordCount: words,
      xp: data['xp'] as int,
      justCleared: data['justCleared'] as bool,
      nextPackId: data['nextPackId'] as String?,
      before: before,
      stampMotif: text('stampMotif'),
      courseContext: course == null
          ? null
          : Map<String, String>.unmodifiable(
              Map<String, String>.from(course as Map),
            ),
      boss: boss,
      after: after,
      settled: data['settled'] as bool,
    );
  }
}

enum PackCompletionStatus { ready, recovering, retryRequired, blocked, result }

final class PackCompletionPendingException implements Exception {
  const PackCompletionPendingException();
  @override
  String toString() => 'An accepted pack completion needs recovery.';
}
