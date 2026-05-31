# Plan: stately-rising-jongga

> **Codename**: stately-rising-jongga (당당히 솟는 종갓집)
> **작성일**: 2026-05-31
> **대상 버전**: v2.0.0 ("Hanok Quest" 업데이트)
> **예상 작업 기간**: 10주 (PNG 자산 병행)
> **상태**: 초안 — Jin 검토 대기

---

## 0. 문제 진단

### 0.1 사용자 보고

> "레벨 선택하고 단어 공부하려는데, 한 레벨당 단어가 500개 넘어가니까 한 번에 하려니 스트레스. 퀘스트 깨는 것처럼 변경하고 싶다. 보상 뱃지나 유저끼리 커뮤니케이션이 있으면 좋겠다."

### 0.2 데이터 실측 (2026-05-31)

`assets/data/korean_vocab.csv` 526행 분석:

| 레벨 | 단어 수 | 현재 토픽 수 |
|---|---|---|
| A1 | 211 | 25 (Alltag 36, Zeit 25, Zahlen 23 등) |
| A2 | 140 | 17 |
| B1 | 103 | 13 |
| B2 | 72 | 10 |

**핵심 발견**:
- 화면의 "522 due"는 실제 단어 수가 아니라 SRS가 **모든 단어를 즉시 due로 던진** 결과. SRS UX 자체의 문제.
- 토픽 컬럼이 이미 존재 → 재분류 부담 적음. 다만 `Alltag` 36개는 너무 크고, `Geographie`/`Sport` 같은 1~2개 토픽은 너무 작음. **정리·병합 필요**.
- B2가 72개뿐 → 콘텐츠 백로그 (Track D 별개).

### 0.3 디자인 결함

- **빚 명세서 UX**: "522 due"는 학습 의욕을 꺾는 숫자. 진행감·끝맺음감 부재.
- **시각적 보상 부재**: 단어 카드 → 다음 단어 카드 → … 무한 반복. 마일스톤 없음.
- **세계관 활용 부족**: 한옥·단청·호랑이·까치 컨셉이 vocab 학습 흐름에 거의 안 보임.
- **사회적 동기 0**: 익명 단독 학습. 친구·모임·경쟁 모두 부재.

---

## 1. 솔루션 컨셉

### 1.1 핵심 메타포: "터에서 종갓집까지"

사용자가 학습을 시작하면 **빈 마당(터)** 하나가 주어진다. 단어팩을 클리어할 때마다 마당 위에 한옥이 한 단계씩 지어진다.

```
A1 시작     →  빈 터, 잡초
A1 25%      →  주춧돌 8개
A1 50%      →  기둥 4개
A1 75%      →  대들보 + 서까래 골조
A1 100%     →  초가지붕 완성 (소박한 첫 집)
A2 0~50%    →  초가 → 기와 교체
A2 100%     →  처마에 단청
B1          →  솟을대문 + 창살문
B2          →  사랑채 별채 + 마당 정원
B2 100%     →  종갓집 완성 (낙관 + 닉네임 편액)
```

각 단계 진입 시 **1.5초 시네마틱** (까치가 날아와 새 부분을 가져다놓는 연출).

### 1.2 보조 메타포: "특별 퀘스트로 마당 꾸미기"

본 빌드(주춧돌→종갓집)는 단어 진행도에 따라 **자동**으로 올라간다.
특별 퀘스트는 **선택적**·**조건적**으로 마당에 영구 장식을 추가한다 (장독대, 매화나무, 석등 등).
종갓집 본채는 모두 동일하지만 **마당 풍경은 사용자마다 다르게** 꾸며진다 → 자기 정체성·자랑거리.

### 1.3 사회적 동기: 계(契) 커뮤니티

전통 학습 모임 단어 "계"를 그대로 사용. 5~10명 비공개 모임방.
- **공동 한옥**: 계원 진행도가 합쳐져 더 큰 종갓집을 함께 짓는다.
- **주간 공동 목표**: "이번 주 우리 계가 함께 50팩 클리어"
- **자유 텍스트 금지**, 스티커/이모지 30종만 → 모더레이션 부담 최소화.
- **신고·차단 시스템** + Jin 수동 검토 큐.

---

## 2. 10주 Phase 분할

| Phase | 기간 | 주요 작업 | 트랙 |
|---|---|---|---|
| 1 | Week 1 | 데이터 구조 (pack 컬럼 + Firestore schema) + SRS UX 임시 패치 | Code |
| 2 | Week 2 | 팩 화면 (vocab_screen 분할) + 진행도 트래킹 | Code |
| 3 | Week 3 | 한옥 건축 진행도 시스템 (단계 계산 + 시네마틱) | Code |
| 4 | Week 4 | 특별 퀘스트 12개 + 마당 장식 합성 | Code + PNG |
| **5** | **Week 5-6** | **책 한 컷 (Snap-and-Learn) — OCR + 한국어 NLP + 번역 + 내 책장** | **Code + Cloud Function** |
| 6 | Week 7 | 계(契) 데이터 모델 + 모임방 UX | Code |
| 7 | Week 8 | 계 공동 마당 + 주간 목표 + 스티커 채팅 | Code |
| 8 | Week 9 | 모더레이션 (신고·차단·자동 정지) + GDPR (16세 미만 동의) | Code + 문서 |
| 9 | Week 10 | 출시 자료 업데이트 + 실기기 검증 + Closed Testing | 검증 |

**병행 트랙**: Jin이 Phase 3~4 PNG 자산을 Week 2부터 양산 시작. Phase 5 (책 한 컷) 동안 PNG 양산 계속.

---

## 3. Phase 1 — 데이터 구조 (Week 1)

### 3.1 vocab CSV 재구조

**기존 컬럼**: `korean, romanization, german, level, pos_de, example_korean, example_german, topic`

**추가 컬럼**:
- `pack_id` — 팩 식별자. 예: `a1_greetings`, `a1_numbers_1`, `a1_food_basic`
- `pack_order` — 팩 내 단어 순서 (1부터)
- `is_review_boss` — 팩 끝 복습 보스 단어 여부 (각 팩당 3~5개)

**팩 분할 원칙**:
- 팩당 8~15 단어 (5~10분 세션). A1은 평균 10개 → 약 21팩.
- 같은 토픽은 가능하면 한 팩. 큰 토픽(`Alltag` 36개)은 의미군 기준 3~4개 팩으로 분할 (예: `a1_daily_morning`, `a1_daily_evening`, `a1_daily_actions`).
- 작은 토픽(`Geographie` 1개, `Technologie` 1개)은 인접 토픽 팩에 흡수.

### 3.2 Goethe A1/A2 토픽 매핑

Goethe-Institut A1 표준 토픽 (참고 매핑):

