# 콘텐츠 확장 작업지시서 — B1/B2 대형 (2026-08-14 Jin 승인)

> 실행 세션은 이 문서 + `docs/HANDOFF_UI_OVERHAUL_2026-08-14_V2.md` §3(방법론)을 정본으로 삼는다.

> 선행 UI/UX 개편(Phase 0~3)은 `dcef0ba3`으로 완료·배포 대기. 이 계획은 그 후속 —
> **콘텐츠 깊이**를 중급(B1/B2)에서 A1/A2급으로 끌어올린다. 실행은 별도 세션.
> 방법론은 `docs/HANDOFF_UI_OVERHAUL_2026-08-14_V2.md` §3(사이클·래칫 실측·파괴-복원 센서·SESSION_LOG) 그대로.

## Context — 왜, 무엇을

Jin 확정 결정 3건:
1. **B1/B2 집중** — C1 신설 제외 (레벨 시스템이 4레벨로 ~28곳 하드코딩, `LevelRatios` 변경만으로 테스트 24파일 파급. C1은 후속 라운드에서 "§Z 선행 리팩터" 후 진행).
2. **AI 초안 + Jin 전수 검수** — 세션이 CEFR 기준으로 생성 → 리뷰 시트 → Jin 승인 후 번들. `tools/content_factory/README.md` §0의 "native-speaker review required" 규약과 일치.
3. **대형 볼륨** — 레벨당 단어 500+, 팩 15+, 시나리오 8+ 신규.

**실측된 격차** (2026-08-14, 3-agent 탐색):

| 소스 | A1 | A2 | **B1** | **B2** | 대형 목표 (B1/B2) |
|---|---|---|---|---|---|
| korean_vocab.csv 단어 | 211 | 271 | 257 | 191 | **각 520+** (+263/+329) |
| vocab 팩 | 24 | 28 | 24 | 19 | **각 45+** (+21/+26) |
| scenarios.json | 15 | 15 | **8** | **4** | **16 / 12** (+8/+8) |
| grammar.csv (quiz-ready) | 32(32) | 41(37) | 33(30) | **17(17)** | **60 / 50** |
| cloze.json | 99 | 75 | 55 | 57 | **각 150** |
| satz_sentences.json | 63 | 38 | 49 | 41 | **각 120** |
| smalltalk.json | 64 | 57 | 36 | 36 | **각 80** + 공백 4카테고리 채움 |
| silben_puzzles.json | 20 | 20 | 20 | 20 | **각 40 퍼즐** |
| kkeunmari_pool.json | 1483 | 1043 | **53** | **55** | **각 400+** |
| curriculum 유닛 | 16 | 8 | 6 | 6 | **각 10** |
| grammar_patterns.json | 10 | 15 | **6** | **0** | **15 / 12** |
| 발음 스튜디오 | (하드코딩 4문장 전체) | | | | **레벨별 자산화, b1/b2 각 30** |

핵심 구조 통찰: **시나리오가 최고 레버리지 자산**이다 — `scenarios.json` 하나가 시나리오 화면 + 듣기(listening_screen이 dialog를 TTS 재생) + 퀘스트 7종 엔진 + 코스 체크포인트를 동시에 먹인다. b2는 4개뿐이라 코스 유닛 6개가 시나리오 2개를 중복 참조 중.

## 절대 규칙 (기존 + 콘텐츠 신규)

