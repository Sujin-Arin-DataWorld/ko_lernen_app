# 모듈 통합 그래프 — "Sori Brain" 설계

> **목적**: 5개 모듈(시나리오/단어/문법/Wordle/초성퀴즈)의 사일로 해체. 사용자 행동이 단일 진도 모델에 누적되고 학습 추천이 자동.
> **현황 (검증)**: 현재 `Scenario.vocab[].korean`은 한국어 String일 뿐 — `korean_vocab.csv`와 자동 join 안 됨. `Scenario.grammarIds[]`는 `grammar.csv`의 `pattern` 컬럼과 연결되도록 설계되어 있으나 사용자 측 시각화 없음. 받침/조사 약점 추적 X.

## 1. 메타데이터 그래프 — 3-layer

### Layer 1: 원자 (atomic) — 이미 존재
- **VocabItem**: korean, romanization, german, level, pos_de, example_korean, example_german, topic — `korean_vocab.csv` (526개)
- **GrammarPattern**: pattern, level, type_de, explanation_de, example_korean, example_german, note — `grammar.csv` (88개)
- **Scenario**: 13 ⇒ 30 (Track A 후)

### Layer 2: 신규 메타 — 추가 필요
- **ParticleId**: 18개 표준 (`은`,`는`,`이`,`가`,`을`,`를`,`에`,`에서`,`에게`,`께`,`로`,`으로`,`와`,`과`,`도`,`만`,`부터`,`까지`)
- **BatchimSyllable**: 받침 7가지 그룹 (`ㄱㅋ`, `ㄴ`, `ㄷㅌㅅㅆㅈㅊㅎ`, `ㄹ`, `ㅁ`, `ㅂㅍ`, `ㅇ`) + 무종성
- **TOPIK 빈도** (v1.2 후): TOPIK I (1~2급) / TOPIK II (3~6급) 출제 빈도 메타 (외부 dataset 필요)

### Layer 3: 사용자 행동 (User Activity)
- **VocabMastery**: { vocabId, srs_box, last_seen, correct_count, error_count, next_due }
- **GrammarMastery**: 동일 구조 with grammarId
- **ParticleAccuracy**: { particleId, attempts, correct, last_error_at }
- **BatchimAccuracy**: { batchimGroup, attempts, correct }
- **ScenarioProgress**: { scenarioId, completed_at, quest_results[], xp_earned }

## 2. 자동 연결 규칙 (Resolver)

### 2.1 시나리오 → 어휘 자동 join (즉시 가능)
```dart
// lib/services/vocab_resolver.dart (신규)
class VocabResolver {
  final Map<String, VocabItem> _byKorean; // CSV load 시 build
  VocabResolver(Iterable<VocabItem> csv) 
    : _byKorean = { for (var v in csv) v.korean: v };
  
  /// 시나리오의 VocabRef.korean으로 CSV 카드를 찾아 반환.
  VocabItem? resolve(String korean) => _byKorean[korean];
  
  /// 시나리오의 모든 vocab을 CSV와 매칭 — `note` field가 없으면 CSV의 example로 fallback.
  Iterable<EnrichedVocab> enrich(Scenario s) => s.vocab.map((ref) {
    final csvCard = _byKorean[ref.korean];
    return EnrichedVocab(ref: ref, card: csvCard);
  });
}
```

### 2.2 시나리오 완주 → SRS 자동 등록 (즉시 가능)
```dart
// 시나리오 완주 콜백
void onScenarioComplete(Scenario s, ScenarioResult r) {
  for (final vref in s.vocab) {
    srsRepository.upsert(vref.korean, source: 'scenario:${s.id}');
  }
  for (final gid in s.grammarIds) {
    grammarSrsRepository.upsert(gid, source: 'scenario:${s.id}');
  }
  // particle / batchim accuracy 자동 갱신
  for (final q in r.questResults) {
    if (q.type == QuestType.particlePop) {
      particleStats.record(q.particleId, q.correct);
    }
    if (q.type == QuestType.batchimDrop) {
      batchimStats.record(q.batchimGroup, q.correct);
    }
  }
}
```

### 2.3 약점 기반 추천 (v1.0.2 핵심)
```dart
class WeaknessRecommender {
  ScenarioRecommendation next(UserActivity ua) {
    final weakParticle = ua.particleStats.bottomOne(); // 정확도 가장 낮은 1개
    final weakBatchim = ua.batchimStats.bottomOne();
    
    // 후보 시나리오 중에 → weakParticle을 포함하고 weakBatchim 단어가 dialog에 자주 나오는 것 우선
    final candidates = allScenarios.where((s) => 
      !ua.completed.contains(s.id) &&
      s.level.rank <= ua.currentLevel.rank
    );
    
    final scored = candidates.map((s) => MapEntry(s, 
      _particleScore(s, weakParticle) * 2 +
      _batchimScore(s, weakBatchim) * 1.5 +
      _topicMatchScore(s, ua.preferredTopics)
    ));
    
    return scored.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
```

