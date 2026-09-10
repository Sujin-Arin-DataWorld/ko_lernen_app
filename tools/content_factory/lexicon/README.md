# NIKL 등급 사전 (`tools/content_factory/lexicon/`)

`tool/cefr_lexicon.py`가 읽는 등급 판정용 CSV 4종. 생성기는
`tool/ingest_nikl_grade_lists.py`(표준 라이브러리 `zipfile`+
`xml.etree.ElementTree`로 xlsx를 직접 파싱 — `openpyxl`은 이 환경에 없음).
원본 소스의 URL·sha256·라이선스 유형은 `docs/data/level_bible/SOURCES.md`
참고.

**한국어교수학습샘터 어휘기본정보 CSV는 저장소에서 제거되었다** — 공공누리
제4유형(출처표시·상업적 이용금지·변경금지)으로 확인되어(2026-09-07) 이
저장소에 커밋·사용할 수 없다. 원본은 preservation 폴더에만 보관하며,
2017 kiiq xlsx가 이미 같은 초/중/고급 밴드 열을 갖고 있으므로 정보 손실은
없다. 자세한 근거는 `docs/data/level_bible/SOURCES.md` 참고.

## 파일

| 파일 | 열 | 행수 | 정렬 |
|---|---|---|---|
| `nikl_kiiq_2017_vocab.csv` | `grade,headword,homograph,pos,guide,band` | 11,097(구분자 분리 후) | `(grade,headword,homograph)` |
| `nikl_kiiq_2017_grammar.csv` | `grade,category,form,variants,meaning,band_2stage,band_1to4` | 336 | `(grade,category,form,variants)` |
| `nikl_basic_2023_vocab.csv` | `grade,headword,homograph,pos,origin` | 40,000 | `(grade,headword,homograph)` |
| `aliases.csv` | `app_form,lexicon_form,note` | 18 | 고정 목록(Fable 룰링, 아래 참고) |

## 등급별 행수 (재생성 시 이 숫자와 비교)

- **kiiq 어휘 (분리 전)**: 1급 735 · 2급 1,100 · 3급 1,655 · 4급 2,200 · 5급 2,365 · 6급 2,580 (합계 10,635)
- **kiiq 어휘 (구분자 분리 후, CSV에 실제로 쓰는 행수)**: 1급 809 · 2급 1,132 · 3급 1,713 · 4급 2,284 · 5급 2,457 · 6급 2,702 (합계 11,097)
- **kiiq 문법**: 1급 45 · 2급 45 · 3급 67 · 4급 67 · 5급 56 · 6급 56 (합계 336)
- **basic 2023**: 1등급 5,000 · 2등급 2,500 · 3등급 5,500 · 4등급 10,000 · 5등급 17,000 (합계 40,000)

## 정규화 규칙 (docs/CONTENT_LEVEL_BIBLE.md §3.C 요약)

1. 공백·개행 정리(각 필드).
2. 표제어가 `/`, `∙`(U+2219 bullet operator), `·`(U+00B7 가운뎃점),
   `•`(U+2022 bullet) 중 무엇으로든 묶여 있으면(`오늘02/오늘01`,
   `마흔02∙마흔`) 행을 분리한다 — 네 구분자 모두 동등하게 취급한다. 2017
   어휘 목록은 동형어/품사 변형을 묶을 때 `/`뿐 아니라 `∙`도 섞어 쓴다
   (약 262행 — 개행이 같이 낀 경우도 있다: `독립적01∙\n독립적02`). 품사도
   같은 구분자 조합으로 같은 개수만큼 나뉘어 있으면 위치대로 짝짓고
   (`수사∙관형사`→`['수사','관형사']`), 아니면(품사가 안 나뉘었거나 — 실측
   12건처럼 — 개수가 안 맞으면) 품사 문자열 전체를 각 행에 그대로 반복한다.
3. 표제어 끝 2자리 동형어 번호를 분리한다(`감사01`→`감사`,1; 번호가 없으면
   homograph=0).
4. 등급은 `1급`/`1등급`처럼 텍스트 앞의 정수를 취한다.

## `aliases.csv` 초기 행 (Fable 룰링 2026-09-07, 승인 플랜 §6/T1.1)

구어체 별칭·존대 동급어·관용 표현 18건을 고정 값으로 싣는다(사전 데이터에서
파생하지 않음). `lexicon_form`이 비어 있으면 "사전 등급과 무관하게 A1 유지"
예외(예: 화이팅·별말씀을요·천만에요)를 뜻한다. 새 별칭은 이 파일을 직접
편집하지 말고 브리프로 Fable에게 룰링을 요청한 뒤 `ALIAS_ROWS`
(`tool/ingest_nikl_grade_lists.py`)에 추가하고 재생성한다.

