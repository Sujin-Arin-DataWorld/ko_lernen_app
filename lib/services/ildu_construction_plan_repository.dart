import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ildu_construction_plan.dart';

/// 번들에서 일두 건설 플랜을 로드하는 fail-closed 경계.
///
/// D1 분리 계약: 인덱스(`estate_plan_v1.json`)가 건물별 파일을 참조하고,
/// 이 리포지토리가 `assets/data/ildu_construction/` 바로 아래에서 그 파일들을
/// 읽어 [IlDuEstateConstructionPlan.fromParts] 로 조립한다. 어떤 파일이든
/// 없거나 계약을 어기면 부분 플랜을 만들지 않고 그대로 실패한다.
///
/// 성공한 로드는 캐시된다. 실패한 로드는 캐시하지 않으므로 다음 호출이
/// 다시 시도한다.
final class IlDuConstructionPlanRepository {
  IlDuConstructionPlanRepository({this._bundle});

  /// 인덱스 파일. 건물 파일 이름은 이 인덱스만 선언할 수 있다.
  static const indexAssetPath =
      'assets/data/ildu_construction/estate_plan_v1.json';

  /// 건물 파일이 사는 유일한 폴더. 인덱스가 로컬 파일 이름만 갖도록 모델이
  /// 강제하므로, 이 폴더 밖의 경로는 조립될 수 없다.
  static const assetDirectory = 'assets/data/ildu_construction/';

  final AssetBundle? _bundle;
  Future<IlDuEstateConstructionPlan>? _cached;

  AssetBundle get _effectiveBundle => _bundle ?? rootBundle;

  Future<IlDuEstateConstructionPlan> load() {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    late final Future<IlDuEstateConstructionPlan> loading;
    loading = _loadFresh().then<IlDuEstateConstructionPlan>(
      (plan) => plan,
      onError: (Object error, StackTrace stack) {
        // 실패를 캐시에 남기지 않는다 — fail-closed 상태에서 재시도를 허용한다.
        if (identical(_cached, loading)) {
          _cached = null;
        }
        Error.throwWithStackTrace(error, stack);
      },
    );
    _cached = loading;
    return loading;
  }

  Future<IlDuEstateConstructionPlan> _loadFresh() async {
    final bundle = _effectiveBundle;
    final index = IlDuEstateConstructionIndex.fromJson(
      jsonDecode(await bundle.loadString(indexAssetPath)),
    );
    final documents = <String, Object?>{};
    for (final ref in index.buildingFiles) {
      documents[ref.buildingId] = jsonDecode(
        await bundle.loadString('$assetDirectory${ref.file}'),
      );
    }
    return IlDuEstateConstructionPlan.fromParts(index, documents);
  }
}
