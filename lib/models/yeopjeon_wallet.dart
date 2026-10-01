import 'dart:convert';

import 'ildu_construction_art.dart';
import 'sarangchae_construction.dart';

enum YeopjeonBuilding { sarangchae, b2 }

/// One validated document owns money, claim identities, and built stages.
/// Its balance is checked against the full transaction history on every read.
final class YeopjeonWallet {
  YeopjeonWallet({
    required this.balance,
    required this.sarangchaeEligibleStage,
    required this.b2EligibleStage,
    required this.sarangchaeOwnedStage,
    required this.b2OwnedStage,
    required this.grandfatheredSarangchaeStage,
    required this.grandfatheredB2Stage,
    required Map<String, int> claims,
    required Set<String> completedSourceIds,
    required Set<String> reviewedSourceIds,
  }) : claims = Map.unmodifiable(claims),
       completedSourceIds = Set.unmodifiable(completedSourceIds),
       reviewedSourceIds = Set.unmodifiable(reviewedSourceIds) {
    _validate();
  }

  static const schemaVersion = 1;
  static const nextConstructionCost = 40;

  final int balance;
  final int sarangchaeEligibleStage;
  final int b2EligibleStage;
  final int sarangchaeOwnedStage;
  final int b2OwnedStage;
  final int grandfatheredSarangchaeStage;
  final int grandfatheredB2Stage;
  final Map<String, int> claims;
  final Set<String> completedSourceIds;
  final Set<String> reviewedSourceIds;

  bool get isPristineZero =>
      balance == 0 &&
      sarangchaeEligibleStage == 0 &&
      b2EligibleStage == 0 &&
      claims.isEmpty &&
      reviewedSourceIds.isEmpty;

