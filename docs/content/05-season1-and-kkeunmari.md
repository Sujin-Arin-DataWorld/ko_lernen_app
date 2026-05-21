# 시즌 1 패키징 + 끝말잇기 챌린지

> **두 트랙을 하나로 묶은 이유**: 둘 다 "기존 자산 재포장 → 신규 인지 가치"를 만드는 작업. 시즌은 마케팅 단위, 끝말잇기는 첫 사회적 (또는 셀프-챌린지) 루프.

---

## Part 1: 시즌 1 — "베를린 한국인의 첫 한 달"

### 컨셉
기존 13개 시나리오를 **30일 학습 여정**으로 재포장. 자기소개 → 첫 카페 → 일상 → 갈등 → 회식 흐름.

### 13개 시나리오 재배열 (학습 순서)

| Day | Scenario | Level | Sidekick | 누적 XP |
|---|---|---|---|---|
| 1 | introduce_yourself | A1 | minsu | 100 |
| 2 | airport_arrival | A1 | minsu | 200 |
| 3 | hotel_checkin | A1 | minsu | 300 |
| 4 | taxi_kakao | A1 | minsu | 400 |
| 5 | convenience_store | A1 | minsu | 500 |
| 6 | bunshik_tteokbokki | A1 | minsu | 600 |
| 7 | cafe_starbucks_basic | A2 | minsu | 740 |
| 8 | subway_transfer | A2 | minsu | 880 |
| 9 | pharmacy_headache | A2 | minsu | 1020 |
| 10 | myeongdong_shopping | A2 | jieun | 1170 |
| 11 | warm_encouragement | B1 | **magpie** ← legacy minsu → magpie 변경 권장 (격려 톤) | 1320 |
| 12 | couple_argument | B1 | jieun | 1470 |
| 13 | company_dinner_hoeshik | B1 | minsu | 1620 |

→ **시즌 1 완주 = 1620 XP + "베를린에서 한 달 살아남기" 뱃지**

### 시즌 2 (Track A 후) — "한국에서 1년 살기"
B2 6개 + B1 신규 4개 = 10개
- 결혼식 → 부동산 → 의보 → 친구위로 → 면접 → 직장 → 부모님 → 협상 → 사회뉴스 → 정치회식
- "한국 사회 진입자" 컨셉

### 시즌 3 (Track A 후) — "K-드라마 일상"
A2 신규 4개 + A1 신규 3개 = 7개
- 미용실 → 카톡 → 길찾기 → 마트 → 식당 → T-money → 김밥
- "현지인처럼 일상" 컨셉

### UI 통합 포인트 (디자인 세션 참고용)
- `scenarios_list_screen.dart`에 시즌 헤더 추가 ("시즌 1: 베를린의 첫 한 달")
- 각 시즌 완주 후 뱃지 unlock + 시즌 2 카드 노출
- 완주율 표시: "N/13 완료"
- (디자인 세션이 시즌 카드 UI 만들 때까지 컨텐츠 메타만 준비)

### 시즌 메타 — JSON 확장

```json
// assets/data/seasons.json (신규)
{
  "version": 1,
  "seasons": [
    {
      "id": "s1_berlin_first_month",
      "title": { "ko": "베를린의 첫 한 달", "de": "Erster Monat in Berlin", "en": "First month in Berlin" },
      "tagline": { "ko": "도착부터 회식까지", "de": "Von Ankunft bis Hoeshik", "en": "From arrival to hoeshik" },
      "emoji": "🐯",
      "scenarioIds": [
        "introduce_yourself", "airport_arrival", "hotel_checkin", "taxi_kakao",
        "convenience_store", "bunshik_tteokbokki", "cafe_starbucks_basic",
        "subway_transfer", "pharmacy_headache", "myeongdong_shopping",
        "warm_encouragement", "couple_argument", "company_dinner_hoeshik"
      ],
      "completionXp": 200,
      "completionBadge": "berlin_survivor"
    }
  ]
}
```

### 마케팅 활용 (v1.0.2 release notes)
> "시즌 1: 베를린의 첫 한 달 출시 — 도착부터 회식까지 13챕터로 한 달을 살아내세요. 시즌 2 (B2 콘텐츠) 곧 출시!"

---

## Part 2: 끝말잇기 챌린지 — "오늘의 5단계 도전"