| Goethe 토픽 | 기존 CSV 토픽 | 예상 팩 수 |
|---|---|---|
| Begrüßung & Vorstellung | Begrüßung, Höflichkeit, Person | 1~2 |
| Familie & Freunde | Familie, Beziehungen | 2 |
| Zahlen & Zeit | Zahlen, Zeit, Menge | 3 (숫자/시간/날짜) |
| Essen & Trinken | Essen & Trinken | 2 (음식/음료) |
| Wohnen | Position, Alltag (집 부분) | 2 |
| Körper & Gesundheit | Körper | 1 |
| Farben & Formen | Farben, Beschreibung (색깔/모양) | 1 |
| Tägliche Aktivitäten | Alltag (행동 동사) | 3 |
| Gefühle | Gefühle | 1 |
| Bildung & Beruf | Bildung, Beruf | 2 (A2 강화) |
| Verkehr & Reise | Verkehr, Bewegung, Reise | 2 (A2 강화) |
| Einkaufen | Einkaufen | 1 (A2 강화) |
| Wetter & Natur | Wetter, Geographie | 1 (A2 강화) |

**예상 팩 수**:
- A1: 약 21팩
- A2: 약 15팩
- B1: 약 11팩 (TOPIK 중급1 토픽 — 사회 이슈, 직장, 기술)
- B2: 약 9팩 (TOPIK 중급2 토픽 — 시사, 추상)
- **총 ~56팩**

### 3.3 Firestore Schema (User 진행도)

```
users/{uid}/
  profile: {
    nickname: string                  // 임의 생성 또는 사용자 입력 (한국식 닉네임 추천)
    levelActive: 'A1' | 'A2' | 'B1' | 'B2'
    hanokStage: int (0~100)           // 한옥 건축 진행 % (계산값, 표시용)
    decorations: string[]             // 획득한 특별 퀘스트 ID 목록
    titleId: string                   // 호랑이 칭호 (예: 'seonbi')
    streakDays: int
    totalXp: int
    createdAt: timestamp
  }

  packs/{packId}: {
    level: string                     // 'A1' | 'A2' | 'B1' | 'B2'
    status: 'locked' | 'available' | 'in_progress' | 'cleared'
    wordsLearned: int                 // 팩 내 학습한 단어 수
    wordsTotal: int
    accuracy: float (0.0~1.0)         // 보스 단어 정답률
    clearedAt: timestamp | null
    attemptsCount: int
  }

  quests/{questId}: {                 // 특별 퀘스트
    progress: int                     // 현재 진행도 (단어 수, 일수 등)
    target: int
    completedAt: timestamp | null
    decorationGranted: bool
  }
```

**Security Rules**: `request.auth.uid == userId` 만 본인 데이터 read/write.

### 3.4 SRS UX 임시 패치 (Phase 1 후반)

Phase 2 본격 화면 분할 전, **vocab_screen 헤더 한 줄 교체**만 먼저 푸시 (사용자 스트레스 즉시 완화):

기존: `🔥 522 due`
변경: `🔥 오늘의 목표: 새 단어 10개 + 복습 15개`

내부 로직:
- "오늘 신규" = `wordsLearned < wordsTotal`인 활성 팩에서 10개 추출
- "오늘 복습" = SRS due에서 max 15개

전체 진행감 표시는 Phase 2에서 팩 그리드로 대체.

### 3.5 Deliverables (Phase 1)

- [ ] `assets/data/korean_vocab.csv` — pack_id/pack_order/is_review_boss 컬럼 추가 + 분할/병합
- [ ] `docs/data/vocab_pack_map.md` — 팩별 단어 리스트 (검토용)
- [ ] `lib/models/vocab_pack.dart` — 팩 모델
- [ ] `lib/services/vocab_pack_service.dart` — CSV 로더, 팩 그룹화, 진행도 계산
- [ ] `lib/services/firestore_progress_service.dart` — Firestore CRUD
- [ ] `firestore.rules` — 사용자 packs/quests 접근 규칙
- [ ] vocab_screen 헤더 임시 패치 (오늘의 목표 표시)
- [ ] 단위 테스트: 팩 로딩, 진행도 계산, 보스 단어 추출

---

## 4. Phase 2 — 팩 화면 (Week 2)

### 4.1 화면 구조 변경

```
[기존] /vocab → 단일 카드 흐름 (위·아래)

[변경]
/vocab           → 팩 선택 화면 ("팩 마당")
/vocab/pack      → 팩 플레이 화면 (args: packId)
/vocab/result    → 팩 클리어 결과 + 도장 + 다음 팩 추천
```

### 4.2 팩 선택 화면 (VocabPacksScreen)

레이아웃:
- 상단: 현재 레벨 표시 + 한옥 건축 진행 바 (예: `A1 12 / 21 팩 — 기둥 세우는 중`)
- 본문: 팩 그리드 (2 columns)
  - 각 팩 카드: 토픽 아이콘 + 팩 이름 + 진행도 dots (예: ●●●●●○○○○○) + 클리어 시 단청 도장 오버레이
  - 잠긴 팩: 자물쇠 아이콘 + 잠금 해제 조건 (예: "앞 팩 80% 정답률 시")
- 하단: 특별 퀘스트 진행 카드 (Phase 4에서 채움)

**잠금 진행 원칙**:
- 첫 팩만 처음에 열림.
- 이전 팩 보스 단어 70%+ 정답 시 다음 팩 unlock.
- 70% 미달 시 보스 단어만 재도전 가능 (전체 팩 재학습 강제 X — 사용자 친화).

### 4.3 팩 플레이 화면 (VocabPackScreen)

3 단계 흐름:
1. **신규 학습** (팩 내 미학습 단어 카드 — 기존 vocab_screen 카드 컴포넌트 재사용)
2. **미니 퀴즈** (객관식 4지선다 — 한국어→독일어, 독일어→한국어 섞임)
3. **보스 단어 복습** (팩 끝 3~5개 보스 단어 발음 듣고 의미 맞추기)

각 단계 사이에 **호랑이/까치 격려 컷** (1초). 단조로움 깸.

### 4.4 결과 화면 (VocabPackResultScreen)

- 보스 정답률 % 표시 + 단청 도장 시네마틱 (한지 위에 도장 찍히는 0.8초 애니메이션)
- XP 보상: `wordsTotal * 5 + bossCorrect * 10`
- "다음 팩으로" + "마당 보기" 두 CTA
- 한옥 단계가 바뀌었으면 (예: 12팩 → 15팩으로 75% 도달) **한옥 시네마틱 트리거** (Phase 3에서 구현)

### 4.5 Deliverables (Phase 2)

- [ ] `lib/screens/vocab_packs_screen.dart` (팩 선택)
- [ ] `lib/screens/vocab_pack_screen.dart` (팩 플레이 3단계)
- [ ] `lib/screens/vocab_pack_result_screen.dart` (결과 + 도장)
- [ ] `lib/widgets/sori/pack_card.dart` (팩 카드 위젯)
- [ ] `lib/widgets/sori/dancheong_stamp.dart` (도장 시각화)
- [ ] `main.dart` 라우트 등록 (`/vocab` 교체, `/vocab/pack`, `/vocab/result`)
- [ ] DE/EN ARB 키 추가 (팩 이름 토픽 라벨, 잠금 메시지, 결과 카피)
- [ ] PR: 기존 `vocab_screen.dart`는 `_legacy_vocab_screen.dart`로 이름 변경 후 한 번 더 push (롤백용)

