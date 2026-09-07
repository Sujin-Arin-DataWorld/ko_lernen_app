# 레벨 바이블 사전 원본 — 출처·해시·라이선스 (T1.1)

`tools/content_factory/lexicon/*.csv`를 만드는 2개 원본 파일의 출처 URL, sha256,
다운로드 파라미터, 실측 라이선스 유형을 기록한다. 원본 xlsx는 저장소에
커밋하지 않는다(`.gitignore`); 보존 사본은 저장소 밖
`C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07\`에 둔다.

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
