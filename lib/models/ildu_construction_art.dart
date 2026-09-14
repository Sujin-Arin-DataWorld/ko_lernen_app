import 'dart:convert';

import 'package:flutter/services.dart';

typedef IlDuArtText = Map<String, String>;

const _approvedStageCounts = {
  'hyeopmun': 6,
  'changgo': 8,
  'jungmunganchae': 12,
  'araechae': 12,
  'anchae': 14,
  'anchae-store': 11,
  'ansarangchae': 14,
  'sadangmun': 8,
  'sadang': 12,
};

const _approvedMapAnchors = {
  'ansarangchae': 'ansarang',
  'sadangmun': 'sadang-gate',
  'sadang': 'sadang',
};

String ilduArtText(IlDuArtText text, String language) =>
    text[language] ?? text['en']!;

const b2ConstructionStageCount = 34;
const b2ConstructionSeriesIds = <String>['ansarangchae', 'sadangmun', 'sadang'];

/// Projects the verified B2 completion fraction onto the approved 34-stage
/// sequence. The ratio itself comes from current curriculum units and durable
/// completion evidence; this function adds no counter or persistence.
int ilduB2ConstructionStageForRatio(double ratio) {
  if (!ratio.isFinite || ratio <= 0) {
    return 0;
  }
  if (ratio >= 1) {
    return b2ConstructionStageCount;
  }
  return (ratio * b2ConstructionStageCount + 1e-9).floor();
}

final class IlDuConstructionArtCatalog {
  const IlDuConstructionArtCatalog(this.series);

  static const assetPath = 'assets/data/ildu_construction_art_v1.json';
  final List<IlDuConstructionArtSeries> series;

  List<IlDuConstructionArtReveal> b2RevealsBetween({
    required int before,
    required int after,
  }) {
    final start = before.clamp(0, b2ConstructionStageCount);
    final finish = after.clamp(0, b2ConstructionStageCount);
    if (finish <= start) {
      return const [];
    }
    final byId = {for (final item in series) item.id: item};
    final reveals = <IlDuConstructionArtReveal>[];
    var offset = 0;
    for (final id in b2ConstructionSeriesIds) {
      final item = byId[id];
      if (item == null) {
        throw const FormatException('B2 construction series is missing.');
      }
      final localBefore = (start - offset).clamp(0, item.stages.length);
      final localAfter = (finish - offset).clamp(0, item.stages.length);
      if (localAfter > localBefore) {
        reveals.add(
          IlDuConstructionArtReveal(
            series: item,
            beforeSequence: localBefore,
            afterSequence: localAfter,
          ),
        );
      }
      offset += item.stages.length;
    }
    if (offset != b2ConstructionStageCount) {
      throw const FormatException('B2 construction stage count is invalid.');
    }
    return List.unmodifiable(reveals);
  }

  static Future<IlDuConstructionArtCatalog> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return IlDuConstructionArtCatalog.fromJson(jsonDecode(raw));
  }

  factory IlDuConstructionArtCatalog.fromJson(Object? value) {
    final json = _object(value);
    if (json['schemaVersion'] != 1 || json['status'] != 'approved_canonical') {
      throw const FormatException('Unsupported construction art catalog.');
    }
    final series = _array(
      json['series'],
    ).map(IlDuConstructionArtSeries.fromJson).toList(growable: false);
    final ids = series.map((item) => item.id).toSet();
    if (series.length != _approvedStageCounts.length ||
        ids.length != _approvedStageCounts.length ||
        !ids.containsAll(_approvedStageCounts.keys)) {
      throw const FormatException(
        'Expected all nine approved building series.',
      );
    }
    return IlDuConstructionArtCatalog(List.unmodifiable(series));
  }
}

final class IlDuConstructionArtReveal {
  const IlDuConstructionArtReveal({
    required this.series,
    required this.beforeSequence,
    required this.afterSequence,
  });

  final IlDuConstructionArtSeries series;
  final int beforeSequence;
  final int afterSequence;

  IlDuConstructionArtStage? get beforeStage =>
      beforeSequence == 0 ? null : series.stages[beforeSequence - 1];
  IlDuConstructionArtStage get afterStage => series.stages[afterSequence - 1];
}

final class IlDuConstructionArtSeries {
  const IlDuConstructionArtSeries({
    required this.id,
    required this.mapAnchorId,
    required this.name,
    required this.culture,
    required this.stages,
  });

  final String id;
  final String mapAnchorId;
  final IlDuArtText name;
  final IlDuArtText culture;
  final List<IlDuConstructionArtStage> stages;

