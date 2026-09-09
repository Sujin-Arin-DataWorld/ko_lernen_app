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
