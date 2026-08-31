/// 일두고택 V3 가변 건설 플랜 데이터 계약 (Phase 1).
///
/// 2026-08-29 승인 설계(`ildu-variable-construction-cultural-lernpath` §5)의
/// 런타임 이식이다. 단계 수는 `stages[]` 배열 길이가 선언하며, 8·12 같은
/// 숫자를 도메인 의미로 저장하지 않는다. 파서는 fail-closed 로 동작한다 —
/// 계약을 어긴 JSON 은 부분적으로 살리지 않고 [FormatException] 으로 거부한다.
///
/// 이 파일은 순수 Dart 다. Flutter/rootBundle 경계는
/// `lib/services/ildu_construction_plan_repository.dart` 가 담당한다.
library;

/// 모든 건물이 공유하는 공정 어휘. 단계 번호가 아니라 태그가 공통이다.
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

  String get code => name;

  static IlDuProcessTag parse(Object? value, String path) {
    if (value is! String) {
      throw FormatException('$path must be a process tag string.');
    }
    for (final tag in values) {
      if (tag.code == value) {
        return tag;
      }
    }
    throw FormatException('$path has an unknown process tag "$value".');
  }
}

/// 학습 모듈 완료를 인정하는 증거의 종류 (설계 결정 D3).
enum IlDuCompletionEvidenceType {
  /// CanDo 세그먼트 완료가 증거다. `segmentId` 가 반드시 있어야 한다.
  canDoSegment,

  /// 앱 안의 모듈 수행(평가 통과)이 그대로 증거다.
  inApp;

  String get code => name;
}

/// 모듈 하나를 완료로 인정하기 위한 증거 계약.
final class IlDuCompletionEvidence {
  const IlDuCompletionEvidence._({required this.type, this.segmentId});

  const IlDuCompletionEvidence.inApp()
    : type = IlDuCompletionEvidenceType.inApp,
      segmentId = null;

  final IlDuCompletionEvidenceType type;

  /// `canDoSegment` 일 때만 존재하는 CanDo 세그먼트 ID.
  final String? segmentId;

  factory IlDuCompletionEvidence.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final rawType = json['type'];
    if (rawType == IlDuCompletionEvidenceType.inApp.code) {
      if (json.containsKey('segmentId')) {
        throw FormatException('$path.segmentId is not allowed for inApp.');
      }
      return const IlDuCompletionEvidence.inApp();
    }
    if (rawType == IlDuCompletionEvidenceType.canDoSegment.code) {
      return IlDuCompletionEvidence._(
        type: IlDuCompletionEvidenceType.canDoSegment,
        segmentId: _stableId(json['segmentId'], '$path.segmentId'),
      );
    }
    throw FormatException('$path.type has an unknown evidence type.');
  }
}

/// 논리 픽셀 단위의 캔버스/뷰포트 크기. 순수 Dart 유지를 위해
/// `dart:ui` 의 Size 를 쓰지 않는다.
final class IlDuPlanSize {
  const IlDuPlanSize({required this.width, required this.height});

  final double width;
  final double height;

  factory IlDuPlanSize.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuPlanSize(
      width: _positiveNumber(json['width'], '$path.width'),
      height: _positiveNumber(json['height'], '$path.height'),
    );
  }
}

/// 한 건설 단계. 완성까지의 시각 상태 하나와 그 단계를 여는 학습 모듈을 잇는다.
final class IlDuConstructionStage {
  IlDuConstructionStage({
    required this.stageId,
    required this.sequence,
    required Iterable<IlDuProcessTag> processTags,
    required this.baseAsset,
    required Iterable<String> overlayAssets,
    required Iterable<String> requiredModuleIds,
    required Iterable<String> optionalModuleIds,
    required this.completionEffect,
    required this.fallbackStageId,
  }) : processTags = List.unmodifiable(processTags),
       overlayAssets = List.unmodifiable(overlayAssets),
       requiredModuleIds = List.unmodifiable(requiredModuleIds),
       optionalModuleIds = List.unmodifiable(optionalModuleIds);

