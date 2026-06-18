# 원어민 자연스러움 전수 검사 — DE · EN · KO (2026-06-18)

> 범위: 앱 전 표면(UI ARB 922 · 시나리오 33 · 문법 88 · 단어장 546 · 끝말잇기 2,453 · smalltalk 145 · grammar_patterns 31 · hangul_data 발음 24). 결정: **DE·EN = 직접 수정**, **KO = 제안만**(Jin 원어민 검토 후 반영).
> §0: 모든 항목은 파일에서 verbatim 확인된 문자열만 인용. 추측·환각 없음.
> **총평:** 2026-06-09 독일어 딥다이브 덕에 **기존 품질이 이미 매우 높음**(시나리오·단어장·문법·smalltalk 모두 원어민급). 이번 패스는 그 위의 잔여 결함과, 한 번도 검수 안 된 한국어/전체 영어를 전수 통독. **실제 결함은 소수**였고, 가장 큰 발견은 끝말잇기 풀의 미번역 자막조각(아래 B-2, 기존에 인지된 항목).

---

## A. 적용한 DE·EN 수정 (직접 반영 완료 · 8건)

### A-1. `lib/l10n/app_de.arb` (독일어 UI)
| 키 | before → after | 사유 |
|---|---|---|
| `coachDojangTitle` | `Dangseon-Stempel sammeln` → `Dancheong-Stempel sammeln` | 단청 로마자 오기. 앱 전체(`dojangEmptyBody`·`gyeStickerCatDancheong`·EN `coachDojang*`)는 **Dancheong** 사용. "Dangseon"은 어디에도 근거 없는 잘못된 표기. |
| `coachDojangBody` | `…um alle 8 Dangseon-Muster zu freizuschalten` → `…um alle 8 Dancheong-Muster freizuschalten` | ① 동일 로마자 오기 ② **문법 오류: "zu freizuschalten" 이중 zu**. `freischalten`은 분리동사 → zu-부정사가 이미 `freizuschalten`(zu 내포). 앞에 zu 추가 = 비문. 동일 파일 `scenariosLocked`·`coachQuestsBody`가 올바른 `um … freizuschalten` 패턴. |

### A-2. `lib/l10n/app_en.arb` (영어 UI)
| 키 | before → after | 사유 |
|---|---|---|
| `coachWordleStep3Title` | `Input & colours` → `Input & colors` | 앱 전반이 미국식(`analyze`/`analyzed`). BrE `colours`만 튐 → 일관성. |
| `coachHangulBody` | `Cards help you practise` → `…practice` | BrE `practise`(동사) → AmE `practice`. |
| `coachScenariosBody` | `practise real everyday situations` → `practice …` | 동일. |

### A-3. `assets/data/korean_vocab.csv` (독일어 예문 일관성)
| 행 | before → after | 사유 |
|---|---|---|
| 33 아버지 | `Mein Vater ist zuhause.` → `…zu Hause.` | `zuhause`/`zu Hause` 둘 다 유효하나 **프로젝트는 `zu Hause`로 통일**(grammar.csv `Ich esse zu Hause.`). 부사형 3건만 통일. |
| 92 있다 | `Ich bin zuhause.` → `Ich bin zu Hause.` | 동일. |
| 175 쉬다 | `Ich ruhe mich zuhause aus.` → `…zu Hause aus.` | 동일. (20행 명사 `Zuhause`는 정상 → 미변경) |

---

## B. 한국어(KO) / 콘텐츠 제안 — ✅ 적용 완료 (Jin "B-1·B-2 반영" 요청)

### B-1. `assets/data/grammar.csv` — `N에서 N까지` (행 17) — ✅ 적용
- **변경**: `월요일에서 금요일까지` → **`월요일부터 금요일까지`** (`note` 독일어열 + `note_en` 영어열 양쪽 = 같은 한국어 예가 2곳).
- **사유**: 시간 시작점은 **부터**, 장소 출발점이 **에서**. `월요일에서`는 원어민이 안 쓰는 어색한 표현.