## 재생성

```powershell
python tool\ingest_nikl_grade_lists.py `
  --kiiq <kiiq_2017_grades.xlsx 경로> `
  --basic <basic_vocab_2023.xlsx 경로> `
  --out tools\content_factory\lexicon
```

값이 바뀌지 않았는지 검증(다르면 exit 2):

```powershell
python tool\ingest_nikl_grade_lists.py --kiiq ... --basic ... --out tools\content_factory\lexicon --check
```

원본 xlsx는 저장소에 커밋하지 않는다(`.gitignore`의
`tools/content_factory/lexicon/*.xlsx`). 보존 사본과 URL·sha256은
`docs/data/level_bible/SOURCES.md` 참고.

## `sejong_culture_vocab_1.csv` / `sejong_culture_vocab_2.csv` (F5 문화 어휘 입력)

`tool/build_level_bible_tables.py`의 F5(세종한국문화 어휘 등급 -- `CULTURE1_CSV`/
`CULTURE2_CSV`)가 읽는 입력. 위 "파일" 표의 4종(등급 판정용, `cefr_lexicon.py`가
읽는 것)과는 별도이며 `cefr_lexicon.py`는 이 두 CSV를 읽지 않는다.

- **제목:** 세종한국문화1 주요 어휘 / 세종한국문화2 주요 어휘.
- **발행:** 세종학당재단.
- **원본 파일명:** `세종학당재단_교재_한국문화_세종한국문화1 주요 어휘_20260501.csv`
  (81행) / `세종학당재단_교재_한국문화_세종한국문화2 주요 어휘_20260507.csv`(48행).
- **라이선스:** 공공누리 제1유형(출처표시) --
  `tools/content_factory/reference_intake/source_inventory.csv`의 ref0041/
  ref0042 행(`rights_status=licensed`, notes에 "KOGL type1" 명시).
- **저장소 사본:** 원본(BOM 포함 UTF-8, CRLF)을 UTF-8(BOM 제거)·LF로만
  변환했다 -- 헤더(`연번,구분,교재명,단원 연번,단원명,주요 어휘,관련 페이지`)와
  어휘 CSV의 각 행은 원본과 바이트 단위로 동일한 내용을 그대로 옮겼다(재인코딩 외
  변경 없음). 문법 CSV는 두 행만 예외로, `ingest_nikl_grade_lists._clean_form()` 이
  `form`·`variants` 칸의 soft hyphen(U+00AD)을 붙임표로 되돌리고 형태 끝 문장부호를
  걷어 낸다 — 5급 `-으려고2`, 6급 `-을망정`. 근거와 이유는
  `docs/data/level_bible/SOURCES.md` 의 변환 방법 절 참고. 원본 그대로의 보존 사본은 계속
  `C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\`에도 남아 있다.
- **F5가 preservation 폴더에 의존하지 않는 이유(R9, 2026-09-07):** 이전에는
  `build_level_bible_tables.py`가 이 두 CSV를 저장소 밖 preservation
  폴더에서 직접 읽어, 그 폴더가 없는 머신(CI 포함)에서 F5뿐 아니라
  `generate_all()`을 호출하는 모든 테스트가 `FileNotFoundError`로
  실패했다(PR #283 CI 실패 원인). 이미 공공누리 제1유형으로 재사용이 허용된
  자료이므로 preservation 사본 대신 이 저장소 사본을 커밋해 의존성을 완전히
  제거했다 -- F6(KERIS CSV·전국초중등 JSON, 아직 저장소 반입 미승인)처럼
  "선택 입력 + 생성 생략" 처리로 남겨두지 않은 것은 이 때문이다.

## 라이선스 고지

출처: 국립국어원 「2017년 국제 통용 한국어 표준 교육과정 적용 연구(4단계)」
어휘·문법 등급 목록 / 「2023년 국어 기초 어휘 선정 및 어휘 등급화 연구」 —
두 xlsx 모두 공공누리 제1유형(출처표시)이다. `sejong_culture_vocab_1.csv`/
`sejong_culture_vocab_2.csv`(세종학당재단 세종한국문화1·2 주요 어휘)도
공공누리 제1유형(출처표시)이다 -- 자세한 내용은 위 전용 절 참고. 한국어교수학습샘터
어휘기본정보 CSV(공공누리 제4유형 — 출처표시·상업적 이용금지·변경금지)는 이
저장소에서 제거되었고 사용하지 않는다. 자세한 근거는
`docs/data/level_bible/SOURCES.md` 참고.