  /// Safe whole-document restore when every local transaction is already in
  /// the candidate history. Divergent histories need an explicit policy.
  bool dominates(YeopjeonWallet older) {
    if (grandfatheredSarangchaeStage != older.grandfatheredSarangchaeStage ||
        grandfatheredB2Stage != older.grandfatheredB2Stage ||
        sarangchaeEligibleStage < older.sarangchaeEligibleStage ||
        b2EligibleStage < older.b2EligibleStage ||
        sarangchaeOwnedStage < older.sarangchaeOwnedStage ||
        b2OwnedStage < older.b2OwnedStage ||
        !completedSourceIds.containsAll(older.completedSourceIds) ||
        !reviewedSourceIds.containsAll(older.reviewedSourceIds)) {
      return false;
    }
    for (final entry in older.claims.entries) {
      if (claims[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  int eligibleStage(YeopjeonBuilding building) =>
      building == YeopjeonBuilding.sarangchae
      ? sarangchaeEligibleStage
      : b2EligibleStage;

  int ownedStage(YeopjeonBuilding building) =>
      building == YeopjeonBuilding.sarangchae
      ? sarangchaeOwnedStage
      : b2OwnedStage;

  int get nextConstructionGoal =>
      sarangchaeOwnedStage < sarangchaeEligibleStage ||
          b2OwnedStage < b2EligibleStage
      ? nextConstructionCost
      : 0;

  factory YeopjeonWallet.grandfather({
    required int sarangchaeStage,
    required int b2Stage,
  }) => YeopjeonWallet(
    balance: 0,
    sarangchaeEligibleStage: sarangchaeStage,
    b2EligibleStage: b2Stage,
    sarangchaeOwnedStage: sarangchaeStage,
    b2OwnedStage: b2Stage,
    grandfatheredSarangchaeStage: sarangchaeStage,
    grandfatheredB2Stage: b2Stage,
    claims: const {},
    completedSourceIds: const {},
    reviewedSourceIds: const {},
  );

  YeopjeonWallet copyWith({
    int? balance,
    int? sarangchaeEligibleStage,
    int? b2EligibleStage,
    int? sarangchaeOwnedStage,
    int? b2OwnedStage,
    Map<String, int>? claims,
    Set<String>? completedSourceIds,
    Set<String>? reviewedSourceIds,
  }) => YeopjeonWallet(
    balance: balance ?? this.balance,
    sarangchaeEligibleStage:
        sarangchaeEligibleStage ?? this.sarangchaeEligibleStage,
    b2EligibleStage: b2EligibleStage ?? this.b2EligibleStage,
    sarangchaeOwnedStage: sarangchaeOwnedStage ?? this.sarangchaeOwnedStage,
    b2OwnedStage: b2OwnedStage ?? this.b2OwnedStage,
    grandfatheredSarangchaeStage: grandfatheredSarangchaeStage,
    grandfatheredB2Stage: grandfatheredB2Stage,
    claims: claims ?? this.claims,
    completedSourceIds: completedSourceIds ?? this.completedSourceIds,
    reviewedSourceIds: reviewedSourceIds ?? this.reviewedSourceIds,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'balance': balance,
    'sarangchaeEligibleStage': sarangchaeEligibleStage,
    'b2EligibleStage': b2EligibleStage,
    'sarangchaeOwnedStage': sarangchaeOwnedStage,
    'b2OwnedStage': b2OwnedStage,
    'grandfatheredSarangchaeStage': grandfatheredSarangchaeStage,
    'grandfatheredB2Stage': grandfatheredB2Stage,
    'claims': Map<String, int>.fromEntries(
      claims.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    'completedSourceIds': completedSourceIds.toList()..sort(),
    'reviewedSourceIds': reviewedSourceIds.toList()..sort(),
  };

  String encode() => jsonEncode(toJson());

  factory YeopjeonWallet.decode(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference(const {
          'schemaVersion',
          'balance',
          'sarangchaeEligibleStage',
          'b2EligibleStage',
          'sarangchaeOwnedStage',
          'b2OwnedStage',
          'grandfatheredSarangchaeStage',
          'grandfatheredB2Stage',
          'claims',
          'completedSourceIds',
          'reviewedSourceIds',
        }).isNotEmpty ||
        value.length != 11 ||
        value['schemaVersion'] != schemaVersion ||
        value['claims'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid Yeopjeon wallet schema.');
    }
    final claims = <String, int>{};
    for (final entry in (value['claims'] as Map<String, dynamic>).entries) {
      if (entry.value is! int) {
        throw const FormatException('Invalid Yeopjeon claim amount.');
      }
      claims[entry.key] = entry.value as int;
    }
    Set<String> ids(Object? value) {
      if (value is! List || value.any((item) => item is! String)) {
        throw const FormatException('Invalid Yeopjeon source IDs.');
      }
      final result = value.cast<String>().toSet();
      if (result.length != value.length) {
        throw const FormatException('Duplicate Yeopjeon source ID.');
      }
      return result;
    }

    int number(String key) {
      final valueAtKey = value[key];
      if (valueAtKey is! int) {
        throw const FormatException('Invalid Yeopjeon stage or balance.');
      }
      return valueAtKey;
    }

    return YeopjeonWallet(
      balance: number('balance'),
      sarangchaeEligibleStage: number('sarangchaeEligibleStage'),
      b2EligibleStage: number('b2EligibleStage'),
      sarangchaeOwnedStage: number('sarangchaeOwnedStage'),
      b2OwnedStage: number('b2OwnedStage'),
      grandfatheredSarangchaeStage: number('grandfatheredSarangchaeStage'),
      grandfatheredB2Stage: number('grandfatheredB2Stage'),
      claims: claims,
      completedSourceIds: ids(value['completedSourceIds']),
      reviewedSourceIds: ids(value['reviewedSourceIds']),
    );
  }

  void _validate() {
    if (balance < 0 ||
        sarangchaeEligibleStage < 0 ||
        sarangchaeEligibleStage > SarangchaeConstruction.stageCount ||
        b2EligibleStage < 0 ||
        b2EligibleStage > b2ConstructionStageCount ||
        grandfatheredSarangchaeStage < 0 ||
        grandfatheredSarangchaeStage > sarangchaeOwnedStage ||
        sarangchaeOwnedStage > sarangchaeEligibleStage ||
        grandfatheredB2Stage < 0 ||
        grandfatheredB2Stage > b2OwnedStage ||
        b2OwnedStage > b2EligibleStage) {
      throw const FormatException('Invalid Yeopjeon ownership.');
    }
    var earned = 0;
    final daily = <String, Set<String>>{};
    var completionClaims = 0;
    var reviewClaims = 0;
    for (final entry in claims.entries) {
      final key = entry.key;
      final amount = entry.value;
      if (key.startsWith('milestone:s:')) {
        final stage = int.tryParse(key.substring('milestone:s:'.length));
        if (amount != nextConstructionCost ||
            stage == null ||
            key != 'milestone:s:$stage' ||
            stage <= grandfatheredSarangchaeStage ||
            stage > sarangchaeEligibleStage) {
          throw const FormatException('Invalid Sarangchae grant.');
        }
      } else if (key.startsWith('milestone:b:')) {
        final stage = int.tryParse(key.substring('milestone:b:'.length));
        if (amount != nextConstructionCost ||
            stage == null ||
            key != 'milestone:b:$stage' ||
            stage <= grandfatheredB2Stage ||
            stage > b2EligibleStage) {
          throw const FormatException('Invalid B2 grant.');
        }
      } else if (RegExp(
        r'^daily:\d{4}-\d{2}-\d{2}:(first|second|review)$',
      ).hasMatch(key)) {
        final parts = key.split(':');
        final day = parts[1];
        final kind = parts[2];
        if (DateTime.tryParse(day)?.toIso8601String().substring(0, 10) != day ||
            amount != (kind == 'first' ? 20 : 10) ||
            !daily.putIfAbsent(day, () => {}).add(kind)) {
          throw const FormatException('Invalid daily grant.');
        }
        if (kind == 'review') {
          reviewClaims++;
        } else {
          completionClaims++;
        }
      } else {
        throw const FormatException('Unknown Yeopjeon claim source.');
      }
      earned += amount;
    }
    for (final kinds in daily.values) {
      if (kinds.contains('second') && !kinds.contains('first')) {
        throw const FormatException(
          'Second objective without first completion.',
        );
      }
    }
    for (
      var stage = grandfatheredSarangchaeStage + 1;
      stage <= sarangchaeEligibleStage;
      stage++
    ) {
      if (claims['milestone:s:$stage'] != nextConstructionCost) {
        throw const FormatException('Missing Sarangchae stage grant.');
      }
    }
    for (
      var stage = grandfatheredB2Stage + 1;
      stage <= b2EligibleStage;
      stage++
    ) {
      if (claims['milestone:b:$stage'] != nextConstructionCost) {
        throw const FormatException('Missing B2 stage grant.');
      }
    }
    if (completionClaims > completedSourceIds.length ||
        reviewClaims > reviewedSourceIds.length) {
      throw const FormatException('Unbacked Yeopjeon daily claim.');
    }
    for (final id in completedSourceIds) {
      if (!(id.startsWith('unit:') && id.length > 5 ||
          id.startsWith('lesson:') && id.length > 7)) {
        throw const FormatException('Invalid Yeopjeon completion source.');
      }
    }
    for (final id in {...completedSourceIds, ...reviewedSourceIds}) {
      if (id.isEmpty || id.length > 256 || id.trim() != id) {
        throw const FormatException('Invalid Yeopjeon evidence source.');
      }
    }
    final spent =
        nextConstructionCost *
        ((sarangchaeOwnedStage - grandfatheredSarangchaeStage) +
            (b2OwnedStage - grandfatheredB2Stage));
    if (earned - spent != balance) {
      throw const FormatException('Yeopjeon balance does not reconcile.');
    }
  }
}
