# 원어민 자연스러움 전수 재검사 — DE / KO / EN (2026-07-01)

> Jin 요청: "독일어·한국어·영어 표현을 각 언어의 특성에 맞게 가장 자연스럽게."
> 범위 확정(Q&A): **3개 언어 전수 재검사** · KO도 **직접 수정** · 로마자 오타 6건 **함께 수정**.
> 직전 감사: [NATIVE_TEXT_AUDIT_2026-06-18](NATIVE_TEXT_AUDIT_2026-06-18.md) · [LOCALIZATION_DEEP_DIVE_2026-06-09](LOCALIZATION_DEEP_DIVE_2026-06-09.md)

## 방법론 (§0)

언어 자연스러움 판정·편집은 **Opus 메인이 전 표면 직접 통독**. 서브에이전트에 언어 판정 위임 안 함(2026-06-09에 서브에이전트가 없는 영어 대사를 환각한 전례 — `feedback_model_delegation`). 서브에이전트/도구는 텍스트 추출·무결성 카운트만. 대용량은 python 추출 후 직접 정독.

## 총평

**기존 품질이 이미 매우 높음.** 2026-06-09(독일어 딥다이브)·06-18(전수검사) 두 차례 감사 덕에 DE·KO는 원어민급 확정. 이번 패스의 새 발견은 **영어 시나리오 204줄**(과거 "신뢰성 검수 없음"으로 미검수였던 유일 표면)을 직접 정독한 것 — 실제 품질은 **양호**(구어체 idiom 자연스러움). 전 표면 통틀어 확정 결함은 **소수**.

| 표면 | 규모 | KO | DE | EN | 판정 |
|---|---|---|---|---|---|
| `scenarios.json` 대화 | 33개 / 204줄 | native | native | **native**(첫 신뢰 검수) | 결함 1(DE 노트) |
| `scenarios.json` 노트·문법·문화 | 33×다수 | native | native | native | 결함 1 위와 동일 |
| `scenarios.json` 퀘스트 | 전 타입 | — | native | native | 결함 0 |
| `korean_vocab.csv` | 546행 | 교과서급 | native | native | 로마자 6건 |
| `grammar.csv` | 88행 | native | 전문가급 | 전문가급 | 결함 0 |
| `grammar_patterns.json` | 31(DE only) | — | native | (영어 없음) | 결함 0 |
| `kkeunmari_pool.json` | 392(DE gloss) | 사전 명사 | native | (영어 없음) | TODO 0·결함 0 |
| `smalltalk.json` | 145 | native | native | native | 결함 0 |
| `app_de.arb`·`app_en.arb` | 931키 ×2 | (마스코트명 등 의도적 KO) | native | native | 결함 0 |

## 적용한 수정 (8건)

### 1. 독일어 노트의 한국어 조각 — `scenarios.json` `cafe_study` 단어 `영수증`
독일어 노트에 미번역 한국어 조각이 박혀 있던 유일한 진짜 결함. 영어판은 정상이었음.
- DE: `Kassenbon (오늘 영수증에 비번이 있을 때도).` → **`Kassenbon (manchmal steht das WLAN-Passwort darauf).`** (영어 "receipt (sometimes shows the WiFi password)"와 의미 일치)

### 2. 고유명사 로마자 — `scenarios.json` `taxi_street` (DE·EN 4곳)
`성산대교`의 표준 로마자(RR)는 **Seongsan**. 같은 시나리오의 `Mapo`(마포)는 정확했으나 `Sungsan`은 비표준 오기 → 한국어·표준 표기와 일치시킴.
- `Sungsan-Brücke` → **`Seongsan-Brücke`** (DE ×2) · `Sungsan Bridge` → **`Seongsan Bridge`** (EN ×2)

### 3. 로마자 발음표기 오타 6건 — `korean_vocab.csv` `romanization` 열
번역·자연스러움과 무관한 발음 보조 열의 명백한 오타(06-18에 Jin 판단으로 보류 → 이번 승인 반영).