- 기존: 캐릭터 AI 재생성 금지 / 커밋은 Jin 지시 시 / ARB DE+EN 쌍 / 래칫 하향만 / SESSION_LOG 기록.
- **콘텐츠 없이 발명 금지** — 모든 한국어 문장은 CEFR 수준·자연성 기준으로 작성하되, 문화·사실 서술(culturalNote 등)은 검증 가능한 것만.
- **Jin 전수 검수 전 번들 금지** — 리뷰 시트 승인 없이 assets/에 넣지 않는다.
- **TTS 재수집 필수** — 새 한국어 텍스트는 `tool/generate_tts.py`를 재실행하지 않으면 조용히 온디바이스 TTS로 폴백한다. 각 Phase 마감 체크리스트에 포함.
- **`content_audit_manifest.json` 갱신 필수** — `content_audit_manifest_test`가 정확한 개수를 단언한다. 레코드 추가 = 매니페스트 bump.
- **기존 id 슬롯 재사용 금지** — vocab에 level 열과 id 접두가 어긋난 잔재 16행 존재(`vocab_b1_*` 3행이 A2에, `vocab_b2_*` 13행이 B1에). 신규 id는 기존 최대 번호 이후에서 시작.

## Phase C0 — 파이프라인·게이트 정비 (0.5일, 코드 소량)

콘텐츠를 붓기 전에 수도관부터. 목표: "생성 → 검수 → 번들 → 검증"이 기계적으로 돌게.

1. **리뷰 시트 워크플로 신설** `tools/content_factory/review/` — 콘텐츠 유형별 CSV 시트
   (`ko, de, en, level, 대상파일, 대상필드, 상태(draft/approved/rejected), Jin메모`).
   세션이 draft 생성 → Jin이 상태 표기 → 세션이 approved만 자산으로 변환하는 스크립트
   (`tools/content_factory/apply_review.py` 신설, 기존 build_*.py 패턴 참조).
2. **검증 스크립트 1개** `tools/content_factory/validate_content.py`: 레벨 whitelist,
   grammar 16열/quiz 규칙(같은 레벨 distractor 정확히 3개, focus 문구가 예문에 정확히 1회),
   시나리오 최소치(≥6 vocab, ≥6 dialog, ≥3 quests — data_integrity와 동일 기준),
   cloze/satz distractor 형식, id 중복·번호 연속성. 로컬에서 `flutter test` 전에 빠른 실패용.
3. **코드 수리 5건** (각각 파괴-복원 센서 1개와 함께 — V2 §3-3):
   - `chosung_quiz_screen.dart:130` — 기본 레벨 `'A1'` 하드코딩 → `Storage.userLevelCode` (센서: B2 유저 픽스처로 초기 레벨 단언)
   - `silben_kreuz_screen.dart:45` — 동일 수리
   - `listening_screen.dart:106` — 정확일치 실패 시 **A1로 추락하는 무제한 폴백** → `daily_challenge_screen.dart:57-68`의 `capToLevel` 누적 패턴 이식 (센서: b2 유저+b2 시나리오 존재 시 a1 미선택 단언)
   - `kkeunmari_engine.dart` — `level` 필드를 파싱만 하고 미사용 → `pickStart`/`_candidates`에 누적(≤rank) 스코핑 + 풀 부족 시 전체 폴백 (센서: B1 유저 시작 단어가 A1 전용 풀로 고정되지 않음 단언). **주의: 풀 확장(C2) 전에는 폴백이 대부분 발동함 — 코드만 먼저, 효과는 C2 후**
   - `pronunciation_studio_screen.dart:33-38` — 하드코딩 4문장 → `assets/data/pronunciation_phrases.json` 신설(`{id, level, ko, de, en, focus}`) + 소형 로더 (기존 `satz_loader.dart` 패턴 복제, 센서: 로더 파싱 + 레벨 필터 테스트)
4. **레벨 필터 의미론 문서화**: 누적(daily)·정확일치(cloze/satz/speed)·rank잠금(scenario) 3종과
   Storage 키 3종(`userLevelCode`/`browseLevelCode`/`placementLevelCode`)의 현황을
   `docs/CONTENT_ARCHITECTURE.md`로 신설 기록. 이번엔 **통일하지 않는다** (게임별 의도가 다름) —
   단, 위 3건 수리로 "잘못된 기본값"만 제거.

