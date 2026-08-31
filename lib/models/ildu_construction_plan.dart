import 'dart:ui' show Size;

enum IlDuProcessTag {
  site,
  foundation,
  framePosts,
  frameBeams,
  raftersSanja,
  roofBed,
  roofTiles,
  floorNumaru,
  wallInfill,
  doorsChangho,
  identityFinish,
  complete;

  static IlDuProcessTag parse(Object? value, String path) {
    if (value is! String) {
      throw FormatException('$path must be a process tag.');
    }
    return values.firstWhere(
      (tag) => tag.name == value,
      orElse: () => throw FormatException('$path has an unknown process tag.'),
    );
  }
}

final class IlDuConstructionStage {
  const IlDuConstructionStage({
    required this.stageId,
    required this.sequence,
    required this.processTags,
    required this.baseAsset,
    required this.overlayAssets,
    required this.requiredModuleIds,
    required this.optionalModuleIds,
    required this.completionEffect,
    required this.fallbackStageId,
  });

  final String stageId;
  final int sequence;
  final List<IlDuProcessTag> processTags;
  final String baseAsset;
  final List<String> overlayAssets;
  final List<String> requiredModuleIds;
  final List<String> optionalModuleIds;
  final String completionEffect;
  final String? fallbackStageId;

  factory IlDuConstructionStage.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final fallback = json['fallbackStageId'];
    return IlDuConstructionStage(
      stageId: _id(json['stageId'], '$path.stageId'),
      sequence: _positiveInt(json['sequence'], '$path.sequence'),
      processTags: _decodeList(
        json['processTags'],
        '$path.processTags',
        IlDuProcessTag.parse,
      ),
      baseAsset: _assetName(json['baseAsset'], '$path.baseAsset'),
      overlayAssets: _stringList(
        json['overlayAssets'],
        '$path.overlayAssets',
        allowEmpty: true,
        validator: _assetName,
      ),
      requiredModuleIds: _idList(
        json['requiredModuleIds'],
        '$path.requiredModuleIds',
      ),
      optionalModuleIds: _idList(
        json['optionalModuleIds'],
        '$path.optionalModuleIds',
        allowEmpty: true,
      ),
      completionEffect: _nonEmptyString(
        json['completionEffect'],
        '$path.completionEffect',
      ),
      fallbackStageId: fallback == null
          ? null
          : _id(fallback, '$path.fallbackStageId'),
    );
  }
}

final class IlDuSpeechBrief {
  const IlDuSpeechBrief({
    required this.scene,
    required this.channel,
    required this.purpose,
    required this.speaker,
    required this.addressee,
    required this.relationship,
    required this.speechStyle,
    required this.speechAct,
    required this.knownFacts,
    required this.unresolvedFacts,
    required this.forbiddenInvention,
  });

  final String scene;
  final String channel;
  final String purpose;
  final String speaker;
  final String addressee;
  final String relationship;
  final String speechStyle;
  final String speechAct;
  final List<String> knownFacts;
  final List<String> unresolvedFacts;
  final List<String> forbiddenInvention;

  factory IlDuSpeechBrief.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuSpeechBrief(
      scene: _nonEmptyString(json['scene'], '$path.scene'),
      channel: _nonEmptyString(json['channel'], '$path.channel'),
      purpose: _nonEmptyString(json['purpose'], '$path.purpose'),
      speaker: _nonEmptyString(json['speaker'], '$path.speaker'),
      addressee: _nonEmptyString(json['addressee'], '$path.addressee'),
      relationship: _nonEmptyString(json['relationship'], '$path.relationship'),
      speechStyle: _nonEmptyString(json['speechStyle'], '$path.speechStyle'),
      speechAct: _nonEmptyString(json['speechAct'], '$path.speechAct'),
      knownFacts: _plainStringList(json['knownFacts'], '$path.knownFacts'),
      unresolvedFacts: _plainStringList(
        json['unresolvedFacts'],
        '$path.unresolvedFacts',
      ),
      forbiddenInvention: _plainStringList(
        json['forbiddenInvention'],
        '$path.forbiddenInvention',
      ),
    );
  }
}

final class IlDuLearningCriterion {
  const IlDuLearningCriterion({
    required this.id,
    required this.kind,
    required this.acceptedVariants,
    required this.requiredForCompletion,
  });

  final String id;
  final String kind;
  final List<String> acceptedVariants;
  final bool requiredForCompletion;