| 행 | 단어 | 수정 전 | 수정 후 |
|---|---|---|---|
| 101 | 싫어하다 | `sireohadam` | `sireohada` (말미 m 오타) |
| 154 | 회의 | `hoei` | `hoeui` |
| 253 | 선택하다 | `seontaek hada` | `seontaekhada` (불필요 공백) |
| 267 | 오히려 | `ohilleo` | `ohiryeo` |
| 272 | 드디어 | `deudieeo` | `deudieo` |
| 447 | 업로드하다 | `eopload-hada` | `eoprodeuhada` (영어 혼입 `load` 제거·`다운로드=daunrodeu`와 통일) |

## 검토 후 유지 (제안 — 미적용, Jin 재량)

각 언어로는 자연스러워 **결함이 아님**. "각 언어 특성에 맞게 자연스럽게"라는 목표상 그대로 두는 것이 정답. 일관성을 더 원하면 변경 가능.

- **사이다 = "Sprite" (EN) vs "Limo" (DE)** — `bunshik` 대사 + diktat 프롬프트 2곳. 독일어는 06-09에 의도적으로 일반명사 `Limo`로, 영어는 브랜드 `Sprite`. 단, 영어 단어노트가 "Clear soda (Sprite-like) — NOT cider!"로 프레이밍하고, **"a Sprite"는 미국식 구어로 가장 자연스러움.** → 유지(각 언어 native). 브랜드 회피 일관성을 원하면 EN을 "lemon-lime soda"류로.
- **`introduce_yourself` DE "Bitte um Ihre Unterstützung"** — `잘 부탁드립니다`의 번역. 단어·문화 노트가 "독일어 등가 없음, 통째로 외우라"고 명시하는 정형구라 직역 허용 범위. 유지.
- **`job_interview` EN 대사 "I give my best to the end"** — 약간 번역체이나 이해 가능(같은 시나리오 퀘스트의 "I'll do my best"는 깔끔). 유지.
- **`gameChosungTitle/navChosung` EN "Initial Quiz"** — 공간 제약 nav 라벨, 설명문이 "from its initial consonants"로 보완. 유지.
- **`onboardingExampleA2Trans` EN "Iced Americano in tall, please."** — 미세하게 어색("a tall iced americano"가 더 자연)하나 온보딩 예시 라벨. 유지.

## 미확인 플래그 (Jin 판단 — 미수정)

- **`색깔` romanization = `saekkkal`** (k 삼중) — 적대적 재스캔에서 발견. 음절별 결합(색=saek + 깔=kkal)으로는 설명 가능하나 일반 통용 표기는 `saekkal`(k 이중)일 수 있음. **확신 불가 + 합의된 오타 6건 범위 밖** → §0대로 미수정, Jin(원어민) 판단에 회부.
- **색채어 형태소 공백** (`ppalgan saek`·`paran saek`·`chorok saek`·`geomeun saek`·`noran saek`) — `hinsaek`/`bunhongsaek`(무공백)과 스타일 불일치이나 오타 아님(형태소 분리는 정당). 범위 밖 → 미수정.

## 검증

- `scenarios.json` `json.load` **OK**, 33 시나리오 불변, 잔여 `오늘 영수증/Sungsan` **0**, `Seongsan` 4·신규 DE 노트 1
- `korean_vocab.csv` **14열 / 546행 / 불량 0**, 로마자 6건 정확, 잔여 옛 오타 **0**
- `flutter test` (편집 표면 8 스위트: data_integrity·scenario_loader·satz_bauen·diktat·grammar_patterns·smalltalk·vocab_pack·scenario_stage_plan) → **70 통과**
- ⚠️ **미검증(Jin 실기기 `flutter run -d 9053622f`)**: DE/EN 토글 양 언어 시각 스팟체크, 수정 표현 실제 화면 노출

## 알림: 동시세션 미완성(내 작업 무관)

`flutter analyze`에 8개 에러 — 전부 동시세션 신규 기능 **cloze**(`assets/data/cloze.json`·`lib/screens/cloze_game_screen.dart`·`lib/services/cloze_loader.dart`·`tools/content_factory/build_cloze.py`, 전부 untracked). ARB에 `cloze*` 키 추가됐으나 **`flutter gen-l10n` 미실행**으로 생성 `AppL10n`에 `clozeTitle`·`clozeEmptyBody`·`clozeInstruction`·`clozeLevelAll` getter 부재. **내 변경(데이터 only)과 무관** — 해당 세션이 gen-l10n 실행하면 해소. 나는 미손댐.
