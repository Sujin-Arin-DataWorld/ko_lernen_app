# 동기 기반 온보딩 + 5분 자동 코스

> **목적 1**: 신규 사용자 첫 90초에 "이 앱이 나를 위한 것"이라고 느끼게 하기 (현재 레벨 선택만).
> **목적 2**: 매일 5분 학습 약속을 자동 조립으로 지키게 하기 (U-Bahn / 점심시간 / 자기 전).
> **비고**: 이 트랙은 UI 작업 일부 포함 → 다른 세션 디자인과 카피 정합성 필요. **이 문서는 컨텐츠/카피만 정의**. 위젯 구현은 별도.

---

## Part 1: 동기 기반 온보딩 — "왜 배우세요?"

### 현재 흐름 (`lib/screens/onboarding_level_screen.dart`)
1. 환영 화면
2. CEFR 레벨 선택 (A1/A2/B1/B2)
3. 홈

### 신규 흐름 (90초 목표)
1. 환영 (5초): "환영합니다 / Willkommen / Welcome"
2. **동기 선택 (15초)**: 6택 — 한국어로 무엇을 하고 싶나
3. **레벨 자가측정 (30초)**: 예문 3개 보고 "이해돼요/어렵네요" 탭 → 자동 레벨
4. **첫 시나리오 매칭 (5초)**: 동기 + 레벨 기반 자동 매칭
5. **즉시 플레이 (35초)**: 첫 시나리오 시작

---

### 6택 동기 (German + English copy)

| ID | 한국어 | German UI | English UI | 우선 시나리오 가중치 |
|---|---|---|---|---|
| `drama_kpop` | K-드라마 / K-팝 즐기기 | **Dramen & K-Pop verstehen** — Lyrics, Dialoge, ohne Untertitel | **Enjoy K-dramas & K-pop** — songs, dialogue, without subtitles | couple_argument, friend_breakup_comfort, news_discussion (B1+ 감정·관계 우선) |
| `partner` | 한국인 파트너·가족과 대화 | **Mit koreanischem Partner reden** — Familie, Schwiegereltern, Alltag | **Talk with Korean partner** — family, in-laws, daily life | parents_video_call, couple_argument, wedding_korean_guest, warm_encouragement |
| `work_visa` | 한국에서 일 / 이민 | **In Korea arbeiten / einwandern** — Interview, Visa, Büro | **Work or move to Korea** — interview, visa, office | interview_visa_first, vacation_request_boss, company_dinner_hoeshik, negotiation_business |
| `travel` | 한국 여행·출장 준비 | **Reise nach Korea** — Hotel, Verkehr, Cafés, Notfälle | **Travel to Korea** — hotel, transport, cafes, emergencies | airport_arrival, hotel_checkin, taxi_kakao, subway_ticket_buy, pharmacy_headache |
| `topik_study` | TOPIK 시험 / 학업 | **TOPIK & Studium** — Test-Vorbereitung, akademisches Vokabular | **TOPIK & studies** — exam prep, academic vocab | (v1.2 TOPIK 메타 도입 후 적극 활용) — 현재는 모든 레벨 균형 |
| `curiosity` | 그냥 호기심 — 천천히 | **Einfach Interesse** — kein Druck, K-Kultur entdecken | **Just curious** — no pressure, discover K-culture | bunshik_tteokbokki, convenience_store, myeongdong_shopping, daily char |

### 데이터 저장
```dart
// lib/services/user_profile.dart (신규 또는 확장)
class UserProfile {
  final Motivation? motivation;          // enum: dramaKpop, partner, workVisa, travel, topikStudy, curiosity
  final LearnerLevel level;
  final DateTime onboardedAt;
  
  // SharedPreferences 또는 Firestore
}

enum Motivation { dramaKpop, partner, workVisa, travel, topikStudy, curiosity }
```

### 레벨 자가측정 — 3 예문 패턴

각 사용자에게 임의 3개 보여줌 (1 from A1, 1 from A2, 1 from B1). 응답 → 자동 추정:
- 3개 다 어려움 → A1
- A1 OK, A2 어려움 → A1
- A1+A2 OK, B1 어려움 → A2
- A1+A2 OK, B1 일부 OK → B1
- 다 이해 → B2 추천 (수동 선택 가능)

**예문 풀** (각 레벨 5개 풀에서 랜덤):