  final String stageId;
  final int sequence;
  final List<IlDuProcessTag> processTags;
  final String baseAsset;
  final List<String> overlayAssets;
  final List<String> requiredModuleIds;
  final List<String> optionalModuleIds;
  final String completionEffect;

  /// 이 단계 에셋이 없거나 검증에 실패할 때 유지할 **더 이른** 단계.
  /// 첫 단계만 null 이다 (설계 §14: 일반 한옥 대체물 금지).
  final String? fallbackStageId;

  factory IlDuConstructionStage.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final tags = [
      for (final (i, tag) in _list(json['processTags'], '$path.processTags').indexed)
        IlDuProcessTag.parse(tag, '$path.processTags[$i]'),
    ];
    if (tags.isEmpty) {
      throw FormatException('$path.processTags must not be empty.');
    }
    return IlDuConstructionStage(
      stageId: _stableId(json['stageId'], '$path.stageId'),
      sequence: _positiveInt(json['sequence'], '$path.sequence'),
      processTags: tags,
      baseAsset: _pngName(json['baseAsset'], '$path.baseAsset'),
      overlayAssets: [
        for (final (i, overlay)
            in _list(json['overlayAssets'], '$path.overlayAssets').indexed)
          _pngName(overlay, '$path.overlayAssets[$i]'),
      ],
      requiredModuleIds: _stableIdList(
        json['requiredModuleIds'],
        '$path.requiredModuleIds',
      ),
      optionalModuleIds: _stableIdList(
        json['optionalModuleIds'],
        '$path.optionalModuleIds',
      ),
      completionEffect: _stableId(
        json['completionEffect'],
        '$path.completionEffect',
      ),
      fallbackStageId: json['fallbackStageId'] == null
          ? null
          : _stableId(json['fallbackStageId'], '$path.fallbackStageId'),
    );
  }
}

/// 작성 전에 잠그는 의사소통 사건 브리프 (설계 §8).
final class IlDuSpeechBrief {
  IlDuSpeechBrief({
    required this.scene,
    required this.channel,
    required this.purpose,
    required this.speaker,
    required this.addressee,
    required this.relationship,
    required this.speechStyle,
    required this.speechAct,
    required Iterable<String> knownFacts,
    required Iterable<String> unresolvedFacts,
    required Iterable<String> forbiddenInvention,
  }) : knownFacts = List.unmodifiable(knownFacts),
       unresolvedFacts = List.unmodifiable(unresolvedFacts),
       forbiddenInvention = List.unmodifiable(forbiddenInvention);

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
      knownFacts: _stringList(json['knownFacts'], '$path.knownFacts'),
      unresolvedFacts: _stringList(
        json['unresolvedFacts'],
        '$path.unresolvedFacts',
      ),
      forbiddenInvention: _stringList(
        json['forbiddenInvention'],
        '$path.forbiddenInvention',
      ),
    );
  }
}

/// 평가기가 허용하는 세 가지 저작 기준 종류. 도덕적 입장을 판정하는 종류는
/// 계약상 존재하지 않는다.
enum IlDuLearningCriterionKind {
  meaningSlot,
  tokenSequence,
  sentenceEnding;

  String get code => name;

  static IlDuLearningCriterionKind parse(Object? value, String path) {
    if (value is! String) {
      throw FormatException('$path must be a criterion kind string.');
    }
    for (final kind in values) {
      if (kind.code == value) {
        return kind;
      }
    }
    throw FormatException('$path has an unknown criterion kind "$value".');
  }
}

/// 저작된 언어 증거 기준 하나.
final class IlDuLearningCriterion {
  IlDuLearningCriterion({
    required this.id,
    required this.kind,
    required Iterable<String> acceptedVariants,
    required this.requiredForCompletion,
  }) : acceptedVariants = List.unmodifiable(acceptedVariants);