  factory IlDuConstructionArtSeries.fromJson(Object? value) {
    final json = _object(value);
    final id = _text(json['buildingId']);
    final count = _approvedStageCounts[id];
    if (count == null) {
      throw const FormatException('Unknown construction building.');
    }
    final mapAnchorId = _text(json['mapAnchorId'] ?? id);
    final approvedMapAnchor = _approvedMapAnchors[id];
    if (approvedMapAnchor != null && mapAnchorId != approvedMapAnchor) {
      throw const FormatException(
        'Construction building map anchor is invalid.',
      );
    }
    final stages = _array(json['stages'])
        .map((stage) => IlDuConstructionArtStage.fromJson(stage, id))
        .toList(growable: false);
    if (stages.length != count ||
        stages.map((s) => s.id).toSet().length != count) {
      throw const FormatException(
        'Construction stages are missing or repeated.',
      );
    }
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].sequence != i + 1) {
        throw const FormatException('Construction stages are out of order.');
      }
    }
    if (stages.last.asset != json['canonicalAsset'] ||
        stages.last.sha256 != json['canonicalSha256']) {
      throw const FormatException(
        'The final stage must be the canonical image.',
      );
    }
    return IlDuConstructionArtSeries(
      id: id,
      mapAnchorId: mapAnchorId,
      name: _translated(json['name']),
      culture: _translated(json['culture']),
      stages: List.unmodifiable(stages),
    );
  }
}

final class IlDuConstructionArtStage {
  const IlDuConstructionArtStage({
    required this.id,
    required this.sequence,
    required this.asset,
    required this.sha256,
    required this.width,
    required this.height,
    required this.title,
    required this.observe,
    required this.line,
    required this.scene,
    required this.task,
    required this.options,
    required this.correctOptionId,
    required this.glossary,
    this.lessonIllustration,
  });

  final String id;
  final int sequence;
  final String asset;
  final String sha256;
  final int width;
  final int height;
  final IlDuArtText title;
  final IlDuArtText observe;
  final IlDuArtText line;
  final IlDuArtText scene;
  final IlDuArtText task;
  final Map<String, IlDuArtText> options;
  final String? correctOptionId;
  final List<({IlDuArtText label, IlDuArtText explanation})> glossary;
  final IlDuLessonIllustration? lessonIllustration;

  factory IlDuConstructionArtStage.fromJson(Object? value, String buildingId) {
    final json = _object(value);
    final asset = _text(json['asset']);
    final prefix =
        'assets/illustrations/personal_hanok_v3/construction/$buildingId/';
    if (!asset.startsWith(prefix) ||
        !RegExp(
          r'^stage_[0-9]{2}_[a-z_]+\.(png|webp)$',
        ).hasMatch(asset.substring(prefix.length))) {
      throw const FormatException('Stage image must be a bundled PNG or WebP.');
    }
    final hash = _text(json['sha256']);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw const FormatException('Stage image must have a SHA-256 hash.');
    }
    final exercise = _object(json['exercise']);
    final options = <String, IlDuArtText>{};
    String? correct;
    if (exercise['kind'] == 'choice') {
      for (final value in _array(exercise['options'])) {
        final option = _object(value);
        final id = _text(option['id']);
        if (options.containsKey(id)) {
          throw const FormatException('Repeated construction option.');
        }
        options[id] = _translated(option['label']);
      }
      correct = _text(exercise['correctOptionId']);
      if (options.length < 2 || !options.containsKey(correct)) {
        throw const FormatException('Construction answer is missing.');
      }
    } else if (exercise['kind'] != 'spoken_request_or_suggestion' &&
        exercise['kind'] != 'spoken_description') {
      throw const FormatException('Unsupported construction exercise.');
    }
    return IlDuConstructionArtStage(
      id: _text(json['stageId']),
      sequence: _positive(json['sequence']),
      asset: asset,
      sha256: hash,
      width: _positive(json['width']),
      height: _positive(json['height']),
      title: _translated(json['title']),
      observe: _translated(json['observe']),
      line: _translated(json['line']),
      scene: _translated(json['scene']),
      task: _translated(json['task']),
      options: Map.unmodifiable(options),
      correctOptionId: correct,
      lessonIllustration: json['lessonIllustration'] == null
          ? null
          : IlDuLessonIllustration.fromJson(json['lessonIllustration']),
      glossary: List.unmodifiable([
        for (final item in _array(json['glossary']))
          (
            label: _translated(_object(item)['label']),
            explanation: _translated(_object(item)['explanation']),
          ),
      ]),
    );
  }
}

final class IlDuLessonIllustration {
  const IlDuLessonIllustration(this.asset, this.caption, this.alt);

  final String asset;
  final IlDuArtText caption;
  final IlDuArtText alt;

  factory IlDuLessonIllustration.fromJson(Object? value) {
    final json = _object(value);
    final asset = _text(json['asset']);
    if (!RegExp(
      r'^assets/illustrations/personal_hanok_v3/construction/lessons/[a-z_]+\.webp$',
    ).hasMatch(asset)) {
      throw const FormatException(
        'Lesson illustration must be a bundled WebP.',
      );
    }
    return IlDuLessonIllustration(
      asset,
      _translated(json['caption']),
      _translated(json['alt']),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Construction data must be an object.');
  }
  return value;
}

List<dynamic> _array(Object? value) {
  if (value is! List<dynamic>) {
    throw const FormatException('Construction data must be an array.');
  }
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Construction text is missing.');
  }
  return value;
}

int _positive(Object? value) {
  if (value is! int || value <= 0) {
    throw const FormatException(
      'Construction dimension or sequence is invalid.',
    );
  }
  return value;
}

IlDuArtText _translated(Object? value) {
  final json = _object(value);
  return Map.unmodifiable({
    for (final language in const ['ko', 'en', 'de'])
      language: _text(json[language]),
  });
}
