import 'dart:convert';

import '../../models/grammar_study_plan.dart';
import '../../models/learner_level.dart';
import '../../models/yeopjeon_wallet.dart';
import '../grammar_plan_service.dart';

/// Strict domain adapters. These functions never write storage or rewards.
abstract final class AccountReconciliationFieldPolicy {
  static String mergeStudyLog(Object? local, Object? remote) {
    Map<String, List<String>> decode(Object? raw) {
      final source = _object(raw);
      return {
        for (final entry in source.entries)
          _date(entry.key): _ids(entry.value, deduplicate: true),
      };
    }

    final left = decode(local);
    final right = decode(remote);
    final dates = {...left.keys, ...right.keys}.toList()..sort();
    return jsonEncode({
      for (final date in dates)
        date: _studyUnion(left[date] ?? const [], right[date] ?? const []),
    });
  }

  static String mergeGrammarPlan(Object? local, Object? remote) {
    final left = _plans(local);
    final right = _plans(remote);
    final levels = {...left.keys, ...right.keys}.toList()..sort();
    final result = <String, GrammarStudyPlan>{};
    for (final level in levels) {
      final device = left[level];
      final cloud = right[level];
      if (device == null || cloud == null) {
        result[level] = device ?? cloud!;
        continue;
      }
      // If one source repeated a served item on a later date, retain that
      // source's own history. Two independent dates for the same item cannot
      // be combined into additional completed slices that neither source had.
      final deviceDates = _servedDates(device);
      final cloudDates = _servedDates(cloud);
      for (final id in deviceDates.keys.toSet().intersection(
        cloudDates.keys.toSet(),
      )) {
        if (!deviceDates[id]!.containsAll(cloudDates[id]!) &&
            !cloudDates[id]!.containsAll(deviceDates[id]!)) {
          throw const FormatException('Divergent grammar served history.');
        }
      }
      final dates = {
        ...device.servedIdsByDate.keys,
        ...cloud.servedIdsByDate.keys,
      }.toList()..sort();
      final served = <String, List<String>>{};
      for (final date in dates) {
        final first = device.servedIdsByDate[date];
        final second = cloud.servedIdsByDate[date];
        if (first == null || second == null) {
          served[date] = List<String>.from(first ?? second!);
        } else if (_prefix(first, second)) {
          served[date] = List<String>.from(second);
        } else if (_prefix(second, first)) {
          served[date] = List<String>.from(first);
        } else {
          throw const FormatException('Divergent grammar served order.');
        }
      }
      // Cross-pace legacy histories remain conservatively blocked here.
      // Retain the device's preference and accept only history already held
      // locally; planner selection does not authorize a history conversion.
      if (device.itemsPerDay != cloud.itemsPerDay &&
          (served.length != device.servedIdsByDate.length ||
              served.entries.any((entry) {
                final original = device.servedIdsByDate[entry.key];
                return original == null ||
                    original.length != entry.value.length ||
                    !_prefix(original, entry.value);
              }))) {
        throw const FormatException('Incompatible grammar plan pace history.');
      }
      result[level] = device.copyWith(servedIdsByDate: served);
    }
    return GrammarPlanService.encodePlans(result);
  }

  static String? mergeLearnerGoal(Object? local, Object? remote) {
    String? decode(Object? raw) {
      if (raw == null || raw == '') {
        return null;
      }
      if (raw is! String) {
        throw const FormatException('Invalid learning goal.');
      }
      final level = LearnerLevel.fromCode(raw);
      if (level == null) {
        throw const FormatException('Unsupported learning goal.');
      }
      return level.code;
    }

    final device = decode(local);
    final cloud = decode(remote);
    return device ?? cloud;
  }