---

## 5. Phase 3 — 한옥 건축 진행도 (Week 3)

### 5.1 단계 정의

```dart
enum HanokStage {
  empty,            // 0%       빈 터
  foundation,       // A1 25%   주춧돌
  pillars,          // A1 50%   기둥
  beams,            // A1 75%   대들보 + 서까래
  thatchRoof,       // A1 100%  초가지붕
  tileRoofPartial,  // A2 25-75% 기와 부분
  tileRoofComplete, // A2 100%  기와 완성
  dancheong,        // A2 100% + 첫 단청 퀘스트   처마 단청
  gate,             // B1 50%   솟을대문
  windows,          // B1 100%  창살문
  sideBuilding,     // B2 50%   사랑채
  jongga,           // B2 100%  종갓집 완성 (낙관 + 편액)
}
```

진행도 계산 (`HanokStage computeStage(UserProgress p)`):
- A1 팩 클리어 수 → foundation/pillars/beams/thatchRoof 분기
- A2 진입 시 thatchRoof → tileRoofPartial → tileRoofComplete → dancheong
- B1·B2 동일 패턴

### 5.2 시각화 합성

**옵션 A: PNG 레이어 합성** (추천)
- 각 단계당 마당 PNG 1장 (전체 풍경). 단계 전환은 cross-fade.
- light/dark = 12 단계 × 2 = **24 PNG**.
- 장점: Jin이 Faceted Minhwa 스타일로 통일감 있게 그릴 수 있음.
- 단점: 자산 부담 큼.

**옵션 B: 레이어 합성 (base + 추가 요소)**
- base 마당 1장 + 단계별 요소 PNG (주춧돌, 기둥, 지붕 등) 12개를 stack.
- 장점: 자산 부담 적음, 추가 단계 도입 쉬움.
- 단점: 단계 간 자연스러운 풍경 변화(잡초가 마당 다듬어진 흙으로 바뀌는 등) 표현 어려움.

**결정**: 옵션 A. 일러스트 품질 우선. Jin이 양산하기 어려우면 옵션 B로 fallback.

### 5.3 단계 전환 시네마틱

새 단계 도달 시:
1. 결과 화면에서 "마당이 자라났어요" 배너 + "확인하기" CTA
2. 홈 화면 진입 시 시네마틱 자동 재생:
   - 까치가 화면 왼쪽에서 날아옴 (1초)
   - 새 단계 PNG로 cross-fade (0.5초)
   - 까치가 추가된 부분 위에 앉음 (1초)
   - "기둥이 세워졌어요!" 토스트
3. 한 번 본 단계는 다시 시네마틱 트리거 X (보관 플래그 `seenStages: int[]`).

`SoriMotion.reduceMotion(context)` 시 → 시네마틱 생략, 토스트만 표시.

### 5.4 홈 화면 통합

기존 `home_screen.dart`의 마당 배경 (`madang(light/dark).png`)을 **단계별 동적 배경**으로 교체:
- `MadangBackground(stage: userProgress.hanokStage, brightness: theme)` 위젯
- 데코레이션 (특별 퀘스트로 획득한 장식)은 별도 레이어로 stack (Phase 4)

### 5.5 Deliverables (Phase 3)

- [ ] `lib/models/hanok_stage.dart` (enum + computeStage 함수)
- [ ] `lib/widgets/sori/madang_background.dart` (단계별 배경 + cross-fade)
- [ ] `lib/widgets/sori/hanok_cinematic.dart` (까치 날아옴 + 새 부분 등장)
- [ ] `assets/illustrations/hanok_stages/` 폴더 + pubspec 등록
- [ ] PNG 자산 요청 (Jin, 24장 — Phase 5 자산 명세 참조)
- [ ] 홈 화면 통합 (기존 배경 위젯 교체)
- [ ] 단위 테스트: 모든 진행도 % → 올바른 stage 매핑

---

## 6. Phase 4 — 특별 퀘스트 12개 + 마당 장식 (Week 4)

### 6.1 퀘스트 카탈로그

#### 상시 퀘스트 (조건 달성 시 영구 장식)

| ID | 이름 | 조건 | 장식 | PNG |
|---|---|---|---|---|
| `q_jangdokdae` | 장독대 | 음식 토픽 단어 50개 마스터 (A1+A2) | 마당 한쪽 항아리 5~7개 | 1장 (light+dark) |
| `q_maehwa` | 매화나무 | A2 형용사·감정 단어 30개 마스터 | 매화 한 그루 (봄에 꽃 핌) | 1장 (season variant) |
| `q_sonamu` | 노송 | B1 시나리오 10개 완료 | 큰 소나무 | 1장 |
| `q_pond` | 연못과 잉어 | 자연·날씨 단어 마스터 | 작은 연못 + 헤엄치는 잉어 | 1장 (gif/animated) |
| `q_seokdeung` | 장명등 | 발음 평가 80%+ 100회 | 마당에 석등 (다크 모드 시 빛남) | 1장 |
| `q_punggyeong` | 풍경 (처마 종) | 끝말잇기 10판 승리 | 처마에 풍경 + 바람 사운드 | 1장 (small overlay) |
| `q_pyeonaek` | 편액 (현판) | 한글 자모 100% 마스터 | 대문 위 본인 닉네임 편액 | 1장 (text overlay) |
| `q_doldam` | 돌담 | 친구 코드 5명 등록 (또는 계원 5명) | 마당 둘레 돌담 | 1장 |
| `q_sagunja` | 사군자 4폭 | 매·난·국·죽 각각의 단어 묶음 마스터 (4 sub-quests) | 사랑채 벽에 4계절 그림 | 4장 |
| `q_kkachi_nest` | 까치 둥지 | 30일 streak | 마당 나무에 까치 가족 상주 | 1장 |

#### 계절 이벤트 (시즌 한정, 1~2주만 등장)

| ID | 이름 | 시즌 | 챌린지 | 장식 |
|---|---|---|---|---|
| `q_seollal` | 설날 윷놀이 | 음력 1월 | 윷놀이 미니퀴즈 5판 | 대문에 색동 보드 |
| `q_chuseok` | 추석 보름달 | 음력 8월 | 송편 단어 12개 마스터 | 마당 위 보름달 영구 |
| `q_hangeulday` | 한글날 챌린지 | 10/9 ± 7일 | 훈민정음 28자 미니퀘스트 | 세종대왕 편액 (대문 옆 작은 현판) |
| `q_kite` | 연 날리기 | 4월 어린이날 ± 7일 | 정해진 단어 묶음 마스터 | 마당 위 연 (바람에 흔들림) |

시즌 on/off는 Firebase Remote Config (`active_seasonal_quests: string[]`)로 제어. Jin이 매년 가벼운 수동 토글.

