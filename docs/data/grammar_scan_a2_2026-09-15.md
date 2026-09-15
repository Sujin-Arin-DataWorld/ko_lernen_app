# A2 Grammar Scan — 2026-09-15 (C2b-2 step 2, scan_grammar_level.py)

> Detector: `tool/cefr_lexicon.py` `GrammarIndex` (grade>=3 = out of level for A2) + explicit 인용 regex (grade 3) (the grade-2 contracted-aux/전성어미 sub-checks are inactive at this level -- grade 2 is IN level, see module docstring). Known structural gap: nikl grade>=3 items with a <=2-syllable literal core (19 such items, e.g. -어도/-어야/대로/뿐/만큼/-는다/-잖아) are dropped by GrammarIndex's own anti-overmatch guard regardless of level and are NOT regex-hunted here (see module docstring) -- add a hand-verified `MANUAL_HITS` entry if the row-by-row reading pass finds a concrete instance.

## korean_vocab.csv (A2 `example_korean`)

- flagged rows: **0**
- id-prefix/level-field mismatches: **291**

id-prefix vs level-field mismatches -- EXPECTED (ids are immutable; a later relevel only changes `level`). Listed for visibility only.

| id | level field | id-prefix level |
|---|---|---|
| `vocab_a1_0211` | b1 | a1 |
| `vocab_a1_0216` | b1 | a1 |
| `vocab_a1_0224` | b1 | a1 |
| `vocab_a1_0225` | b1 | a1 |
| `vocab_a1_0226` | b1 | a1 |
| `vocab_a1_0227` | b1 | a1 |
| `vocab_a1_0228` | b1 | a1 |
| `vocab_a1_0229` | b1 | a1 |
| `vocab_a1_0230` | b1 | a1 |
| `vocab_a1_0231` | b1 | a1 |
| `vocab_a1_0232` | b1 | a1 |
| `vocab_a1_0233` | b1 | a1 |
| `vocab_a1_0234` | b1 | a1 |
| `vocab_a1_0235` | b1 | a1 |
| `vocab_a1_0236` | a2 | a1 |
| `vocab_a1_0237` | a2 | a1 |
| `vocab_a1_0238` | a2 | a1 |
| `vocab_a1_0239` | a2 | a1 |
| `vocab_a1_0240` | a2 | a1 |
| `vocab_a1_0241` | a2 | a1 |
| `vocab_a1_0242` | a2 | a1 |
| `vocab_a1_0243` | a2 | a1 |
| `vocab_a1_0244` | a2 | a1 |
| `vocab_a1_0245` | a2 | a1 |
| `vocab_a1_0246` | a2 | a1 |
| … | (266 more, truncated) | |

## cloze.json (A2 `fullKo`)

- flagged rows: **0**
- id-prefix/level-field mismatches: **256**

id-prefix vs level-field mismatches -- EXPECTED (ids are immutable; a later relevel only changes `level`). Listed for visibility only.

| id | level field | id-prefix level |
|---|---|---|
| `cloze_a1_0104` | b1 | a1 |
| `cloze_a1_0112` | b1 | a1 |
| `cloze_a1_0113` | b1 | a1 |
| `cloze_a1_0114` | b1 | a1 |
| `cloze_a1_0115` | b1 | a1 |
| `cloze_a1_0116` | b1 | a1 |
| `cloze_a1_0117` | b1 | a1 |
| `cloze_a1_0118` | b1 | a1 |
| `cloze_a1_0119` | b1 | a1 |
| `cloze_a1_0120` | b1 | a1 |
| `cloze_a1_0121` | b1 | a1 |
| `cloze_a1_0122` | b1 | a1 |
| `cloze_a1_0123` | b1 | a1 |
| `cloze_a1_0124` | a2 | a1 |
| `cloze_a1_0125` | a2 | a1 |
| `cloze_a1_0126` | a2 | a1 |
| `cloze_a1_0127` | a2 | a1 |
| `cloze_a1_0128` | a2 | a1 |
| `cloze_a1_0129` | a2 | a1 |
| `cloze_a1_0130` | a2 | a1 |
| `cloze_a1_0131` | a2 | a1 |
| `cloze_a1_0132` | a2 | a1 |
| `cloze_a1_0133` | a2 | a1 |
| `cloze_a1_0134` | a2 | a1 |
| `cloze_a1_0135` | a2 | a1 |
| … | (231 more, truncated) | |

## satz_sentences.json (A2 `targetKo`)

- flagged rows: **0**
- id-prefix/level-field mismatches: **267**

id-prefix vs level-field mismatches -- EXPECTED (ids are immutable; a later relevel only changes `level`). Listed for visibility only.

