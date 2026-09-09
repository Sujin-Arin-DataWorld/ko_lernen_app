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
| `taxonomy.json` | 언어 독립 id: `topics`(32) · `speechActs`(39) · `textTypes`(31) · `vocabDomains`(26) · `functionalGrammar`(34) · `registers`(4) · `skills`(5). 각 항목에 `label{ko,en,de}` 와 **앱 표면 alias**(`appAliases.vocabTopics/shelfSlugs/smalltalkCategories/packKeywords/titleKeywords`, 기능 `matchers.ko/en`, 텍스트 유형 `matchers`) |
| `ko.json` | 한국어 — 레벨별 `scale`·`canDo`·`topics`(required/optional + focus)·`grammar`(국제통용 형태 전수 + `briefHighlights` + `discourseFeatures`)·`speechActs`·`textTypes`(R/P)·`vocabDomains`·`registers`·발음·문화·문장 규칙; `functionalGrammar`(앱 grammar.csv id 앵커) |
| `en.json` / `de.json` | 영어·독일어 — 같은 구조. 문법은 항목 목록(`grammar.items`, 출처 인용 포함). 갭 판정에는 쓰지 않고 삼언어 정렬표에만 쓴다 |
| `reference/cefrj-grammar-profile-20180315.csv` | CEFR-J 문법 프로파일 500항목(170항목 CEFR-J 레벨 + EGP 교차 레벨). `en.json` 이 `cefrj:<ID>` 로 인용 |

## 근거 등급 (`provenance`)

| 값 | 뜻 |
|---|---|
| `verified_repo` | 저장소 안의 공공누리 1유형 원본 데이터 또는 검증된 정본 문서에서 그대로 |
| `verified_user` | Jin 이 2026-09-09 세션에 입력한 교차검증 브리프 |
| `url_verified_search` | 출처 문서의 존재·URL은 웹 검색으로 확인, 원문은 열지 못함(프록시 차단) — 항목 내용은 model_knowledge |
| `model_knowledge` | 모델 지식으로 채움 — **원문 대조 전까지 EVIDENCE_REQUIRED** |

한국어 문법 축(336항목)과 영어 CEFR-J 항목만 저장소 데이터로 검증된 상태다. 주제·기능·텍스트
유형 목록은 Threshold/Profile deutsch/국제통용 체계를 따르되 세부 문구는 원문 대조가 남아 있다.
원문 PDF 를 받으면 `sources[].provenance` 를 올리고 어긋난 항목만 고친다.

## 감사기

```bash
python tool/audit_curriculum_matrix.py                 # 리포트·요약·갭 CSV
python tool/audit_curriculum_matrix.py --write-matrix  # + 삼언어 매트릭스 MD 렌더
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