## 3. 새 메타필드 — JSON 스키마 변경

### Scenario JSON에 추가
```json
{
  "id": "...",
  "level": "...",
  // ... 기존 필드
  
  // ↓ 신규 (모두 optional, backward compatible)
  "particleIds": ["은/는", "(으)로", "에서"],   // dialog/quests에 등장한 조사 명시
  "batchimWeights": {                          // 0~1 점수, dialog 받침 분포
    "ㄱㅋ": 0.05, "ㄴ": 0.12, "ㄹ": 0.18, "ㅁ": 0.10, "ㅇ": 0.45
  },
  "motivationTags": ["partner", "drama"],       // 동기 onboarding 가중치
  "topikLevel": "TOPIK-I-2"                    // (v1.2) 외부 dataset 부착
}
```

### Migration plan (기존 13개)
- `particleIds[]`: dialog ko 텍스트를 regex로 자동 추출 → `tool/extract_particle_ids.dart` 1회 실행
- `batchimWeights`: dialog의 모든 syllable 받침 카운트 → 자동 계산
- `motivationTags`: 수동 분류 (cafe/shopping/transport=일반, 회식·면접=취업, 커플다툼=파트너, hotel=여행)
- `topikLevel`: v1.0.2 미적용. v1.2에 TOPIK 단어 list 외부 source 통합 시.

## 4. 사용자가 체감하는 변화

### Before (v1.0.0)
- 시나리오 끝 → 홈으로 돌아옴 → "다음 뭐 하지?" 막연
- 단어장: SRS 큐는 사용자가 수동 add한 단어만
- 받침 틀려도 다음에 같은 받침이 또 나옴 (그냥 랜덤)

### After (v1.0.2)
- 시나리오 끝 → **"방금 배운 단어 5개가 SRS에 추가됨"** 토스트
- 시나리오 끝 → 홈에 **"다음 추천: 약점 우선"** 카드 (자동 매칭된 1개)
- 받침 ㄹ 약점이면 → 다음 Batchim Drop에 ㄹ 우선 출제 + 시나리오 dialog에 ㄹ 많은 것 추천

## 5. 작업 분해 (1 sprint = 1 week)

### Week 1: Resolver + SRS 통합
- [ ] `lib/services/vocab_resolver.dart` 신규
- [ ] 기존 `vocab_screen.dart`의 SRS 로직을 `lib/services/srs_repository.dart`로 분리 (이미 있을 시 wrap)
- [ ] 시나리오 완주 콜백에 SRS auto-enroll 추가
- [ ] 검증: 시나리오 완주 후 단어장 들어가면 방금 본 단어가 큐 top에 있음

### Week 2: 약점 추적
- [ ] `lib/services/weakness_stats.dart` — particle/batchim accuracy 추적
- [ ] particlePop / batchimDrop quest의 결과를 stats에 기록
- [ ] settings_screen.dart에 "내 약점" 표시 (조사 정확도 막대 그래프)
- [ ] 검증: 일부러 ~을/를 5번 틀리면 stats에 반영됨

### Week 3: 추천 + JSON migration
- [ ] `WeaknessRecommender` 구현
- [ ] home_screen.dart에 "오늘의 추천 시나리오" 1장 카드 추가
- [ ] `tool/migrate_scenario_metadata.dart` — 기존 13개에 particleIds/batchimWeights/motivationTags 자동 부여
- [ ] 검증: 새 사용자 → 추천 = a1_introduce_yourself. 약점 가진 사용자 → 약점 관련 시나리오

### Week 4: 통합 + 폴리시
- [ ] 모든 신규 시나리오 (Track A 신규 17개)에도 메타 자동 부여
- [ ] 시나리오 카드에 "왜 추천?" 1줄 노출 ("을/를 정확도 ↑ 도움")
- [ ] 단어장 카드에 출처 표시 ("From: 명동 쇼핑")

## 6. 안 건드릴 영역 (디자인 세션 충돌 회피)

- ❌ `lib/widgets/sori/*` (디자인 시스템)
- ❌ `lib/theme.dart`
- ❌ Mascot 라우팅 (이미 sidekick 코드 지원함)
- ❌ `assets/icons/`, `assets/illustrations/`
- ❌ pubspec.yaml 색상/스플래시 영역

## 7. Open Question (v1.0.2 후)

- TOPIK 외부 dataset 어디서? (TOPIK 공식 word list, 9급 분류 가능 source)
- 받침 정확도 시각화 — bar chart vs heatmap?
- 약점 추적이 학습자 동기에 부정적 영향 가능성 (자존감 ↓) — UI는 "성장 곡선" 톤으로?