## Phase C1 — 시나리오+코스 확장 (최고 레버리지, 3~4일)

**C1a. 시나리오 16편 신작** (b1 +8 → 16, b2 +8 → 12):
- 스키마는 기존 42편과 동일 (필드 전체 목록은 탐색 보고 참조; `lib/models/scenario.dart` 정본).
- **중급다운 주제·화법** — B1: 이직 상담, 부동산 계약, 병원 예약 변경, 동호회 갈등 중재, 배달 오배송 항의, 경조사 인사, 대중교통 민원, 이웃 소음 대화. B2: 프레젠테이션 질의응답, 연봉 협상, 계약 조건 조율, 공식 항의 메일 낭독, 세미나 토론, 부고/조문 격식, 인터뷰 후속 협상, 갈등 조정 회의. (Jin 검수에서 주제 교체 가능 — 시트에 대안 2개씩 제시)
- **화법 다양화가 B1/B2의 본질**: register/speechStyle 필드로 합쇼체·해요체·반말 대비를 시나리오마다 명시하고 dialog에 반영. 퀘스트는 기존 7종 엔진 재사용 (`uebersetzen`/`hoerverstehen`/`particlePop`/`satzBauen`/`diktat`/`luecken` — 신규 엔진 개발 없음), 시나리오당 4~6개, `hoerverstehen` 최소 1개(듣기 화면의 실질 콘텐츠).
- 규격: dialog ≥8줄(기존 평균 6 대비 중급 상향), vocab ≥8, data_integrity 최소치 상회.
- b1/b2 코스 유닛의 **체크포인트 중복 참조 해소** (b2 유닛 6개 ↔ 시나리오 4개 → 유닛별 고유 시나리오).

**C1b. 코스 유닛 +8** (b1/b2 각 6→10): `curriculum_manifest.json`의 `courseUnits` + `concepts`(레벨당 +4~6) + `contentLinks` — 현재 12개(전부 scenario)뿐인 contentLinks에 cloze/satz/smalltalk/vocab/grammar 링크를 전 유닛에 배선 (**순수 데이터, 코드 0** — `curriculum_catalog.dart`가 orphan 검증). 신규 유닛 id는 `b1_07_*`~`b1_10_*` 식 순번.

**게이트**: `validate_content.py` → data_integrity → curriculum orphan 0 → content_audit bump → 전체 스위트 → Jin 검수 시트.

## Phase C2 — 게임 풀 확장 (2~3일, 전부 순수 데이터 드롭)

| 파일 | 작업 | 주의 |
|---|---|---|
| `cloze.json` | b1 +95, b2 +93 (각→150) | distractor 3개는 같은 레벨 어휘 톤 유지, topic은 `clozeTopicUnitMap` 유닛과 연결 |
| `satz_sentences.json` | b1 +71, b2 +79 (각→120) | **a2도 +30 보강** (38로 실측 최저) |
| `smalltalk.json` | b1/b2 각 +44 (→80) | **공백 4카테고리(transport/shopping/phone/emergency)에 b1·b2 각 4개 이상** — 현재 이 카테고리에서 B1/B2 선택 시 빈 목록 |
| `silben_puzzles.json` | B1/B2 각 +20 퍼즐 | 격자 유효성은 validate_content.py에 검사 추가 (dir/row/col 겹침 검증) |
| `kkeunmari_pool.json` | B1 +350, B2 +350 | `first`/`last`/`next_count`/`is_dead_end`는 `tools/content_factory/build_kkeunmari_pool.py` 재실행으로 산출 — 손으로 계산 금지 |
| `grammar_patterns.json` | B1 6→15, B2 0→12 | 정규식은 기존 31개 패턴 스타일; OCR 책 분석의 중급 감지력 |

## Phase C3 — 어휘 팩 대량 확장 (3~4일, 데이터 + 기계적 코드)