### 6.2 퀘스트 트래킹

`users/{uid}/quests/{questId}` Firestore document:
- 학습 액션마다 관련 퀘스트 progress 증가 (vocab 클리어 → 음식 퀘스트, 시나리오 클리어 → 소나무 퀘스트 등)
- target 도달 시 `completedAt` 기록 + `decorationGranted: true` + `users/{uid}/profile.decorations`에 `questId` push

### 6.3 마당 장식 합성

`MadangBackground` 위에 `DecorationLayer` 스택:
```dart
Stack(children: [
  MadangBackground(stage: ..., brightness: ...),   // Phase 3
  DecorationLayer(decorations: profile.decorations), // Phase 4
])
```

각 장식 PNG는 마당 좌표 (예: `Positioned(left: 0.2, bottom: 0.1, ...)`)로 배치. 데코별 hard-coded position.

### 6.4 퀘스트 진행 화면

홈 화면 하단 또는 신규 `/quests` 라우트:
- 진행 중 퀘스트 카드 (`매화나무: 18 / 30 단어`)
- 완료 퀘스트 갤러리 (획득한 장식 thumbnail)
- 잠긴 시즌 퀘스트 (다음 활성 날짜 표시)

### 6.5 Deliverables (Phase 4)

- [ ] `lib/data/quest_catalog.dart` (12개 퀘스트 정의 + 조건 평가 함수)
- [ ] `lib/services/quest_tracker.dart` (학습 액션 → 퀘스트 progress 업데이트)
- [ ] `lib/widgets/sori/decoration_layer.dart` (마당 장식 합성)
- [ ] `lib/screens/quests_screen.dart` (퀘스트 진행 화면)
- [ ] `assets/illustrations/decorations/` 폴더 + 12 PNG (Jin)
- [ ] Remote Config `active_seasonal_quests` 키 추가
- [ ] DE/EN ARB 키 (퀘스트 이름·설명·조건·완료 메시지 × 14)
- [ ] 단위 테스트: 퀘스트 trigger 정확도

---

## 6.5. Phase 5 — 책 한 컷 (Snap-and-Learn) (Week 5-6)

> 사용자가 한국어 교재 페이지를 사진 찍으면, 앱이 자동으로 단어·문법·예문·발음·번역을 추출해서 학습 카드로 만들어주는 기능.
> 컨셉 이름: **책 한 컷** (Ein Bild aus dem Buch / A Page from the Book).
> 기존 `scripts/build_pool.py` 의 OKT + DeepL 파이프라인을 Cloud Function으로 모듈화해서 재사용.

### 6.5.1 사용자 흐름

1. 홈 또는 신규 `/book` 탭 → "책 한 컷" CTA
2. 카메라 캡처 또는 갤러리 선택 (`image_picker`)
3. 미리보기 + 자르기 (`image_cropper`) — 페이지 일부만 자르기 가능
4. **OCR**: Google ML Kit Text Recognition v2 (on-device, 한국어 지원, 무료)
5. 추출된 한국어 텍스트 미리보기 → 사용자가 오타 수정 가능
6. "분석하기" → Cloud Function `analyzeKoreanText` 호출
7. 결과 화면:
   - **단어 카드 N개**: 한국어 + 발음(로마자) + 독일어/영어 번역 + 예문 + TTS 재생 버튼
   - **문법 패턴 N개**: -고 있다, -아/어서, -(으)ㄹ 것이다 등 검출 + 간단 설명
   - **원문 예시 문장**: 전체 문장 + 번역 + TTS
8. 사용자 액션:
   - 단어 개별 저장 → "내 책장" 안에 커스텀 팩 생성 (예: "Schritte 1 - Lektion 5")
   - 페이지 전체 저장 → 사진 thumbnail + 메모
   - 단어 SRS 큐에 추가 → 일반 단어 학습에 섞임

### 6.5.2 아키텍처

| 기능 | 방식 | 비용 |
|---|---|---|
| OCR | Google ML Kit Text Recognition v2 (on-device) | 무료 |
| 한국어 형태소 분석 | Cloud Function (Python + OKT) — `scripts/build_pool.py` 로직 재사용 | Spark 한도 안에서 무료 |
| 번역 (DE/EN) | DeepL API Free tier | 500K char/month 무료 |
| 발음 (TTS) | 기존 `flutter_tts` (ko-KR) | 무료 |
| 사진 저장 | 기기 로컬만 (Firestore X) | 무료 |
| 텍스트 메타 저장 | Firestore `users/{uid}/bookshelf/{pageId}` | 미미 |

### 6.5.3 Firestore Schema

```
users/{uid}/bookshelf/{pageId}: {
  thumbnailPath: string                // 기기 로컬 경로
  capturedAt: timestamp
  extractedText: string                // OCR 결과 원문
  note: string (max 200자)             // 사용자 메모
  wordsExtracted: array<{
    korean: string
    romanization: string
    posDe: string                      // 명사 / 동사 / 형용사
    translationDe: string
    translationEn: string
    exampleKorean: string
    exampleDe: string
    savedToPack: string | null
  }>
  grammarPatternsFound: string[]       // 검출된 문법 ID
  customPackId: string | null
}

users/{uid}/custom_packs/{packId}: {   // 책 한 컷에서 생성한 팩
  name: string                         // "Schritte 1 - Lektion 5"
  sourcePageId: string
  wordIds: string[]
  createdAt: timestamp
  status: 'in_progress' | 'cleared'
  wordsLearned: int
  wordsTotal: int
}

users/{uid}/custom_words/{wordId}: {   // 기본 CSV에 없는 단어 (글로벌 DB 오염 방지)
  korean: string
  romanization: string
  translations: { de, en }
  example: { korean, de }
  pos: string
  source: 'book_a_page'
  capturedAt: timestamp
}
```

### 6.5.4 Cloud Function: analyzeKoreanText

Python 함수, 기존 `scripts/build_pool.py` 의 OKT + DeepL 로직 모듈화:

```python
# functions/analyze_korean_text/main.py
from konlpy.tag import Okt
import deepl
import kss  # 한국어 문장 분리

translator = deepl.Translator(os.environ['DEEPL_API_KEY'])
okt = Okt()

def analyze_korean_text(request):
    body = request.get_json()
    text = body['text']
    target_lang = body.get('lang', 'de').upper()  # 'DE' or 'EN-US'

    # 1. 형태소 분석 → 의미 있는 품사만
    morphs = okt.pos(text, norm=True, stem=True)
    words = list(dict.fromkeys(
        w for w, pos in morphs if pos in ['Noun', 'Verb', 'Adjective']
    ))[:30]

    # 2. 문장 분리
    sentences = kss.split_sentences(text)

    # 3. 문법 패턴 검출
    grammar = detect_grammar_patterns(text)  # regex 사전

    # 4. 번역 (캐시 hit 우선)
    translations = batch_translate_with_cache(words + sentences, target_lang)

    # 5. 각 단어에 예문 매칭 (원문 sentences 중 해당 단어 포함한 첫 문장)
    word_examples = match_words_to_examples(words, sentences)

    return {
        'words': [
            {
                'korean': w,
                'romanization': romanize(w),
                'pos': pos_map[okt.pos(w)[0][1]],
                'translation': translations[w],
                'example': word_examples.get(w),
                'exampleTranslation': translations.get(word_examples.get(w)),
            }
            for w in words
        ],
        'sentences': [
            {'korean': s, 'translation': translations[s]}
            for s in sentences
        ],
        'grammar': grammar,
    }
```

