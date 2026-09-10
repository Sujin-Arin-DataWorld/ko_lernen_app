# CEFR 커리큘럼 매트릭스 (`tools/content_factory/cefr_matrix/`)

한국어·영어·독일어 A1–C2 를 **주제 × 문법 × 기능(Sprachhandlungen) × 텍스트 유형(Textsorten) ×
어휘 영역 × 문체/존대** 축으로 맞댄 검증용 매트릭스. 한글소리의 실제 콘텐츠 누락 검사
(`tool/audit_curriculum_matrix.py`)가 읽는 정본이다.

CEFR 자체는 A1~C2 별 필수 문법 목록을 정하지 않는다(언어 비종속 can-do 프레임워크). 그래서
언어별 Reference Level Description 과 시험기관 인벤토리를 씨앗으로 쓴다:

| 언어 | 1차 기준 | 2차 기준 |
|---|---|---|
| 🇰🇷 한국어 | 국립국어원 2017 국제통용 한국어 표준 교육과정 문법 336·어휘 10,635 (저장소 보유, 공공누리 1유형) | 한국어 표준 교육과정(고시 2020-54호), TOPIK 등급 기준, 세종한국어 회화 1(F4), 레벨 바이블 §A·§B |
| 🇬🇧 영어 | CEFR-J Grammar Profile(저장소 보유, `reference/`), English Grammar Profile / EVP | Cambridge A2 Key·B1 Preliminary·B2 First·C1 Advanced·C2 Proficiency 핸드북, Threshold 1990 / Waystage / Vantage |
| 🇩🇪 독일어 | Profile deutsch, Goethe Prüfungsziele A1–C2 | DTZ Strukturen-Inventar, BAMF Rahmencurriculum, telc Lernziele |

## 파일

| 파일 | 내용 |
|---|---|
| `taxonomy.json` | 언어 독립 id: `topics`(32) · `speechActs`(39) · `textTypes`(31) · `vocabDomains`(26) · `functionalGrammar`(34) · `registers`(7) · `skills`(5). 각 항목에 `label{ko,en,de}` 와 **앱 표면 alias**(`appAliases.vocabTopics/shelfSlugs/smalltalkCategories/packKeywords/titleKeywords`, 기능 `matchers.ko/en`, 텍스트 유형 `matchers`) |
| `ko.json` | 한국어 — 레벨별 `scale`·`canDo`·`topics`(required/optional + focus)·`grammar`(국제통용 형태 전수 + `briefHighlights` + `discourseFeatures`)·`speechActs`·`textTypes`(R/P)·`vocabDomains`·`registers`·발음·문화·문장 규칙; `functionalGrammar`(앱 grammar.csv id 앵커) |
| `en.json` / `de.json` | 영어·독일어 — 같은 구조. 문법은 항목 목록(`grammar.items`, 출처 인용 포함). 갭 판정에는 쓰지 않고 삼언어 정렬표에만 쓴다 |
| `reference/cefrj-grammar-profile-20180315.csv` | CEFR-J 문법 프로파일 500항목(170항목 CEFR-J 레벨 + EGP 교차 레벨). `en.json` 이 `cefrj:<ID>` 로 인용 |

## Learning Phase 체계 (A1–C2 한국어 학습 단계)

매트릭스가 "레벨별로 무엇이 있어야 하는가" 를 정의하면, Learning Phase 는 "그것을 어떤 순서로
가르치는가" 를 정의한다. 대상 학습자는 **영어권·독일어권**이며, 각 Phase 는 16개 필드를 모두 채운다.

