# 인수인계 — 레벨 바이블 완결(336 교수 정보 + 표현 축 신설) 2026-09-09

> ⚠️ `AGENTS.md` 는 신규 인수인계 작성을 금지한다(이유·이력은 git log/PR 본문, 구조는 graphify).
> 이 파일은 **Jin 이 2026-09-09 세션에서 명시적으로 요청**해서 예외로 쓴다 — "후속작업 다음 PR로
> 남길거 인수인계파일로 상세하게 남겨주고, 너가 조사한거 그리고 내가 조사해서 넘긴거 내용도
> 같이 참고하라고 넣어줘".

## 상태 (한 줄)

레벨별 **문법·주제** 전수 목록은 이미 있다(`docs/data/cefr_curriculum_matrix.md`). 빠진 것은
① 336형태의 **뜻·기능·예문**, ② 화행 39종의 **실현 문형(표현) 축**, ③ 바이블 §B.3~§B.6 의
물질화다. 선행 PR #289(Learning Phase A1–C2)가 순서·기능·브리지를 채웠으니, 이 PR 은 그 위에
교수 정보를 얹는다.

## 왜 이 작업이 필요한가 — 2026-09-09 조사 결과

### 1. 레벨을 실제로 결정하는 것은 공식 목록이 아니라 수기 `level` 문자열이다

- `tool/cefr_lexicon.py` 는 판정 엔진이지만 `assets/data/korean_vocab.csv` 에 **쓰지 않는다**.
  판정은 `tool/audit_content_levels.py` 리포트로만 흐른다.
- `korean_vocab.csv` 의 `level`(2,499행)과 `assets/data/grammar.csv` 의 `level`(252행)은 **수기**다.
- CI 의 유일한 실제 게이트 `tools/content_factory/validate_content.py` 는 `level` 이 A1–C2
  문자열인지와 id 레벨 세그먼트 일치만 본다. **언어학적 레벨 정확성은 전혀 검사하지 않는다.**
- `test_audit_content_levels.py` · `test_audit_curriculum_matrix.py` 의 `LiveRatchetTest` 는 현재
  불일치 수치를 **동결**하는 하향 래칫이다 — 줄이라고 요구하지 않는다.
- 생성 시점에 사전이 실제로 게이트인 스크립트는 하나뿐이다
  (`tools/content_factory/promote_batch24_supplement.py:173-186`).
- 결과: `docs/data/level_bible/F1_grammar_map.md:9` — **match 100 · level_mismatch 39 ·
  missing_in_app 197 · app_only 94**. 공식 336 중 197개는 앱에 대응 행이 없고 39개는 레벨이
  다르며, 앱 문법 252개 중 94개는 공식 목록에 없다.

즉 공식 인벤토리는 **사후 감사용**이고 생성 시점의 권위가 아니다. 이 PR 은 그것을 바꾸지
않는다(아래 "범위 밖" 참고) — 다만 그 사실을 알고 시작해야 한다.

### 2. 336형태에 뜻·기능·예문이 없다

- 원본 `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv` 의 `meaning` 열은 336행 중
  **91행**만 채워져 있고, 그 91개도 동형어 구별 태그(`-고3`→"나열", `까지`→"부터/까지")이지
  교수용 뜻풀이가 아니다.
- `tools/content_factory/cefr_matrix/ko.json` 의 `grammar.forms[]` 는 CSV 를 그대로 옮긴
  `{form, category, variants, meaning}` 4필드이고 **순서까지 동일**하다. 같은 91개만 채워져 있다.
- `F1_grammar_map.md` 와 `docs/data/cefr_curriculum_matrix.md` 둘 다 `meaning` 열을 렌더하지
  않는다. 유일한 예외가 `docs/data/level_bible/F4_sejong1_units.md:39-45`(세종 A1 5과분 원문 발췌).
- 기능·예문·사용제약·유사형태 대조 필드는 **아예 없다**.