  static String mergeWallet(Object? local, Object? remote) {
    YeopjeonWallet? decode(Object? raw) {
      if (raw == null) {
        return null;
      }
      if (raw is! String || raw.isEmpty) {
        throw const FormatException('Invalid wallet history.');
      }
      return YeopjeonWallet.decode(raw);
    }

    final device = decode(local);
    final cloud = decode(remote);
    if (device == null && cloud == null) {
      throw const FormatException('Missing wallet history.');
    }
    if (device == null || cloud == null) {
      return (device ?? cloud!).encode();
    }
    if (device.dominates(cloud)) {
      return device.encode();
    }
    if (!cloud.dominates(device) && !device.isPristineZero) {
      throw const FormatException('Divergent wallet histories.');
    }
    // Exactly the existing restore rule: only a pristine device baseline may
    // contribute source markers. Claims, balance and ownership are never unioned.
    return (device.isPristineZero
            ? cloud.copyWith(
                completedSourceIds: {
                  ...cloud.completedSourceIds,
                  ...device.completedSourceIds,
                },
              )
            : cloud)
        .encode();
  }

  static Map<String, dynamic> _object(Object? raw) {
    if (raw == null || raw == '') {
      return {};
    }
    if (raw is! String) {
      throw const FormatException('Invalid account field encoding.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid account field object.');
    }
    return decoded;
  }

  static String _date(String value) {
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-'
                '${parsed.month.toString().padLeft(2, '0')}-'
                '${parsed.day.toString().padLeft(2, '0')}' !=
            value) {
      throw const FormatException('Invalid account history date.');
    }
    return value;
  }

  static List<String> _ids(Object? raw, {required bool deduplicate}) {
    if (raw is! List || raw.any((id) => id is! String || id.trim().isEmpty)) {
      throw const FormatException('Invalid account history IDs.');
    }
    final ids = raw.cast<String>();
    if (!deduplicate) {
      return List<String>.from(ids);
    }
    final unique = ids.toSet().toList()..sort();
    if (unique.length > 500) {
      throw const FormatException('Account study history exceeds retention.');
    }
    return unique;
  }

  static List<String> _studyUnion(List<String> first, List<String> second) {
    final ids = {...first, ...second}.toList()..sort();
    if (ids.length > 500) {
      throw const FormatException('Account study history exceeds retention.');
    }
    return ids;
  }

  static Map<String, GrammarStudyPlan> _plans(Object? raw) {
    final source = _object(raw);
    final result = <String, GrammarStudyPlan>{};
    for (final entry in source.entries) {
      final level = LearnerLevel.fromCode(entry.key);
      final value = entry.value;
      if (level == null ||
          result.containsKey(level.code) ||
          value is! Map<String, dynamic> ||
          value.length != 3 ||
          !value.keys.toSet().containsAll({
            'level',
            'itemsPerDay',
            'servedIdsByDate',
          }) ||
          value['level'] is! String ||
          LearnerLevel.fromCode(value['level'] as String) != level ||
          value['itemsPerDay'] is! int ||
          !GrammarPlanService.itemsPerDayOptions.contains(
            value['itemsPerDay'],
          ) ||
          value['servedIdsByDate'] is! Map<String, dynamic>) {
        throw const FormatException('Unsupported grammar plan schema.');
      }
      final served = value['servedIdsByDate'] as Map<String, dynamic>;
      final dates = served.keys.toList()..sort();
      final history = <String, List<String>>{};
      for (final date in dates) {
        final ids = _ids(served[date], deduplicate: false);
        if (ids.isEmpty) {
          throw const FormatException('Empty grammar served history.');
        }
        history[_date(date)] = ids;
      }
      result[level.code] = GrammarStudyPlan.fromJson({
        'level': level.code,
        'itemsPerDay': value['itemsPerDay'],
        'servedIdsByDate': history,
      });
    }
    return result;
  }

  static Map<String, Set<String>> _servedDates(GrammarStudyPlan plan) {
    final result = <String, Set<String>>{};
    for (final day in plan.servedIdsByDate.entries) {
      for (final id in day.value) {
        (result[id] ??= <String>{}).add(day.key);
      }
    }
    return result;
  }

  static bool _prefix(List<String> prefix, List<String> value) =>
      prefix.length <= value.length &&
      Iterable<int>.generate(
        prefix.length,
      ).every((index) => prefix[index] == value[index]);
}