배포: `firebase deploy --only functions:analyzeKoreanText`
환경변수: `DEEPL_API_KEY`, `NIKL_API_KEY` (선택, 한글 정의 enrichment)

### 6.5.5 번역 캐시 전략

- 동일 한국어 단어/문장에 대한 DeepL 호출 결과를 Firestore `cache/translations/{hash}` 에 30일 보관
- 같은 단어 재요청 시 캐시 hit → DeepL 호출량 절약
- 단어 단위 캐싱 (문장은 hit rate 낮아서 캐시 X)
- 캐시 Cloud Storage 백업 (월 1회)

### 6.5.6 문법 패턴 사전 (초기 50개)

`functions/grammar_patterns.json`:
```json
[
  { "id": "g_progressive", "regex": "고 있[다어]", "name_de": "Progressiv", "explanation_de": "...", "level": "A2" },
  { "id": "g_reason", "regex": "[아어해]서", "name_de": "Begründung", "explanation_de": "...", "level": "A2" },
  { "id": "g_future", "regex": "[으]?ㄹ 것[이]?다", "name_de": "Futur", "explanation_de": "...", "level": "B1" },
  ...
]
```

A1~B2 핵심 문법 50개. 검출되면 해당 패턴 카드 표시 + Grammar 화면으로 link.

### 6.5.7 빈/에러 상태

- **카메라 권한 없음**: 안내 카드 + 설정 열기 버튼
- **OCR 결과 없음** (한국어 미검출): 호랑이 worry + "한국어가 안 보여요. 더 또렷한 사진을 찍어주세요"
- **분석 실패** (Cloud Function 5xx): 까치 worry + "잠시 후 다시 시도해주세요"
- **번역 부분 실패** (DeepL rate limit): 단어만 표시 + 번역에 "—" + "번역 다시 시도" 버튼
- **1일 한도 초과** (20장 이상): "오늘은 충분히 공부했어요" + 내일 다시 안내

### 6.5.8 마스코트 통합

- **분석 중 (3~5초)**: 호랑이 thinking + 까치 wingup 교대 ("호랑이가 단어를 살펴보고 있어요…")
- **분석 완료**: 까치 celebrate + N개 단어 카운터 ("N개의 새 단어를 찾았어요!")
- **첫 사용**: 튜토리얼 카드 (까치 sidekick — "사진을 자르면 더 정확해요")

### 6.5.9 한도 & 비용 관리

- 1인당 1일 max 20장 (DeepL Free 500K char/월 고려, 평균 단어 50자 × 30 = 1500자/장 × 20장 × 30일 × 100명 ≈ 9M char → DeepL Pro 필요할 수 있음)
- 1장당 max 30 단어 추출
- Cloud Function timeout 30초
- **비용 임계점**: DAU 100 도달 시 DeepL Pro ($5.49/100만 char) 검토. 그 전까지는 Free + 캐시로 충분.

### 6.5.10 개인정보·약관 업데이트

- **카메라 권한** 추가: `AndroidManifest.xml`, `Info.plist` (`NSCameraUsageDescription`)
- **개인정보처리방침**: "촬영 이미지는 기기에서만 처리됩니다. OCR로 추출된 텍스트만 분석을 위해 서버로 전송됩니다."
- **DeepL 데이터 공유 명시**: "번역은 DeepL API를 통해 처리되며, EU 외부(독일 DeepL 본사 → AWS Frankfurt) 데이터 처리에 동의가 필요합니다."
- **Data Safety 업데이트**: "Photos: stays on device. Extracted text: sent to DeepL for translation. Photos not stored on our servers."

### 6.5.11 Deliverables (Phase 5)

- [ ] `pubspec.yaml` 의존성: `google_mlkit_text_recognition`, `image_picker`, `image_cropper`, `permission_handler`
- [ ] `lib/services/snap_ocr_service.dart` (ML Kit 래퍼)
- [ ] `lib/services/book_analysis_service.dart` (Cloud Function 클라이언트 + 결과 파싱)
- [ ] `lib/services/bookshelf_service.dart` (Firestore CRUD)
- [ ] `lib/screens/book_capture_screen.dart` (카메라/갤러리 + 자르기)
- [ ] `lib/screens/book_preview_screen.dart` (OCR 결과 사용자 수정)
- [ ] `lib/screens/book_result_screen.dart` (단어/문법/예문 결과)
- [ ] `lib/screens/bookshelf_screen.dart` (내 책장 목록)
- [ ] `lib/screens/bookshelf_page_screen.dart` (저장된 페이지 상세)
- [ ] `lib/widgets/sori/book_card.dart`, `word_extract_card.dart`, `grammar_pattern_card.dart`
- [ ] `functions/analyze_korean_text/main.py` (Cloud Function — OKT + DeepL + 캐시)
- [ ] `functions/requirements.txt` (konlpy, deepl, kss, JPype1)
- [ ] `functions/grammar_patterns.json` (50 패턴 사전)
- [ ] `functions/cache/` 컬렉션 보안 규칙 (read all, write functions only)
- [ ] 5 PNG 일러스트 (Jin — empty bookshelf, camera guide, analyzing, success celebrate, error)
- [ ] DE/EN ARB 키 (책 한 컷 UX 약 25개)
- [ ] 카메라 권한 안내 (Android + iOS)
- [ ] 단위 테스트 (OCR 결과 파싱, 문법 패턴 검출, 캐시 hit/miss)
- [ ] Cloud Function 통합 테스트 (Firebase emulator + 샘플 한국어 텍스트 10개)
- [ ] `docs/privacy.html` 업데이트 (DE/EN — 카메라 + DeepL)
- [ ] `docs/store/data-safety.md` 업데이트

---

## 7. Phase 6 — 계(契) 데이터 모델 + 모임방 UX (Week 7)

### 7.1 컨셉 재확인

**계(契)** — 조선 시대부터 내려온 자발적 학습/저축 모임. 5~10명의 친밀한 그룹.

**v2.0 기능 범위**:
- 비공개 계 (코드로 입장)
- 계장 1명 (생성자)
- 공동 한옥 (계원 진행도 합산 → 더 큰 종갓집)
- 주간 공동 목표 (계장 설정)
- 스티커 채팅 (자유 텍스트 X, 30종 고정)
- 도장 획득 피드 (익명 닉네임)

### 7.2 Firestore Schema (계 데이터)