### 3. "표현" 축이 taxonomy 에 존재하지 않는다 — 가장 구조적인 공백

Jin 이 말한 "표현"에는 두 가지가 섞여 있고 하나는 있고 하나는 없다.

- **있는 것**: 국제통용 `category == 표현` **136개**(급별 9·17·33·26·36·15). `-고 싶다` ·
  `-는 것 같다` · `-게 마련이다` 같은 문법 형태소 구성이고 이미 336 안에 있다.
- **없는 것**: **화행 실현 문형(exponent)**. `tools/content_factory/cefr_matrix/taxonomy.json` 의
  `speechActs` 39종 스키마는 `{id, category, label{ko,en,de}, matchers}` 로 exponent 필드가
  **아예 없다**. "A1 에서 `thank_apologise_respond` 를 가르친다"는 있지만 "감사합니다 /
  고마워요 / 괜찮아요 / 별말씀을요 / 죄송해요 / 아니에요" 같은 목록이 어느 문서에도 없다.
- 파편만 존재: `docs/data/level_bible/F9_exceptions.md` 의 `fixed_expression` 6행 + 감탄·인사
  3개(화이팅·별말씀을요·천만에요), `assets/data/korean_vocab.csv` 의 `pos_de == "Ausdruck"`
  **534행**(A1 49 · A2 33 · B1 130 · B2 123 · C1 98 · C2 101),
  `tools/content_factory/build_smalltalk.py:40-291` 에 하드코딩된 스몰토크 문형.

### 4. 바이블 §B 가 A1·A2 만 물질화돼 있다

`docs/CONTENT_LEVEL_BIBLE.md` §B 의 `③ 문법 전체 표`:

| 절 | 문법 표기 | ② 주제 항목 |
|---|---|---|
| B.1 A1 | 45개 전부 인라인(`:84-90`) | 14 |
| B.2 A2 | 45개 전부 인라인(`:149-155`) | 약 10 |
| B.3 B1 | "3급 67항목 전부. F1 참고"(`:195`) | 약 5 |
| B.4 B2 | 같은 형태(`:233`) | 5 |
| B.5 C1 | 같은 형태(`:272`) | 5 |
| B.6 C2 | 같은 형태(`:306`) | 4 |

인라인 90개, 포인터만 **246개**(그중 표현 110개). 주제도 A1 14개 → C2 4개로 얇아진다.

> 2026-09-09 PR #289 에서 §F 색인에 `cefr_curriculum_matrix.md` 와 `curriculum_matrix_report.md`
> 를 등재해 **발견성 문제는 이미 해결했다**. 남은 것은 §B 본문의 물질화다.

### 5. 문서 간 모순 6건 (이 PR 에서 정리)

1. **앱 문법 244 vs 252** — `F1_grammar_map.md:1` 제목이 244, `:9` 요약이 252. 원인은
   `tool/build_level_bible_tables.py:447` 의 **하드코딩 244**. 실측은 252행이다.
   (`CONTENT_LEVEL_BIBLE.md` §F 의 낡은 244 표기는 PR #289 에서 이미 제거했다 — 숫자를
   바꾼 게 아니라 잘못된 주장을 뺐다. 생성기 하드코딩은 여전히 남아 있다.)
2. **A1 missing 5개가 F1b 수기 정정을 무시** — `docs/data/curriculum_matrix_report.md:82` 는
   `이다`·`-지 않다`·`이 아니다` 를 앱에 없다고 하는데, `F1b_grammar_grade12_manual.md:19-27` 이
   각각 `grammar_a1_copula_polite`·`grammar_a1_long_negation`·`grammar_a1_copula_negation` 을
   지목해 반박하고 **같은 리포트의 바로 아래 표(`:86`, `:96`)가 그 세 id 를 ✅ match 로 찍는다.**
   정본이 어느 쪽인지 문서가 서로 다르게 말한다.
