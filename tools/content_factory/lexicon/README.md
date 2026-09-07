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
| `nikl_kiiq_2017_vocab.csv` | `grade,headword,homograph,pos,guide,band` | 10,841(`/` 분리 후) | `(grade,headword,homograph)` |
| `nikl_kiiq_2017_grammar.csv` | `grade,category,form,variants,meaning,band_2stage,band_1to4` | 336 | `(grade,category,form,variants)` |
| `nikl_basic_2023_vocab.csv` | `grade,headword,homograph,pos,origin` | 40,000 | `(grade,headword,homograph)` |
| `aliases.csv` | `app_form,lexicon_form,note` | 18 | 고정 목록(Fable 룰링, 아래 참고) |

## 등급별 행수 (재생성 시 이 숫자와 비교)

- **kiiq 어휘 (분리 전)**: 1급 735 · 2급 1,100 · 3급 1,655 · 4급 2,200 · 5급 2,365 · 6급 2,580 (합계 10,635)
- **kiiq 어휘 (`/` 분리 후, CSV에 실제로 쓰는 행수)**: 1급 805 · 2급 1,128 · 3급 1,690 · 4급 2,225 · 5급 2,394 · 6급 2,599 (합계 10,841)
- **kiiq 문법**: 1급 45 · 2급 45 · 3급 67 · 4급 67 · 5급 56 · 6급 56 (합계 336)
- **basic 2023**: 1등급 5,000 · 2등급 2,500 · 3등급 5,500 · 4등급 10,000 · 5등급 17,000 (합계 40,000)

## 정규화 규칙 (docs/CONTENT_LEVEL_BIBLE.md §3.C 요약)

1. 공백·개행 정리(각 필드).
2. 표제어가 `/`로 묶여 있으면(`오늘02/오늘01`) 행을 분리한다. 품사도 같은
   개수로 `/` 묶여 있으면 위치대로 짝짓고, 아니면(품사가 안 나뉘었거나 —
   실측 3건처럼 — 개수가 안 맞으면) 품사 문자열 전체를 각 행에 그대로 반복한다.
3. 표제어 끝 2자리 동형어 번호를 분리한다(`감사01`→`감사`,1; 번호가 없으면
   homograph=0).
4. 등급은 `1급`/`1등급`처럼 텍스트 앞의 정수를 취한다.
5. **알려진 데이터 흠**: 2017 어휘 목록의 약 30개 항목은 동형어를 `/`가 아니라
   `∙`(가운뎃점)+개행으로 묶는다(예: `독립적01∙\n독립적02`). 스펙이 정의한
   분리 기준은 `/`뿐이므로 이 항목들은 추가로 쪼개지 않는다 — 표제어에
   `01∙` 같은 잔여 문자가 남을 수 있다. `tool/audit_content_levels.py`나
   `aliases.csv`로 개별 보정할지는 후속 세션(§3.F F9 예외표) 판단.
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

## 라이선스 고지

출처: 국립국어원 「2017년 국제 통용 한국어 표준 교육과정 적용 연구(4단계)」
어휘·문법 등급 목록 / 「2023년 국어 기초 어휘 선정 및 어휘 등급화 연구」 —
두 xlsx 모두 공공누리 제1유형(출처표시)이다. 한국어교수학습샘터 어휘기본정보
CSV(공공누리 제4유형 — 출처표시·상업적 이용금지·변경금지)는 이 저장소에서
제거되었고 사용하지 않는다. 자세한 근거는 `docs/data/level_bible/SOURCES.md`
참고.
