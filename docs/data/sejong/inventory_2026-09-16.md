# Sejong Institute Textbook Inventory — Q-S Phase 1

Generated: 2026-09-16. Source directory (read-only, never modified):
`C:\Users\vjinn\ELibrary\Downloads\세종학당 학국어 레벨별 학습자료 참고`

**40 PDF files found** (the Q-S brief assumed 24 — see discrepancy notes below). Raw extracted text is kept OUTSIDE this repo in the session scratchpad; only structured facts and short samples (<=15 words) are committed here.

**Overall extractable share: 1967/6311 pages = 31.2%** (a page counts as extractable if PyMuPDF's text layer yields >= 20 stripped characters).

Notes on discrepancy from the brief's assumed file list (40 vs 24 assumed): the folder contains **two extra 핸드북(실용 한국어 어휘와 문법) volumes for level 2 and 3** not named in the brief, and does **not** contain full-size 교재 for 입문/1/2/3A/3B as separate clean files (only 익힘책, 연습문제, and 'low file size' 교재 variants for some levels exist) — instead it holds the two-volume **세종한국어 회화 익힘책 영어판 1-1/1-2** (a *conversation* workbook set, distinct in title from `세종학당 한국어 1 익힘책`) which is well text-extractable and is the same title `docs/data/level_bible/F4_sejong1_units.md` was built from. This inventory reflects what is actually on disk; conclusions in later phases are scoped to files that exist and are extractable.

**Extractability is highly uneven.** Most 익힘책/연습문제/교재 PDFs for levels 입문, 2, 3A, 3B, 4A, 4B are scanned image pages with 0% text layer (PyMuPDF finds no embedded text at all) — this is a scanner/print-to-PDF artifact of those specific files, not a statement about the books' content. By contrast 어휘사전(영어판) (100%), 세종한국어 회화 익힘책 1-1/1-2 (97.1%), 익힘책 5A/5B/6A/6B (96.2%), and 한국어_5B (92.4%) have strong text layers. This means Phase 2/3 syllabus extraction and comparison below is **only possible for levels 입문(vocab dict only)/1/5/6**, plus a thin sliver of level 2 via the 1.6%-extractable handbook; **levels 3(B1) and 4(B2) have no extractable Sejong source text at all in this folder** and are reported as NOT_EXTRACTABLE, excluded from every content conclusion.

| File | Kind | Level guess | Size (MB) | Pages | Text-layer pages | Extractable % | Sample lines (<=15 words each) |
|---|---|---|---|---|---|---|---|
| 1권_한국어 어휘사전(영어판).pdf | vocab_dictionary | ? | 42.6 | 608 | 608 | 100.0% | p.1: 한국어로 말하고 듣고 쓰고 읽는 데 꼭 필요한<br>p.2: • 이 사전은 한국어로 말하고 듣고 쓰고 읽는 데 필요한 초중급 어휘를 골라서 실었다.<br>p.3: 3. 배열 |
| [연습문제] 세종학당 한국어3A_영어.pdf | exercise_book | 3A | 13.1 | 58 | 0 | 0.0% | (none extracted) |
| [연습문제] 세종학당 한국어3B_영어.pdf | exercise_book | 3B | 12.4 | 58 | 0 | 0.0% | (none extracted) |
| [연습문제] 세종학당 한국어4A_영어.pdf | exercise_book | 4A | 12.7 | 58 | 0 | 0.0% | (none extracted) |
| [연습문제] 세종학당 한국어4B_영어.pdf | exercise_book | 4B | 13.4 | 58 | 0 | 0.0% | (none extracted) |
| [핸드북] 세종학당 실용 한국어_어휘와 문법_2권.pdf | handbook_vocab_grammar | ? | 10.4 | 63 | 1 | 1.6% | p.19:  ଓš߸Пݻଦ߽ |
| [핸드북] 세종학당 실용 한국어_어휘와 문법_3권.pdf | handbook_vocab_grammar | ? | 16.8 | 89 | 0 | 0.0% | (none extracted) |
| [핸드북] 세종학당 실용 한국어_어휘와 문법_4권.pdf | handbook_vocab_grammar | ? | 17.7 | 91 | 0 | 0.0% | (none extracted) |
| 세종통번역 영어-한국어 1-2 익힘책.pdf | workbook | 1 | 16.2 | 98 | 0 | 0.0% | (none extracted) |
| 세종통번역 영어-한국어 2-2 익힘책.pdf | workbook | 2 | 19.0 | 99 | 0 | 0.0% | (none extracted) |
| 세종통번역 한국어-영어 1-1 익힘책.pdf | workbook | 1 | 17.5 | 100 | 0 | 0.0% | (none extracted) |
| 세종통번역 한국어-영어 2-1 익힘책.pdf | workbook | 1 | 19.3 | 99 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 1 익힘책_한국어.pdf | workbook | 1 | 136.6 | 392 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 2 익힘책_영어.pdf | workbook | 2 | 130.0 | 404 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 3A 익힘책_영어.pdf | workbook | 3A | 46.3 | 240 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 3A(영어)_(low file size).pdf | main_textbook | 3A | 60.8 | 240 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 3B 익힘책_영어.pdf | workbook | 3B | 44.7 | 254 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 3B(영어)_(low file size).pdf | main_textbook | 3B | 61.0 | 240 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 4A 익힘책_한국어.pdf | workbook | 4A | 69.4 | 256 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 4B 익힘책_한국어.pdf | workbook | 4B | 44.9 | 254 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 4B(영어)_(low file size).pdf | main_textbook | 4B | 68.1 | 240 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어 익힘책_5A.pdf | workbook | 5A | 2.6 | 53 | 51 | 96.2% | p.1: 세종학당<br>p.2: 바로 배워 바로 쓰는<br>p.3: 세종학당 한국어 5A |
| 세종학당 한국어 익힘책_5B.pdf | workbook | 5B | 3.0 | 53 | 51 | 96.2% | p.1: 세종학당<br>p.2: 바로 배워 바로 쓰는<br>p.3: 세종학당 한국어 5B |
| 세종학당 한국어 익힘책_6A.pdf | workbook | 6A | 3.1 | 53 | 51 | 96.2% | p.1: 세종학당<br>p.2: 바로 배워 바로 쓰는<br>p.3: 세종학당 한국어 6A |
| 세종학당 한국어 익힘책_6B.pdf | workbook | 6B | 2.9 | 53 | 51 | 96.2% | p.1: 세종학당<br>p.2: 바로 배워 바로 쓰는<br>p.3: 세종학당 한국어 6B |
| 세종학당 한국어 입문(영어)_(low file size).pdf | main_textbook | 입문 | 24.9 | 261 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어4A_영어.pdf | main_textbook | 4A | 90.6 | 240 | 0 | 0.0% | (none extracted) |
| 세종학당 한국어_5A.pdf | main_textbook | 5A | 18.3 | 146 | 11 | 7.5% | p.12: 세종학당 한국어 5A<br>p.135: 바로 배워 바로 쓰는 세종학당 한국어 5A        135<br>p.137: 듣기 지문 |
| 세종학당 한국어_5B.pdf | main_textbook | 5B | 14.5 | 145 | 134 | 92.4% | p.1: 세종학당<br>p.2: 바로 배워 바로 쓰는<br>p.3: 세종학당 한국어 5B |
| 세종학당 한국어_6A_250418.pdf | main_textbook | 6A | 66.3 | 146 | 11 | 7.5% | p.135: 바로 배워 바로 쓰는 세종학당 한국어 6A        135<br>p.137: 듣기 지문<br>p.138: 바로 배워 바로 쓰는 세종학당 한국어 6A        137 |
| 세종학당 한국어_6B.pdf | main_textbook | 6B | 19.0 | 144 | 10 | 6.9% | p.12: 세종학당 한국어 6B<br>p.135: 바로 배워 바로 쓰는 세종학당 한국어 6B        135<br>p.137: 듣기 지문 |
| 세종한국어 회화 익힘책_영어판_1-1.pdf | workbook | 1 | 9.0 | 102 | 99 | 97.1% | p.3: ﻿ ﻿  3<br>p.4: 4  세종한국어 회화 익힘책 ➊-1<br>p.5: ﻿ ﻿  5 |
| 세종한국어 회화 익힘책_영어판_1-2.pdf | workbook | 1 | 7.1 | 102 | 99 | 97.1% | p.3: ﻿ ﻿  3<br>p.4: 4  세종한국어 회화 익힘책 ➊-2<br>p.5: ﻿ ﻿  5 |
| 세종한국어 회화 익힘책_영어판_2-1.pdf | workbook | 1 | 4.7 | 102 | 100 | 98.0% | p.3: ﻿ ﻿  3<br>p.4: 4  세종한국어 회화 익힘책 ➋-1<br>p.5: ﻿ ﻿  5 |
| 세종한국어 회화 익힘책_영어판_2-2.pdf | workbook | 2 | 3.7 | 102 | 99 | 97.1% | p.3: ﻿ ﻿  3<br>p.4: 4  세종한국어 회화 익힘책 ➋-2<br>p.5: ﻿ ﻿  5 |
| 세종한국어 회화 익힘책_영어판_3-1.pdf | workbook | 1 | 8.0 | 104 | 101 | 97.1% | p.3: 《세종한국어 회화》 교재 출판은 전 세계에서 한국어를 배우고 싶어 하는 학습자들<br>p.5: 일러두기<br>p.6: 중급 일러두기 |
| 세종한국어 회화 익힘책_영어판_3-2.pdf | workbook | 2 | 4.7 | 102 | 98 | 96.1% | p.3: 《세종한국어 회화》 교재 출판은 전 세계에서 한국어를 배우고 싶어 하는 학습자들<br>p.5: 일러두기<br>p.6: 중급 일러두기 |
| 세종한국어 회화 익힘책_영어판_4-1.pdf | workbook | 1 | 4.8 | 104 | 101 | 97.1% | p.3: 《세종한국어 회화》 교재 출판은 전 세계에서 한국어를 배우고 싶어 하는 학습자들<br>p.5: 일러두기<br>p.6: 중급 일러두기 |
| 세종한국어 회화 익힘책_영어판_4-2.pdf | workbook | 2 | 4.8 | 106 | 103 | 97.2% | p.3: 《세종한국어 회화》 교재 출판은 전 세계에서 한국어를 배우고 싶어 하는 학습자들<br>p.5: 일러두기<br>p.6: 중급 일러두기 |
| 세종한국어4_익힘책.pdf | workbook | ? | 5.1 | 194 | 188 | 96.9% | p.2: 일러두기<br>p.3: 각단원에제시된문법항목을순서대로연습할수있게문법1, 문법2로<br>p.4: 교재에서학습한표현과문법을활용하여실제상황맥락속에서말하기를 |

## Per-file text-layer page ranges (1-based, yes/no)

- **1권_한국어 어휘사전(영어판).pdf**: 1-608:text
- **[연습문제] 세종학당 한국어3A_영어.pdf**: 1-58:NO_TEXT
- **[연습문제] 세종학당 한국어3B_영어.pdf**: 1-58:NO_TEXT
- **[연습문제] 세종학당 한국어4A_영어.pdf**: 1-58:NO_TEXT
- **[연습문제] 세종학당 한국어4B_영어.pdf**: 1-58:NO_TEXT
- **[핸드북] 세종학당 실용 한국어_어휘와 문법_2권.pdf**: 1-18:NO_TEXT; 19:text; 20-63:NO_TEXT
- **[핸드북] 세종학당 실용 한국어_어휘와 문법_3권.pdf**: 1-89:NO_TEXT
- **[핸드북] 세종학당 실용 한국어_어휘와 문법_4권.pdf**: 1-91:NO_TEXT
- **세종통번역 영어-한국어 1-2 익힘책.pdf**: 1-98:NO_TEXT
- **세종통번역 영어-한국어 2-2 익힘책.pdf**: 1-99:NO_TEXT
- **세종통번역 한국어-영어 1-1 익힘책.pdf**: 1-100:NO_TEXT
- **세종통번역 한국어-영어 2-1 익힘책.pdf**: 1-99:NO_TEXT
- **세종학당 한국어 1 익힘책_한국어.pdf**: 1-392:NO_TEXT
- **세종학당 한국어 2 익힘책_영어.pdf**: 1-404:NO_TEXT
- **세종학당 한국어 3A 익힘책_영어.pdf**: 1-240:NO_TEXT
- **세종학당 한국어 3A(영어)_(low file size).pdf**: 1-240:NO_TEXT
- **세종학당 한국어 3B 익힘책_영어.pdf**: 1-254:NO_TEXT
- **세종학당 한국어 3B(영어)_(low file size).pdf**: 1-240:NO_TEXT
- **세종학당 한국어 4A 익힘책_한국어.pdf**: 1-256:NO_TEXT
- **세종학당 한국어 4B 익힘책_한국어.pdf**: 1-254:NO_TEXT
- **세종학당 한국어 4B(영어)_(low file size).pdf**: 1-240:NO_TEXT
- **세종학당 한국어 익힘책_5A.pdf**: 1-3:text; 4:NO_TEXT; 5-51:text; 52:NO_TEXT; 53:text
- **세종학당 한국어 익힘책_5B.pdf**: 1-3:text; 4:NO_TEXT; 5-51:text; 52:NO_TEXT; 53:text
- **세종학당 한국어 익힘책_6A.pdf**: 1-3:text; 4:NO_TEXT; 5-51:text; 52:NO_TEXT; 53:text
- **세종학당 한국어 익힘책_6B.pdf**: 1-3:text; 4:NO_TEXT; 5-51:text; 52:NO_TEXT; 53:text
- **세종학당 한국어 입문(영어)_(low file size).pdf**: 1-261:NO_TEXT
- **세종학당 한국어4A_영어.pdf**: 1-240:NO_TEXT
- **세종학당 한국어_5A.pdf**: 1-11:NO_TEXT; 12:text; 13-134:NO_TEXT; 135:text; 136:NO_TEXT; 137-144:text; 145:NO_TEXT; 146:text
- **세종학당 한국어_5B.pdf**: 1-13:text; 14:NO_TEXT; 15-25:text; 26:NO_TEXT; 27-37:text; 38:NO_TEXT; 39-49:text; 50:NO_TEXT; 51-61:text; 62:NO_TEXT; 63-73:text; 74:NO_TEXT; 75-85:text; 86:NO_TEXT; 87-97:text; 98:NO_TEXT; 99-109:text; 110:NO_TEXT; 111-121:text; 122:NO_TEXT; 123-143:text; 144:NO_TEXT; 145:text
- **세종학당 한국어_6A_250418.pdf**: 1-134:NO_TEXT; 135:text; 136:NO_TEXT; 137-146:text
- **세종학당 한국어_6B.pdf**: 1-11:NO_TEXT; 12:text; 13-134:NO_TEXT; 135:text; 136:NO_TEXT; 137-144:text
- **세종한국어 회화 익힘책_영어판_1-1.pdf**: 1-2:NO_TEXT; 3-100:text; 101:NO_TEXT; 102:text
- **세종한국어 회화 익힘책_영어판_1-2.pdf**: 1-2:NO_TEXT; 3-100:text; 101:NO_TEXT; 102:text
- **세종한국어 회화 익힘책_영어판_2-1.pdf**: 1-2:NO_TEXT; 3-102:text
- **세종한국어 회화 익힘책_영어판_2-2.pdf**: 1-2:NO_TEXT; 3-100:text; 101:NO_TEXT; 102:text
- **세종한국어 회화 익힘책_영어판_3-1.pdf**: 1-2:NO_TEXT; 3:text; 4:NO_TEXT; 5-104:text
- **세종한국어 회화 익힘책_영어판_3-2.pdf**: 1-2:NO_TEXT; 3:text; 4:NO_TEXT; 5-100:text; 101:NO_TEXT; 102:text
- **세종한국어 회화 익힘책_영어판_4-1.pdf**: 1-2:NO_TEXT; 3:text; 4:NO_TEXT; 5-104:text
- **세종한국어 회화 익힘책_영어판_4-2.pdf**: 1-2:NO_TEXT; 3:text; 4:NO_TEXT; 5-106:text
- **세종한국어4_익힘책.pdf**: 1:NO_TEXT; 2-7:text; 8:NO_TEXT; 9-176:text; 177-178:NO_TEXT; 179-180:text; 181-182:NO_TEXT; 183-194:text

## NOT_EXTRACTABLE policy

Any page range flagged `NO_TEXT` above is image-only or garbled for PyMuPDF's text extraction. Those ranges are excluded from all Phase 2-4 conclusions and are reported as "not found in extracted text of <file>", never as "not taught".
