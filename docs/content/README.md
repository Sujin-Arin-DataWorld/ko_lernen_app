# 한글소리 — 컨텐츠 개발 SSoT 인덱스

> 이 폴더는 v1.0.1 이후 **컨텐츠** 확장 작업의 단일 진실. UI/디자인은 별도 (`docs/ai/` 디자인 세션).

## 컨텐츠 산출 4 트랙 (2026-05-21 기준)

| 트랙 | 문서 | 목표 산출물 |
|---|---|---|
| **A. 시나리오 양산** | [`01-llm-scenario-prompt.md`](01-llm-scenario-prompt.md) **v2** | **5종 프롬프트 매뉴얼** (생성·검수·메타·코드·뉴스레터) + few-shot couple_argument JSON 박힘 + grammar.csv 88 IDs 박힘 + 주간 워크플로우 + 실패모드 3종 |
| **A. 시나리오 양산** | [`02-scenario-roadmap.md`](02-scenario-roadmap.md) | 신규 17개 시나리오 spec (id, level, sidekick, intro hook, grammar focus, cultural angle) |
| **B. 모듈 통합 그래프** | [`03-module-integration.md`](03-module-integration.md) | vocab/grammar/scenario 간 자동 메타 링크 설계 + 마이그레이션 plan |
| **C. 5분 코스 + 온보딩** | [`04-onboarding-and-5min.md`](04-onboarding-and-5min.md) | 6-동기 온보딩 카피 + 5분 코스 알고리즘 + 추천 가중치 |
| **D. 시즌 1 + 끝말잇기** | [`05-season1-and-kkeunmari.md`](05-season1-and-kkeunmari.md) | 시즌 패키징 + 끝말잇기 단어 풀 자동 추출 + 게임 로직 |

## 검증된 컨텐츠 현황 (2026-05-21)

| 자산 | 양 | 빈 칸 |
|---|---|---|
| 시나리오 | 13개 | **B2 0개**, magpie 사이드킥 0회 |
| 어휘 | 526개 (A1:211, A2:140, B1:103, B2:72) | TOPIK 빈도 메타 부재 |
| 문법 | 88개 (A1:27, A2:23, B1:22, B2:16) | 시나리오와 자동 join 없음 |

## 컨텐츠 SSoT 파일 위치

- `assets/data/scenarios.json` — 시나리오 (스키마: [`lib/models/scenario.dart`](../../lib/models/scenario.dart))
- `assets/data/korean_vocab.csv` — 어휘 (header: `korean,romanization,german,level,pos_de,example_korean,example_german,topic`)
- `assets/data/grammar.csv` — 문법 (header: `pattern,level,type_de,explanation_de,example_korean,example_german,note`)

## 6개 Quest Type 데이터 shape (검증됨)

| Type | data 필드 |
|---|---|
| `hoerverstehen` | `audioKo`, `options[{de,en}]`, `correctIndex` |
| `luecken` | `sentence (___ 포함)`, `options[ko]`, `correctIndex` |
| `uebersetzen` | `promptDe`, `promptEn`, `options[{ko}]`, `correctIndex` |
| `particlePop` | `prefix`, `suffix`, `options[ko]`, `correctIndex`, `explanationDe`, `explanationEn` |
| `batchimDrop` | `audioKo`, `targetWord`, `targetSyllableIndex`, `options[ko consonants]`, `correctIndex`, `explanationDe/En` |
| `schreiben` | (개별 시나리오 참조 — schema 확정 시 추가) |

## Sidekick 값 (코드 + 데이터 검증, 2026-05-21)

| 값 | 마스코트 | 코드 라우팅 | 데이터 사용 |
|---|---|---|---|
| `"minsu"` / `"jieun"` | 호랑이 (tiger) | ✅ `mascot.dart:57` | 13개 중 12개 |
| `"kkachi"` / `"magpie"` | 까치 (magpie) | ✅ `scenario_player_screen.dart:564` | 0개 (Track A 신규부터 도입) |
| `"partner"` | (★ 신규 마스코트 v1.0.3+) | ❌ 라우팅 미구현 (fallback) | 1개 (`couple_argument`) |
| `null` / 빈 값 | 이모지 fallback | — | 0개 |

→ 「좋은 소식 / 시험 합격 / 결혼식 / 친구 위로」 = **magpie**
→ 「연인 다툼 / 데이트 / 가족 친밀 대화」 = **partner** (마스코트 디자인 대기 중)

### ⚠️ 디자인 세션 전달 사항 (partner 마스코트)

`couple_argument`는 이미 `sidekick: "partner"`로 데이터에 있으나 `mascot.dart`에 partner 케이스 분기가 없어 fallback 행동. v1.0.3 디자인 sprint에 partner 마스코트(예: 분홍/연한 톤의 호랑이 또는 별도 캐릭터) 추가하거나, 또는 partner sidekick을 호랑이로 alias하는 코드 변경 필요. 이 매뉴얼 v2는 사용자 의도(partner = 별도 마스코트)를 보존.

## 작업 원칙

1. **추측 0**: 시나리오 작성 시 어휘는 가능한 한 `korean_vocab.csv`에 이미 있는 단어 사용. 신규 어휘는 시나리오 vocab[]에 note와 함께 명시.
2. **번역은 모국어**: 모든 ko 텍스트는 학습 대상. de/en은 모국어 번역으로 단순/자연스럽게.
3. **인공적 격식 X**: K-드라마/실생활 톤 우선. "Lehrer가 가르치는 식" 회피.
4. **문화 차이를 가르침**: 한국어 특유 표현 (서운하다, 정, 눈치, 회식 분위기 등) 적극.
5. **각 시나리오 = 약 5~10분 학습**. dialog 6~10줄, quest 4~6개.