A1 예문:
- "안녕하세요. 저는 학생이에요." → ✓이해
- "이것은 책이에요." → ✓
- "물 한 잔 주세요." → ✓
- "어디에 가요?" → ✓
- "감사합니다." → ✓

A2 예문:
- "어제 친구하고 영화를 봤어요." → ✓
- "내일은 비가 올 것 같아요." → ✓
- "버스 정류장이 어디에 있어요?" → ✓
- "이 김치찌개 너무 맵지 않아요?" → ✓
- "공항까지 얼마나 걸려요?" → ✓

B1 예문:
- "솔직히 말하면 그 영화는 좀 지루했어요." → ✓
- "내가 시간이 있었더라면 같이 갔을 텐데." → ✓
- "그분이 화나신 것 같아요. 조심하세요." → ✓
- "혹시 저녁에 시간 되시면 같이 식사할까요?" → ✓
- "이 일을 끝내려면 적어도 사흘은 필요해요." → ✓

(B2는 자가측정 X — A2/B1 결과 보고 마지막에 "더 어려운 것 시도?" 옵션 노출)

### 매칭 룰

```
matched_first_scenario = first scenario where:
  scenario.level == self_assessed_level
  AND motivation in scenario.motivationTags
  AND scenario.id not in completed_set
```

Fallback: 동기 매치 없으면 같은 레벨 첫 시나리오. 그래도 없으면 `introduce_yourself` (A1).

---

## Part 2: 5분 자동 코스 — "오늘 5분만"

### 현재 (v1.0.0)
홈 화면에 모듈 5개 카드 grid. 사용자가 골라서 진입. "어디로 갈까?" 결정 피로.

### 신규 (v1.0.2)
홈 화면 상단에 **고정 큰 버튼**:

```
┌─────────────────────────────────┐
│  🐯 [magpie or tiger mascot]    │
│                                  │
│     오늘의 5분 학습              │
│  Heute 5 Minuten lernen          │
│                                  │
│  ▶ 시작 (Tap)                   │
│                                  │
│  ⏱ 2:00 + 1:30 + 1:30 = 5:00     │
│  📖 시나리오 한 조각              │
│  ⚡️ 받침/조사 퀘스트 5개          │
│  📇 단어 SRS 5장                │
└─────────────────────────────────┘
```

### 5분 코스 알고리즘

```dart
class FiveMinuteSession {
  final Scenario scenarioSegment;       // 다이얼로그 6~8줄 (full 시나리오 X)
  final List<QuestSpec> quickQuests;    // 5개, 90초 안
  final List<VocabCard> srsCards;       // 5장 due

  static FiveMinuteSession assemble(UserProfile p, UserActivity a) {
    // 1. 시나리오 조각 (2분): 진행 중 시나리오의 다음 chunk 또는 추천 시나리오 첫 chunk
    final scenarioChunk = a.currentScenario?.nextChunk(maxLines: 8)
                       ?? recommender.next(p, a).firstChunk(maxLines: 8);
    
    // 2. 약점 우선 퀘스트 (90초)
    final weakParticle = a.particleStats.bottomOne();
    final weakBatchim = a.batchimStats.bottomOne();
    final quests = [
      QuestSpec.particlePop(focus: weakParticle),
      QuestSpec.particlePop(focus: anyRecent),
      QuestSpec.batchimDrop(focus: weakBatchim),
      QuestSpec.luecken(level: p.level),
      QuestSpec.uebersetzen(level: p.level),
    ];
    
    // 3. SRS due 5장 (90초)
    final cards = srsRepo.dueCards(limit: 5);
    if (cards.length < 5) {
      cards.addAll(srsRepo.newCards(limit: 5 - cards.length, motivation: p.motivation));
    }
    
    return FiveMinuteSession(scenarioChunk, quests, cards);
  }
}
```

### 사용자가 보는 흐름 (사용자 카피)

1. **시나리오 (2분)**: "이어서 진행 — 분식집 주문" 또는 "처음 시도 — 카페에서 만남"
2. **퀘스트 (90초)**: "조사 + 받침 5문제" (퀘스트는 한 번에 하나씩 풀스크린)
3. **단어 (90초)**: "오늘 만난 단어 5장" (앞면 ko, 뒷면 de/en)
4. **완료 화면**: magpie 등장 + "+50 XP / 연속 N일째!"

### 5분 완료 후 행동 분기