1. **단어 +592** (B1 +263 → 520, B2 +329 → 520): 15열 스키마 그대로, 예문 필수(예문도 TTS 대상).
   주제: B1 — 감정 뉘앙스, 직장 소통, 주거/계약, 건강/증상, 미디어, 관용구 입문.
   B2 — 한자어 격식 어휘, 비즈니스, 시사/사회, 추상 개념, 관용구/속담, 문어체.
   ⚠️ `scripts/build_vocab_packs.py`는 **재실행 금지** (11열 시대 유물 — EN 열과 id가 날아감).
   팩 배정은 신규 스크립트 `tools/content_factory/add_b_level_packs.py`로 (기존 `add_b1_expansion_packs.py` 패턴 복제).
2. **팩 +47** (~11단어/팩, 보스 2~3개 팩당 후미 배치): 팩당 기계적 4종 세트 —
   - `vocab_pack_service.dart` `packDisplayMap`(DE/EN 라벨) + `packOrderInLevel`
   - `dancheong_stamp.dart` `motifForPackId` switch 추가 (누락 시 lotus 폴백 + 전수 테스트 실패)
   - `curriculum_manifest.json` `vocabPackUnitMap`
   - `build_vocab_packs.py`의 `PACK_DISPLAY`/`PACK_ORDER_IN_LEVEL` 동기화 (파일 주석의 요구)
3. **모티프 이미지**: 기존 14종을 주제 기준으로 재배정하는 것을 기본으로 하되, 레벨당 45팩이면
   반복이 심해지므로 **신규 모티프 4~6종 생성 옵션** — 기존 앵커 런북(핸드오프 v1 §5) +
   `scripts/apply_paper_grain.py` 그레인 필수. `DancheongMotif` enum 확장 + webp 2벌(팩/스탬프).
   BBANANA 잔여 ~1,010크레딧으로 충분.

## Phase C4 — 문법·발음·마감 (2일)

1. `grammar.csv` B1 +27 → 60, B2 +33 → 50: 16열 전부 + quiz 4열 채움 (같은 레벨 distractor
   정확히 3개 · focus 문구가 DE/EN 예문에 정확히 1회 — `hasSingleExampleFocusFor` 계약).
   B2 핵심 문법: 간접화법 축약, ~더니/~던, 피사동 심화, 문어체 연결어미, 격식 완곡 표현.
2. `pronunciation_phrases.json` 시딩: a1/a2 각 20, b1/b2 각 30 (연음·경음화·비음화 등 focus 태그).
3. `placement_diagnostic.dart` 확장 (선택): 9→14문항, b1/b2 판별력 보강. 하드코딩 유지(소량).
4. **TTS 일괄 재수집**: `tool/generate_tts.py` — collect가 전 자산을 걷으므로 마지막에 1회.
   Firebase 업로드는 Jin 계정 권한 필요 → Jin과 함께 실행.
5. `content_audit_manifest.json` 최종 bump + 전체 스위트 + SESSION_LOG.

## Jin 검수 워크플로 (전 Phase 공통)

1. 세션이 Phase별 리뷰 시트 생성 (`tools/content_factory/review/{phase}_{type}.csv`) — 한 줄 = 한 항목,
   한국어/독일어/영어 나란히. 시나리오는 별도 MD(대화 전문이 CSV에 안 맞음).
2. Jin: `상태` 열에 `ok` / `fix: <메모>` / `no` 표기 (부분 승인 가능 — approved만 먼저 번들 가능).
3. 세션: `apply_review.py`로 approved만 자산 병합 → 검증 → 테스트 → SESSION_LOG.
4. 리뷰 시트는 저장소에 남긴다 (콘텐츠 이력 = 감사 추적).

## UI 연계 — 개편된 SoriStage가 새 콘텐츠를 "트리거"하게 (전 Phase 관통 원칙)

콘텐츠는 자산만 붓는 게 아니라 **개편 UI의 진입 동선에 물려야** 산다. 접점별 계약:

1. **Today 미션 스테이지가 제1 노출면** — `mission_recommender.dart`는 `sc.level.index <= userLevel.index`로
   시나리오를 고르고, `today_learning_snapshot.dart`는 레벨별 팩 뷰를 걷는다. C1/C3의 신규 콘텐츠가
   여기 걸리는지 **센서로 고정**: "b1 유저 + 신규 b1 시나리오 미완료 → Today 추천에 등장" 단언 테스트 1개
   (기존 `home_today_snapshot_test` 픽스처 패턴). 새 콘텐츠가 추천에 안 잡히면 만든 의미가 없다.
2. **활동 상세 시트의 보상 계약(§C-2)과 정합** — 신규 코스 유닛·시나리오의 `xpReward`/퀘스트 보상은
   기존 활동 카탈로그 보상 계약(`sori_activity_catalog.dart`)의 스케일(시나리오 XP 120~160대)을 따른다.
   시트의 "약속"과 리시트의 "이행"이 어긋나는 신규 값 금지.
3. **프리미엄 티저(§H)와 페이월 가치 제안 강화** — B1/B2 확장분은 전부 프리미엄 구간
   (`pack_access.dart`: A1만 무료). 카드의 골드 왕관 티저가 이제 "잠긴 대형 콘텐츠"를 실제로 가리키게 되므로,
   C4에서 페이월 혜택 문구를 실측 수치로 갱신 — 예: "B1·B2 단어 1,000+ · 시나리오 28편" (ARB DE/EN 쌍,
   하드코딩 금지, 수치는 audit manifest에서 산출).
4. **카탈로그 Learn 히어로 카드(§C-1-11) = vocab_packs 대형 진입** — C3의 팩 확장이 이 히어로 카드
   바로 뒤 화면을 채운다. 신규 팩의 모티프 일러스트·DE 라벨이 첫인상이므로 모티프 재배정/신규 4~6종은
   "같은 레벨 안에서 인접 팩과 모티프 중복 최소화" 규칙으로 배정.
5. **듣기·게임 기본 레벨 수리(C0-3)가 UI 동선의 전제** — Today→활동 진입 시 유저 레벨 콘텐츠가
   바로 떠야 한다. B2 유저가 카탈로그에서 초성 퀴즈를 열었는데 A1이 기본이면 개편 UI의 "1탭 진입"이 무의미.
6. **한옥/퀘스트 게이미피케이션과 볼륨 균형** — 분모 증가로 진행률 후퇴(아래 검증 전략 참조).
   Phase별로 나눠 릴리스하면 충격이 분산된다 — C1(시나리오)과 C3(팩)을 별도 릴리스로 나누는 것을 기본으로.
7. **스와이프 학습덱은 자동 수혜** — 신규 단어는 `ReviewDeckService.allReviewable()`을 통해 스와이프
   판정 덱·SRS에 코드 0으로 유입. 별도 작업 불필요(확인만).

## 검증 전략 (기존 게이트 전부 + 신규)

- 기존 자동 게이트: `content_audit_manifest_test`(개수 일치) · `data_integrity_test`(레벨 whitelist,
  시나리오 최소치, grammar 열수·distractor 레벨) · `curriculum_catalog` orphan 검증 ·
  `dancheong_stamp_test`(모티프 전수) · `vocab_pack_test:138`(display map 동기화) · 전체 스위트.
- 신규: `validate_content.py`(번들 전 빠른 실패) + C0 코드 수리 5건의 파괴-복원 센서 5개.
- 콘텐츠 회귀 주의점: 분모 증가로 기존 B1/B2 유저의 진행률·한옥 단계가 **시각적으로 후퇴**할 수 있음
  (`structureStage`는 max 가드가 있으나 `studyFraction`은 실제로 내려감) — 릴리스 노트에 명시하고
  Jin과 UX 완충(예: "새 콘텐츠 추가됨" 안내) 여부 결정.