### 실제 단어 풀 (검증됨, 2026-05-21)
`tool/extract_kkeunmari_pool.py` 실행 결과 → `assets/data/kkeunmari_pool.json`:

| 지표 | 값 |
|---|---|
| 명사 총 (외래어 제외, 순수 한글 ≥2글자) | **225개** |
| 체인 가능 (마지막 글자로 시작하는 다른 명사 있음) | **111개** (49%) |
| 한방단어 (dead-ends) | 114개 |
| 안전한 시작 단어 | 111개 |
| 고유 첫 글자 | 219개 |

**해석**: 풀이 작아서 *endless 모드 X*. 하루 1회 짧은 챌린지 (3~5단계 체인) 형태로 디자인.

### 게임 모드 — "오늘의 5단계 도전"

**규칙**:
1. 시스템이 안전한 시작 단어 1개 제시 (e.g. "친구")
2. 사용자는 마지막 글자로 시작하는 다음 단어 입력 ("구두" → "두부" → "부엌" ...)
3. 5단계 완주 시 +30 XP + 까치 응원
4. 막히면 힌트 (1 다음 가능 단어 후보 3개 보기 — 1 XP 차감)
5. 매일 자정 1개 챌린지 갱신

**힌트 시스템**:
```dart
class KkeunmariChallenge {
  final String startWord;
  final List<String> userChain;
  
  List<String> hints({int max = 3}) {
    final lastChar = userChain.last[userChain.last.length - 1];
    final candidates = pool['by_first'][lastChar] ?? [];
    return candidates.where((w) => !userChain.contains(w)).take(max).toList();
  }
}
```

### Solo 모드 (v1.0.2 1차)
- 매일 새 챌린지 (Daily Reset)
- 친구 없이도 가능 — 봇 매칭 X
- 7일 연속 완주 시 뱃지 "끝말잇기 신동"

### Async 친구 모드 (v1.0.3 2차)
- Firestore-backed: friend pair, queue
- 친구가 단어 보내면 24h 내에 응답 push notification
- 양쪽이 다 막히면 "공동 승리" (협력 게임)
- 솔로 dev 부담 ↑ → v1.0.3 이후

### Word Pool 확장 전략 (v1.0.3+)

현재 풀 작은 이유: vocab CSV가 학습 목적 어휘 위주 (526개, 명사 274). 끝말잇기엔 부족.

**옵션 A**: 외부 한국어 기본명사 list 추가 (e.g. 국립국어원 빈도사전 5000개)
- 장점: 풀 5~10배 확장
- 단점: 학습 단어 ≠ 끝말잇기 단어. 새 단어 노출이 학습 효과 + 부담 양면.
- 권장: **별도 list** (`kkeunmari_extra_pool.json`). 끝말잇기 only.

**옵션 B**: 사용자가 직접 새 단어 추가 (creative)
- 사용자가 모르는 단어를 입력 → 시스템이 사전 검증 → 풀에 추가
- 위험: 욕설/오타. 검증 layer 필요.

**옵션 C**: 동사/형용사의 명사형도 포함 ("공부하다" → "공부", "예쁘다" → "예쁨")
- 풀 +30~50개. CSV 자동 처리 가능 (`tool/expand_vocab_to_nouns.py` 신규).

→ v1.0.2는 **현재 111개 체인-capable** 그대로 시작 + Daily 1회 챌린지. 풀 확장은 v1.0.3.

### UI/UX 카피 (게임 화면 텍스트)

```
오늘의 끝말잇기 도전 🪶
Heute · 5 Stufen
[ 시작 ]
```

시작 후:
```
시작 단어:    [ 친구 ]
다음 →       [ 입력 ___ ]

힌트 (-1 XP)
```

5단계 완주:
```
[🪶 magpie celebrate]

대단해요!
친구 → 구두 → 두부 → 부엌 → 엌? (없음!)

축하 +30 XP
내일 새 챌린지가 기다려요.
```

힌트 사용 시:
```
힌트 — '두'로 시작하는 단어 3개:
[ 두부 ]  [ 두꺼비 ]  [ 두유 ]
```

### 검증 게이트 (v1.0.2 출시 전)

- [ ] 7일 연속 완주 가능한가? → 7개 다른 안전한 시작 단어 → 각각 5단계 가능 verified
- [ ] 모든 시작 단어에서 최소 3개 다음 후보 있음 (막힘 방지)
- [ ] 한방단어가 길에 우연히 안 나오게 → 시작 단어 sample 강제
- [ ] 한국어 입력기 (IME) 정상 작동 — Android/iOS 양쪽 테스트