3. **결손 어휘 수** `F2_vocab_coverage.md:10-15`(321·703·1244·1815·2021·2353) vs
   `F10_review_lessons.md:45`(333·725·1247·1827·2021·2353). 5·6급만 일치. Batch 24 전후 스냅샷
   차이로 보이지만 두 문서 어디에도 교차 참조가 없다(F10 은 수기라 재생성으로 갱신되지 않는다).
4. **app_only 94 vs 95** — `F1_grammar_map.md:352` 이하 94개 vs `F9_exceptions.md:190` 95행.
   `F9:192-196` 이 스스로 자백한 손 보정 부채(`grammar_a1_service_request` 를 손으로 넣었고
   재생성하면 94로 되돌아간다).
5. **3~6급 어휘 분모 3종** — 연구보고서 원문 / 실측 행 / 고유 표제어가 화해되지 않았다.
   `CONTENT_LEVEL_BIBLE.md:47-58` 룰링 박스는 1·2급(714·1,070)만 정의한다.
6. **`F7_pronunciation.md:27-33` 의 `항목 수` 칸**이 문구 수인데 focus 고유값 목록과 나란히
   놓여 오해를 부른다(A2 10 vs 나열 9 등). 모순이 아니라 라벨링 문제다.

## Jin 이 정한 것 (2026-09-09)

1. **깊이**: 목록 물질화 + **336형태 전부에 교수 정보 전수**(뜻·기능·예문·사용제약·대조).
   표현은 독립 축. 주제는 공식 17범주 85항목 기준으로 확장.
2. **정본**: `tools/content_factory/cefr_matrix/ko.json` 이 정본, **바이블 문서는 생성본**.
   §B 의 목록 부분을 생성기가 만들게 바꾸고, 수기 규범(⑤ 문장규칙 · ⑥ 담화·화행·존대 ·
   ⑨ DE/EN 규칙 · ⑩ 금지사례)은 사람이 유지한다.
