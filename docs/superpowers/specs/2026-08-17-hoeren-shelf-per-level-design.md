# Hören 책가도 — 레벨별 12칸 서재 설계

> **상태:** 설계 승인 완료(2026-08-17, Jin). 구현 전 스펙.
> **브랜치:** `claude/hoeren-shelf-20260817` (워크트리 `.claude/worktrees/claude+hoeren-shelf-20260817`)
> **기준 커밋:** `3d73d1ac` (main)
> **포섭 관계:** `2026-08-17-scenario-level-category-batch11-design.md`(Batch 11 36개 집필 스펙)를
> 이 문서가 상위에서 포섭한다. Batch 11은 폐기하지 않고 관심 3칸의 첫 씨앗으로 편입한다.

---

## 1. 목적

`/listening`(Hören)의 시나리오 선택을 한 줄 가로 칩에서 **레벨별 책가도 서재**로 바꾼다.
칸은 레벨마다 따로 세우고, 사용자는 자기 레벨의 서재만 본다.

## 2. 실측 (기준 커밋)

| 항목 | 값 | 근거 |
| --- | --- | --- |
| live 시나리오 | **264** | `assets/data/scenarios.json` |
| 레벨 분포 | a1 67 · a2 66 · b1 55 · b2 54 · c1 11 · c2 11 | 같음 |
| distinct `intent` | 237 | 같음 |
| Hören 칩 필터 | `dialog.isNotEmpty` 하나 | `listening_screen.dart:136` |
| 에셋 크기 | 1.60 MB / 264개 = **6.2 KB/시나리오** | `os.path.getsize` |
| 3,600개 투영 | **22.3 MB 단일 에셋** | 6.2 KB × 3,600 |
| 로더 | `rootBundle.loadString` 1회 → `_cached` 전량 상주 | `scenario_loader.dart:15` |
| TTS 단위 | dialog 2,002줄 + quest audioKo 348 = **2,350** (8.9/시나리오) | 실측 |
| backdrop 테이블 | `_categoryById` **264엔트리 · 전수 커버**(고아 0·유령 0) | `scenario.dart:388` |
| pubspec 에셋 등록 | `- assets/data/` **디렉터리 등록** → 샤드 추가에 수정 불필요 | `pubspec.yaml:130` |
| 진행도 저장 | `kl_completed_scenarios` = 단일 `List<String>` | `storage_service.dart:2308` |

**계획서 정정.** 원 계획서의 "90개 / intent 63종"은 Batch 09/10 승격(`3fe6916e`) 이전 수치다.
실제는 264개 / 237종이며, 원래 문제(88번 스와이프)는 262번 스와이프로 악화된 상태였다.

## 3. 확정된 결정

| 항목 | 결정 |
| --- | --- |
| 칸 분류축 | **레벨별로 따로 세운다.** 고정 축을 6레벨에 공유하지 않는다 |
| 레벨당 칸 수 | **12칸** = 기능 9 + 관심 3 |
| 칸당 목표 | **50개** |
| 총량 | 72칸 × 50 = **3,600**. 재고 300(live 264 + Batch 11 36 완주 시) → **신규 3,300** |
| 진입 | Hören 첫 화면이 책가도. 시나리오 선택 시 같은 화면에서 플레이어 뷰로 전환 |
| 칸 선택 | 서랍(바텀시트) — 칸 탭 시 그 칸 시나리오 세로 리스트 |
| 레벨 전환 | **서재 층.** 지난 레벨 서재는 도장이 찍힌 채 남고 언제든 돌아갈 수 있다 |
| 생산 방식 | **하이브리드** — 생성기가 격자·ID·스키마·퀘스트 골격, 대화 8턴×3언어는 장면단위 집필 |
| 배치 단위 | **한 칸 = 한 배치.** 승인·롤백 경계가 UI 서랍과 1:1 |
| 파일럿 | A1 「☕ 카페와 분식집」(`a1_eat`, 재고 3 / 신규 47) |
| 범위 | **Hören만.** `/scenarios`(레벨 섹션 목록)와 Grammatik 화면은 건드리지 않는다 |
| TTS | **Jin이 직접 합성.** 이 설계의 범위 밖. §8 운영 게이트로만 기록 |