  factory IlDuLearningCriterion.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final kind = _nonEmptyString(json['kind'], '$path.kind');
    if (!const {
      'meaningSlot',
      'tokenSequence',
      'sentenceEnding',
    }.contains(kind)) {
      throw FormatException('$path.kind is unsupported.');
    }
    return IlDuLearningCriterion(
      id: _id(json['id'], '$path.id'),
      kind: kind,
      acceptedVariants: _plainStringList(
        json['acceptedVariants'],
        '$path.acceptedVariants',
      ),
      requiredForCompletion: _boolean(
        json['requiredForCompletion'],
        '$path.requiredForCompletion',
      ),
    );
  }
}

final class IlDuLearningCopy {
  const IlDuLearningCopy({
    required this.title,
    required this.history,
    required this.criticalLens,
    required this.modernScene,
    required this.sceneLine,
    required this.actionPrompt,
  });

  final String title;
  final String history;
  final String criticalLens;
  final String modernScene;
  final String sceneLine;
  final String actionPrompt;

  factory IlDuLearningCopy.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuLearningCopy(
      title: _nonEmptyString(json['title'], '$path.title'),
      history: _nonEmptyString(json['history'], '$path.history'),
      criticalLens: _nonEmptyString(json['criticalLens'], '$path.criticalLens'),
      modernScene: _nonEmptyString(json['modernScene'], '$path.modernScene'),
      sceneLine: _nonEmptyString(json['sceneLine'], '$path.sceneLine'),
      actionPrompt: _nonEmptyString(json['actionPrompt'], '$path.actionPrompt'),
    );
  }
}

final class IlDuLearningModule {
  const IlDuLearningModule({
    required this.moduleId,
    required this.sourceRefs,
    required this.levelBand,
    required this.knowledgeLenses,
    required this.copyByLanguage,
    required this.speechBrief,
    required this.targetExpressions,
    required this.acceptedVariants,
    required this.criteria,
    required this.scoredDimensions,
    required this.hanja,
  });

  final String moduleId;
  final List<Uri> sourceRefs;
  final List<String> levelBand;
  final List<String> knowledgeLenses;
  final Map<String, IlDuLearningCopy> copyByLanguage;
  final IlDuSpeechBrief speechBrief;
  final List<String> targetExpressions;
  final List<String> acceptedVariants;
  final List<IlDuLearningCriterion> criteria;
  final Set<String> scoredDimensions;
  final List<String> hanja;

  factory IlDuLearningModule.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final copyJson = _map(json['copy'], '$path.copy');
    const languages = {'ko', 'de', 'en'};
    if (!copyJson.keys.toSet().containsAll(languages)) {
      throw FormatException('$path.copy must contain ko, de, and en.');
    }
    final sources = _plainStringList(json['sourceRefs'], '$path.sourceRefs')
        .map((source) {
          final uri = Uri.tryParse(source);
          if (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              !uri.hasAbsolutePath) {
            throw FormatException('$path.sourceRefs must contain HTTPS URLs.');
          }
          return uri;
        })
        .toList(growable: false);
    final criteria = _decodeList(
      json['criteria'],
      '$path.criteria',
      IlDuLearningCriterion.fromJson,
    );
    _requireUnique(criteria.map((criterion) => criterion.id), '$path.criteria');
    return IlDuLearningModule(
      moduleId: _id(json['moduleId'], '$path.moduleId'),
      sourceRefs: List.unmodifiable(sources),
      levelBand: _idList(json['levelBand'], '$path.levelBand'),
      knowledgeLenses: _idList(
        json['knowledgeLenses'],
        '$path.knowledgeLenses',
      ),
      copyByLanguage: Map.unmodifiable({
        for (final language in languages)
          language: IlDuLearningCopy.fromJson(
            copyJson[language],
            '$path.copy.$language',
          ),
      }),
      speechBrief: IlDuSpeechBrief.fromJson(
        json['speechBrief'],
        '$path.speechBrief',
      ),
      targetExpressions: _plainStringList(
        json['targetExpressions'],
        '$path.targetExpressions',
      ),
      acceptedVariants: _plainStringList(
        json['acceptedVariants'],
        '$path.acceptedVariants',
      ),
      criteria: criteria,
      scoredDimensions: Set.unmodifiable(
        _plainStringList(json['scoredDimensions'], '$path.scoredDimensions'),
      ),
      hanja: json.containsKey('hanja')
          ? _plainStringList(json['hanja'], '$path.hanja')
          : const [],
    );
  }

  IlDuLearningCopy copyFor(String languageCode) =>
      copyByLanguage[languageCode] ?? copyByLanguage['en']!;
}