### B-2. 🔴 `assets/data/kkeunmari_pool.json` — 자막조각 2,061건 제거 — ✅ 적용
- **조치**: §0/메모리대로 **손번역하지 않고**, `german=="TODO"` 2,061건(자막조각: 조사결합형·활용형·문장파편 — 끝말잇기 부적합)을 **풀에서 제거**. 큐레이션된 392 단어만 유지.
- **그래프 재계산**: 삭제 후 각 단어의 `next_count`(후속 단어 수) · `is_dead_end`(후속 0)를 **필터된 392 집합 기준으로 재계산**(메타데이터 stale 방지). 결과: dead-end 163 · startable(nc≥2) **153** → 엔진 `pickStart`/`pickTigerNext` 정상 작동, 게임 플레이 가능(원 설계 225단어 < 현 392).
- **부수 정리**: `meta.total` 2453→392, stale `okt_verified` 제거 + curation 노트 추가. 엔진 docstring `225 단어`→`392 단어(큐레이션)` 갱신.
- **참고**: UI는 이미 `word.german != 'TODO'` 가드로 "TODO" 미표시였음(사용자에 TODO 텍스트 노출 없었음) — 핵심 문제는 부적합 단어가 체인에 쓰이던 것.
- **후속(Jin "사전에서 끌어와서 써" 요청 → 도구 작성):** `tools/content_factory/build_kkeunmari_pool.py` 신규 — hermitdave 빈도시드 → **표준국어대사전(stdict) 명사 검증**(조각 자동 탈락) → DeepL/vocab 글로스 → 풀 재생성. §0대로 손번역 0. 키(`STDICT_API_KEY`+`DEEPL_API_KEY`) 보유한 **Jin이 1회 실행**(학습용 흔한 명사 ~2,500). 오프라인 로직 `--self-test` 통과. 스키마는 data_integrity_test·엔진과 호환.

### B-3. (참고) 로마자(romanization) 오타 — DE/KO 자연스러움 범위 밖, Jin 판단
`korean_vocab.csv`의 `romanization` 열에서 발견한 명백한 오타(번역·자연스러움과 무관, 발음 표기 보조 열):
| 행 | korean | 현재 | 제안 |
|---|---|---|---|
| 101 | 싫어하다 | `sireohadam` | `sireohada` (말미 m 오타) |
| 154 | 회의 | `hoei` | `hoeui` |
| 253 | 선택하다 | `seontaek hada` | `seontaekhada` (불필요 공백) |
| 267 | 오히려 | `ohilleo` | `ohiryeo` |
| 272 | 드디어 | `deudieeo` | `deudieo` |
| 447 | 업로드하다 | `eopload-hada` | 표기 스타일 불일치(영어 혼입) |

---

## C. 검수 통과(이미 원어민급) — 표면별 요약

| 표면 | 분량 | 판정 |
|---|---|---|
| `app_de.arb` UI | 922키 | A-1 2건 외 전부 native. 비격식 du·복합어 하이픈·중성 "Hanok" 등 locked 규칙 준수. |
| `app_en.arb` UI | 922키 | A-2 3건(철자) 외 native. |
| `scenarios.json` 대화 | 33×6 라인 | **DE·KO·EN 전부 native.** 레지스터(존댓/반말/격식) 정확, 2026-06-09 수정(Limo·hoeshik Sie 등) 반영. **결함 0.** |
| `scenarios.json` 문법/문화/단어 노트 | 33개 | 긴 독일어 설명·문화노트 전수 통독 — 정확·idiomatic. **결함 0.** |
| `korean_vocab.csv` | 546행 | DE 예문 native(A-3 통일 3건만), KO 예문 교과서급, EN 정확. |
| `grammar.csv` | 88행 | 독일어 설명 종속절 쉼표·복합어 정확. KO 예문 native(B-1 1건 제안만). |
| `smalltalk.json` | 145구 | 구어체 DE·KO 매우 자연(`-더라고요`·"hat's geschmeckt" 등). **결함 0.** |
| `grammar_patterns.json` | 31 | 독일어 패턴명·설명 native. |
| `lib/data/hangul_data.dart` | 발음 24 | 독일어 발음 가이드 native·정확. |
| `kkeunmari_pool.json` 정상 글로스 | 392 | native(단어장 재사용분). 나머지 2,061은 B-2. |

---

## D. 검증 (실측)

- ARB parity: **DE 922 == EN 922** (양방향 diff 0).
- `flutter gen-l10n`: OK (generated에 `Dancheong` 반영, `Dangseon` 제거).
- CSV: `korean_vocab.csv` 547행 전부 14열 · `grammar.csv` 89행 전부 11열 · **bad 0**.
- JSON: scenarios·smalltalk·kkeunmari·grammar_patterns **파싱 OK**.
- 잔여 확인: `Dangseon` 0 · `zu freizuschalten` 0 · 부사형 `zuhause` 0 · `월요일에서` 0 · kkeunmari `TODO` **0**.
- kkeunmari: 풀 **392** (meta.total 일치) · dead-end 163 · startable 153.
- `flutter analyze lib test`: **No issues found!**
- `flutter test`: **400 passed** (kkeunmari·data integrity 포함).

⚠️ 미검증(Jin): 실기기 시각(코치마크 Dancheong·DE/EN 토글·끝말잇기 392단어 체인 길이 체감), B-3 로마자 오타 반영 여부.