## 4. 축 설계 — 72칸

각 칸은 그 레벨에서 실제로 훈련되는 언어 능력을 축으로 세웠다. 재고는 live 264개의 실측
배정이며, **264개 전부가 자기 레벨의 정확히 한 기능칸에 들어간다**(§4.3 검증).

`shelf` 값은 `{level}_{slug}` 형식이다 (예 `a1_transit`).

### 4.1 기능 9칸 (레벨별)

#### A1 — "듣고 반응해서 하루를 넘기기" · 재고 67 / 신규 383
문장을 만드는 단계가 아니라 알아듣고 한 문장으로 반응하는 단계. A1에만 「못 알아들었어요」가
독립 칸인 이유는 되묻기·천천히 요청이 A1의 최상위 생존 능력이기 때문이다.

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `transit` | 🚇 타고 내리기 | 9 | 41 | 안내방송 핵심어, 하차·환승 확인 |
| `taxi_stay` | 🚕 택시·공항·숙소 | 7 | 43 | 주소 말하기, 체크인 확인 |
| `counter` | 🏪 가게와 창구 | 12 | 38 | 수량·무게·가격 되받기 |
| `eat` | ☕ 카페와 분식집 | 3 | 47 | 주문 + 여기/포장 이분 선택 |
| `home` | 🏠 집과 현관 | 8 | 42 | 층·호수·비밀번호 숫자 청취 |
| `greet` | 🙇 인사·호칭·약속 | 9 | 41 | 존댓말 기본형, 늦음 알리기 |
| `repeat` | 🙋 못 알아들었어요 | 6 | 44 | 되묻기·천천히·써주기 요청 |
| `body` | 💊 약국·날씨·안전 | 6 | 44 | 증상 한 단어 + 아픈 곳 지목 |
| `partner` | 🏡 파트너 가족 첫 방문 | 7 | 43 | 첫 인사·절·앉는 자리 |

#### A2 — "절차를 끝까지 밟기" · 재고 66 / 신규 384
단발 응답에서 여러 턴에 걸친 절차로 넘어간다. 은행·통신·계약이 처음 등장하는 레벨이다.

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `move` | 🚉 이동·숙소·분실물 | 16 | 34 | 분실 신고, 대체 경로 협의 |
| `money` | 🏦 은행·통신·요금 | 9 | 41 | 자동이체·한도·요금제 확인 |
| `buy` | 🛍️ 사고 계산하기 | 6 | 44 | 거스름돈·교환·수령 |
| `eat` | ☕ 카페와 식당 | 5 | 45 | 더치페이, 자리·콘센트 요청 |
| `body` | 💇 몸 관리·병원·운동 | 8 | 42 | 원하는 정도를 말하기(길이·색·강도) |
| `apt` | 🏢 아파트와 이웃 | 5 | 45 | 스티커·방문객·소음 규칙 |
| `work` | 💼 근무 첫걸음 | 6 | 44 | 인수인계 메모, 근무표 |
| `plan` | 🗓️ 약속과 연락 | 5 | 45 | 시간 조정, 우천 취소 |
| `partner` | 🏡 파트너 가족과 명절 | 6 | 44 | 반말 실수 복구, 명절 이동 |

#### B1 — "문제가 생긴 뒤를 처리하기" · 재고 55 / 신규 395

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `repair` | 🔧 집 수리와 하자 | 6 | 44 | 하자 설명 + 방문 일정 |
| `refund` | 💸 환불·보상·보증 | 8 | 42 | 규정 확인, 근거 제시 |
| `bill` | 🧾 영수증과 정산 | 4 | 46 | 항목 분리, 증빙 요청 |
| `delay` | 🚆 일정 변경과 지연 | 5 | 45 | 대체안 협의, 대기 순번 |
| `form` | 📋 서류와 대리 접수 | 8 | 42 | 위임·추가 서류·스캔 |
| `team` | 💼 팀 조율과 인수인계 | 9 | 41 | 부재 대체, 회신 범위 |
| `neighbor` | 🤝 이웃과 공용 공간 | 4 | 46 | 순번·조용히·공지 |
| `feel` | ❤️ 감정과 관계 | 5 | 45 | 갈등 완화, 마음 전달 |
| `partner` | 🏡 파트너 가족과의 거리 | 6 | 44 | 사적 질문 피하기, 통역 부담 |