- 커밋 단위: Phase당 1커밋(콘텐츠+해당 게이트), Jin 지시 시에만.

## 범위 밖 (기록만)

- C1 레벨 신설 — 선행 리팩터(`LevelRatios`→Map화, 레벨 리터럴 ~20곳 enum 파생으로 통일) 후 별도 라운드. 탐색 보고에 전체 터치포인트 목록 있음.
- 신규 퀘스트 엔진·게임 신설, 레벨 필터 의미론 통일, wordle_screen 데드코드 정리(Phase 4 소관).

## 기술 부록 — 실행 세션용 상세 스펙

### A. 신규 스크립트 3종 (tools/content_factory/, 전부 표준 라이브러리 python3)

**A-1. `validate_content.py`** — 번들 전 빠른 실패 게이트. CLI: `python3 tools/content_factory/validate_content.py [--json]`. 종료코드 0=통과/1=위반(위반 목록 stderr). 검사 규칙:
```
공통   : level ∈ {a1,a2,b1,b2}(대소문자는 파일별 관례 따름), id 중복 0, id 접두-level 일치
         (기존 잔재 16행은 whitelist 상수로 예외 등록 — 신규 유입만 차단)
vocab  : 15열 정확, pack_id 접두=level, 예문 2필드 비어있지 않음, pack당 boss 2~3
grammar: 16열 정확, quiz_enabled=true 행은 distractor 정확히 3개·전부 같은 레벨·전부 enabled,
         quiz_focus_de/en가 example_german/example_en에 정확히 1회 등장
scenario: vocab≥6·dialog≥6·quests≥3, courseUnitId가 manifest에 존재, hoerverstehen≥1(신규만),
         quest 스키마(type별 필수 data 키)
cloze/satz: distractor≥2, 정답이 문장에 실제 포함(cloze: fullKo=sentenceKo의 ＿＿＿ 치환 일치)
silben : 격자 경계 내, 교차 셀 글자 일치, 단어 중복 0
kkeunmari: first/last가 word의 실제 첫/끝 음절과 일치 (재계산 검증)
manifest: content_audit_manifest.json 수치 == 실제 파일 카운트
```

**A-2. `apply_review.py`** — 승인분만 병합. CLI: `python3 ... apply_review.py review/<시트>.csv --target assets/data/<파일>`. 동작: `상태==ok` 행만 대상 파일에 병합(json은 정렬 유지 append, csv는 말미) → 백업 `.bak` 생성 → validate_content.py 자동 호출 → audit manifest 수치 자동 bump(`--no-manifest`로 끔). `fix:` 행은 stderr로 목록만 출력(세션이 수정 후 재시트).