- **여유 있으면**: "이어서 5분 더?" 버튼 (= 새 시나리오 + 새 퀘스트)
- **만족**: 닫기 → 홈 → 다음 날 알림

### Edge cases

- **첫날 (no SRS due)**: 모두 신규 단어로 5장
- **시나리오 없을 때**: 동기 매칭 시나리오 추천 후 첫 다이얼로그
- **퀘스트 부족** (사용자가 한 퀘스트 종류만 풀었을 때): 균형 fallback

## Part 3: 첫 7일 retention loop

### Day 0 (onboarding)
- 6동기 → 자가측정 → 첫 시나리오 → "내일 같은 시간에 알림 받을래요?" 토글

### Day 1~7 (push notification or in-app)
- 알림 메시지 (German): 
  - Day 1: "Heute schon 5 Min Koreanisch? 🐯"
  - Day 3: "3 Tage in Folge — toll! 까치가 응원해요"
  - Day 7: "Eine Woche! Du hast jetzt N Wörter im Kopf."
- 누적 통계: 학습한 시나리오 수, SRS box 분포, 약점 영역

### Day 7 후
- 첫 사회적 루프 nudge: "친구와 끝말잇기 시작?" (Track D)
- 시즌 1 진도 표시: "시즌 1 — N/13 시나리오 완주"

---

## 작업 분해

### Week 1: 카피 + 데이터 모델
- [ ] `lib/services/user_profile.dart` 신규 (Motivation enum, persistence)
- [ ] `lib/data/onboarding_examples.dart` — 위 15개 자가측정 예문 정적 데이터
- [ ] `lib/data/motivation_copy.dart` — 6택 카피 (ko/de/en) 정적
- [ ] `assets/data/scenarios.json`에 모든 시나리오에 `motivationTags[]` 추가 (수동)

### Week 2: 온보딩 화면
- [ ] `lib/screens/onboarding_motivation_screen.dart` 신규 — 6택 grid
- [ ] `lib/screens/onboarding_assessment_screen.dart` 신규 — 3예문 self-rating
- [ ] `lib/screens/onboarding_first_scenario_screen.dart` 신규 — 첫 매칭 시나리오 결과
- [ ] 기존 `onboarding_level_screen.dart`는 "고급 사용자 직접 선택" 옵션으로 강등

### Week 3: 5분 코스 위젯 + 알고리즘
- [ ] `lib/services/five_minute_session.dart` — assemble 로직
- [ ] `lib/widgets/home/five_min_card.dart` — 홈 상단 큰 카드 (디자인 세션과 컬러 정합 필요)
- [ ] `lib/screens/five_min_player_screen.dart` — 시나리오 chunk + quests + cards 연속 재생
- [ ] Edge case (first day, no due cards) 처리

### Week 4: 알림 + 7일 loop
- [ ] flutter_local_notifications 추가 (이미 dependency 있는지 확인 후)
- [ ] 일일 알림 시간 설정 (settings_screen에 "학습 시간 알림" 토글)
- [ ] Day 1, 3, 7 milestone 토스트

---

## 컨텐츠 카피 — 5분 코스 페이지

### 진입 시 (시작 버튼 tap 후 1초 spinner + 첫 화면)

```
오늘의 5분 학습
Heute · 5 Minuten · 시즌 1, 4번째 시나리오

🍵 카페에서 만남 — 다이얼로그
🎯 약점 트레이닝: 을/를 + 받침 ㄹ
📇 복습할 단어: 5장

[ ▶ 시작 ]
```

### 시나리오 끝 토스트

```
+2분 끝났어요. 다음은 빠른 퀘스트 5개.
[ 다음 → ]
```

### 퀘스트 끝 토스트

```
오! 받침 ㄹ 5문제 중 4개 정답.
지난주보다 +20% 좋아졌어요.
[ 단어 5장 → ]
```

### 5분 끝 화면 (까치 등장)

```
[🪶 magpie smile]

5분 완료! 좋은 소식이에요 —
오늘 +50 XP, 연속 12일째!

내일은 같은 시간에 알림 드릴게요.

[ 더 5분? ]  [ 닫기 ]
```

## 향후 개선

- **Adaptive duration**: 사용자가 자주 "더 5분?" 누르면 기본 시간을 7분 / 10분으로 자동 권장
- **Time-of-day awareness**: 아침엔 새 시나리오 / 밤엔 SRS 위주
- **Streak save**: 23:50에 알림 ("오늘 1분만!")