#### B2 — "근거로 협상하고 문서로 남기기" · 재고 54 / 신규 396

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `meeting` | 🗂️ 회의 운영 | 7 | 43 | 안건 교체, 정족수, 시간 관리 |
| `evidence` | 📊 근거와 수치 | 7 | 43 | 출처·축·교차확인·전제 노출 |
| `negotiate` | 🤝 협상과 조건 | 7 | 43 | 필수/양보 구분, 한계선 |
| `contract` | 📄 계약과 서명 | 5 | 45 | 조항 질의, 서명 권한 범위 |
| `notice` | 📮 공식 통보와 이의 | 6 | 44 | 내용증명, 구제 계획 요구 |
| `travel` | 🛄 이동 중 문제 확대 | 5 | 45 | 상급자 연결, 위험 고지 |
| `health` | 🏥 의료·청구·영수 | 4 | 46 | 청구 근거, 진료 설명 되짚기 |
| `public` | 🗣️ 공적 발언과 글 | 8 | 42 | 공개 질의, 문구 수정 요청 |
| `partner` | 🏡 파트너 가족의 경계 | 5 | 45 | 사진 허락, 가사 분담 협의 |

#### C1 — "한계를 명시하며 말하기" · 재고 11 / 신규 439
⚠️ **9칸 중 5칸이 재고 0.** 기존 11개가 브리핑·표본에 몰려 있어 그 두 축만으로 450개를
세울 수 없다. seed 없는 5칸은 집필 난이도가 최상이므로 **순서상 맨 뒤**로 둔다.

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `briefing` | 🎤 브리핑과 발언권 | 4 | 46 | 발언 순서·질의 시간 확보 |
| `uncertainty` | 📉 불확실성과 표본 | 4 | 46 | 표본 편향·상대위험 한정 |
| `access` | 🔐 접근 권한과 기한 | 1 | 49 | 권한 범위·기한 협의 |
| `labor` | 🏡 가족 안의 보이지 않는 노동 | 2 | 48 | 비가시 노동 명명 |
| `conflict_interest` | ⚖️ 이해충돌과 회피 | **0** | 50 | 이해관계 고지·회피 요청 |
| `policy` | 🧭 정책 해석과 재량 | **0** | 50 | 재량 범위 따져묻기 |
| `clinical` | 🩺 전문가 설명과 동의 | **0** | 50 | 설명 후 동의, 대안 요구 |
| `critique` | 🎭 문화·예술 비평 | **0** | 50 | 근거 있는 호오 표현 |
| `mediation` | 🌐 다문화 갈등 조정 | **0** | 50 | 입장 재진술, 중재 |

#### C2 — "제도의 빈틈을 언어로 짚기" · 재고 11 / 신규 439
⚠️ **3칸이 재고 0.**

| slug | 칸 | 재고 | 신규 | 훈련 능력 |
| --- | --- | ---: | ---: | --- |
| `automation` | 🤖 자동화 결정과 이의 | 2 | 48 | 알고리즘 결정 이의 설계 |
| `record` | 🗄️ 기록·추적·보존 공백 | 2 | 48 | 로그 부재를 논증 |
| `discourse` | 🗣️ 담화의 전제와 은폐 | 2 | 48 | 수동태 은폐 지적 |
| `mandate` | ⚖️ 권한의 경계와 철회 | 2 | 48 | 위임 철회·경계 사례 |
| `impact` | 📊 불균등한 영향 | 1 | 49 | 집단별 차등 영향 |
| `memory` | 🏡 장소와 이름의 기억 | 2 | 48 | 기록되지 않은 기억 |
| `ethics` | 🧬 연구 윤리와 동의 | **0** | 50 | 동의 범위·재사용 |
| `history` | 🕊️ 역사 서술과 화해 | **0** | 50 | 서술 주체·복수 서사 |
| `aesthetic` | 💠 미학과 번역 불가능성 | **0** | 50 | 번역 손실 논증 |