```
gye/{gyeId}/
  meta: {
    name: string                      // 계 이름 (계장이 설정)
    code: string (6자리)               // 입장 코드
    ownerId: string                   // 계장 uid
    memberCount: int                  // 캐시 (max 10)
    createdAt: timestamp
    weeklyGoalPacks: int              // 주간 공동 목표 (팩 수)
    weeklyGoalEndAt: timestamp        // 매주 일요일 23:59 (KST)
    weeklyGoalProgress: int           // 캐시
  }

  members/{uid}: {
    nickname: string                  // 익명 닉네임
    joinedAt: timestamp
    role: 'owner' | 'member'
    weeklyPacksContributed: int
    status: 'active' | 'reported' | 'suspended'
  }

  feed/{eventId}: {                   // 도장 획득·승급 등 이벤트 피드 (최근 100개만 유지)
    type: 'pack_cleared' | 'quest_completed' | 'level_up' | 'sticker'
    actorUid: string
    actorNickname: string
    payload: map                      // 이벤트별 데이터
    createdAt: timestamp
  }

  stickers/{stickerId}: {             // 스티커 메시지
    senderUid: string
    senderNickname: string
    stickerCode: string (1~30)
    targetEventId: string | null      // 특정 피드 이벤트에 반응
    createdAt: timestamp
  }

  reports/{reportId}: {               // 신고
    reporterUid: string
    targetUid: string
    reason: 'spam' | 'inappropriate' | 'harassment' | 'other'
    note: string (max 200자)
    createdAt: timestamp
    status: 'pending' | 'reviewed' | 'dismissed'
    reviewedBy: 'auto' | 'manual'
    actionTaken: string | null
  }
```

### 7.3 계 입장·생성 흐름

**생성**:
1. 홈 → "계 만들기" CTA
2. 계 이름 입력 (max 20자, 자모 필터링)
3. 6자리 코드 자동 생성 (예: `K3X9W1`)
4. 본인 닉네임 설정 (max 12자, 욕설 사전 필터)
5. 친구에게 코드 공유 (시스템 share sheet)

**입장**:
1. 홈 → "계 입장" → 6자리 코드 입력
2. 닉네임 설정
3. 계 마당 화면 진입

**한도**:
- 1인당 동시 가입 계 max 3개
- 계 max 10명 (계장 + 9명)

### 7.4 계 마당 화면 (GyeScreen)

화면 구조:
- 상단: 계 이름 + 멤버 N명 + 주간 목표 진행 바 (`32 / 50 팩`)
- 중간: 공동 한옥 시각화 (계원 진행도 합산해서 더 큰 한옥)
- 하단: 피드 (최근 이벤트 20개)
- FAB: 스티커 전송

### 7.5 공동 한옥 시각화

개인 한옥보다 한 단계 큰 컨셉:
- 본채 종갓집은 동일 (Phase 3)
- 추가 요소: 행랑채, 별당, 정자, 연못 확장 등
- 계원 합산 진행도 → 추가 요소 잠금 해제
- 계원별 마당 한쪽에 작은 미니 한옥 (계원 칭호 표시)

상세 PNG는 Phase 6에서 양산.

### 7.6 Deliverables (Phase 6)

- [ ] `lib/services/gye_service.dart` (계 CRUD, 입장 코드 생성/검증)
- [ ] `lib/screens/gye_create_screen.dart`
- [ ] `lib/screens/gye_join_screen.dart`
- [ ] `lib/screens/gye_screen.dart` (계 마당)
- [ ] `lib/widgets/sori/gye_hanok.dart` (공동 한옥)
- [ ] `firestore.rules` — 계 접근 규칙 (멤버만 read, 계장만 meta write)
- [ ] 닉네임 욕설 사전 (간단한 deny-list, DE/EN/KO 100단어 정도)
- [ ] DE/EN ARB 키 (계 생성·입장·오류 메시지)

---

## 8. Phase 7 — 계 공동 마당 + 주간 목표 + 스티커 (Week 8)

### 8.1 주간 공동 목표

**설정**:
- 계장이 매주 월요일 자정 (KST) 다음 주 목표 설정 가능
- 목표 종류 (v2.0은 팩 수만):
  - 팩 수: 5 ~ 200
  - (백로그) 시나리오 수, XP 합산, 신규 단어 수

**진행 트래킹**:
- 계원이 팩 클리어할 때마다 `gye/{gyeId}/meta.weeklyGoalProgress` 증가 (Cloud Function 또는 client-side merge)
- 진행 바 실시간 업데이트

**달성 보상**:
- 100% 달성: 계 전체에 "이번 주 목표 달성!" 시네마틱 + 공동 한옥에 작은 장식 1개 영구 추가
- 70%+: XP 부스트 (다음 주 +10%)
- 70% 미만: 다음 주 자동 같은 목표 재시도

### 8.2 스티커 채팅

**스티커 풀** (30종):
- 호랑이 5종 (응원, 박수, 놀람, 슬픔, 사랑)
- 까치 5종 (춤, 손 흔들기, 자장가, 노래, 격려)
- 단청 모티프 5종 (꽃, 별, 구름, 등롱, 한지)
- 한글 자모 5종 (ㅋㅋ, ㅎㅎ, 화이팅, 짱, 굿)
- 음식 5종 (떡, 차, 김밥, 호떡, 식혜)
- 도장 5종 (참 잘했어요, 화이팅, 사랑, 응원, 행복)

PNG 또는 SVG 자산. 키보드형 UI에서 선택 → 전송.

**전송 제한**:
- 1인당 1분당 max 10개 (스팸 방지)
- 1일당 max 100개

### 8.3 피드 알림

피드 이벤트 발생 시 (`pack_cleared`, `quest_completed`, `level_up`):
- 계 멤버 전체에게 푸시 알림 옵션 (사용자가 끄기 가능)
- "○○님이 매화나무 퀘스트를 클리어했어요! 🎉"

스티커는 푸시 없음 (스팸 방지).

### 8.4 Deliverables (Phase 7)

- [ ] `lib/widgets/sori/weekly_goal_bar.dart`
- [ ] `lib/widgets/sori/gye_feed.dart` (이벤트 피드 list)
- [ ] `lib/widgets/sori/sticker_picker.dart` (스티커 키보드)
- [ ] `assets/stickers/` 폴더 + 30 PNG (Jin)
- [ ] Cloud Function `onPackCleared` (계 진행도 합산, 피드 이벤트 생성)
- [ ] Cloud Function `weeklyGoalRollover` (매주 월요일 자정 실행)
- [ ] FCM (Firebase Cloud Messaging) 통합 — 피드 푸시 알림
- [ ] DE/EN ARB 키 (스티커 라벨, 피드 메시지 템플릿)

---

## 9. Phase 8 — 모더레이션 + GDPR (Week 9)

### 9.1 신고 시스템

**신고 가능 대상**:
- 닉네임 (욕설·차별·개인정보 노출)
- 스티커 사용 패턴 (스팸·괴롭힘 — 한 사용자에게 연속 10개+)

