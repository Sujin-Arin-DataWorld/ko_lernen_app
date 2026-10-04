import 'dart:math' as math;

/// Device-local discovery history. Visits and launches never award progress.
/// The four positions stay fixed for a local calendar day.
final class CatalogRecommendations {
  CatalogRecommendations._(
    this.events,
    this.everUsed,
    this.visitCount,
    this.lastVisit,
    this.slates,
    this.dismissed,
    this.lastShown,
    this.suggestion,
  );

  final List<({String id, int at})> events;
  final Set<String> everUsed;
  int visitCount;
  int lastVisit;
  final Map<String, ({String day, List<String> ids})> slates;
  final Map<String, int> dismissed;
  int lastShown;
  String? suggestion;

  static const _dayMs = 86400000;
  static String dayKey(DateTime now) => '${now.year}-${now.month}-${now.day}';

  factory CatalogRecommendations.read(
    dynamic raw,
    Set<String> allowed,
    DateTime now,
  ) {
    final map = raw is Map && raw['version'] == 1 ? raw : const {};
    int time(dynamic value) =>
        value is int && value > 0 && value <= now.millisecondsSinceEpoch + 1000
        ? value
        : 0;
    final cutoff = now.millisecondsSinceEpoch - 90 * _dayMs;
    final events = <({String id, int at})>[];
    if (map['events'] is List) {
      for (final e in map['events'] as List) {
        if (e is Map && allowed.contains(e['id']) && time(e['at']) >= cutoff) {
          events.add((id: e['id'] as String, at: time(e['at'])));
        }
      }
    }
    final used = <String>{...events.map((e) => e.id)};
    if (map['everUsed'] is List) {
      used.addAll(
        (map['everUsed'] as List).whereType<String>().where(allowed.contains),
      );
    }
    final slates = <String, ({String day, List<String> ids})>{};
    if (map['slates'] is Map) {
      for (final e in (map['slates'] as Map).entries) {
        if (e.key is String && e.value is Map) {
          final v = e.value as Map;
          if (v['day'] is String && v['ids'] is List) {
            slates[e.key as String] = (
              day: v['day'] as String,
              ids: (v['ids'] as List)
                  .whereType<String>()
                  .where(allowed.contains)
                  .toSet()
                  .take(4)
                  .toList(),
            );
          }
        }
      }
    }
    final dismissed = <String, int>{};
    if (map['dismissed'] is Map) {
      for (final e in (map['dismissed'] as Map).entries) {
        if (allowed.contains(e.key) &&
            e.value is int &&
            e.value > now.millisecondsSinceEpoch &&
            e.value <= now.millisecondsSinceEpoch + 7 * _dayMs) {
          dismissed[e.key as String] = e.value as int;
        }
      }
    }
    return CatalogRecommendations._(
      events.skip(math.max(0, events.length - 1400)).toList(),
      used,
      map['visits'] is int && map['visits'] >= 0 ? map['visits'] as int : 0,
      time(map['lastVisit']),
      slates,
      dismissed,
      time(map['lastShown']),
      allowed.contains(map['suggestion']) ? map['suggestion'] as String : null,
    );
  }

  void record(String id, DateTime now) {
    final at = now.millisecondsSinceEpoch;
    final prior = events.where((e) => e.id == id).lastOrNull;
    if (prior != null && at - prior.at < 30000) {
      return;
    }
    events.add((id: id, at: at));
    if (events.length > 1400) {
      events.removeRange(0, events.length - 1400);
    }
    everUsed.add(id);
    if (suggestion == id) {
      suggestion = null;
    }
  }

  List<String> rank(List<String> allowed, List<String> defaults, DateTime now) {
    final scores = <String, double>{};
    final caps = <String, int>{};
    for (final e in events.reversed) {
      final age = now.millisecondsSinceEpoch - e.at;
      if (age < 0 || age > 28 * _dayMs || !allowed.contains(e.id)) {
        continue;
      }
      final key =
          '${e.id}:${dayKey(DateTime.fromMillisecondsSinceEpoch(e.at))}';
      final count = caps[key] ?? 0;
      if (count >= 3) {
        continue;
      }
      caps[key] = count + 1;
      scores[e.id] = (scores[e.id] ?? 0) + math.pow(.5, age / (7 * _dayMs));
    }
    final fallback = {...defaults.where(allowed.contains), ...allowed}.toList();
    return [...allowed]..sort((a, b) {
      final score = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
      return score != 0
          ? score
          : fallback.indexOf(a).compareTo(fallback.indexOf(b));
    });
  }

  List<String> quickIds(
    String tab,
    List<String> allowed,
    List<String> defaults,
    DateTime now,
  ) {
    final slate = slates[tab];
    if (slate != null &&
        slate.day == dayKey(now) &&
        slate.ids.length == math.min(4, allowed.length) &&
        slate.ids.every(allowed.contains)) {
      return slate.ids;
    }
    return rank(allowed, defaults, now).take(4).toList();
  }

  void visit(
    String tab,
    List<String> allowed,
    List<String> defaults,
    DateTime now,
  ) {
    final at = now.millisecondsSinceEpoch;
    if (lastVisit == 0 || at - lastVisit >= 1800000) {
      visitCount++;
      lastVisit = at;
    }
    slates[tab] = (
      day: dayKey(now),
      ids: quickIds(tab, allowed, defaults, now),
    );
    if (visitCount >= 3 &&
        visitCount % 3 == 0 &&
        (lastShown == 0 || at - lastShown >= _dayMs)) {
      final quick = slates[tab]!.ids;
      suggestion = allowed
          .where(
            (id) =>
                !quick.contains(id) &&
                !everUsed.contains(id) &&
                (dismissed[id] ?? 0) <= at,
          )
          .firstOrNull;
      if (suggestion != null) {
        lastShown = at;
      }
    }
  }

  String? discover(List<String> allowed, List<String> quick, DateTime now) {
    final id = suggestion;
    return id != null &&
            allowed.contains(id) &&
            !quick.contains(id) &&
            !everUsed.contains(id) &&
            (dismissed[id] ?? 0) <= now.millisecondsSinceEpoch &&
            dayKey(DateTime.fromMillisecondsSinceEpoch(lastShown)) ==
                dayKey(now)
        ? id
        : null;
  }

  void dismiss(String id, DateTime now) {
    dismissed[id] = now.millisecondsSinceEpoch + 7 * _dayMs;
    lastShown = now.millisecondsSinceEpoch;
    suggestion = null;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'events': [
      for (final e in events) {'id': e.id, 'at': e.at},
    ],
    'everUsed': everUsed.toList(),
    'visits': visitCount,
    'lastVisit': lastVisit,
    'slates': {
      for (final e in slates.entries)
        e.key: {'day': e.value.day, 'ids': e.value.ids},
    },
    'dismissed': dismissed,
    'lastShown': lastShown,
    'suggestion': suggestion,
  };
}