**A-3. `add_b_level_packs.py`** — 승인된 신규 단어의 팩 배정. 입력: 병합 완료된 korean_vocab.csv + `TOPIC_TO_PACK_B1_V2`/`_B2_V2` dict(스크립트 내 정의). 출력: pack_id/pack_order/is_review_boss 열 채움 + `docs/data/vocab_pack_map_v2.md` 리뷰 표 + **Dart 동기화 스텁 출력**(packDisplayMap/packOrderInLevel/motifForPackId에 붙여넣을 코드 조각을 stdout으로 생성 — 손 전사 금지). 기존 팩의 행은 불변(신규 id만 대상). 보스: 팩 후미 min(3,max(2,n//4)).

### B. 리뷰 시트 정확 스키마

CSV 공통 열: `id,level,ko,de,en,field_notes,상태,jin_memo` — 유형별 추가 열:
```
vocab    : +romanization,pos_de,pos_en,example_ko,example_de,example_en,topic
grammar  : +pattern,type_de,explanation_de(요약),example_ko,quiz_focus_de,distractor_ids
cloze    : +sentence_ko,answer,distractors(|구분)
satz     : +target_ko,distractors,vocab_ko
smalltalk: +category,kind,follow_up_ko
silben   : (CSV 부적합 → 퍼즐당 격자 프리뷰 포함 MD)
발음     : +focus(연음/경음화/비음화/유음화/ㅎ탈락)
```
시나리오는 `review/scenarios/<id>.md` 1편 1파일: 메타 표(level/register/speechStyle/유닛) → 대화 전문(ko/de 병기) → vocab 표 → 퀘스트 목록 → `상태: draft` 헤더 필드를 Jin이 직접 수정.

### C. AI 생성 프롬프트 골격 (실행 세션이 콘텐츠 유형별로 변주)

```
역할: 한국어 교육 콘텐츠 저자 (독일어권 성인 학습자 대상, CEFR {level}).
수준 준거: B1=일상+직장 구체 상황, 연결어미(-는데/-거든요/-느라고), 간접화법 입문,
  해요체 중심+합쇼체/반말 대비 노출. B2=격식·추상·협상, 한자어 격식 어휘, ~더니/~던,
  피사동 심화, 문어체 연결(-(으)며/-(으)나), 완곡·공손 전략.
출력: 지정 JSON/CSV 스키마 그대로(스키마 위반=폐기). 독일어는 자연스러운 구어 번역
  (직역 금지), 영어 번역 병기. 로마자 표기는 국립국어원 방식.
금지: 이미 자산에 있는 문장 재사용(중복 검사 대상), 번역투 한국어, 문화적 사실 단정
  (culturalNote는 일반 상식 수준만), 고유명사 상표.
분포 규칙: 화법 register를 {합쇼체 30%/해요체 50%/반말 20%} 근사로 섞을 것(시나리오·smalltalk).
```

### D. ID 채번 — 실행 세션 첫 작업에서 실측 후 고정

```bash
awk -F, '$15 ~ /vocab_b1/ {print $15}' assets/data/korean_vocab.csv | sort | tail -1  # b1 최대
# 동일하게 vocab_b2 / cloze_b* / satz_b* / smalltalk_b* / grammar id는 slug라 중복만 검사
```
신규는 (최대+1)부터 연속. **잔재 16행의 번호 대역은 건너뛴다** (validate가 whitelist로 앎).

### E. TTS·명령 모음 (C4 마감)

```bash
python3 tool/generate_tts.py --dry-run   # 신규 텍스트 수집 목록 확인 (비용 견적)
python3 tool/generate_tts.py             # 합성 (Google Cloud 자격증명 = Jin)
# rsync 업로드 스텝은 스크립트 내장 — Jin 계정으로 실행. 검증: 앱에서 신규 문장 1개
# 재생 시 네트워크 로그에 tts/v3/ 경로 히트 (폴백 TTS 음색이면 실패)
flutter test test/content_audit_manifest_test.dart test/data_integrity_test.dart  # 콘텐츠 게이트
flutter test  # 전체
```

### F. Phase 완료 체크리스트 (각 Phase 커밋 전, 순서 고정)

1. `validate_content.py` 0 → 2. `flutter analyze` 0 → 3. 콘텐츠 게이트 2종 → 4. 전체 스위트
→ 5. (코드 수리 포함 시) 파괴-복원 프로브 실측 → 6. 리뷰 시트 approved 100% 확인
→ 7. SESSION_LOG 최상단 기록 → 8. Jin 커밋 지시 대기. 커밋 메시지: `content(b1b2): <Phase> — <수치 요약>`.

## 실행 순서 요약

C0(파이프라인+코드5) → C1(시나리오+코스 = 듣기·퀘스트 동시 해결) → C2(게임 풀) → C3(어휘 팩+모티프) → C4(문법·발음·TTS·마감). 각 Phase: 생성 → validate → Jin 시트 → 병합 → 게이트 전체 → SESSION_LOG. 총 예상 10~13 작업일 + Jin 검수 시간.