**신고 흐름**:
1. 사용자가 피드 이벤트 또는 멤버 프로필 → "신고" 버튼
2. 사유 선택 (spam / inappropriate / harassment / other) + optional note
3. Firestore `gye/{gyeId}/reports/{reportId}` 기록
4. 자동 처리:
   - 같은 대상에 대해 **3건 이상 신고** → 자동 `members/{uid}.status = 'suspended'` (즉시 계에서 가려짐, 전송 불가)
   - Cloud Function 트리거
5. Jin 수동 검토 큐 (Admin 패널):
   - `reports?status=pending` 쿼리
   - 검토 후 `dismiss` 또는 `ban` (계 영구 제명)

### 9.2 Admin 패널 (Jin 전용)

별도 웹 페이지 (Firebase Hosting):
- 신고 큐 (시간순)
- 사용자 검색 (uid로)
- 계 검색 (코드로)
- 닉네임 강제 변경
- 계 강제 해체 (긴급)

**인증**: Firebase Auth Custom Claims (`admin: true`). Jin uid에 set.

### 9.3 GDPR / GDPR-K (16세 미만 독일 사용자)

**기본 원칙**: 데이터 최소화. 계 가입 시 추가 약관 동의 필요.

**16세 미만 (독일)** 사용자 흐름:
1. 가입 시 생년월일 입력 (선택, 안 하면 13~17로 가정)
2. 16세 미만이면 계 입장/생성 **비활성화** (회색 처리 + 안내)
3. 보호자 동의 흐름 (v2.1 이후로 보류 — 현재는 단순 차단)

**데이터 보존**:
- 계 탈퇴 시 → 본인 닉네임·피드 이벤트 30일 후 자동 삭제 (Cloud Function)
- 계 해체 시 → 모든 계 데이터 즉시 삭제

**개인정보처리방침 업데이트** (`docs/privacy.html`):
- 계 데이터 항목 추가
- 신고·차단 데이터 보존 정책
- Cloud Functions 데이터 처리

### 9.4 In-App 계정 삭제 (Play 정책)

CLAUDE.md v1.0.1 후보로 적힌 항목, v2.0에서 같이 처리:
- `AuthService.deleteAccount()`:
  - 모든 가입 계에서 자동 탈퇴
  - `users/{uid}/*` 전체 삭제
  - FirebaseAuth 계정 삭제
- Settings 화면 하단 "계정 삭제" 버튼 + 2단계 확인

### 9.5 Deliverables (Phase 8)

- [ ] `lib/services/moderation_service.dart` (신고 CRUD)
- [ ] `lib/screens/report_screen.dart` (신고 양식)
- [ ] Cloud Function `onReportCreated` (3건 도달 시 자동 정지)
- [ ] Admin 패널 웹 페이지 (separate sub-project `tools/admin/`)
- [ ] `lib/services/age_gate_service.dart` (16세 미만 차단 로직)
- [ ] `AuthService.deleteAccount()` 구현 + Cloud Function `onAccountDeleted` 캐스케이드
- [ ] `docs/privacy.html` 업데이트 (DE/EN)
- [ ] `docs/store/data-safety.md` 업데이트 (Gye 데이터 항목 추가)
- [ ] Settings 화면 "계정 삭제" 추가

---

## 10. Phase 9 — 출시 자료 + 검증 (Week 10)

### 10.1 스토어 자료 업데이트

- [ ] `docs/store/listing-de.md` — "한옥을 함께 짓는 한국어 학습" 포지셔닝 보강
- [ ] `docs/store/listing-en.md` — 동일
- [ ] `docs/store/release-notes-v2.md` — DE/EN 작성
- [ ] 스크린샷 8슬롯 재캡처 (한옥 마당 전후, 계 마당, 도장첩, 특별 퀘스트 갤러리)
- [ ] Feature graphic 재제작 (한옥 + 호랑이 + 까치 + 단청 + "함께 짓다" 카피)
- [ ] Play Store 미디어 업데이트

### 10.2 실기기 검증

Android + iOS 각 1대씩:
- [ ] 신규 사용자 흐름: 가입 → 첫 팩 → 결과 도장 → 한옥 변화
- [ ] 기존 사용자 흐름: 마이그레이션 (CSV 변경) → 진행도 유지
- [ ] 계 흐름: 생성 → 친구 입장 → 주간 목표 → 스티커
- [ ] 신고 흐름: 신고 → 3건 → 자동 정지
- [ ] 모든 한옥 단계 (12개) 시각 검수
- [ ] 모든 특별 퀘스트 (12개) 트리거 검수
- [ ] 계정 삭제 + 데이터 cascade 검증
- [ ] 16세 미만 차단 검증

### 10.3 Closed Testing

- Play Console Closed Testing 트랙: 5~10명 (기존 v1 사용자 위주)
- 1주 운영 → 피드백 → 패치 → Open Testing

### 10.4 Deliverables (Phase 9)

- [ ] 스토어 자료 일체
- [ ] 검증 보고서 (`docs/qa/v2_release_qa_report.md`)
- [ ] Closed Testing 피드백 정리
- [ ] v2.0.0 태깅 + AAB 빌드 + 업로드

---

## 11. PNG 자산 명세 (Jin)

### 11.1 우선순위 1 (Phase 2~3 시작 전 필요)

- 한옥 단계 12 × 2 brightness = **24장** (1024×768, Faceted Minhwa)
- 단청 도장 8 베이스 디자인 (256×256, transparent)

### 11.2 우선순위 2 (Phase 4 시작 전 필요)

- 특별 퀘스트 장식 12장 (각 768×512 이내, transparent, 마당 합성용)

### 11.3 우선순위 3 (Phase 5 — 책 한 컷 필요)

- 책 한 컷 UI 일러스트 5장 (empty bookshelf, camera guide, analyzing, success celebrate, error)

### 11.4 우선순위 4 (Phase 7 필요)

- 스티커 30 (256×256, transparent)
- 공동 한옥 추가 요소 8장 (행랑채, 별당, 정자, 연못 확장 등)

### 11.5 우선순위 5 (Phase 9 출시 전)

- Feature graphic 1024×500
- 스크린샷 frame asset (필요 시)

**총 예상**: ~95 PNG
**제작 방법**: Faceted Minhwa 스타일 가이드 (`docs/HANGUL_SORI_STYLE_GUIDE.md`) 기반 AI 생성 → Jin 다듬기. 주당 평균 12~15장 페이스.
**상세 프롬프트**: `docs/plans/stately-rising-jongga-assets.md` 참조.

---

## 12. CSV 팩 분할 (초안 — Phase 1에서 확정)

전체 56팩 예상. 여기서는 A1 21팩 초안만 제시.