3. **순서**: Learning Phase(PR #289) 먼저, 이 작업은 다음 PR.

## 참고 자료 — 반드시 함께 읽을 것

### (A) Jin 이 업로드한 딥리서치 보고서 (2026-09-09)

260행 / 54,235 bytes, sha256
`17fe4ee5161a94afcdc2bf164c05020cbcdee54d8797dcd39484733a15f55a44`.
**원본은 세션 스크래치패드에 있었고 저장소에 벤더링하지 않았다** — 아래가 그 핵심이다.

증거 등급 주의: 보고서의 `citeturnNNviewM` 표시는 조사 도구의 내부 참조 토큰이고 열 수 있는
URL 이 아니다. korean.go.kr · moe.go.kr · rm.coe.int · goethe.de 등이 이 환경에서 전부 차단이라
원문 대조가 불가능하다. **이 보고서만 근거로 어떤 항목도 `[OFFICIAL]` 로 올리지 마라.**

성립한 교차 확인 하나: 보고서가 적은 국제통용 문법 등급 분포(1급 45 · 2급 45 · 3·4급 각 67 ·
5·6급 각 56 = 336)가 저장소 보유 CSV 의 336행 실측 분포와 **완전히 일치**한다.

보고서에서 가져올 것:

- **교육부 2021 개정 해외 현지 초·중등학교 한국어 교육과정** — Pre-A1 · A1 · A2 · B1 · B2 ·
  C1 · C2 및 일부 plus level 을 실제로 도입하고, CEFR 처럼 수용·산출·상호작용·매개와
  언어적·사회언어학적·화용적 능력을 체계에 포함한다. **한국 공식 문서 계열 중 CEFR 라벨을 그대로
  쓰는 유일한 축**이라, 이 앱이 KO 를 A1–C2 로 라벨링하는 근거가 된다 — 국립국어원 1~6급을
  A1~C2 로 환산한 것이 아니라는 방어선. 단 특정 해외 학교 맥락용 참조체계이므로 TOPIK·국제통용
  등급과 기계적으로 1:1 대응시키지 않는다. (PR #289 에서 `ko.json` 출처
  `moe_overseas_korean_2021` 로 등록한다 — provenance `model_knowledge`, 즉 `[DERIVED]`.)
- **다른 축의 공식 총량** — 주제 17범주 85항목 · 기능 52 · 어휘 10,635 · 문법 336 ·
  **발음 72** · 텍스트 144. `ko.json` 의 각 축 `expectedCount` 와 대조해 어긋나는 축이 있으면
  갭으로 올린다.
- **발음을 문법과 독립된 spiral track 으로** — 음소 · 음절 · 음운현상 · 초분절음 · 현실 발음.
  경음화 · 비음화 · 유음화 · 구개음화 · ㅎ탈락 · ㄴ첨가 · 격음화는 전 등급에 걸쳐 재등장한다.
  L2 공통 오류: 격음/경음 → 평음 대치, 종성 삭제, 이중모음 단모음화.
- **형태마다 단일 level 대신 `introduced_at` / `core_at` / `recycled_at` / `mastered_by`** —
  현재 스키마의 `role: new|spiral` 은 introduced_at + recycled_at 만 표현한다.
- **주제를 레벨에 못 박지 말 것** — 고시 자체가 주제별 "등장 가능 범위"와 "집중 교육 단계"를
  구별한다. 환경: A2 날씨·분리수거 → B2 기후변화 찬반 → C1 환경정책 분석 → C2 규제의 경제·윤리
  효과. `Topic → difficulty realization` 구조가 `topic=환경, level=B2` 보다 정확하다.
- **보고서가 지정한 6개 spiral item** — 은/는 · -는데 · 관형사형 · 것 같다 계열 ·
  높임/speech level · 발음. 우리 `role: spiral` 배치가 이 여섯을 모두 포함하는지 확인하라.
- **금지선 5개** (우리 설계와 일치, 유지할 것):
  - `Dativ = 에게/한테`, `Akkusativ = 을/를` 식 등가표 금지.
  - `doch = 잖아`, `well = 근데` 식 단일 번역 금지 — Modalpartikeln 은 개념 bridge 로만.
  - English backshift / German Konjunktiv 를 한국어 인용에 강제 금지.
  - A1 의 `-요` 를 가르치고 "존댓말 완료"로 처리 금지 — 고급 학습자도 높임 규범에서 벗어난다.
  - "복잡한 문장 = 고급" 금지 — 목적·독자에 맞춘 단순화도 C2 능력.
- **보고서와 우리 설계의 의도된 차이** — 보고서는 레벨당 2 phase(총 12)를 권하지만 브리프는
  레벨당 3–6을 요구했고 PR #289 는 30개(A1 4 · A2 4 · B1 5 · B2 5 · C1 6 · C2 6)다. 또 보고서의
  문법은 레벨별 "대표형" 묶음이고 우리는 336 전수를 배치한다. 보고서는 상호 검증용 참조이지
  산출물의 대체가 아니다.

### (B) PR #289 산출물

`tools/content_factory/cefr_matrix/phases.json`(30 Phase × 16필드) · `cross_mapping.json` ·
`transfer.json` · `phase_review.json`, 그리고 `docs/data/korean_learning_phases_part*.md`.
문법 형태마다 이미 `functionUse` · `example` · `evidence` · `appGrammarIds` 가 붙어 있으므로
**336 교수 정보 집필의 절반은 Phase 데이터에서 끌어올 수 있다.** 중복 집필하지 마라.

## 할 일

### 작업 1 — 표현 축 신설 (최우선)

`taxonomy.json` 의 `axes` 에 8번째 축을 세운다. 39개 화행마다 레벨별 실현 문형 목록.
씨앗: `korean_vocab.csv` 의 `pos_de == "Ausdruck"` 534행 + `F9` `fixed_expression` 6행 +
`build_smalltalk.py` 문형. 새 표 `docs/data/level_bible/F12_expression_bank.md` —
레벨별로 `형태 | 뜻 | 화행 | 예문 | 같은 화행의 하위·상위 레벨 대안`.

### 작업 2 — 336 교수 정보

`ko.json` 의 `grammar.forms[]` 에 `function` · `example` · `constraint` · `contrastWith` ·
`evidence` 를 추가한다. 새 표 `docs/data/level_bible/F11_grammar_teaching.md` —
`등급 | 범주 | 형태 | 이형태 | 뜻 | 기능 | 예문 | 사용 제약 | 선택 대조 | 근거`.

**주의: 336행은 (급, 형태) 쌍이고 고유 형태는 333개다.** 세 형태가 두 급에 서로 다른 기능으로
등재돼 있다 — `-고4`(1급 "덧붙여 서술" · 4급 "덧붙여 질문"), `-는다고1`(3급 "이유" · 6급 "의도"),
`-다니1`(4급 · 5급 "감탄"). PR #289 의 `tool/audit_learning_phases.py` 가 이 셋의 기능 진술이
급마다 실제로 다른지 검사한다(`C3_grammar`). 교수 정보도 급마다 따로 써야 한다.

### 작업 3 — 주제·발음 구조화

- `pronunciationFocus` · `cultureFocus` · `sentenceRules` 는 레벨당 **자유 문장 1개**라 발음
  72항목을 담을 구조가 없다. 구조화가 필요하다.
- `F6_topic_bank.md` 는 248행(KERIS 152 + 표준데이터 96) 전부 `제안 레벨대` **공란**이다.
  원본 2종은 저장소에 없고 `--sources-dir`(`$LCP_SOURCES_DIR`) 밖에 있다.
- `F5_culture_vocab.md` 는 `Fable 룰링` 칸 116행 전부 **공란**이다.
- B1~C2 주제는 스스로 "앱 유닛에서 역산한 목록이라 공식 주제 목록이 아니다"라고 신고했다
  (`docs/data/cefr_curriculum_matrix.md:17`).
- 새 표 `F13_topic_matrix.md` — 레벨 × 주제를 "등장 가능 범위 vs 집중 교육 단계"로.

### 작업 4 — §B.3~§B.6 물질화

각 절의 `③ 문법 전체 표` 를 A1·A2 처럼 범주별 인라인 표로 바꾸고 뜻·예문은 F11/F12 로 링크한다
(§B 가 폭발하지 않게). `② 주제·상황` 은 F13 의 해당 레벨 행으로 대체한다. C1·C2 의 `⑩ 금지 사례`
를 A1 수준의 구체성으로 올린다.

### 작업 5 — 모순 6건 정리

특히 (1) `build_level_bible_tables.py:447` 하드코딩 244 제거, (2) F1 자동 매처 vs F1b 수기 판정의
정본 확정 — A1·A2 에서 매처가 6건 틀렸음이 이미 입증됐고 **3~6급 246항목에는 수기 재검증이 아예
없다**. 즉 B1~C2 의 `missing 184 / mismatch 39` 는 전부 자동 매처 값이다.

## 규칙 — 어기면 바로 사고 나는 것들

- **문법 항목 자체(형태·급·범주)를 고치려면 CSV 를 고친다, JSON 이 아니다.**
  `tools/content_factory/cefr_matrix/README.md` 마지막 절. 테스트가 급별 개수를 대조한다.
- **`cefr_matrix` JSON 은 전부 indent=2.** 어기면 헛디프가 수천 줄 난다(전례 있음).
- **증거 등급**: 형태·급·범주는 `[OFFICIAL]`(CSV 보유), 뜻·기능·예문·대조는
  **`[PEDAGOGICAL]`**. 원문 PDF 가 차단이라 `[OFFICIAL]` 로 올리는 것은 금지.
  `tool/audit_learning_phases.py` 의 `check_evidence` 가 이미 같은 원칙을 강제한다.
- **레벨 블록의 실제 키**: `scale · canDo · topics · grammar · speechActs · textTypes ·
  vocabDomains · registers · pronunciationFocus · cultureFocus · sentenceRules`.
  `speechActs` · `textTypes` · `vocabDomains` 는 **id 참조만**이고 한국어 라벨은 `taxonomy.json`
  에 있다. `briefHighlights` · `discourseFeatures` 는 레벨 직속이 아니라 `grammar` 안에 중첩된다.
- **생성물 문서는 직접 편집 금지.** F1·F2·F3·F5·F6·F7·F9 는
  `python tool/build_level_bible_tables.py` 가, `cefr_curriculum_matrix.md` ·
  `curriculum_matrix_report.md` 는 `python tool/audit_curriculum_matrix.py --write-matrix` 가,
  `korean_learning_phases_part*.md` 는 `python tool/audit_learning_phases.py` 가 만든다.

## 재사용할 것

- **생성기 확장점**: `tool/build_level_bible_tables.py`(1101줄) — `build_f1`(`:357-434`) …
  `build_f9_md`(`:982`) + `generate_all()`(`:1058`) + `main()`(`:1076`),
  출력 `OUT_DIR = docs/data/level_bible`(`:112`). F1 알고리즘은 정규식이 아니라
  `normalize_form_variants`(`:273`)로 양쪽을 리터럴 문자열 집합으로 전개한 뒤 교집합이다.
- **예문 레벨 검증**: `tool/cefr_lexicon.py` 의 `sentence_profile`(`:2429-2531`) —
  어휘 90퍼센타일, `GrammarIndex` 최고 등급, 길이 규칙, 그리고 **최고 등급 토큰 1개 무조건 면제**
  (레벨 바이블의 "1급 밖 단어 하나까지만 허용" 규칙, `:2494-2502`).
- **예문 재사용**: `korean_vocab.csv` 의 `example_korean` 과 시나리오 대사에서 끌어오면 바이블과
  앱이 어긋나지 않는다. 없는 형태는 집필하되 **앱에 예가 없다는 사실 자체를 결손으로 보고**한다
  (197 missing_in_app 과 크게 겹칠 것이다).

## 검증

- `python tool/build_level_bible_tables.py` → F11·F12·F13 생성, 재실행 시 무변화(결정론)
- `python tool/audit_curriculum_matrix.py --check` → 뜻·기능·예문 결손 0, 표현 축 전수,
  예문 레벨 위반 0
- `python -m unittest discover -s tool -p "test_*.py" -t .` → 전부 통과
  (CI 와 같은 명령, `.github/workflows/ci.yml:882`)
- 기존 `LiveRatchetTest` 는 **하향 래칫**이라 개선하면 CAP 상수를 함께 내려야 한다
- 표본 검사(사람): C1 `-는 듯하다` 와 B1 `-나 보다` 의 `contrastWith` 가 서로를 가리키고 선택
  조건이 실제로 다른지

## 범위 밖 (별도 작업으로 제안)

- **`cefr_matrix` 는 앱 런타임에 전혀 연결돼 있지 않다** — `lib/` 에서 grep 0건,
  `pubspec.yaml` 에 asset 선언 없음, `functions/`·`web/` 도 0건. 읽는 코드는
  `tool/audit_curriculum_matrix.py` · `tool/audit_learning_phases.py` 와 그 테스트뿐이다.
  바이블을 정본으로 세운 뒤에도 **생성 시점에 강제하는 게이트는 여전히 없다.**
- **텍스트 유형 19종은 앱 표면 자체가 없어 실현 불가**하다
  (`docs/data/curriculum_matrix_report.md:22-44`). 표지판·메뉴·서식·공지·기사·논설문·계약서·
  학술텍스트 등이며 A1 의 읽기 장르까지 포함된다. 콘텐츠가 아니라 **표면 설계** 문제다.