final class IlDuBuildingConstructionPlan {
  const IlDuBuildingConstructionPlan({
    required this.buildingId,
    required this.planVersion,
    required this.canonicalAsset,
    required this.canonicalSha256,
    required this.buildingRole,
    required this.culturalMeaning,
    required this.stages,
  });

  final String buildingId;
  final String planVersion;
  final String canonicalAsset;
  final String canonicalSha256;
  final String buildingRole;
  final String culturalMeaning;
  final List<IlDuConstructionStage> stages;

  factory IlDuBuildingConstructionPlan.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final stages = _decodeList(
      json['stages'],
      '$path.stages',
      IlDuConstructionStage.fromJson,
    );
    _requireUnique(stages.map((stage) => stage.stageId), '$path.stages');
    for (var index = 0; index < stages.length; index++) {
      final stage = stages[index];
      if (stage.sequence != index + 1) {
        throw FormatException('$path.stages must use increasing sequences.');
      }
      final fallback = stage.fallbackStageId;
      if (fallback != null &&
          !stages
              .take(index)
              .any((candidate) => candidate.stageId == fallback)) {
        throw FormatException(
          '$path.stages[$index].fallbackStageId must reference an earlier stage.',
        );
      }
    }
    final sha = _nonEmptyString(
      json['canonicalSha256'],
      '$path.canonicalSha256',
    ).toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha)) {
      throw FormatException('$path.canonicalSha256 must be SHA-256.');
    }
    return IlDuBuildingConstructionPlan(
      buildingId: _id(json['buildingId'], '$path.buildingId'),
      planVersion: _id(json['planVersion'], '$path.planVersion'),
      canonicalAsset: _assetName(
        json['canonicalAsset'],
        '$path.canonicalAsset',
      ),
      canonicalSha256: sha,
      buildingRole: _nonEmptyString(json['buildingRole'], '$path.buildingRole'),
      culturalMeaning: _nonEmptyString(
        json['culturalMeaning'],
        '$path.culturalMeaning',
      ),
      stages: stages,
    );
  }

  IlDuConstructionStage stageFor(String stageId) =>
      stages.firstWhere((stage) => stage.stageId == stageId);
}

final class IlDuEstateConstructionPlan {
  const IlDuEstateConstructionPlan({
    required this.estateId,
    required this.planVersion,
    required this.canvas,
    required this.viewport,
    required this.siteStageIds,
    required this.buildingOrder,
    required this.buildings,
    required this.modules,
  });

  final String estateId;
  final String planVersion;
  final Size canvas;
  final Size viewport;
  final List<String> siteStageIds;
  final List<String> buildingOrder;
  final List<IlDuBuildingConstructionPlan> buildings;
  final List<IlDuLearningModule> modules;

  factory IlDuEstateConstructionPlan.fromJson(Object? value) {
    final json = _map(value, r'$');
    if (json['schemaVersion'] != 1 ||
        json['estateId'] != 'ildu-gotaek-v3' ||
        json['planVersion'] != 'sarangchae-v1') {
      throw const FormatException('Unsupported Ildu construction plan.');
    }
    final canvas = _lockedSize(json['canvas'], r'$.canvas', 2412, 2622);
    final viewport = _lockedSize(json['viewport'], r'$.viewport', 1206, 2622);
    final buildings = _decodeList(
      json['buildings'],
      r'$.buildings',
      IlDuBuildingConstructionPlan.fromJson,
    );
    final modules = _decodeList(
      json['modules'],
      r'$.modules',
      IlDuLearningModule.fromJson,
    );
    _requireUnique(
      buildings.map((building) => building.buildingId),
      r'$.buildings',
    );
    _requireUnique(modules.map((module) => module.moduleId), r'$.modules');

    final buildingOrder = _idList(json['buildingOrder'], r'$.buildingOrder');
    final buildingIds = buildings
        .map((building) => building.buildingId)
        .toSet();
    if (buildingOrder.length != buildings.length ||
        buildingOrder.toSet().length != buildingOrder.length ||
        !buildingOrder.every(buildingIds.contains)) {
      throw const FormatException('Building order must cover every building.');
    }

    final stageIds = buildings
        .expand((building) => building.stages)
        .map((stage) => stage.stageId)
        .toList(growable: false);
    _requireUnique(stageIds, r'$.buildings[*].stages');
    final siteStageIds = _idList(json['siteStageIds'], r'$.siteStageIds');
    if (!siteStageIds.every(stageIds.toSet().contains)) {
      throw const FormatException('Site stage references an unknown stage.');
    }

    final moduleIds = modules.map((module) => module.moduleId).toSet();
    for (final building in buildings) {
      if (building.planVersion != json['planVersion']) {
        throw FormatException(
          'Building ${building.buildingId} uses another plan version.',
        );
      }
      for (final stage in building.stages) {
        final refs = [...stage.requiredModuleIds, ...stage.optionalModuleIds];
        if (!refs.every(moduleIds.contains)) {
          throw FormatException(
            'Stage ${stage.stageId} references an unknown module.',
          );
        }
      }
    }

    return IlDuEstateConstructionPlan(
      estateId: json['estateId']! as String,
      planVersion: json['planVersion']! as String,
      canvas: canvas,
      viewport: viewport,
      siteStageIds: siteStageIds,
      buildingOrder: buildingOrder,
      buildings: buildings,
      modules: modules,
    );
  }