---

## 작업 분해 (시즌 + 끝말잇기 통합 4 sprint)

### Week 1: 시즌 메타 데이터
- [ ] `assets/data/seasons.json` 신규 (시즌 1 정의)
- [ ] `lib/models/season.dart` 신규
- [ ] `lib/services/season_repository.dart` 신규 (loads JSON, tracks completion)
- [ ] 검증: 시나리오 리스트에서 시즌 그룹 표시 가능

### Week 2: 끝말잇기 데이터 파이프라인
- [ ] `tool/extract_kkeunmari_pool.py` ✓ 완료 (이 세션)
- [ ] `assets/data/kkeunmari_pool.json` ✓ 완료
- [ ] `lib/models/kkeunmari.dart` 신규 (pool, challenge, chain)
- [ ] `lib/services/kkeunmari_repository.dart` 신규 (daily challenge gen, validate input)
- [ ] 검증: 7일 daily challenges 사전 생성 가능

### Week 3: 끝말잇기 게임 화면
- [ ] `lib/screens/kkeunmari_screen.dart` 신규 (Solo 모드)
- [ ] 키보드 입력 + 한국어 IME 지원
- [ ] 힌트 + XP 차감 로직
- [ ] 5단계 완주 시 magpie celebration

### Week 4: 시즌 완주 표시 + 통합
- [ ] `home_screen.dart` 또는 `scenarios_list_screen.dart` 시즌 헤더 카드 추가
- [ ] 시즌 1 완주 시 뱃지 + 시즌 2 unlock 처리 (시즌 2는 Track A 콘텐츠 완성 후)
- [ ] 끝말잇기를 home_screen에 진입 카드 추가 (현재 5개 모듈 grid 옆)

---

## Daily Challenge 생성 알고리즘 (구현 spec)

```dart
class DailyKkeunmariGenerator {
  KkeunmariChallenge generateFor(DateTime day) {
    final seed = day.toIso8601String().substring(0, 10).hashCode;
    final rng = Random(seed);
    
    // 안전한 시작 단어 중 → 5단계 체인 가능한 것만 picking
    final safeStarters = pool.safeStarters;
    KkeunmariChallenge? candidate;
    
    for (int tries = 0; tries < 100; tries++) {
      final start = safeStarters[rng.nextInt(safeStarters.length)];
      final chain = _attemptChain(start, depth: 5, rng: rng);
      if (chain.length == 5) {
        candidate = KkeunmariChallenge(startWord: start, exampleChain: chain);
        break;
      }
    }
    
    return candidate ?? _fallbackChallenge();
  }
  
  List<String> _attemptChain(String start, {required int depth, required Random rng}) {
    final chain = [start];
    while (chain.length < depth) {
      final last = chain.last[chain.last.length - 1];
      final candidates = (pool.byFirst[last] ?? []).where((w) => !chain.contains(w)).toList();
      if (candidates.isEmpty) break;
      chain.add(candidates[rng.nextInt(candidates.length)]);
    }
    return chain;
  }
}
```

## Pool 확장 v1.0.3 (예상)

| 변경 | 풀 +(예상) | 영향 |
|---|---|---|
| 동사·형용사의 명사형 자동 추출 | +30~50 | 약 160 chain-capable |
| 국립국어원 기본 명사 1000개 별도 list | +500~700 | 챌린지 길이 확장 가능 (10단계 도전) |
| 시즌별 시그니처 단어 묶음 | +50 | 시즌 끝나면 unlock |

---

## 안 건드릴 영역

- ❌ 디자인 세션이 작업 중인 widget (`lib/widgets/sori/*`, `lib/theme.dart`)
- ❌ pubspec 색상 / 스플래시
- ❌ 마스코트 painter 로직 (magpie celebrate emotion은 이미 코드 지원)

## 다음 Open Question

- 끝말잇기 정답 단어 → SRS 자동 등록할지? (학습 가치 ↑ but 풀이 작아서 매번 같은 단어 보일 위험)
- 두음법칙을 학습자 모드에 옵션으로 켤지? (한국 native 게임 호환성 vs 학습 단순성)
- 친구 async 모드는 Firestore 비용 — solo 인디 단계에서 viable한지 검토 필요