  final String id;
  final IlDuLearningCriterionKind kind;
  final List<String> acceptedVariants;
  final bool requiredForCompletion;

  factory IlDuLearningCriterion.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final variants = _stringList(
      json['acceptedVariants'],
      '$path.acceptedVariants',
    );
    if (variants.isEmpty) {
      throw FormatException('$path.acceptedVariants must not be empty.');
    }
    final required = json['requiredForCompletion'];
    if (required is! bool) {
      throw FormatException(
        '$path.requiredForCompletion must be a boolean.',
      );
    }
    return IlDuLearningCriterion(
      id: _stableId(json['id'], '$path.id'),
      kind: IlDuLearningCriterionKind.parse(json['kind'], '$path.kind'),
      acceptedVariants: variants,
      requiredForCompletion: required,
    );
  }
}

/// 한 언어의 모듈 본문. 한국어가 의미 정본이고 DE/EN 은 독립 현지화다.
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

/// 채점이 허용되는 유일한 차원들. 학습자의 입장·도덕·가치관(stance 류)은
/// 계약상 채점 차원이 될 수 없다 (설계 §7, §14).
const kIlDuAllowedScoredDimensions = <String>{
  'communicativeFunction',
  'relationshipRegister',
  'targetLanguage',
};

/// 반드시 존재해야 하는 세 언어.
const kIlDuRequiredCopyLanguages = <String>['ko', 'de', 'en'];

/// 건설 단계와 연결되는 학습 모듈 하나.
final class IlDuLearningModule {
  IlDuLearningModule({
    required this.moduleId,
    required Iterable<Uri> sourceRefs,
    required Iterable<String> levelBand,
    required Iterable<String> knowledgeLenses,
    required Iterable<String> hanja,
    required Map<String, IlDuLearningCopy> copyByLanguage,
    required this.speechBrief,
    required Iterable<String> targetExpressions,
    required Iterable<String> acceptedVariants,
    required Iterable<IlDuLearningCriterion> criteria,
    required Set<String> scoredDimensions,
    required this.completionEvidence,
  }) : sourceRefs = List.unmodifiable(sourceRefs),
       levelBand = List.unmodifiable(levelBand),
       knowledgeLenses = List.unmodifiable(knowledgeLenses),
       hanja = List.unmodifiable(hanja),
       copyByLanguage = Map.unmodifiable(copyByLanguage),
       targetExpressions = List.unmodifiable(targetExpressions),
       acceptedVariants = List.unmodifiable(acceptedVariants),
       criteria = List.unmodifiable(criteria),
       scoredDimensions = Set.unmodifiable(scoredDimensions);

  final String moduleId;
  final List<Uri> sourceRefs;
  final List<String> levelBand;
  final List<String> knowledgeLenses;

  /// 현판·명칭에 실제로 존재할 때만 채워지는 한자 목록. 없으면 빈 리스트.
  final List<String> hanja;
  final Map<String, IlDuLearningCopy> copyByLanguage;
  final IlDuSpeechBrief speechBrief;
  final List<String> targetExpressions;
  final List<String> acceptedVariants;
  final List<IlDuLearningCriterion> criteria;
  final Set<String> scoredDimensions;
  final IlDuCompletionEvidence completionEvidence;

  factory IlDuLearningModule.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final moduleId = _stableId(json['moduleId'], '$path.moduleId');

