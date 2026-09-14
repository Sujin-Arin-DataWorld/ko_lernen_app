import 'dart:convert';

/// Immutable local effects, never a resumable lesson or review attempt.
/// Null means the native preference was absent (distinct from an empty value).
class SrsCommitJournal {
  const SrsCommitJournal({
    required this.date,
    required this.recordHistory,
    required this.beforeDeck,
    required this.afterDeck,
    required this.beforeHistory,
    required this.afterHistory,
  });

  static const key = 'kl_srs_commit_journal_v1';
  final String date;
  final bool recordHistory;
  final String? beforeDeck;
  final String afterDeck;
  final List<String>? beforeHistory;
  final List<String>? afterHistory;
  String get historyKey => 'kl_study_log_v1_$date';

  String encode() => jsonEncode({
    'version': 1,
    'date': date,
    'history': recordHistory,
    'beforeDeck': beforeDeck,
    'afterDeck': afterDeck,
    'beforeHistory': beforeHistory,
    'afterHistory': afterHistory,
  });

  static bool validDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    return parsed != null && parsed.toIso8601String().startsWith('${value}T');
  }

  static bool validDeck(String? raw) {
    if (raw == null || raw.isEmpty) {
      return true;
    }
    try {
      final deck = jsonDecode(raw);
      if (deck is! Map<String, dynamic>) {
        return false;
      }
      for (final entry in deck.entries) {
        final card = entry.value;
        if (entry.key.trim().isEmpty || card is! Map<String, dynamic>) {
          return false;
        }
        final ease = card['e'];
        final interval = card['i'];
        final count = card['r'];
        final date = card['n'];
        if (card.length != 4 ||
            ease is! num ||
            !ease.isFinite ||
            ease < 1.3 ||
            ease > 3.5 ||
            interval is! int ||
            interval < 0 ||
            interval > 365 ||
            count is! int ||
            count < 0 ||
            date is! String ||
            (date.isNotEmpty && !validDate(date))) {
          return false;
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  static bool validHistory(Object? value) =>
      value == null ||
      (value is List &&
          value.length <= 500 &&
          value.every((id) => id is String && id.trim().isNotEmpty) &&
          value.toSet().length == value.length);

  factory SrsCommitJournal.decode(Object? raw) {
    if (raw is! String) {
      throw const FormatException('Invalid SRS commit journal type.');
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value.length != 7 ||
        value['version'] is! int ||
        value['version'] != 1 ||
        value['date'] is! String ||
        !validDate(value['date'] as String) ||
        value['history'] is! bool ||
        !value.containsKey('beforeDeck') ||
        !value.containsKey('beforeHistory') ||
        !value.containsKey('afterHistory') ||
        (value['beforeDeck'] != null && value['beforeDeck'] is! String) ||
        value['afterDeck'] is! String ||
        !validDeck(value['beforeDeck'] as String?) ||
        !validDeck(value['afterDeck'] as String?) ||
        (value['afterDeck'] as String).isEmpty ||
        !validHistory(value['beforeHistory']) ||
        !validHistory(value['afterHistory'])) {
      throw const FormatException('Invalid SRS commit journal.');
    }
    final history = value['history'] as bool;
    final before = value['beforeHistory'] as List?;
    final after = value['afterHistory'] as List?;
    if ((!history && (before != null || after != null)) ||
        (history &&
            (after == null ||
                after.isEmpty ||
                after.length < (before?.length ?? 0) ||
                after.length > (before?.length ?? 0) + 1 ||
                !List.generate(
                  before?.length ?? 0,
                  (i) => before![i] == after[i],
                ).every((matches) => matches)))) {
      throw const FormatException('Invalid SRS history effects.');
    }
    return SrsCommitJournal(
      date: value['date'] as String,
      recordHistory: history,
      beforeDeck: value['beforeDeck'] as String?,
      afterDeck: value['afterDeck'] as String,
      beforeHistory: before == null ? null : List<String>.unmodifiable(before),
      afterHistory: after == null ? null : List<String>.unmodifiable(after),
    );
  }
}