  IlDuBuildingConstructionPlan buildingFor(String buildingId) =>
      buildings.firstWhere((building) => building.buildingId == buildingId);

  IlDuConstructionStage stageFor(String stageId) => buildings
      .expand((building) => building.stages)
      .firstWhere((stage) => stage.stageId == stageId);

  IlDuLearningModule moduleFor(String moduleId) =>
      modules.firstWhere((module) => module.moduleId == moduleId);
}

typedef _Decoder<T> = T Function(Object? value, String path);
typedef _StringValidator = String Function(Object? value, String path);

List<T> _decodeList<T>(Object? value, String path, _Decoder<T> decoder) {
  if (value is! List || value.isEmpty) {
    throw FormatException('$path must be a nonempty array.');
  }
  return List<T>.unmodifiable([
    for (var index = 0; index < value.length; index++)
      decoder(value[index], '$path[$index]'),
  ]);
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return value.map((key, item) {
    if (key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    return MapEntry(key, item);
  });
}

Size _lockedSize(
  Object? value,
  String path,
  int requiredWidth,
  int requiredHeight,
) {
  final json = _map(value, path);
  final width = _positiveInt(json['width'], '$path.width');
  final height = _positiveInt(json['height'], '$path.height');
  if (width != requiredWidth || height != requiredHeight) {
    throw FormatException('$path does not match the locked geometry.');
  }
  return Size(width.toDouble(), height.toDouble());
}

int _positiveInt(Object? value, String path) {
  if (value is! int || value <= 0) {
    throw FormatException('$path must be a positive integer.');
  }
  return value;
}

bool _boolean(Object? value, String path) {
  if (value is! bool) {
    throw FormatException('$path must be a boolean.');
  }
  return value;
}

String _nonEmptyString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path must be a nonempty string.');
  }
  return value.trim();
}

String _id(Object? value, String path) {
  final id = _nonEmptyString(value, path);
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
    throw FormatException('$path must be a lowercase stable ID.');
  }
  return id;
}

String _assetName(Object? value, String path) {
  final asset = _nonEmptyString(value, path);
  if (asset.contains('/') ||
      asset.contains(r'\') ||
      asset == '.' ||
      asset == '..') {
    throw FormatException('$path must be an asset filename.');
  }
  return asset;
}

List<String> _stringList(
  Object? value,
  String path, {
  bool allowEmpty = false,
  required _StringValidator validator,
}) {
  if (value is! List || (!allowEmpty && value.isEmpty)) {
    throw FormatException(
      '$path must be ${allowEmpty ? 'an' : 'a nonempty'} array.',
    );
  }
  final result = <String>[
    for (var index = 0; index < value.length; index++)
      validator(value[index], '$path[$index]'),
  ];
  _requireUnique(result, path);
  return List.unmodifiable(result);
}

List<String> _idList(Object? value, String path, {bool allowEmpty = false}) =>
    _stringList(value, path, allowEmpty: allowEmpty, validator: _id);

List<String> _plainStringList(Object? value, String path) =>
    _stringList(value, path, validator: _nonEmptyString);

void _requireUnique(Iterable<String> values, String path) {
  final items = values.toList(growable: false);
  if (items.toSet().length != items.length) {
    throw FormatException('$path contains duplicate IDs or values.');
  }
}
