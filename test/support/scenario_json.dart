import 'dart:convert';
import 'dart:io';

/// 시나리오 코퍼스는 레벨 샤드 6 개다.  테스트가 각자 경로를 조립하면 샤드가
/// 늘거나 이름이 바뀔 때 11 개 파일이 같이 깨진다 — 여기만 고치면 되게 둔다.
const scenarioShardLevels = <String>['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

String scenarioShardPath(String level) => 'assets/data/scenarios_$level.json';

Map<String, dynamic> scenarioShardRoot(String level) =>
    jsonDecode(File(scenarioShardPath(level)).readAsStringSync())
        as Map<String, dynamic>;

/// 샤딩 이전의 단일 루트와 같은 모양(`{version, scenarios}`).  기존 테스트가
/// `root['scenarios']` 로 이어지므로 그 아래 코드를 건드리지 않아도 된다.
Map<String, dynamic> allScenarioRoot() => <String, dynamic>{
  'version': scenarioShardRoot(scenarioShardLevels.first)['version'],
  'scenarios': allScenarioJson(),
};

/// 레벨 순서(a1→c2)로 병합된 전 코퍼스.
List<Map<String, dynamic>> allScenarioJson() {
  final merged = <Map<String, dynamic>>[];
  for (final level in scenarioShardLevels) {
    final items = (scenarioShardRoot(level)['scenarios'] as List?) ?? const [];
    merged.addAll(items.cast<Map<String, dynamic>>());
  }
  return merged;
}