    final sourceRefs = <Uri>[];
    final rawRefs = _list(json['sourceRefs'], '$path.sourceRefs');
    if (rawRefs.isEmpty) {
      throw FormatException('$path.sourceRefs must not be empty.');
    }
    for (final (i, raw) in rawRefs.indexed) {
      final refPath = '$path.sourceRefs[$i]';
      final text = _nonEmptyString(raw, refPath);
      final uri = Uri.tryParse(text);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw FormatException('$refPath must be an HTTPS URL.');
      }
      sourceRefs.add(uri);
    }

    final levelBand = _stringList(json['levelBand'], '$path.levelBand');
    if (levelBand.isEmpty) {
      throw FormatException('$path.levelBand must not be empty.');
    }
    const knownLevels = {'a1', 'a2', 'b1', 'b2', 'c1', 'c2'};
    for (final level in levelBand) {
      if (!knownLevels.contains(level)) {
        throw FormatException('$path.levelBand has an unknown level "$level".');
      }
    }

    final copyJson = _map(json['copy'], '$path.copy');
    final copyByLanguage = <String, IlDuLearningCopy>{};
    for (final language in kIlDuRequiredCopyLanguages) {
      if (!copyJson.containsKey(language)) {
        throw FormatException('$path.copy.$language is required.');
      }
      copyByLanguage[language] = IlDuLearningCopy.fromJson(
        copyJson[language],
        '$path.copy.$language',
      );
    }

    final scoredDimensions = _stringList(
      json['scoredDimensions'],
      '$path.scoredDimensions',
    ).toSet();
    if (scoredDimensions.isEmpty) {
      throw FormatException('$path.scoredDimensions must not be empty.');
    }
    for (final dimension in scoredDimensions) {
      if (!kIlDuAllowedScoredDimensions.contains(dimension)) {
        throw FormatException(
          '$path.scoredDimensions may only contain communicative dimensions; '
          '"$dimension" is not gradable (moral stance is never scored).',
        );
      }
    }

    final criteria = [
      for (final (i, criterion)
          in _list(json['criteria'], '$path.criteria').indexed)
        IlDuLearningCriterion.fromJson(criterion, '$path.criteria[$i]'),
    ];
    if (criteria.isEmpty) {
      throw FormatException('$path.criteria must not be empty.');
    }
    final criterionIds = {for (final criterion in criteria) criterion.id};
    if (criterionIds.length != criteria.length) {
      throw FormatException('$path.criteria has duplicate criterion IDs.');
    }

    final targetExpressions = _stringList(
      json['targetExpressions'],
      '$path.targetExpressions',
    );
    final acceptedVariants = _stringList(
      json['acceptedVariants'],
      '$path.acceptedVariants',
    );
    if (targetExpressions.isEmpty || acceptedVariants.isEmpty) {
      throw FormatException(
        '$path must author targetExpressions and acceptedVariants.',
      );
    }

    return IlDuLearningModule(
      moduleId: moduleId,
      sourceRefs: sourceRefs,
      levelBand: levelBand,
      knowledgeLenses: _stringList(
        json['knowledgeLenses'],
        '$path.knowledgeLenses',
      ),
      hanja: json['hanja'] == null
          ? const <String>[]
          : _stringList(json['hanja'], '$path.hanja'),
      copyByLanguage: copyByLanguage,
      speechBrief: IlDuSpeechBrief.fromJson(
        json['speechBrief'],
        '$path.speechBrief',
      ),
      targetExpressions: targetExpressions,
      acceptedVariants: acceptedVariants,
      criteria: criteria,
      scoredDimensions: scoredDimensions,
      completionEvidence: IlDuCompletionEvidence.fromJson(
        json['completionEvidence'],
        '$path.completionEvidence',
      ),
    );
  }
}

/// 건물 하나의 가변 단계 계획.
final class IlDuBuildingConstructionPlan {
  IlDuBuildingConstructionPlan({
    required this.buildingId,
    required this.planVersion,
    required this.canonicalAsset,
    required this.canonicalSha256,
    required this.buildingRole,
    required this.culturalMeaning,
    required Iterable<IlDuConstructionStage> stages,
  }) : stages = List.unmodifiable(stages) {
    _validateStages();
  }

