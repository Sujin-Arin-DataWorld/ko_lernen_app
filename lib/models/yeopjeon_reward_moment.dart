import 'package:flutter/foundation.dart';

/// Display provenance only: this value cannot grant money or save learning.
enum YeopjeonRewardSource { currentActivity, recovery }

@immutable
final class YeopjeonRewardMoment {
  YeopjeonRewardMoment({
    required Map<String, int> claims,
    required this.balance,
    required this.source,
    required this.day,
  }) : claims = Map.unmodifiable(claims);

  final Map<String, int> claims;
  final int balance;
  final YeopjeonRewardSource source;

  /// Frozen when the ledger result is observed, using the economy's local day.
  final String day;
  int get amount => claims.values.fold(0, (sum, value) => sum + value);
  bool get playMintVideo =>
      source == YeopjeonRewardSource.currentActivity &&
      claims['daily:$day:first'] == 20;

  YeopjeonRewardMoment? retaining(Set<String> ids) {
    final remaining = Map<String, int>.fromEntries(
      claims.entries.where((entry) => ids.contains(entry.key)),
    );
    if (remaining.isEmpty) {
      return null;
    }
    return YeopjeonRewardMoment(
      claims: remaining,
      balance: balance,
      source: source,
      day: day,
    );
  }

  static String dayKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

/// Confirmed learning whose ledger verification still needs a read or retry.
/// This carries no promised amount and cannot complete learning again.
@immutable
final class YeopjeonPendingReward {
  YeopjeonPendingReward({
    required Set<String> sourceIds,
    required Set<String> baselineClaimIds,
    this.hasClaimBaseline = true,
  }) : sourceIds = Set.unmodifiable(sourceIds),
       baselineClaimIds = Set.unmodifiable(baselineClaimIds);
  final Set<String> sourceIds;
  final Set<String> baselineClaimIds;

  /// Without a frozen baseline, a readback cannot attribute historical claims.
  final bool hasClaimBaseline;
}