| 파일 | 내용 |
|---|---|
| `phases.json` | Phase 정본 — 레벨당 3–6개, 누적 번호 `KP01…`. 각 Phase: 주제 · 한국어 문법(실제 형태) · 기능 · 어휘 영역 · 텍스트 유형 · 듣기/말하기/읽기/쓰기 · 발음 · 화용·문체 · 선수 조건 · EN→KO 브리지 · DE→KO 브리지 · 전이 경고 · 숙달 점검. 하단에 문법 의존 지도(`dependencyMap`: 선수 → 목표 → 상위 재활용) |
| `cross_mapping.json` | 레벨별 KO/EN/DE 개념 교차 매핑(PART 3) + 출처 간 불일치 기록 |
| `transfer.json` | EN→KO · DE→KO 전이 분석(PART 4) — 판정 `positive` / `partial` / `negative_risk` / `new_concept` |
| `phase_review.json` | 배열 검증(PART 6)·10항목 갭 분석(PART 7) 검토 소견 |
| `source_access.json` | 직접 열람한 1차 자료의 URL·쪽·확인 주장·확인하지 않은 범위와 사전 교정 근거 |

현재 배정은 A1 4 · A2 4 · B1 5 · B2 5 · C1 6 · C2 6, 총 30 Phase다.
유실된 클라우드 JSON의 원본 바이트를 복구한 결과가 아니라, 저장소 문법 목록과 남은 89개
의존 노트를 검토해 새로 작성한 설계다. 전이 182항목, 교차 매핑 233행, 의존 연결 117개를 포함한다.
앱 출하 콘텐츠와 336 전 항목의 상세 교수 주석 확장은 별도 범위다.

핵심 불변식: **국제통용 336 형태가 정확히 한 Phase 에서 한 번만 새로 도입된다.** 누락·중복·급 불일치가
있으면 `tool/audit_learning_phases.py` 가 error 를 내고 테스트가 빨개진다. 이전 레벨 형태를 더 깊은
기능으로 다시 쓰는 것은 `role: "spiral"` 로 표시하며 도입으로 세지 않는다.

근거 등급은 확인한 주장과 함께 정한다. 2017 연구의 *문법 목록*은 저장소 CSV와 같은
형태·원 급·범주에만 `[OFFICIAL]`을 붙인다. 새 기능 설명·예문·Phase 배열은 `[PEDAGOGICAL]`이다.
원문 항목을 대조하지 않은 주제 목록도 `[PEDAGOGICAL]`이며 URL만으로 `[DERIVED]`가 되지 않는다.
언어 간 대응·전이 판단 전체는 공식 목록 사실과 다르므로 `[OFFICIAL]`을 붙이지 않는다.
국제통용 원 급, TOPIK 시험 급, CEFR 수행 척도와 모어 쪽 인벤토리는 자동 환산하지 않는다.

문법 식별자는 `G{원 급}:{정확한 형태}`다. 같은 표기의 다른 급·의미를 하나로 합치지 않는다.
선수·재사용·전이·교차표의 `grammarKeys`는 실제 항목과 일치해야 하며 같은 Phase 내부의
의존 순서도 검사한다. `textTypes.use`의 R/P는 해당 매체의 기술 목표(`textTypeId`)에 연결한다.
장르 연습은 과제 설계이며 앱에 실제 녹음·글이 배치되었다는 증거가 아니다.

```bash
python tool/audit_learning_phases.py          # 검증 + PART 1~8 문서 재생성
python tool/audit_learning_phases.py --check  # error 나 낡은 생성물이 있으면 exit 2
python -m unittest tool.test_audit_learning_phases -v
```

산출물(`docs/data/korean_learning_phases_*`): `part1_2_sources`(언어별 레벨 기술 + 근거 등급),
`part3_crossmap`(삼언어 교차 매핑), `part4_transfer`(EN·DE 전이 분석), `part5_phases`(색인) +
`part5_A1`…`part5_C2`(Phase 전문, 레벨별 파일), `part6_7_review`(배열 검증·갭 분석),
`part8_master_matrix`(마스터 매트릭스 + 문법 의존 지도). 기계 판독용: `tool/learning_phase_master_matrix.csv`,
`tool/learning_phase_findings.csv`(소견 한 줄 한 행), `tool/learning_phase_summary.json`.