  final String buildingId;
  final String planVersion;
  final String canonicalAsset;
  final String canonicalSha256;
  final String buildingRole;
  final String culturalMeaning;

  /// 단계 수는 이 배열의 길이가 선언한다 (D2). 협문 4단계, 사랑채 12단계가
  /// 모두 정상이다.
  final List<IlDuConstructionStage> stages;

  IlDuConstructionStage stageFor(String stageId) => stages.firstWhere(
    (stage) => stage.stageId == stageId,
    orElse: () =>
        throw ArgumentError.value(stageId, 'stageId', 'Unknown stage'),
  );

  bool hasStage(String stageId) =>
      stages.any((stage) => stage.stageId == stageId);

  void _validateStages() {
    if (stages.isEmpty) {
      throw FormatException('Building "$buildingId" has no stages.');
    }
    final seen = <String>{};
    var previousSequence = 0;
    for (final (index, stage) in stages.indexed) {
      if (!seen.add(stage.stageId)) {
        throw FormatException(
          'Building "$buildingId" has a duplicate stage ID '
          '"${stage.stageId}".',
        );
      }
      if (stage.sequence <= previousSequence) {
        throw FormatException(
          'Building "$buildingId" stage "${stage.stageId}" breaks the '
          'strictly increasing sequence.',
        );
      }
      previousSequence = stage.sequence;
      if (index == 0) {
        if (stage.fallbackStageId != null) {
          throw FormatException(
            'The first stage of "$buildingId" must not declare a fallback.',
          );
        }
        continue;
      }
      final fallback = stage.fallbackStageId;
      if (fallback == null) {
        throw FormatException(
          'Stage "${stage.stageId}" of "$buildingId" must declare an '
          'earlier fallback stage.',
        );
      }
      final fallbackIndex = stages.indexWhere(
        (candidate) => candidate.stageId == fallback,
      );
      if (fallbackIndex < 0 || fallbackIndex >= index) {
        throw FormatException(
          'Stage "${stage.stageId}" of "$buildingId" falls back to '
          '"$fallback", which is not an earlier stage.',
        );
      }
    }
  }

  /// 건물 파일 하나(`{schemaVersion, building, modules}`)에서 건물 계획과
  /// 그 건물이 가져오는 학습 모듈을 함께 파싱한다 (설계 결정 D1).
  static ({IlDuBuildingConstructionPlan building, List<IlDuLearningModule> modules})
  parseBuildingDocument(Object? value, String path) {
    final json = _map(value, path);
    if (json['schemaVersion'] != 1) {
      throw FormatException('$path.schemaVersion must be 1.');
    }
    final buildingJson = _map(json['building'], '$path.building');
    final building = IlDuBuildingConstructionPlan(
      buildingId: _stableId(
        buildingJson['buildingId'],
        '$path.building.buildingId',
      ),
      planVersion: _stableId(
        buildingJson['planVersion'],
        '$path.building.planVersion',
      ),
      canonicalAsset: _pngName(
        buildingJson['canonicalAsset'],
        '$path.building.canonicalAsset',
      ),
      canonicalSha256: _sha256(
        buildingJson['canonicalSha256'],
        '$path.building.canonicalSha256',
      ),
      buildingRole: _nonEmptyString(
        buildingJson['buildingRole'],
        '$path.building.buildingRole',
      ),
      culturalMeaning: _nonEmptyString(
        buildingJson['culturalMeaning'],
        '$path.building.culturalMeaning',
      ),
      stages: [
        for (final (i, stage)
            in _list(buildingJson['stages'], '$path.building.stages').indexed)
          IlDuConstructionStage.fromJson(stage, '$path.building.stages[$i]'),
      ],
    );
    final modules = [
      for (final (i, module) in _list(json['modules'], '$path.modules').indexed)
        IlDuLearningModule.fromJson(module, '$path.modules[$i]'),
    ];
    return (building: building, modules: modules);
  }
}