### 4.2 관심 3칸 (모든 레벨 공통 slug)

기능축은 *생활 절차*, 관심축은 *관심사*다. 하나의 taxonomy로 합치면 둘 다 망가지므로
칸을 분리한다. live 264개에는 이 축이 사실상 없다(`plans_with_friend`·`friend_birthday` 둘뿐)
— Batch 11이 그 공백을 채운다.

| slug | 칸 | 소재축 | Batch 11 재고/레벨 | 신규/레벨 |
| --- | --- | --- | ---: | ---: |
| `friends` | 🫂 친구 수다 | 약속·고민상담·모임 정산·잠수 | 1 | 49 |
| `dating` | 💗 데이트·연애 | 소개팅·썸·기념일·싸움과 화해 | 1 | 49 |
| `fandom` | 🎧 팬덤·게임·콘텐츠 | 최애·입덕·티켓팅·굿즈 · 랭크·듀오·패치·현질 · 알고리즘·쇼츠·구독 | 3 | 47 |

**Batch 11 36개의 편입.** Batch 11의 6카테고리는 다음과 같이 배정된다 — `daily` 6개는
각 레벨의 해당 **기능칸**으로, `friends` 6 → `friends`, `dating` 6 → `dating`,
`youtube`/`gaming`/`kpop` 18 → `fandom`. 버려지는 산출물은 없다.

`fandom`이 3개 소재를 묶는 이유: 유튜브·게임·덕질은 화행이 같다(취향 선언 → 근거 → 온도차
조율). 칸을 셋으로 쪼개면 레벨당 15칸이 되어 서재가 다시 커진다.

⚠️ **Batch 11 draft의 결함.** 현재 draft 18개에 `shelf`/`category` 필드가 **0개**이고,
카테고리가 `a1_kpop_my_bias`처럼 **ID 슬러그에만** 들어 있다. UI가 슬러그 문자열을 파싱해
서랍을 만드는 것은 계약이 아니다. Batch 11 완주 시 §5.1의 `shelf` 필드를 반드시 포함한다.

**보류.** A2의 `plans_with_friend`·`friend_birthday`는 현재 `a2_plan`에 있다. `a2_friends`로
옮기는 게 더 맞을 수 있으나, §4.3 검증이 끝난 배정을 흔들지 않기 위해 이번에는 옮기지 않는다.
파일럿 이후 별건으로 재검토한다.

### 4.3 검증 계약

기능 54칸 배정은 다음을 만족함이 확인됐다(264개 전수):

```
live 264 | assigned 264
DUPES 0 | ORPHANS 0 | GHOSTS 0 | WRONG LEVEL 0
```

`WRONG LEVEL 0`은 **모든 시나리오가 자기 레벨의 칸에만 배정됨**을 뜻한다. 이 4개 지표는
마이그레이션 스크립트의 fail-closed 조건으로 옮긴다. 하나라도 0이 아니면 원복한다.
전체 id→칸 배정은 부록 A다.

## 5. 데이터 계약

### 5.1 필드 2개 추가

| 필드 | 타입 | 값 | 비고 |
| --- | --- | --- | --- |
| `shelf` | string | `{level}_{slug}` (예 `a1_transit`) | 서랍을 결정 |
| `backdrop` | string | 기존 12개 열거값 | 장면 그림을 결정 |

**두 축은 독립이다. `backdrop`을 `shelf`에서 파생시키지 않는다.** 파생 시 기존 264개 중
**102개의 배경 그림이 바뀐다**(실측). 재고가 있는 46칸 중 backdrop이 단일한 칸은 10개뿐이다:

```
a2_move    {station 6, taxi 2, hotel 2, directions 2, airport 1, cafe 1, market 1, convenience 1} -> 10개 변경
a1_counter {convenience 5, market 2, office 2, restaurant 1, pharmacy 1, home 1}                  ->  7개 변경
```

