# 레벨 바이블 사전 원본 — 출처·해시·라이선스 (T1.1, R9 갱신)

`tools/content_factory/lexicon/*.csv`를 만드는 2개 원본 xlsx(§1~2)와 F5(세종한국문화
어휘 등급)가 쓰는 2개 CSV(§4)의 출처, sha256, 다운로드 파라미터, 실측
라이선스 유형을 기록한다. 원본 xlsx(§1~2)는 저장소에 커밋하지 않는다
(`.gitignore`); 보존 사본은 저장소 밖
`C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\`에 둔다. **예외(§4,
R9 2026-09-07):** 세종한국문화 1·2 주요 어휘 CSV는 이미 공공누리 제1유형으로
재사용이 허용되어 있어, 이 규칙과 달리 저장소 사본을
`tools/content_factory/lexicon/sejong_culture_vocab_{1,2}.csv`에 직접
커밋했다 -- PR #283 CI 실패(F5가 이 preservation 폴더에 의존해 그 폴더가
없는 CI에서 `FileNotFoundError`)를 근본적으로 없애기 위함.

## ⚠ 라이선스 불일치 — kcenter CSV는 제거됨 (Fable 룰링 2026-09-07)

플랜 §4.1·§6/T1.1은 세 원본 모두 **공공누리 제1유형(출처표시)**이라고 전제했다.
2026-09-07 이 세션에서 `korean.go.kr`·`data.go.kr` 페이지를 직접 열어 확인한
결과, **한국어교수학습샘터 어휘기본정보(kcenter) CSV만 실제로는 제4유형
(출처표시 + 상업적 이용금지 + 변경금지)**임이 드러났다. 나머지 두 xlsx는
제1유형이 맞다.

| 소스 | 문서에 표시된 유형 | 확인 방법 |
|---|---|---|
| kiiq_2017_grades.xlsx | 제1유형 | report_seq=932 페이지: "제1유형: 출처표시" — 첨부 스프레드시트 라이선스 |
| basic_vocab_2023.xlsx | 제1유형 | report_seq=1160 페이지: 연구보고서 PDF는 제4유형이지만 **첨부 어휘 목록 xlsx는 별도로 "공공누리 제1유형(출처 표시, 상업적·비상업적 이용 가능, 변형 등 2차적 저작물 작성 가능)"**으로 명시 |
| kcenter CSV (어휘기본정보) | **제4유형 — 저장소에서 제거, 사용 금지, 원본은 preservation 폴더에만 보관** | data.go.kr/data/15152177 파일데이터 페이지 라이선스 배지: "공공저작물 : 출처표시, 상업적 이용금지, 변경금지 (제4유형)" (`img_opencode4_m.jpg`) |

제4유형은 **상업적 이용 금지·변형(2차적 저작물 작성) 금지**를 명시하며, 이 앱은
상업 배포 중이다. Fable 룰링(2026-09-07): kcenter CSV는 이 저장소에 커밋하지도
사용하지도 않는다 —
`tools/content_factory/lexicon/nikl_kcenter_vocab_bands.csv`는 삭제했고,
`tool/ingest_nikl_grade_lists.py`에서 kcenter 입출력(`--kcenter` 플래그,
`read_kcenter_csv()`, `nikl_kcenter_vocab_bands.csv` 출력)을 모두 제거했다.
원본 CSV는 preservation 폴더에만 보관한다(재사용 판단이 나올 때까지 저장소에는
절대 들이지 않는다). `tools/content_factory/reference_intake/source_inventory.csv`의
ref0040은 `rights_status=reference_only, allowed_use=coverage_audit_only,
review_status=blocked`로 갱신되었다. 2017 kiiq xlsx가 이미 같은 초/중/고급
밴드 열(`band`)을 갖고 있으므로, kcenter를 빼도 레벨 판정에 필요한 정보는
손실되지 않는다.

## 1. kiiq_2017_grades.xlsx

- **연구명:** 국립국어원(2017)「2017년 국제 통용 한국어 표준 교육과정 적용
  연구(4단계)」— 연구책임자 김중섭.
- **페이지:** https://www.korean.go.kr/front/reportData/reportDataView.do?report_seq=932
- **첨부 파일명(원본):** `2017년 국제 통용 한국어 표준 교육과정 적용 연구(4단계) 어휘, 문법 등급 목록_20180227_20201117 수정.xlsx`
- **다운로드 파라미터:** `/common/download.do?file_path=reportData&c_file_name=<서버 UUID 파일명>.xlsx&o_file_name=<URL 인코딩된 원본 파일명>` — `o_file_name`이 없으면 서버가 원본 파일명을 못 채우므로(응답 자체가 실패하거나 확장자 없는 파일이 내려옴) 다운로드 시 반드시 원본 파일명을 URL-인코딩해 `o_file_name`에 넣어야 한다.
- **sha256:** `2cde28ab90e04728513e65ef5df4baaa400a4055fe2abd1856889cb983c4c3ac`
- **라이선스:** 공공누리 제1유형(출처표시) — report_seq=932 페이지 명시.
- **시트:** `어휘`(10,635행), `문법`(336행).

## 2. basic_vocab_2023.xlsx

- **연구명:** 국립국어원(2023)「2023년 국어 기초 어휘 선정 및 어휘 등급화 연구」
  — 연구책임자 김한샘 외 14인.
- **페이지:** https://www.korean.go.kr/front/reportData/reportDataView.do?report_seq=1160
- **첨부 파일명(원본):** `국어 기초 어휘 선정 및 어휘 등급화 목록 전체.xlsx` (최종보고서 PDF는 `2023년 국어 기초어휘 선정 및 어휘 등급화 연구_최종보고서_20240712.pdf`이며 별도 파일 — 이 PDF는 본 프로그램에서 쓰지 않는다)
- **다운로드 파라미터:** 위 kiiq 항목과 같은 `/common/download.do?file_path=reportData&c_file_name=...&o_file_name=...` 패턴.
- **sha256:** `6eec715bca39d1006702da020f5c61a7a1f3db81fdb6101619f68d0b0ff70b53`
- **라이선스:** 어휘 목록 xlsx는 공공누리 **제1유형**(출처 표시, 상업적·비상업적
  이용 가능, 변형 등 2차적 저작물 작성 가능) — report_seq=1160 페이지가 연구보고서
  PDF(제4유형)와 첨부 xlsx(제1유형)를 별도로 표시함. **본 프로그램은 xlsx만 쓴다.**
- **시트:** `1등급(5,000개)`,`2등급(2,500개)`,`3등급(5,500개)`,`4등급(10,000개)`,
  `5등급(17,000개)`,`전체(1~5등급), 40,000개`(이 프로그램이 쓰는 시트).

## 3. 한국어교수학습샘터 어휘기본정보 CSV (kcenter) — 제거됨, 사용 금지

- **제목:** 문화체육관광부 국립국어원_한국어교수학습샘터_어휘기본정보_20251112
- **페이지:** https://www.data.go.kr/data/15152177/fileData.do?recommendDataYn=Y
- **파일명(원본):** `문화체육관광부 국립국어원_한국어교수학습샘터_어휘기본정보_20251112.csv`
- **sha256:** `24fc7560e5c47114fc40d054edc4bf381759ba153185a0b0d7b002f0d252fe3e`
- **라이선스:** 공공누리 **제4유형**(출처표시, 상업적 이용금지, 변경금지) —
  data.go.kr 파일데이터 상세 페이지 라이선스 배지 확인(2026-09-07).
- **행 수:** 헤더 포함 10,635줄 = 데이터 10,634행, 열 `수준,동형어번호,표출 어휘`.
- **상태:** 위 "라이선스 불일치" 절의 Fable 룰링(2026-09-07)에 따라 저장소에서
  제거되었고(`tools/content_factory/lexicon/nikl_kcenter_vocab_bands.csv` 삭제,
  `tool/ingest_nikl_grade_lists.py`의 `--kcenter`/`read_kcenter_csv()`/출력
  CSV 제거) 앱 어디에도 사용하지 않는다. 원본 CSV는
  `C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\`에만 보관한다.

## 4. 세종한국문화 1·2 주요 어휘 CSV — F5 입력, 저장소에 커밋됨 (R9, 2026-09-07)

`tool/build_level_bible_tables.py`의 F5(세종한국문화 어휘 등급)가 읽는 두 CSV.
위 1~3번과 달리 `cefr_lexicon.py`(등급 판정 엔진)는 이 둘을 읽지 않고, F5
전용이다. `tools/content_factory/reference_intake/source_inventory.csv`의
ref0041/ref0042 행이 이미 `rights_status=licensed`(notes: "KOGL type1")로
기록해 둔 것을 이번 세션에서 그대로 반영했다 -- **이 세션에서 data.go.kr 등
발행 페이지를 직접 재확인하지는 않았다**(1~3번 항목과 달리 실측 라이선스
배지 확인 절차를 거치지 않음; 페이지 URL 확인은 후속 과제로 남는다).

### 4a. 세종한국문화1 주요 어휘

- **발행:** 세종학당재단.
- **파일명(원본):** `세종학당재단_교재_한국문화_세종한국문화1 주요 어휘_20260501.csv`
- **sha256(원본, preservation 사본):**
  `598fe80db17a70946e50de4ac91474062b91da7314d193858b5a4d5b035daf06`
- **sha256(저장소 사본, UTF-8 BOM 제거·LF):**
  `06f784e2ce48b229b437ba67f33fdc97693695dc7dcc584c4a9f56555fb2a714`
- **행 수:** 헤더 포함 82줄 = 데이터 81행, 열 `연번,구분,교재명,단원 연번,단원명,주요 어휘,관련 페이지`.
- **라이선스:** 공공누리 제1유형(출처표시) — source_inventory.csv ref0041.
- **저장소 경로:** `tools/content_factory/lexicon/sejong_culture_vocab_1.csv`.

### 4b. 세종한국문화2 주요 어휘

- **발행:** 세종학당재단.
- **파일명(원본):** `세종학당재단_교재_한국문화_세종한국문화2 주요 어휘_20260507.csv`
- **sha256(원본, preservation 사본):**
  `460b956578d1dfa3b4ad1f7ab3ece59d245a734fb27ed24d404b6fbb30868fa2`
- **sha256(저장소 사본, UTF-8 BOM 제거·LF):**
  `b78851acd9a39e90492679fc6c2ba2e05d4b1f0dc03546b035e9f9b50c4b4bee`
- **행 수:** 헤더 포함 49줄 = 데이터 48행, 열은 4a와 동일.
- **라이선스:** 공공누리 제1유형(출처표시) — source_inventory.csv ref0042.
- **저장소 경로:** `tools/content_factory/lexicon/sejong_culture_vocab_2.csv`.

### 변환 방법 (원본 -> 저장소 사본)

원본은 BOM 포함 UTF-8·CRLF였다. 저장소 사본은 BOM 제거·LF로만 다시 인코딩했고
(Python `str.read_text(encoding="utf-8-sig")` → `write_text(encoding="utf-8",
newline="\n")`), 헤더·행 내용은 원본과 바이트 단위로 동일하다(csv 파싱 결과가
행 단위로 완전히 일치함을 이 세션에서 직접 검증). PR #283이 CI에서 실패한
원인은 F5가 이 두 CSV를 저장소 밖 preservation 폴더에서 직접 읽었기
때문(그 폴더가 없는 CI에서 `FileNotFoundError`) -- 두 CSV가 이미 공공누리
제1유형으로 재사용이 허용된 자료이므로, "선택 입력 + 생성 생략" 처리(F6이
쓰는 방식) 대신 저장소에 직접 커밋해 의존성 자체를 없앴다. 자세한 내용은
`tools/content_factory/lexicon/README.md`의 전용 절 참고.

## 재생성 명령

```powershell
python tool\ingest_nikl_grade_lists.py `
  --kiiq "C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\kiiq_2017_grades.xlsx" `
  --basic "C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\basic_vocab_2023.xlsx" `
  --out tools\content_factory\lexicon
```

무변경 확인(값이 바뀌면 exit 2):

```powershell
python tool\ingest_nikl_grade_lists.py --kiiq ... --basic ... --out tools\content_factory\lexicon --check
```