/// 인덱스 파일이 참조하는 건물 파일 하나 (설계 결정 D1).
final class IlDuBuildingFileRef {
  const IlDuBuildingFileRef({
    required this.buildingId,
    required this.file,
    required this.planVersion,
  });

  final String buildingId;

  /// `assets/data/ildu_construction/` 바로 아래의 로컬 JSON 파일 이름.
  final String file;
  final String planVersion;

  factory IlDuBuildingFileRef.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuBuildingFileRef(
      buildingId: _stableId(json['buildingId'], '$path.buildingId'),
      file: _jsonName(json['file'], '$path.file'),
      planVersion: _stableId(json['planVersion'], '$path.planVersion'),
    );
  }
}

/// 인덱스 파일(`estate_plan_v1.json`)의 파싱 결과. 건물 본문은 아직 없다.
final class IlDuEstateConstructionIndex {
  IlDuEstateConstructionIndex({
    required this.estateId,
    required this.planVersion,
    required this.canvas,
    required this.viewport,
    required Iterable<String> siteStageIds,
    required Iterable<String> buildingOrder,
    required Iterable<IlDuBuildingFileRef> buildingFiles,
  }) : siteStageIds = List.unmodifiable(siteStageIds),
       buildingOrder = List.unmodifiable(buildingOrder),
       buildingFiles = List.unmodifiable(buildingFiles);

  final String estateId;
  final String planVersion;
  final IlDuPlanSize canvas;
  final IlDuPlanSize viewport;
  final List<String> siteStageIds;
  final List<String> buildingOrder;
  final List<IlDuBuildingFileRef> buildingFiles;

  factory IlDuEstateConstructionIndex.fromJson(Object? value) {
    const path = 'estatePlan';
    final json = _map(value, path);
    if (json['schemaVersion'] != 1) {
      throw FormatException('$path.schemaVersion must be 1.');
    }
    final estateId = _stableId(json['estateId'], '$path.estateId');
    if (estateId != 'ildu-gotaek-v3') {
      throw const FormatException('Unsupported Ildu estate ID.');
    }
    final canvas = IlDuPlanSize.fromJson(json['canvas'], '$path.canvas');
    final viewport = IlDuPlanSize.fromJson(json['viewport'], '$path.viewport');
    if (canvas.width != 2412 ||
        canvas.height != 2622 ||
        viewport.width != 1206 ||
        viewport.height != 2622) {
      throw const FormatException(
        'The Ildu estate camera contract is 2412x2622 with a 1206x2622 '
        'viewport.',
      );
    }
    final buildingOrder = _stableIdList(
      json['buildingOrder'],
      '$path.buildingOrder',
    );
    if (buildingOrder.isEmpty) {
      throw FormatException('$path.buildingOrder must not be empty.');
    }
    if (buildingOrder.toSet().length != buildingOrder.length) {
      throw FormatException('$path.buildingOrder has duplicate building IDs.');
    }
    final buildingFiles = [
      for (final (i, ref) in _list(json['buildings'], '$path.buildings').indexed)
        IlDuBuildingFileRef.fromJson(ref, '$path.buildings[$i]'),
    ];
    final referencedIds = {for (final ref in buildingFiles) ref.buildingId};
    if (referencedIds.length != buildingFiles.length) {
      throw FormatException('$path.buildings has duplicate building IDs.');
    }
    if (referencedIds.length != buildingOrder.length ||
        !referencedIds.containsAll(buildingOrder)) {
      throw FormatException(
        '$path.buildingOrder and $path.buildings must reference the same '
        'building set.',
      );
    }
    final files = {for (final ref in buildingFiles) ref.file};
    if (files.length != buildingFiles.length) {
      throw FormatException('$path.buildings has duplicate file references.');
    }
    return IlDuEstateConstructionIndex(
      estateId: estateId,
      planVersion: _stableId(json['planVersion'], '$path.planVersion'),
      canvas: canvas,
      viewport: viewport,
      siteStageIds: _stableIdList(json['siteStageIds'], '$path.siteStageIds'),
      buildingOrder: buildingOrder,
      buildingFiles: buildingFiles,
    );
  }
}