이유가 분명하다 — `backdrop`은 *어디서 벌어지나*, `shelf`는 *무엇을 배우나*다. A1
「가게와 창구」에 편의점·시장·약국·우체국 장면이 섞여 있는 건 오류가 아니라 정상이다.

### 5.2 `_categoryById` 이관

`scenario.dart:388`의 264엔트리 const map을 **삭제가 아니라 JSON `backdrop` 필드로 이관**한다.
주석이 *"Add new scenarios here"* 라서 현재는 **시나리오 추가마다 Dart 수정**을 요구하는데,
신규 3,300개에서 이 규칙은 무너진다. 이관 후:

- Dart에서 264엔트리 제거. 파생 테이블도 두지 않는다 (남는 건 아무것도 없다)
- 신규 3,300개의 Dart 수정 횟수 **0**
- 배경 회귀 **0개** (기존 값을 그대로 옮기므로)
- `SceneAssetResolver`의 per-scenario 자산 오버라이드 동작은 변경하지 않는다

### 5.3 레벨 샤딩

`assets/data/scenarios.json` → `assets/data/scenarios_{a1,a2,b1,b2,c1,c2}.json` 6개.

- pubspec은 `- assets/data/` 디렉터리 등록이므로 **수정 불필요**(실측)
- 레벨당 약 3.7 MB (600개 × 6.2 KB), 단일 22.3 MB 대비 로드량 1/6
- **UI 필터링은 로딩을 줄이지 않는다** — 현재 로더는 전체를 파싱한 뒤 `.where(level)`로
  거르므로, 화면이 자기 레벨만 보여줘도 22.3 MB를 전부 메모리에 올린다. 파일을 물리적으로
  쪼개는 것이 유일한 해결이다

### 5.4 마이그레이션과 승인 게이트

기존 264개에 `shelf`/`backdrop`을 소급 부여하는 것은 **문장을 건드리지 않는 메타데이터
변경**이다. 따라서 콘텐츠 재검수 없이 처리한다:

1. `validate_content.py`에 `shelf`/`backdrop` 스키마 규칙 추가 (열거값 검사, 필수)
2. 일회성 마이그레이션이 264개에 두 필드를 주입하고 6샤드로 분할. §4.3의 4개 지표가
   하나라도 0이 아니면 원복
3. 신규는 draft에 `shelf`/`backdrop`을 포함해 그 칸의 배치 승인에 태운다

⛔ 문장·ID·레벨은 이 마이그레이션에서 바꾸지 않는다.

## 6. 프론트엔드

| 항목 | 변경 |
| --- | --- |
| `scenario_loader.dart` | 사용자 레벨 샤드 1개만 로드. 서재 층 전환 시 해당 레벨 샤드를 추가 로드하고 LRU로 2개까지만 상주 |
| 진행도 | `kl_completed_scenarios`를 레벨별 키(`kl_completed_scenarios_{level}`)로 분할 + 칸별 완료 카운트 캐시. 도장 UI는 카운트만 읽고 전체 리스트를 파싱하지 않는다 |
| 레벨 소스 | `Storage.userLevelCode` / `placementLevelPreferenceKey` 기존 값을 그대로 쓴다. 새 레벨 개념을 만들지 않는다 |

**진행도 규모 주석.** 레벨 선택 덕에 실질 규모는 한 레벨 600개 ≈ 12 KB로 떨어져 단일 List로도
견딜 수 있다. 분할은 레벨을 올려가며 누적될 때를 위한 예방이며, 우선순위는 샤딩보다 낮다.

## 7. UI — 서재 → 서랍 → 플레이어

| 층 | 내용 |
| --- | --- |
| 서재 | 사용자 레벨의 12칸을 2열 × 6행 그리드. 상단에 **층 전환**(A1/A2/…) — 지난 레벨 서재는 도장이 찍힌 채 남고 언제든 돌아갈 수 있다 |
| 칸 표지 | 칸 이름 + backdrop 크롭 + **`n/50` 집계 도장**. 50개를 개별 도장으로 찍으면 시각적으로 안 읽히므로 수집감은 칸 단위로 준다 |
| 서랍 | 칸 탭 → 바텀시트에 그 칸 시나리오 세로 리스트. **진행도 정렬**(안 한 것 위 / 완료 아래) |
| 플레이어 | 시나리오 선택 시 같은 화면에서 플레이어 뷰로 전환 |
| 상단 점유 | 히어로 배너·부제·"Szenario wählen" 라벨·칩 줄을 걷어낸다. 발화 카드가 접힌 채 시작하지 않는다 |

