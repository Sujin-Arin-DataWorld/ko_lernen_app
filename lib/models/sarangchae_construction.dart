import 'dart:convert';

import 'package:flutter/services.dart';

/// The approved artwork sequence. Learning evidence, never this catalog,
/// determines which stage a learner owns.
final class SarangchaeConstruction {
  const SarangchaeConstruction._(this.stages);

  static const assetPath = 'assets/data/sarangchae_construction_v3.json';
  static const canonicalSha256 =
      'f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a';
  static const stageCount = 16;
  final List<SarangchaeConstructionStage> stages;

  static Future<SarangchaeConstruction> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return SarangchaeConstruction.fromJson(jsonDecode(raw));
  }

  factory SarangchaeConstruction.fromJson(dynamic json) {
    if (json is! Map ||
        json['id'] != 'sarangchae-v3-16' ||
        json['canonicalSha256'] != canonicalSha256 ||
        json['completedStage'] != stageCount ||
        json['stages'] is! List ||
        (json['stages'] as List).length != stageCount) {
      throw const FormatException('Invalid approved Sarangchae catalog.');
    }
    final stages = <SarangchaeConstructionStage>[];
    final ids = <String>{};
    for (final item in json['stages'] as List) {
      final stage = SarangchaeConstructionStage.fromJson(item);
      if (stage.sequence != stages.length + 1 || !ids.add(stage.stageId)) {
        throw const FormatException('Invalid Sarangchae stage order.');
      }
      stages.add(stage);
    }
    if (stages.last.sha256 != canonicalSha256 ||
        stages.last.stageId != 'sarangchae-complete') {
      throw const FormatException('Stage 16 must be the approved original.');
    }
    return SarangchaeConstruction._(List.unmodifiable(stages));
  }

  SarangchaeConstructionStage stage(int sequence) => stages[sequence - 1];
}

final class SarangchaeConstructionStage {
  SarangchaeConstructionStage.fromJson(dynamic json)
    : stageId = json['stageId'] as String,
      sequence = json['sequence'] as int,
      assetPath = json['assetPath'] as String,
      sha256 = json['sha256'] as String,
      term = json['term'] as String,
      _copy = Map<String, dynamic>.unmodifiable(json as Map) {
    const artworkDirectory =
        'assets/illustrations/personal_hanok_v3/sarangchae/';
    if (!assetPath.startsWith(artworkDirectory) ||
        !RegExp(
          r'^stage_\d{2}_[a-z_]+\.png$',
        ).hasMatch(assetPath.substring(artworkDirectory.length))) {
      throw const FormatException('Invalid Sarangchae artwork path.');
    }
    for (final field in [
      'gloss',
      'chapter',
      'title',
      'question',
      'body',
      'caption',
    ]) {
      for (final language in ['ko', 'en', 'de']) {
        final text = (_copy[field] as Map?)?[language];
        if (text is! String || text.trim().isEmpty) {
          throw FormatException('Missing $field in $language.');
        }
      }
    }
  }

  final String stageId;
  final int sequence;
  final String assetPath;
  final String sha256;
  final String term;
  final Map<String, dynamic> _copy;

  String text(String field, String languageCode) =>
      (_copy[field] as Map)[['ko', 'de'].contains(languageCode)
              ? languageCode
              : 'en']
          as String;
}