/// 전체 일두고택 가변 건설 플랜. 인덱스와 건물 파일들을 합쳐 검증한 결과다.
final class IlDuEstateConstructionPlan {
  IlDuEstateConstructionPlan._({
    required this.estateId,
    required this.planVersion,
    required this.canvas,
    required this.viewport,
    required Iterable<String> siteStageIds,
    required Iterable<String> buildingOrder,
    required Iterable<IlDuBuildingConstructionPlan> buildings,
    required Iterable<IlDuLearningModule> modules,
  }) : siteStageIds = List.unmodifiable(siteStageIds),
       buildingOrder = List.unmodifiable(buildingOrder),
       buildings = List.unmodifiable(buildings),
       modules = List.unmodifiable(modules) {
    _validateReferences();
  }

  final String estateId;
  final String planVersion;
  final IlDuPlanSize canvas;
  final IlDuPlanSize viewport;
  final List<String> siteStageIds;
  final List<String> buildingOrder;
  final List<IlDuBuildingConstructionPlan> buildings;
  final List<IlDuLearningModule> modules;

  IlDuBuildingConstructionPlan buildingFor(String buildingId) =>
      buildings.firstWhere(
        (building) => building.buildingId == buildingId,
        orElse: () => throw ArgumentError.value(
          buildingId,
          'buildingId',
          'Unknown building',
        ),
      );

  bool hasBuilding(String buildingId) =>
      buildings.any((building) => building.buildingId == buildingId);

  IlDuLearningModule moduleFor(String moduleId) => modules.firstWhere(
    (module) => module.moduleId == moduleId,
    orElse: () =>
        throw ArgumentError.value(moduleId, 'moduleId', 'Unknown module'),
  );

  bool hasModule(String moduleId) =>
      modules.any((module) => module.moduleId == moduleId);

  /// 인덱스와, `buildingId → 건물 파일 JSON` 매핑으로 전체 플랜을 조립한다.
  ///
  /// 파일 로드는 리포지토리의 일이고, 여기서는 참조 무결성만 책임진다:
  /// - 인덱스가 참조한 모든 건물 파일이 존재해야 한다.
  /// - 건물 파일의 buildingId·planVersion 이 인덱스 참조와 일치해야 한다.
  /// - 모듈 ID 는 estate 전체에서 유일해야 한다.
  factory IlDuEstateConstructionPlan.fromParts(
    IlDuEstateConstructionIndex index,
    Map<String, Object?> buildingDocumentsById,
  ) {
    final buildings = <IlDuBuildingConstructionPlan>[];
    final modules = <IlDuLearningModule>[];
    for (final ref in index.buildingFiles) {
      if (!buildingDocumentsById.containsKey(ref.buildingId)) {
        throw FormatException(
          'Missing building document for "${ref.buildingId}".',
        );
      }
      final parsed = IlDuBuildingConstructionPlan.parseBuildingDocument(
        buildingDocumentsById[ref.buildingId],
        'buildings/${ref.file}',
      );
      if (parsed.building.buildingId != ref.buildingId) {
        throw FormatException(
          'File "${ref.file}" declares building '
          '"${parsed.building.buildingId}" but the index expected '
          '"${ref.buildingId}".',
        );
      }
      if (parsed.building.planVersion != ref.planVersion) {
        throw FormatException(
          'File "${ref.file}" declares planVersion '
          '"${parsed.building.planVersion}" but the index expected '
          '"${ref.planVersion}".',
        );
      }
      buildings.add(parsed.building);
      modules.addAll(parsed.modules);
    }
    return IlDuEstateConstructionPlan._(
      estateId: index.estateId,
      planVersion: index.planVersion,
      canvas: index.canvas,
      viewport: index.viewport,
      siteStageIds: index.siteStageIds,
      buildingOrder: index.buildingOrder,
      buildings: buildings,
      modules: modules,
    );
  }