**자산.** 기존 `assets/illustrations/scenes/` 12장을 칸 표지로 재사용한다. 레벨이 서재를
가르므로 **같은 레벨 안에서만 겹치지 않으면 되고**, 레벨당 12칸이므로 12장으로 정확히 충분하다.
신규 칸 자산 제작은 이 설계의 범위에 없다.

**서랍 크기.** 계획서가 8칸을 버린 이유는 "28권 서랍은 원래 문제를 재현한다"였다. 레벨별 칸은
사용자에게 **자기 레벨의 서랍 50개**만 보이므로 그 판단과 어긋나지 않는다.

## 8. 범위 밖 / 운영 게이트

| 항목 | 처리 |
| --- | --- |
| **TTS** | **Jin이 직접 합성한다.** 이 설계는 합성·업로드·검증을 수행하지 않는다. 참고 물량: 신규 3,300개 × 8.9 = 약 **29,400 클립**. 규칙만 못 박는다 — **칸 승인 → 그 칸 TTS → 다음 칸.** 오디오 없는 칸은 서재에서 "준비 중"으로 잠근다. Hören은 오디오가 본질이므로 `flutter_tts` 폴백 음질로 듣기 학습을 시키지 않는다 |
| Grammatik 화면 | 범위 밖 (Jin 지시, 2026-08-17 — 다른 세션 담당) |
| `/scenarios` 레벨 섹션 목록 | 이번에 건드리지 않는다 |
| Firebase·Firestore 스키마 | 변경 없음 |

## 9. 미결로 남긴 것

| # | 항목 | 언제 정하나 |
| --- | --- | --- |
| 1 | **50이라는 수가 미검증** | 파일럿이 답. `a1_eat` 47개가 억지 없이 나오지 않으면 그것이 목표 재조정 신호다 |
| 2 | **레벨당 600개가 제품으로 맞나** | 사용자가 600개를 다 듣지는 않는다. "칸을 다 채우는 게 목표"인지 "사용자 소화량이 목표"인지에 따라 칸당 50 중 핵심 15개를 필수로 표시하는 층이 필요할 수 있다. 파일럿 이후 결정 |
| 3 | `a2_plan` ↔ `a2_friends` 재배정 | 파일럿 이후 별건 |
| 4 | C1/C2 재고 0 칸 8개의 집필 기준 | 해당 칸 배치 착수 시. seed가 없어 기준을 먼저 세워야 한다 |

## 10. 실행 순서

```
1. 칸 축 확정        shelf/backdrop 스키마 + validate_content.py 규칙
2. 마이그레이션       264개에 두 필드 주입 + 6샤드 분할 (fail-closed 4지표)
3. 로더·진행도        레벨 샤드 로드 + 진행도 키 분할
4. 파일럿 1칸         a1_eat 47개 집필 → review 승인            (Batch 12)
5. 그 칸 TTS          Jin
6. 책가도 UI          서재(층) → 서랍(n/50) → 플레이어
7. 실측 반영 후 잔여   기능칸 → 관심칸 → C1/C2 seed 0 칸 (맨 뒤)
```

1·2가 먼저인 이유는 파일럿 47개가 갈 자리가 없으면 4번이 곧 재작업이 되기 때문이고,
4+5를 한 칸으로 붙여 끝내는 이유는 72칸 파이프라인 전체가 한 번 실증되어야 잔여 71칸의
일정을 숫자로 잡을 수 있기 때문이다.

**배치 번호.** Batch 11은 진행 중(관심축 36개)이므로 이 설계의 첫 칸 배치는 **Batch 12**다.
이후 한 칸당 한 배치를 부여한다.

