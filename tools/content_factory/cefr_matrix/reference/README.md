# reference/ — 외부 공개 데이터셋 사본

## `cefrj-grammar-profile-20180315.csv`

- **제목:** The CEFR-J Grammar Profile, Version 20180315
- **저작권:** Tono Laboratory, Tokyo University of Foreign Studies (TUFS)
- **배포:** Open Language Profiles — https://github.com/openlanguageprofiles/olp-en-cefrj
  (`cefrj-grammar-profile-20180315.csv`, master, 2026-09-09 다운로드)
- **sha256(원본, CRLF):** `94953af376c1336166257e56c78d2139697b40ad8cf6f1235d8f9e89c2efc428`
- **sha256(저장소 사본, LF):** `941895f70173c3c1f5acd1891a62db1d0320cd5636b61bf2600345b8ea3e57b5` —
  `.gitattributes` 의 `*.csv text eol=lf` 가 줄끝만 정규화한다(행 내용은 바이트 동일).
- **라이선스(배포처 명시):** "CEFR-J vocabulary and grammar profile datasets can be used for
  research and commercial purposes with no charge, provided that you cite the dataset
  properly." — 인용 문구: *The CEFR-J Grammar Profile Version 20180315. Compiled by Yukio Tono,
  Tokyo University of Foreign Studies. Retrieved from http://www.cefr-j.org/download.html.*
- **열:** `ID, Shorthand Code, Grammatical Item, Sentence Type, CEFR-J Level, FREQ*DISP,
  Core Inventory, EGP, GSELO, Notes` — 500행, 그중 170행에 CEFR-J 레벨(A1.1~B2.2)이 있고
  `EGP` 열이 English Grammar Profile 레벨을 교차 표기한다. 일본어 주석(`Notes`)은 원본 그대로.
- **용도:** `../en.json` 의 영어 문법 항목이 `cefrj:<ID>` 로 인용한다. 앱 런타임은 읽지 않는다.
- **변경:** 줄끝 CRLF→LF 정규화만(git 속성). 재다운로드 시 원본 sha256 을 대조한다.

## `cefrj-vocabulary-profile-1.5.csv`

- **제목:** The CEFR-J Vocabulary Profile, Version 1.5
- **저작권:** Tono Laboratory, Tokyo University of Foreign Studies (TUFS)
- **배포:** https://raw.githubusercontent.com/openlanguageprofiles/olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv
  (2026-09-09 다운로드)
- **sha256(원본, CRLF):** `b0dd3c635f1c9a4fdf1490c7e5b7c48e8bbe55b652ad0c9860a95f98e10ae498`
- **sha256(저장소 사본, LF):** `be1a5f4e17fcaa5bb3e31643f5844645a496dbdfbdace3b4278a179853f2317e`
- **라이선스:** 문법 프로파일과 동일 — 인용하면 연구·상업 목적 무료 사용. 인용 문구:
  *The CEFR-J Vocabulary Profile Version 1.5. Compiled by Yukio Tono, Tokyo University of Foreign
  Studies. Retrieved from http://www.cefr-j.org/download.html.*
- **열:** `headword, pos, CEFR, CoreInventory 1, CoreInventory 2, Threshold` — 7,799행.
  레벨 분포 A1 1,164 · A2 1,411 · B1 2,446 · B2 2,778. **A1–B2 만 다룬다(C1·C2 없음).**
- **용도:** `../en.json` 의 레벨별 `scale.cefrjVocabulary` 가 이 수치를 인용한다 — 영어 어휘 규모는
  이제 재구성이 아니라 저장소 대조 가능한 값이다. 앱 런타임은 읽지 않는다.

## 초기 환경의 접근 기록과 현재 확인 범위

아래 접근 제한은 2026-09-09 초기 작성 환경의 기록이다. 2026-09-10 후속 검토에서는
CEFR CV·Goethe A1·Cambridge C1·국립국어원 2020 고시 PDF의 지정 부분을 직접 읽었다.
현재 확인한 URL·쪽·주장·한계는 `../source_access.json`이 정본이다. 원문 열람만으로
프로젝트의 언어 목록이나 전이·Phase 전체를 검증했다고 표시하지 않는다.

### 받아오지 못한 것 / 받았지만 넣지 않은 것 (2026-09-09 기록)

이 세션의 이그레스는 좁은 허용 목록이다. `raw.githubusercontent.com` 만 curl 로 문서를 준다
(`example.com` 조차 차단된다). 두 경로(curl · WebFetch)를 각각 시험한 결과:

- **차단(원문 확보 불가):** korean.go.kr · kcenter.korean.go.kr · topik.go.kr · data.go.kr ·
  api.odcloud.kr · nl.go.kr · riss.kr · mcst.go.kr · korea.kr · moe.go.kr · ncic.re.kr ·
  rm.coe.int · coe.int · englishprofile.org · cambridgeenglish.org · goethe.de · bamf.de ·
  telc.net · wikipedia · huggingface.co · zenodo.org · archive.org · web.archive.org.
  따라서 국제통용 고시 별책 · TOPIK 등급 기술 · CEFR CV 2020 · Goethe Prüfungsziele · DTZ ·
  BAMF · telc · Cambridge 핸드북의 내용을 대조하지 못했다. 해당 상태의 재구성은
  현재 근거 규칙상 `[PEDAGOGICAL]`이며, URL만으로 `[DERIVED]`를 부여하지 않는다.
- **확정된 부재:** `openlanguageprofiles` 조직은 저장소가 정확히 3개다(`olp-en-cefrj`,
  `olp-zh-zerotohero`, 웹사이트). **English Grammar Profile · English Vocabulary Profile 데이터셋은
  이 조직에 없다** — 이 경로로는 EGP/EVP 원본을 얻을 수 없다. `en.json` 의 `egp:` 인용은 레벨
  라벨 참조이며 원본 대조가 아니다(CEFR-J 문법 CSV 의 `EGP` 열이 유일한 교차 표기다).
- **받았지만 저장소에 넣지 않음:**
  - *Octanove Vocabulary Profile C1/C2 v1.0* — C1 1,111 · C2 1,025, CC BY-SA 4.0,
    sha256 `18c33a407f2f89f7b8de9671c6d45fe3ea0bce45e7d2d7dcaab48d73e0f7b380`,
    `…/olp-en-cefrj/master/octanove-vocabulary-profile-c1c2-1.0.csv`. CEFR-J 가 비워 둔 C1·C2 를
    메우지만 copyleft 라이선스라 이 저장소에 벤더링할지는 사람이 판단할 일이다 — 수치만 인용한다.
  - *haydarkadioglu/goethe-vocab* — Goethe A1/A2/B1 Wortliste 를 제3자가 추출한 JSON
    (737 · 1,409 · 3,645 = 5,791항목, 원본 PDF 쪽번호 포함). 라이선스 없음, 단독 저자, 검증 없음.
    Goethe 어휘를 `[OFFICIAL]` 로 올리는 근거가 되지 못한다(기껏해야 "제3자 추출과 교차 확인").