  /// 테스트·픽스처용 단일 진입점: 인덱스 JSON 과 건물 문서 매핑을 한 번에
  /// 파싱한다.
  factory IlDuEstateConstructionPlan.fromJson(
    Object? indexJson,
    Map<String, Object?> buildingDocumentsById,
  ) => IlDuEstateConstructionPlan.fromParts(
    IlDuEstateConstructionIndex.fromJson(indexJson),
    buildingDocumentsById,
  );

  void _validateReferences() {
    final moduleIds = <String>{};
    for (final module in modules) {
      if (!moduleIds.add(module.moduleId)) {
        throw FormatException(
          'Duplicate module ID "${module.moduleId}" across the estate.',
        );
      }
    }
    final stageIds = <String>{};
    for (final building in buildings) {
      for (final stage in building.stages) {
        if (!stageIds.add(stage.stageId)) {
          throw FormatException(
            'Duplicate stage ID "${stage.stageId}" across the estate.',
          );
        }
        for (final moduleId in [
          ...stage.requiredModuleIds,
          ...stage.optionalModuleIds,
        ]) {
          if (!moduleIds.contains(moduleId)) {
            throw FormatException(
              'Stage "${stage.stageId}" references unknown module '
              '"$moduleId".',
            );
          }
        }
        if (stage.requiredModuleIds.isEmpty) {
          throw FormatException(
            'Stage "${stage.stageId}" must require at least one module.',
          );
        }
      }
    }
    for (final siteStageId in siteStageIds) {
      if (!stageIds.contains(siteStageId)) {
        throw FormatException(
          'siteStageIds references unknown stage "$siteStageId".',
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 공용 파싱 도우미 — ildu_world_manifest.dart 의 fail-closed 스타일을 따른다.

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return value.map((key, entry) {
    if (key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    return MapEntry(key, entry);
  });
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path must be a list.');
  }
  return value;
}

String _nonEmptyString(Object? value, String path) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('$path must be a non-empty string.');
}

final _stableIdPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

String _stableId(Object? value, String path) {
  if (value is String && _stableIdPattern.hasMatch(value)) {
    return value;
  }
  throw FormatException('$path must be a lowercase stable ID.');
}

List<String> _stableIdList(Object? value, String path) => [
  for (final (i, id) in _list(value, path).indexed) _stableId(id, '$path[$i]'),
];

List<String> _stringList(Object? value, String path) => [
  for (final (i, text) in _list(value, path).indexed)
    _nonEmptyString(text, '$path[$i]'),
];

final _pngNamePattern = RegExp(r'^[a-z0-9_]+\.png$');

String _pngName(Object? value, String path) {
  if (value is String && _pngNamePattern.hasMatch(value)) {
    return value;
  }
  throw FormatException('$path must be a local PNG filename.');
}

final _jsonNamePattern = RegExp(r'^[a-z0-9_]+\.json$');

String _jsonName(Object? value, String path) {
  if (value is String && _jsonNamePattern.hasMatch(value)) {
    return value;
  }
  throw FormatException('$path must be a local JSON filename.');
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

String _sha256(Object? value, String path) {
  if (value is String && _sha256Pattern.hasMatch(value)) {
    return value;
  }
  throw FormatException('$path must be a lowercase SHA-256 hex digest.');
}

double _positiveNumber(Object? value, String path) {
  if (value is num && value.isFinite && value > 0) {
    return value.toDouble();
  }
  throw FormatException('$path must be a positive number.');
}

int _positiveInt(Object? value, String path) {
  if (value is int && value > 0) {
    return value;
  }
  throw FormatException('$path must be a positive integer.');
}