## 11. 검증 방법

| 대상 | 방법 |
| --- | --- |
| 칸 배정 | §4.3의 4개 지표(DUPES/ORPHANS/GHOSTS/WRONG LEVEL)를 마이그레이션 테스트로 고정 |
| backdrop 무회귀 | 마이그레이션 전/후 264개의 `backdropKey` 값이 **완전히 동일**함을 단정하는 테스트 |
| 샤딩 | 6샤드 합집합이 원본 264개와 id 집합으로 일치. 레벨별 개수 67/66/55/54/11/11 고정 |
| 로더 | 사용자 레벨 샤드만 읽는지, 층 전환 시 2개까지만 상주하는지 위젯 테스트 |
| UI | 서재 12칸 렌더, 서랍 진행도 정렬, `n/50` 카운트, reduced-motion 계약 |
| 콘텐츠 | 기존 게이트(validator + review 원장). 문장 품질은 `humanizer` + 칸 단위 육안 검수 |

---

## 부록 A — 기능 54칸 id 배정 (live 264 전수)

`WRONG LEVEL 0` 검증을 통과한 배정이다. 마이그레이션 스크립트의 입력이 된다.

### A1
- `a1_transit` — a1_bus_late a1_last_train a1_platform_line a1_station_rest a1_subway_exit a1_thanks_seat a1_card_topup a1_locker_key a1_meet_station
- `a1_taxi_stay` — a1_airport_cart a1_taxi_address a1_direction_left a1_hotel_key airport_arrival hotel_checkin taxi_kakao
- `a1_counter` — a1_market_bag a1_rice_shop a1_water_shop a1_mask_pack convenience_store mart_grocery a1_post_queue a1_parcel_weight a1_stamp_ask a1_submit_name delivery_address_confirmation a1_office_print
- `a1_eat` — a1_cafe_wifi a1_tea_order bunshik_tteokbokki
- `a1_home` — a1_door_bell a1_floor_number a1_gate_code a1_hall_shoes a1_home_light a1_neighbor_box home_morning_routine a1_trash_sort
- `a1_greet` — introduce_yourself first_class_meeting titles_relationship_distance a1_sorry_late a1_excuse_pass a1_late_text phone_messenger_reply a1_cancel_walk a1_weekend_rain
- `a1_repeat` — a1_ask_again a1_slow_speech clarify_repeat a1_whiteboard_word a1_class_pencil survival_day_capstone
- `a1_body` — a1_pharmacy_hours a1_pharmacy_ointment a1_dust_mask clinic_safety a1_rain_jacket a1_weather_layer
- `a1_partner` — a1_partner_first_door a1_partner_gift_too_big a1_partner_more_side_dishes a1_partner_wrong_seat a1_partner_new_year_money a1_partner_seollal_bow a1_partner_songpyeon_too_big

### A2
- `a2_move` — a2_direction_bus a2_station_lost a2_seat_hold subway_directions subway_transfer ktx_ticket a2_booth_line a2_taxi_wait taxi_street a2_airport_sim a2_data_roam a2_front_desk a2_hotel_late a2_found_umbrella a2_lost_wallet lost_phone
- `a2_money` — a2_auto_debit a2_bank_number a2_card_balance a2_transfer_limit a2_bill_high a2_phone_plan a2_label_phone rent_bank_transfer a2_night_pay
- `a2_buy` — a2_market_change a2_water_set a2_convenience_copy a2_id_pickup myeongdong_shopping a2_food_bag
- `a2_eat` — a2_cafe_plug a2_tea_taste a2_restaurant_split cafe_starbucks_basic cafe_study
- `a2_body` — a2_dye_dark a2_hair_time a2_salon_cut a2_gym_lock gym_signup a2_stretch_start feeling_sick pharmacy_headache
- `a2_apt` — a2_apt_sticker a2_guest_pass a2_quiet_ten a2_recycle_box a2_contract_read
- `a2_work` — a2_handover_note a2_manager_leave a2_office_badge a2_shift_table a2_volunteer_vest a2_festival_stamp
- `a2_plan` — a2_hours_six a2_rain_cancel friend_birthday plans_with_friend running_late
- `a2_partner` — a2_partner_banmal_slip a2_partner_group_chat_join a2_partner_morning_greeting a2_partner_hanbok_rental a2_partner_holiday_train a2_partner_leftover_bags

