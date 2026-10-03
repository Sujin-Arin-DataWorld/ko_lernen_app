import 'dart:convert';
import 'learner_level.dart';

enum PracticeKind { smalltalk, silben }

String _id(Object? value) {
  if (value is! String ||
      !RegExp(r'^[a-zA-Z0-9_.:-]{1,160}$').hasMatch(value)) {
    throw const FormatException('Invalid practice identifier.');
  }
  return value;
}

DateTime _time(Object? value) {
  if (value is! String) {
    throw const FormatException('Invalid practice time.');
  }
  final result = DateTime.tryParse(value);
  if (result == null || !result.isUtc) {
    throw const FormatException('Invalid practice time.');
  }
  return result;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid practice object.');
  }
  return value;
}

class PracticeSource {
  const PracticeSource({
    required this.kind,
    required this.id,
    required this.level,
    required this.revision,
  });
  final PracticeKind kind;
  final String id;
  final String level;
  final int revision;
  String get key => '${kind.name}:$id:$revision';
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'id': id,
    'level': level,
    'revision': revision,
  };
  factory PracticeSource.fromJson(Map<String, dynamic> json) {
    final kind = PracticeKind.values
        .where((v) => v.name == json['kind'])
        .firstOrNull;
    final level = json['level'];
    final revision = json['revision'];
    if (kind == null ||
        level is! String ||
        LearnerLevel.fromCode(level)?.code != level ||
        revision is! int ||
        revision < 1 ||
        revision > 10000) {
      throw const FormatException('Invalid practice source.');
    }
    return PracticeSource(
      kind: kind,
      id: _id(json['id']),
      level: level,
      revision: revision,
    );
  }
}

/// A bounded completion snapshot. No XP, currency or course mastery is stored.
class PracticeAttempt {
  const PracticeAttempt({
    required this.id,
    required this.at,
    required this.variant,
    required this.completed,
    this.hints = const {},
    this.expressionId,
  });
  final String id;
  final DateTime at;
  final String variant;
  final bool completed;
  final Map<String, int> hints;
  final String? expressionId;
  bool get usedHelp => hints.isNotEmpty;
  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    'variant': variant,
    'completed': completed,
    'hints': {for (final key in (hints.keys.toList()..sort())) key: hints[key]},
    if (expressionId != null) 'expressionId': expressionId,
  };
  factory PracticeAttempt.fromJson(Map<String, dynamic> json) {
    final hints = _map(json['hints']);
    if (hints.length > 20 || json['completed'] is! bool) {
      throw const FormatException('Invalid practice attempt.');
    }
    return PracticeAttempt(
      id: _id(json['id']),
      at: _time(json['at']),
      variant: _id(json['variant']),
      completed: json['completed'] as bool,
      expressionId: json['expressionId'] == null
          ? null
          : _id(json['expressionId']),
      hints: {for (final e in hints.entries) _id(e.key): _hint(e.value)},
    );
  }
  static int _hint(Object? value) {
    if (value is! int || value < 1 || value > 3) {
      throw const FormatException('Invalid help level.');
    }
    return value;
  }
}

class PracticeItem {
  const PracticeItem({
    required this.source,
    this.viewedAt,
    this.assisted,
    this.independent,
  });
  final PracticeSource source;
  final DateTime? viewedAt;
  final PracticeAttempt? assisted;
  final PracticeAttempt? independent;
  DateTime get updatedAt => [
    viewedAt,
    assisted?.at,
    independent?.at,
  ].whereType<DateTime>().reduce((a, b) => a.isAfter(b) ? a : b);
  PracticeItem merge(PracticeItem other) {
    if (source.key != other.source.key || source.level != other.source.level) {
      throw const FormatException('Conflicting practice source.');
    }
    return PracticeItem(
      source: source,
      viewedAt: _later(viewedAt, other.viewedAt),
      assisted: _latest(assisted, other.assisted),
      independent: _latest(independent, other.independent),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source.toJson(),
    if (viewedAt != null) 'viewedAt': viewedAt!.toUtc().toIso8601String(),
    if (assisted != null) 'assisted': assisted!.toJson(),
    if (independent != null) 'independent': independent!.toJson(),
  };
  factory PracticeItem.fromJson(Map<String, dynamic> json) {
    final assisted = json['assisted'] == null
        ? null
        : PracticeAttempt.fromJson(_map(json['assisted']));
    final independent = json['independent'] == null
        ? null
        : PracticeAttempt.fromJson(_map(json['independent']));
    final viewed = json['viewedAt'] == null ? null : _time(json['viewedAt']);
    if ((assisted != null && !assisted.usedHelp) ||
        (independent != null && independent.usedHelp) ||
        (viewed == null && assisted == null && independent == null)) {
      throw const FormatException('Invalid practice evidence.');
    }
    return PracticeItem(
      source: PracticeSource.fromJson(_map(json['source'])),
      viewedAt: viewed,
      assisted: assisted,
      independent: independent,
    );
  }
  static DateTime? _later(DateTime? a, DateTime? b) => a == null
      ? b
      : b == null
      ? a
      : a.isAfter(b)
      ? a
      : b;
  static PracticeAttempt? _latest(PracticeAttempt? a, PracticeAttempt? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    final order = a.at.compareTo(b.at);
    return order > 0
        ? a
        : order < 0
        ? b
        : jsonEncode(a.toJson()).compareTo(jsonEncode(b.toJson())) >= 0
        ? a
        : b;
  }
}

class PracticeHistory {
  PracticeHistory([Iterable<PracticeItem> items = const []])
    : _items = {for (final item in items) item.source.key: item};
  final Map<String, PracticeItem> _items;
  List<PracticeItem> get items => List.unmodifiable(
    _items.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );
  PracticeItem? forSource(PracticeSource source) => _items[source.key];
  PracticeHistory add(PracticeItem value) {
    final existing = _items[value.source.key];
    final next = {
      ..._items,
      value.source.key: existing == null ? value : existing.merge(value),
    };
    if (next.length > 1000) {
      throw const FormatException('Practice history capacity exceeded.');
    }
    return PracticeHistory(next.values);
  }

  String encode() => jsonEncode({
    'version': 1,
    'items': {
      for (final key in (_items.keys.toList()..sort()))
        key: _items[key]!.toJson(),
    },
  });
  factory PracticeHistory.decode(String raw) {
    if (raw.isEmpty) {
      return PracticeHistory();
    }
    final json = _map(jsonDecode(raw));
    if (json['version'] != 1 || json.length != 2) {
      throw const FormatException('Unsupported practice history.');
    }
    final items = _map(json['items']);
    if (items.length > 1000) {
      throw const FormatException('Practice history capacity exceeded.');
    }
    return PracticeHistory(
      items.entries.map((e) {
        final item = PracticeItem.fromJson(_map(e.value));
        if (e.key != item.source.key) {
          throw const FormatException('Invalid practice key.');
        }
        return item;
      }),
    );
  }
  static String mergeJson(String local, String remote) {
    var result = PracticeHistory.decode(local);
    for (final item in PracticeHistory.decode(remote).items) {
      result = result.add(item);
    }
    return result.encode();
  }
}