| Pack ID | 이름 (DE) | 토픽 | 단어 수 |
|---|---|---|---|
| `a1_greetings_basic` | Begrüßung & Höflichkeit | Begrüßung, Höflichkeit | 12 |
| `a1_self_intro` | Sich vorstellen | Person | 8 |
| `a1_family` | Familie | Familie, Beziehungen | 13 |
| `a1_numbers_basic` | Zahlen 1-10 | Zahlen (1-10) | 10 |
| `a1_numbers_extended` | Zahlen 11-100 | Zahlen (>10) | 13 |
| `a1_time_clock` | Uhrzeit | Zeit (시간) | 9 |
| `a1_time_calendar` | Wochentage & Monate | Zeit (요일/월) | 12 |
| `a1_time_periods` | Tageszeiten | Zeit (아침/저녁) | 4 |
| `a1_food_basics` | Essen | Essen & Trinken (음식) | 10 |
| `a1_drinks` | Getränke | Essen & Trinken (음료) | 7 |
| `a1_body_parts` | Körperteile | Körper | 10 |
| `a1_colors` | Farben | Farben | 6 |
| `a1_descriptions` | Beschreibungen | Beschreibung | 13 |
| `a1_positions` | Räumliche Position | Position | 12 |
| `a1_home_actions` | Tägliche Handlungen (Zuhause) | Alltag (집 동사) | 12 |
| `a1_school_work_actions` | Tägliche Handlungen (Schule/Arbeit) | Alltag (학교/일) | 12 |
| `a1_outdoor_actions` | Tägliche Handlungen (Draußen) | Alltag (외출) | 12 |
| `a1_feelings_basic` | Gefühle | Gefühle | 3 |
| `a1_shopping_basic` | Einkaufen | Einkaufen | 3 |
| `a1_transport_basic` | Verkehr | Verkehr, Bewegung | 4 |
| `a1_misc_basic` | Sonstiges | Menge, Beruf, etc | ~5 |

**보스 단어**: 각 팩에서 빈도·중요도 기준 3~5개 표시.

A2/B1/B2 분할은 Phase 1 작업 시 동일 원칙으로 확정.

---

## 13. l10n 키 (DE/EN 신규 — 예상 ~80키)

주요 카테고리:
- `pack_*` (팩 이름·잠금·진행 — 약 30)
- `hanok_stage_*` (단계 이름·시네마틱 메시지 — 약 15)
- `quest_*` (특별 퀘스트 이름·설명·완료 — 약 28)
- `gye_*` (계 생성·입장·주간 목표·신고 — 약 25)
- `sticker_*` (스티커 라벨 — 30)

기존 ARB 패턴 (`l10n/app_de.arb`, `l10n/app_en.arb`) 동일하게 추가.

---

## 14. 테스트 전략

### 14.1 단위 테스트 (Dart)

- 팩 로딩 / 진행도 계산
- 한옥 단계 매핑 (모든 % → 올바른 stage)
- 퀘스트 trigger 정확도 (학습 액션 → 올바른 퀘스트 progress)
- 계 코드 생성 (충돌 없음 검증)
- 모더레이션 임계값 (3건 → 정지)

### 14.2 통합 테스트 (Firestore Emulator)

- 계 생성 → 입장 → 진행도 합산 → 주간 목표 달성
- 신고 → Cloud Function → 자동 정지
- 계정 삭제 → 모든 데이터 cascade

### 14.3 위젯 테스트

- 팩 그리드 렌더링 (잠금/진행 중/완료 상태)
- 한옥 시네마틱 (재생/스킵/reduce-motion 대응)
- 스티커 picker

### 14.4 수동 시각 검증

Phase 8 실기기 검증 항목 (위 10.2 참조).

---

## 15. 리스크 & 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| PNG 자산 양산 지연 (85장) | 출시 지연 | errorBuilder fallback 패턴 유지 — PNG 없어도 단색 placeholder로 빌드 정상. 단계별 cascade 출시 (한옥 단계만 먼저, 장식은 차후). |
| 계 모더레이션 부담 | Jin 운영 시간 폭증 | 자동 정지 임계값(3건) + 자유 텍스트 0 + 신고 대시보드. 그래도 부족하면 Closed Testing 단계에서 임계값 조정. |
| Firebase 비용 증가 (Cloud Functions + Firestore 쓰기 증가) | 월 운영비 상승 | Phase 8 직전 비용 시뮬레이션. Spark plan 한도(125k functions calls/일) 안에 들어오는지 확인. 초과 시 Blaze + 예산 알람. |
| 16세 미만 차단으로 사용자 이탈 | DAU 감소 | 차단 대신 "보호자 동의" 흐름 v2.1로 빠르게 후속. |
| 마이그레이션 충돌 (기존 사용자 진행도 손실) | 평점 폭락 | 첫 실행 시 기존 SRS 데이터 → 새 팩 진행도로 자동 매핑 (단어별 mastery → 팩별 wordsLearned). 마이그레이션 단위 테스트 + Closed Testing 검증 필수. |
| 자산 압축 후 한옥 그라데이션 깨짐 (palette 256 한계) | 시각 품질 저하 | 한옥 PNG는 양자화 제외 또는 quality 우선 → ABI split + dynamic delivery 검토. |

---

## 16. 출시 후 로드맵 (v2.1+)

- **v2.1** (출시 +1개월): 보호자 동의 흐름 (GDPR-K), 마당 계절 효과 (봄 매화·여름 푸름·가을 단풍·겨울 눈), 스티커 50종으로 확장
- **v2.2** (출시 +3개월): 계 주간 목표 종류 확장 (시나리오 수, XP 합산, 신규 단어 수), 계 간 친선 리그
- **v2.3** (출시 +6개월): 마당 사용자 커스터마이징 (장식 위치 드래그), 콘텐츠 백로그 (시나리오 30+, B1/B2 단어 100+ 추가)
- **v3.0** (출시 +1년): 자유 텍스트 채팅 (성숙한 모더레이션 인프라 전제), 음성 채팅 (스피킹 파트너 매칭), 공식 자격증 모드 (TOPIK 1·2급)

---

## 17. 의존성·전제

- Firebase Blaze plan (Cloud Functions 사용 위해)
- Firestore 보안 규칙 작성·테스트
- FCM 설정 (피드 푸시)
- Admin 패널 호스팅 (Firebase Hosting 또는 별도)
- PNG 자산 ~85장 (Jin)
- 욕설 사전 (KO/DE/EN 100단어, 첫 1주 안에 작성)

---

## 18. 다음 액션

1. [ ] **Jin 검토 + 승인** (이 plan 전체)
2. [ ] Phase 1 시작: CSV 재분류 + 데이터 구조 작업
3. [ ] PNG 자산 spec sheet 별도 문서 (`docs/plans/stately-rising-jongga-assets.md`)
4. [ ] 욕설 사전 초안

> Phase 1 코딩 시작 전까지 변경·중단 자유. 한 번 코드 작업 들어가면 매 Phase 끝마다 main 머지 + tag.

---

**작성자**: Claude (Cowork)
**검토자**: Jin (pending)
**관련 문서**: `docs/HANGUL_SORI_STYLE_GUIDE.md`, `docs/store/data-safety.md`, `CLAUDE.md`