## 근거 등급 (`provenance`)

| 값 | 뜻 |
|---|---|
| `verified_repo` | 저장소 안의 공공누리 1유형 원본 데이터 또는 검증된 정본 문서에서 그대로 |
| `verified_user` | 사용자가 제공한 연구 요구·작업 로그의 출처 확인. 그 안의 모델 생성 내용을 공식 검증한 표시는 아님 |
| `url_verified_search` | 문서 URL의 존재 확인. 특정 원문 열람은 `source_access.json`에 별도 기록하며 항목 전체의 검증으로 확대하지 않음 |
| `model_knowledge` | 모델 지식으로 채움 — **원문 대조 전까지 EVIDENCE_REQUIRED** |

한국어 문법 축(336항목)과 영어 CEFR-J 항목만 저장소 데이터로 검증된 상태다. 주제·기능·텍스트
유형 목록은 Threshold/Profile deutsch/국제통용 체계를 따르되 세부 문구는 원문 대조가 남아 있다.
2026-09-10에는 CEFR CV, Goethe A1, Cambridge C1 핸드북, 국립국어원 2020 고시의 지정 부분을
직접 읽었다. 확인한 쪽·주장만 기록했으며 기존 목록 전체의 상태를 일괄 승격하지 않았다.
EN/DE 전이의 `sourceLevel`은 현재 교수 추정이다. 항목별 원문 대조와 교육자·원어민 검토가 남아 있다.

## 감사기

```bash
python tool/audit_curriculum_matrix.py                 # 리포트·요약·갭 CSV·삼언어 매트릭스 MD
python tool/audit_curriculum_matrix.py --write-matrix  # 기존 호출 호환 옵션(결과 동일)
python tool/audit_curriculum_matrix.py --check         # 산출물이 낡았으면 exit 2
python -m unittest tool.test_audit_curriculum_matrix -v
```

산출물: `docs/data/curriculum_matrix_report.md`(갭 리포트), `docs/data/cefr_curriculum_matrix.md`
(매트릭스 전문), `tool/curriculum_matrix_summary.json`(카운트), `tool/curriculum_matrix_gaps.csv`
(갭 한 줄 한 행 — `level,axis,id,label,status,evidence,suggested_action`).

판정은 **빈 칸 검출**이 목적이라 문턱이 낮다(주제: 단어 <6 이고 시나리오·유닛 0 이면 thin /
기능·텍스트 유형: <2건 thin / 어휘 영역: <8단어 thin). 풍부함과 레벨 정확도는
`tool/audit_content_levels.py` 와 `docs/CONTENT_LEVEL_BIBLE.md` 의 몫이다. 문법 매칭은
`tool/build_level_bible_tables.py` 의 F1 매처를 그대로 재사용한다.

## 편집 규칙

- JSON 이 정본이다. 빌더 스크립트는 없다 — 직접 고친다(`python -m json.tool` 로 유효성 확인).
- 새 앱 라벨(어휘 `topic`, 서재 slug, 스몰토크 category, 팩 키워드, 시나리오 제목 키워드)은
  `taxonomy.json` 의 alias 에 넣는다. 리포트 §9 "매핑 진단" 이 0 이 되게 유지한다.
- `packKeywords` 는 언더스코어 토큰 단위로 맞춘다(정확 일치, 4자 이상은 접두 일치) — 부분 문자열이
  아니다('ai' 가 'daily' 를 잡지 않는다). `titleKeywords` 는 부분 문자열이므로 한 글자 키워드를 넣지
  않는다.
- 한국어 `grammar.forms` 는 `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv` 와 같아야
  한다(테스트가 등급별 개수를 대조한다). 문법 항목 자체를 고치려면 사전 CSV 를 고친다.
- 새 항목의 `provenance` 를 정직하게 적는다. 원문을 열어 확인하기 전에는 `verified_*` 로 올리지 않는다.
