import 'dart:convert';

/// A confirmed decoration's presentation data. These values never award XP,
/// currency, ownership, or another box.
final class DecorationRewardReceipt {
  const DecorationRewardReceipt({
    required this.id,
    required this.sourceQuestId,
    required this.decorationSlug,
    required this.claimedAtUtc,
    required this.totalXp,
    required this.xpLevel,
    required this.xpToNext,
    this.yeopjeonBalance,
    this.acknowledged = false,
  });

  final String id;
  final String sourceQuestId;
  final String decorationSlug;
  final DateTime claimedAtUtc;
  final int totalXp;
  final int xpLevel;
  final int xpToNext;
  final int? yeopjeonBalance;
  final bool acknowledged;

  DecorationRewardReceipt acknowledge() => DecorationRewardReceipt(
    id: id,
    sourceQuestId: sourceQuestId,
    decorationSlug: decorationSlug,
    claimedAtUtc: claimedAtUtc,
    totalXp: totalXp,
    xpLevel: xpLevel,
    xpToNext: xpToNext,
    yeopjeonBalance: yeopjeonBalance,
    acknowledged: true,
  );

  bool hasSameReward(DecorationRewardReceipt other) =>
      id == other.id &&
      sourceQuestId == other.sourceQuestId &&
      decorationSlug == other.decorationSlug &&
      claimedAtUtc == other.claimedAtUtc &&
      totalXp == other.totalXp &&
      xpLevel == other.xpLevel &&
      xpToNext == other.xpToNext &&
      yeopjeonBalance == other.yeopjeonBalance;

  Map<String, Object?> toJson() => {
    'id': id,
    'sourceQuestId': sourceQuestId,
    'decorationSlug': decorationSlug,
    'claimedAtUtc': claimedAtUtc.toUtc().toIso8601String(),
    'totalXp': totalXp,
    'xpLevel': xpLevel,
    'xpToNext': xpToNext,
    'yeopjeonBalance': yeopjeonBalance,
    'acknowledged': acknowledged,
  };

  factory DecorationRewardReceipt.fromJson(Map<String, dynamic> json) {
    final id = _identifier(json['id']);
    final source = _identifier(json['sourceQuestId']);
    final slug = _identifier(json['decorationSlug']);
    final rawAt = json['claimedAtUtc'];
    final at = rawAt is String ? DateTime.tryParse(rawAt) : null;
    final xp = json['totalXp'];
    final level = json['xpLevel'];
    final toNext = json['xpToNext'];
    final balance = json['yeopjeonBalance'];
    final acknowledged = json['acknowledged'];
    if (!slug.startsWith('decoration_') ||
        at == null ||
        !at.isUtc ||
        at.toIso8601String() != rawAt ||
        xp is! int ||
        xp < 0 ||
        level is! int ||
        toNext is! int ||
        level != xp ~/ 100 + 1 ||
        toNext != 100 - xp % 100 ||
        (balance != null && (balance is! int || balance < 0)) ||
        acknowledged is! bool) {
      throw const FormatException('Invalid decoration reward receipt.');
    }
    return DecorationRewardReceipt(
      id: id,
      sourceQuestId: source,
      decorationSlug: slug,
      claimedAtUtc: at,
      totalXp: xp,
      xpLevel: level,
      xpToNext: toNext,
      yeopjeonBalance: balance as int?,
      acknowledged: acknowledged,
    );
  }

  static String _identifier(Object? value) {
    if (value is! String ||
        value.isEmpty ||
        value.length > 512 ||
        value.trim() != value ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
      throw const FormatException('Invalid decoration reward identifier.');
    }
    return value;
  }
}

/// Keeps unacknowledged receipts across restart and merges their presentation
/// history across devices. No entry can recreate ownership or consume a queue.
final class DecorationRewardReceiptHistory {
  DecorationRewardReceiptHistory([
    Iterable<DecorationRewardReceipt> values = const [],
  ]) : receipts = List.unmodifiable(values) {
    if (receipts.length > 256 ||
        receipts.map((receipt) => receipt.id).toSet().length !=
            receipts.length) {
      throw const FormatException('Invalid decoration reward receipt history.');
    }
  }

  final List<DecorationRewardReceipt> receipts;

  DecorationRewardReceipt? find(String id) {
    for (final receipt in receipts) {
      if (receipt.id == id) {
        return receipt;
      }
    }
    return null;
  }

  DecorationRewardReceipt? get pending {
    final remaining =
        receipts.where((receipt) => !receipt.acknowledged).toList()
          ..sort(_compare);
    return remaining.firstOrNull;
  }

  DecorationRewardReceiptHistory add(DecorationRewardReceipt receipt) {
    final existing = find(receipt.id);
    if (existing != null && !existing.hasSameReward(receipt)) {
      throw const FormatException('Conflicting decoration reward receipt.');
    }
    final value = existing?.acknowledged == true ? existing! : receipt;
    return DecorationRewardReceiptHistory([
      for (final stored in receipts)
        if (stored.id != receipt.id) stored,
      value,
    ]);
  }

  DecorationRewardReceiptHistory acknowledge(String id) {
    final receipt = find(id);
    if (receipt == null) {
      return this;
    }
    return add(receipt.acknowledge());
  }

  String encode() {
    final ordered = receipts.toList()..sort(_compare);
    return jsonEncode({
      'version': 1,
      'receipts': [for (final receipt in ordered) receipt.toJson()],
    });
  }

  factory DecorationRewardReceiptHistory.decode(String raw) {
    if (raw.isEmpty) {
      return DecorationRewardReceiptHistory();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['receipts'] is! List) {
      throw const FormatException('Invalid decoration reward receipt history.');
    }
    return DecorationRewardReceiptHistory([
      for (final value in decoded['receipts'] as List)
        if (value is Map<String, dynamic>)
          DecorationRewardReceipt.fromJson(value)
        else
          throw const FormatException('Invalid decoration reward receipt.'),
    ]);
  }

  static String mergeJson(String local, String remote) {
    var merged = DecorationRewardReceiptHistory.decode(local);
    for (final receipt in DecorationRewardReceiptHistory.decode(
      remote,
    ).receipts) {
      merged = merged.add(receipt);
    }
    return merged.encode();
  }

  static int _compare(
    DecorationRewardReceipt first,
    DecorationRewardReceipt second,
  ) {
    final time = first.claimedAtUtc.compareTo(second.claimedAtUtc);
    return time == 0 ? first.id.compareTo(second.id) : time;
  }
}
