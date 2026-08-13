import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../models/course_mastery.dart';
import 'storage_service.dart';

class LearningDataExportPackage {
  const LearningDataExportPackage({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.data,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final Map<String, dynamic> data;
}

/// Builds a portable copy of local learning progress without dumping the
/// preferences database.
///
/// Every exported field is explicitly allowlisted. Account identifiers,
/// authentication material, consent flags, deletion/transition journals and
/// private media paths are never inspected. Parsing raw learning blobs is pure:
/// corrupt data is omitted rather than invoking Storage's quarantine/migration
/// writers.
abstract final class LearningDataExportService {
  static const int schemaVersion = 1;
  static const String mimeType = 'application/json';

  static LearningDataExportPackage buildPackage({DateTime? exportedAt}) {
    final at = (exportedAt ?? DateTime.now()).toUtc();
    final data = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportType': 'hangul_sori_local_learning_data',
      'exportedAt': at.toIso8601String(),
      'scope': {
        'source': 'local-device',
        'readOnly': true,
        'excluded': const [
          'account identifiers and authentication',
          'consent and account-operation journals',
          'private books, images, and local file paths',
        ],
      },
      'learner': {
        'level': Storage.userLevelCode,
        'coursePlacementLevel': Storage.dedicatedCoursePlacementLevelCode,
        'browseLevel': Storage.browseLevelCode,
        'dailyGoalMinutes': Storage.dailyGoalMinutes,
        'motivation': Storage.motivation,
        'companion': Storage.preferredMascot,
        'interests': Storage.interests,
      },
      'progress': {
        'xp': Storage.xp,
        'streakDays': Storage.streakDays,
        'bestStreak': Storage.bestStreak,
        'lastLearningDate': Storage.lastOpenDate,
        'vocabulary': {
          'correct': Storage.vokCorrect,
          'wrong': Storage.vokWrong,
          'skipped': Storage.vokSkipped,
          'seenIds': Storage.vokSeenIds,
          'favoriteIds': Storage.vokFavorites,
        },
        'grammar': {
          'seenPatterns': Storage.grammarSeen,
          'hardPatterns': Storage.grammarHard,
        },
        'calligraphyDates': Storage.calligraphyDates,
        'scenarios': {
          'completedIds': Storage.completedScenarios,
          'stars': Storage.scenarioStars,
        },
        'achievements': {
          'stamps': Storage.earnedStamps,
          'badges': Storage.earnedBadges,
          'questCompletions': Storage.questCompletions,
          'ownedDecor': Storage.ownedDecor,
        },
        'pronunciation': {
          'passedAssessments': Storage.pronunciationPassCount,
          'lastScore': Storage.pronunciationLastScore,
          'assessmentIds': Storage.pronunciationAssessmentIds,
        },
      },
      'course': {
        'activeUnitId': Storage.courseUnitId,
        'mastery': _readCourseMastery(),
      },
      'review': {
        'cards': _readReviewCards(),
        'wrongCounts': _readWrongCounts(),
      },
      'packs': _readPackProgress(),
    };
    final body = const JsonEncoder.withIndent('  ').convert(data);
    return LearningDataExportPackage(
      fileName: 'hangul-sori-learning-data-${_fileTimestamp(at)}.json',
      mimeType: mimeType,
      bytes: Uint8List.fromList(utf8.encode('$body\n')),
      data: data,
    );
  }

  static Future<ShareResult> sharePackage(LearningDataExportPackage package) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(package.bytes, mimeType: package.mimeType)],
          fileNameOverrides: [package.fileName],
        ),
      );

  static Map<String, dynamic>? _readCourseMastery() {
    final raw = Storage.courseMasterySnapshotRawJson.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      return CourseMasterySnapshot.decodeAndMigrate(map).toJson();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _readReviewCards() {
    final decoded = _decodeMap(Storage.srsRawJson);
    if (decoded == null) return const {};
    final cards = <String, dynamic>{};
    for (final entry in decoded.entries) {
      final id = _safeId(entry.key);
      final value = entry.value;
      if (id == null || value is! Map) continue;
      final card = value.map((key, item) => MapEntry(key.toString(), item));
      final ease = _finiteDouble(card['e'], min: 1.3, max: 3.5);
      final interval = _nonNegativeInt(card['i']);
      final reviews = _nonNegativeInt(card['r']);
      final next = card['n'];
      if (ease == null ||
          interval == null ||
          reviews == null ||
          next is! String ||
          !_validReviewDate(next)) {
        continue;
      }
      cards[id] = {
        'ease': ease,
        'intervalDays': interval,
        'nextReviewDate': next,
        'reviewCount': reviews,
      };
    }
    return cards;
  }

  /// 단어별 누적 오답 횟수 (`kl_wrong_count_v1`) — Extra-Lernset 의 원천.
  static Map<String, dynamic> _readWrongCounts() {
    final decoded = _decodeMap(Storage.wrongCountRawJson);
    if (decoded == null) return const {};
    final counts = <String, dynamic>{};
    for (final entry in decoded.entries) {
      final id = _safeId(entry.key);
      final value = entry.value;
      if (id == null || value is! int || value <= 0) continue;
      counts[id] = value;
    }
    return counts;
  }

  static Map<String, dynamic> _readPackProgress() {
    final decoded = _decodeMap(Storage.packProgressJsonRaw);
    if (decoded == null) return const {};
    final packs = <String, dynamic>{};
    for (final entry in decoded.entries) {
      final id = _safeId(entry.key);
      final value = entry.value;
      if (id == null || value is! Map) continue;
      final pack = value.map((key, item) => MapEntry(key.toString(), item));
      final level = pack['level'];
      final status = pack['status'];
      final learned = _nonNegativeInt(pack['wordsLearned']);
      final total = _nonNegativeInt(pack['wordsTotal']);
      final accuracy = _finiteDouble(pack['bossAccuracy'], min: 0, max: 1);
      final attempts = _nonNegativeInt(pack['attempts']);
      final clearedAt = pack['clearedAt'];
      if (level is! String ||
          level.trim().isEmpty ||
          status is! String ||
          !const {
            'locked',
            'available',
            'inProgress',
            'cleared',
          }.contains(status) ||
          learned == null ||
          total == null ||
          learned > total ||
          accuracy == null ||
          attempts == null ||
          (clearedAt != null && clearedAt is! String)) {
        continue;
      }
      packs[id] = {
        'level': level,
        'status': status,
        'wordsLearned': learned,
        'wordsTotal': total,
        'bossAccuracy': accuracy,
        'attempts': attempts,
        'clearedAt': clearedAt,
      };
    }
    return packs;
  }

  static Map<String, dynamic>? _decodeMap(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  static String? _safeId(String value) {
    final id = value.trim();
    return id.isEmpty || id.length > 128 ? null : id;
  }

  static int? _nonNegativeInt(Object? value) {
    if (value is! num || !value.isFinite || value != value.roundToDouble()) {
      return null;
    }
    final result = value.toInt();
    return result < 0 ? null : result;
  }

  static double? _finiteDouble(
    Object? value, {
    required double min,
    required double max,
  }) {
    if (value is! num || !value.isFinite) return null;
    final result = value.toDouble();
    return result < min || result > max ? null : result;
  }

  static bool _validReviewDate(String value) {
    if (value.isEmpty) return true;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
        DateTime.tryParse(value) != null;
  }

  static String _fileTimestamp(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}-'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}Z';
  }
}