### B1
- `b1_repair` — b1_leak_report b1_repair_photo b1_repair_visit_followup b1_heating_safety_call b1_move_in_handover b1_contract_appointment
- `b1_refund` — b1_refund_rule b1_warranty_week b1_market_claim b1_claim_same_day b1_return_visit b1_quote_change b1_deductible food_delivery
- `b1_bill` — b1_bill_split b1_cafe_invoice b1_taxi_receipt bank_account
- `b1_delay` — b1_connecting b1_pickup_delay b1_typhoon_change b1_waitlist b1_hotel_shift
- `b1_form` — b1_proxy_form b1_civil_ticket b1_case_status b1_school_letter b1_parent_slot b1_extra_paper b1_scan_note b1_intranet_form
- `b1_team` — b1_team_meeting_coordination b1_covering_absence b1_reschedule_request b1_attendance_followup b1_followup_mail b1_mail_cc b1_missing_file b1_volunteer_gap company_dinner_hoeshik
- `b1_neighbor` — b1_guest_notice b1_laundry_turn b1_quiet_exam b1_safety_vest
- `b1_feel` — couple_argument love_confession warm_encouragement cancel_plans postpone_plans
- `b1_partner` — b1_partner_drink_table b1_partner_heavy_bags_home b1_partner_interpret_skip b1_partner_marriage_question b1_partner_overnight_door b1_partner_salary_deflect

### B2
- `b2_meeting` — b2_agenda_swap b2_minutes_draft b2_quorum_wait b2_time_box b2_hold_share business_meeting_intro b2_decision_criteria_workshop
- `b2_evidence` — b2_chart_axes b2_metric_clear b2_cross_check b2_source_check b2_market_source b2_assumption b2_review_three
- `b2_negotiate` — b2_counter_offer b2_must_have b2_limit_line b2_restore_scope b2_next_level job_interview b2_deadline_deferral_request
- `b2_contract` — b2_contract_clause_inquiry b2_signature_scope_confirmation b2_hotel_clause b2_vacate_short b2_case_id
- `b2_notice` — b2_certified_mail b2_objection_status_request b2_remedy_plan_request b2_evidence_date b2_device_failure_escalation complaint_delivery
- `b2_travel` — b2_airport_reseat b2_station_hold b2_taxi_escalate b2_direction_risk b2_on_site
- `b2_health` — doctor_consultation b2_pharmacy_claim b2_convenience_scan b2_restaurant_note
- `b2_public` — b2_public_question b2_public_wording_feedback b2_reading_circle_response b2_cafe_brief b2_one_pager b2_read_receipt b2_selective_edit b2_self_fail
- `b2_partner` — b2_partner_dowry_joke b2_partner_inlaw_rotation b2_partner_photo_permission b2_partner_public_intro b2_partner_holiday_labor_chart

### C1
- `c1_briefing` — c1_briefing_number c1_leading_item c1_speaking_slot c1_question_window
- `c1_uncertainty` — c1_sample_bias c1_uncertainty c1_relative_risk c1_survey_limits_briefing
- `c1_access` — c1_access_time
- `c1_labor` — c1_partner_invisible_labor c1_partner_guest_or_family
- `c1_conflict_interest` · `c1_policy` · `c1_clinical` · `c1_critique` · `c1_mediation` — 재고 0

### C2
- `c2_automation` — c2_appeal_bot c2_automated_decision_appeal
- `c2_record` — c2_archive_gap c2_trace_log
- `c2_discourse` — c2_discourse_premise c2_passive_hide
- `c2_mandate` — c2_mandate_edge c2_withdraw_deep
- `c2_impact` — c2_uneven_impact
- `c2_memory` — c2_partner_document_the_place c2_partner_name_and_memory
- `c2_ethics` · `c2_history` · `c2_aesthetic` — 재고 0