| id | level field | id-prefix level |
|---|---|---|
| `satz_a1_0063` | b1 | a1 |
| `satz_a1_0068` | b1 | a1 |
| `satz_a1_0076` | b1 | a1 |
| `satz_a1_0077` | b1 | a1 |
| `satz_a1_0078` | b1 | a1 |
| `satz_a1_0079` | b1 | a1 |
| `satz_a1_0080` | b1 | a1 |
| `satz_a1_0081` | b1 | a1 |
| `satz_a1_0082` | b1 | a1 |
| `satz_a1_0083` | b1 | a1 |
| `satz_a1_0084` | b1 | a1 |
| `satz_a1_0085` | b1 | a1 |
| `satz_a1_0086` | b1 | a1 |
| `satz_a1_0087` | b1 | a1 |
| `satz_a1_0088` | a2 | a1 |
| `satz_a1_0089` | a2 | a1 |
| `satz_a1_0090` | a2 | a1 |
| `satz_a1_0091` | a2 | a1 |
| `satz_a1_0092` | a2 | a1 |
| `satz_a1_0093` | a2 | a1 |
| `satz_a1_0094` | a2 | a1 |
| `satz_a1_0095` | a2 | a1 |
| `satz_a1_0096` | a2 | a1 |
| `satz_a1_0097` | a2 | a1 |
| `satz_a1_0098` | a2 | a1 |
| … | (242 more, truncated) | |

## A2 vocabulary outside its NIKL grade ceiling (report only)

- total: **92**

| id | grade | headword |
|---|---|---|
| `vocab_a1_0239` | 6 (C2) | 윗목 |
| `vocab_a1_0240` | 6 (C2) | 아랫목 |
| `vocab_a2_0350` | 6 (C2) | 밤참 |
| `vocab_a2_0399` | 6 (C2) | 근력 |
| `vocab_a2_0096` | 5 (C1) | 매콤하다 |
| `vocab_a2_0243` | 5 (C1) | 왕자 |
| `vocab_a1_0306` | 5 (C1) | 사진 전송 |
| `vocab_a2_0218` | 4 (B2) | 땅콩 |
| `vocab_a1_0324` | 4 (B2) | 일회용 밴드 |
| `vocab_a1_0329` | 4 (B2) | 무처방 |
| `vocab_a1_0366` | 4 (B2) | 필기하다 |
| `vocab_a1_0391` | 4 (B2) | 겹쳐 입다 |
| `vocab_a2_0400` | 4 (B2) | 유산소 |
| `vocab_a2_0403` | 4 (B2) | 염색 |
| `vocab_a2_0412` | 4 (B2) | 손질 |
| `vocab_a2_0029` | 3 (B1) | 문자 |
| `vocab_a2_0088` | 3 (B1) | 메뉴판 |
| `vocab_a2_0089` | 3 (B1) | 추천하다 |
| `vocab_a2_0101` | 3 (B1) | 환불 |
| `vocab_a2_0104` | 3 (B1) | 점원 |
| `vocab_a2_0106` | 3 (B1) | 곧장 |
| `vocab_a2_0118` | 3 (B1) | 신나다 |
| `vocab_a2_0121` | 3 (B1) | 동료 |
| `vocab_a2_0126` | 3 (B1) | 야근하다 |
| `vocab_a2_0128` | 3 (B1) | 면접 |
| `vocab_a2_0131` | 3 (B1) | 화장하다 |
| `vocab_a2_0145` | 3 (B1) | 청소기 |
| `vocab_a2_0148` | 3 (B1) | 월세 |
| `vocab_a2_0157` | 3 (B1) | 수수료 |
| `vocab_a2_0160` | 3 (B1) | 저축하다 |
| `vocab_a2_0161` | 3 (B1) | 코트 |
| `vocab_a2_0172` | 3 (B1) | 배낭 |
| `vocab_a2_0179` | 3 (B1) | 벨트 |
| `vocab_a2_0181` | 3 (B1) | 부츠 |
| `vocab_a2_0182` | 3 (B1) | 샌들 |
| `vocab_a2_0183` | 3 (B1) | 슬리퍼 |
| `vocab_a2_0184` | 3 (B1) | 스타킹 |
| `vocab_a2_0187` | 3 (B1) | 후추 |
| `vocab_a2_0191` | 3 (B1) | 차림표 |
| `vocab_a2_0196` | 3 (B1) | 후식 |
| `vocab_a2_0207` | 3 (B1) | 화분 |
| `vocab_a2_0213` | 3 (B1) | 쇠고기 |
| `vocab_a2_0219` | 3 (B1) | 잼 |
| `vocab_a2_0223` | 3 (B1) | 숲 |
| `vocab_a2_0226` | 3 (B1) | 풀 |
| `vocab_a2_0228` | 3 (B1) | 용 |
| `vocab_a2_0230` | 3 (B1) | 눈사람 |
| `vocab_a2_0231` | 3 (B1) | 눈싸움 |
| `vocab_a2_0244` | 3 (B1) | 공주 |
| `vocab_a2_0258` | 3 (B1) | 닫히다 |
| `vocab_a2_0260` | 3 (B1) | 꺼지다 |
| `vocab_a1_0236` | 3 (B1) | 현관 |
| `vocab_a1_0237` | 3 (B1) | 손님 슬리퍼 |
| `vocab_a1_0247` | 3 (B1) | 방문 예절 |
| `vocab_a1_0298` | 3 (B1) | 촬영 금지 |
| `vocab_a1_0305` | 3 (B1) | 안부 |
| `vocab_a1_0307` | 3 (B1) | 방문 소감 |
| `vocab_a2_0269` | 3 (B1) | 어디서 오셨어요 |
| `vocab_a2_0274` | 3 (B1) | 소개팅 |
| `vocab_a2_0276` | 3 (B1) | 통역 부탁 |

## Summary

- vocab flagged: 0
- cloze flagged: 0
- satz flagged: 0
- **total flagged: 0**
- A2 vocab words outside grade ceiling: 92
