# Sejong ↔ NIKL ↔ our CEFR level map (Q-S, 2026-09-16)

This is Fable's working assumption from the Q-S brief, checked against what
the books themselves actually say (front matter, colophon), and against what
is even extractable in this folder (see `inventory_2026-09-16.md`).

## Two different Sejong series live in this folder

The Q-S brief assumed one 11-book series (입문/1/2/3A/3B/4A/4B/5A/5B/6A/6B).
The folder actually holds **two different published series**:

1. **세종학당 한국어 (main course)** — 교재/익힘책/연습문제 for 입문, 1, 2, 3A,
   3B, 4A, 4B, 5A, 5B, 6A, 6B. Almost all of these files are scanned-image
   PDFs with **0% text layer** (see inventory) — the only well-extractable
   members are `세종학당 한국어 익힘책_5A/5B/6A/6B.pdf` (96.2%) and, thinly,
   `세종학당 한국어_5B.pdf` (92.4%, mostly its 듣기 지문 listening-script
   appendix).
2. **세종한국어 회화 (conversation course)** — 익힘책_영어판 in 4 levels
   (1,2,3,4), each split into two half-volumes (`-1`=units 1-7,
   `-2`=units 8-14), 14 units/level. All 8 files are ~96-98% text. This is
   the same title `docs/data/level_bible/F4_sejong1_units.md` was already
   built from (level 1 only).

Because the main-course books for 입문/2/3A/3B/4A/4B are not extractable at
all, **Phase 2/3 syllabus data in this audit comes from series 2 for levels
1-4 and from series 1's workbook for levels 5-6.** There is no way, with what
is on disk, to split series 2's level-3/4 units into "3A vs 3B" or "4A vs
4B" — the app's own level taxonomy is CEFR (A1..C2), not Sejong's A/B
sub-split, so this loss is immaterial to the comparison in Phase 3.

## Working mapping used in this audit

| Our CEFR | NIKL/TOPIK grade | Sejong source used here | Extractable? |
|---|---|---|---|
| A1 | 1급 | 세종한국어 회화 익힘책 1(-1,-2) | yes, 97.1% |
| A2 | 2급 | 세종한국어 회화 익힘책 2(-1,-2) | yes, ~97.5% |
| B1 | 3급 | 세종한국어 회화 익힘책 3(-1,-2) | yes, ~96.6% |
| B2 | 4급 | 세종한국어 회화 익힘책 4(-1,-2) | yes, ~97.1% |
| C1 | 5급 | 세종학당 한국어 익힘책 5A/5B (main course) | yes, 96.2% (no vocab index appendix; grammar only) |
| C2 | 6급 | 세종학당 한국어 익힘책 6A/6B (main course) | yes, 96.2% (no vocab index appendix; grammar only) |
| (below A1) | — | 입문 (main course) | **NOT_EXTRACTABLE** — the only 입문 file on disk is 0% text (`세종학당 한국어 입문(영어)_(low file size).pdf`) |

This matches `docs/CONTENT_LEVEL_BIBLE.md` §A's own stated mapping ("세종한국어
1·회화 1" → A1, "2" → A2, "3" → B1, "4" → B2, "5A/5B" → C1, "6A/6B" → C2) —
Fable's assumption and the book's own naming agree here.

## What the books say about themselves (cited)

- `세종한국어 회화 익힘책_영어판_1-1.pdf` p.6: section heading **"초급
  일러두기"** ("Beginner-level guide") and colophon p.102: **"세종한국어 회화
  익힘책 ❶ - 1(초급)"** — level 1 is self-labelled 초급 (beginner).
- `세종한국어 회화 익힘책_영어판_2-1.pdf` p.6: **"초급 일러두기"** and
  colophon p.102: **"세종한국어 회화 익힘책 ❷ - 1(초급)"** — level 2
  is *also* self-labelled 초급, not a separate tier from level 1.
- `세종한국어 회화 익힘책_영어판_3-1.pdf` p.6: **"중급 일러두기"** and
  colophon p.104: **"세종한국어 회화 익힘책 ❸ - 1(중급)"** — level 3 is 중급
  (intermediate).
- `세종한국어 회화 익힘책_영어판_4-1.pdf` p.6: **"중급 일러두기"** and
  colophon p.104: **"세종한국어 회화 익힘책 ❹ - 1(중급)"** — level 4 is
  *also* 중급, not a separate tier from level 3.
- `세종학당 한국어 익힘책_5A.pdf` p.3: cover states **"ADVANCED  King Sejong
  Institute Korean 5A"** in English (no separate 초/중/고 Korean label found
  on the extractable pages).

So the book's own self-description only distinguishes three coarse tiers
(초급=1-2, 중급=3-4, [advanced label seen in English only for 5]) — it does
**not** print an explicit "1급/2급/.../6급" TOPIK number anywhere we found in
the extracted front matter. The 1-2 vs 3-4 coarse grouping is at least
consistent in direction with treating 1→A1, 2→A2, 3→B1, 4→B2 (beginner pair,
then intermediate pair), but it is **not independent confirmation of the
exact 1:1 grade mapping** — that mapping is Fable's assumption (matching
`CONTENT_LEVEL_BIBLE.md` §A), not something these books state in so many
words. This is flagged, not silently assumed as confirmed.

## Vocabulary dictionary as a cross-check (per Q-S Phase 1 instruction)

`1권_한국어 어휘사전(영어판).pdf` (100% extractable, 608pp) states in its
front matter:

- p.1: title **"한국어 기초어휘 학습사전 / KOREAN BASIC VOCABULARY LEARNING
  DICTIONARY / English Edition"**.
- p.2: **"현대 한국어의 어휘 가운데 5,039개를 가려 뽑았다"** (5,039 headwords
  selected) and **"한국어 학습용 초급 및 중급 목록에 수록된 어휘를 중심으로
  선정하였다"** (selected mainly from beginner/intermediate learning-vocab
  lists) — i.e. this dictionary only covers 초급/중급 (roughly TOPIK 1-4), not
  the full 1-6 range.
- p.3: **"등급 기준은 국립국어원 〈한국어기초사전〉과 국립국어원 〈국제 통용
  한국어 표준 교육과정〉에서 제시한 등급을 따랐다"** — the grading standard is
  explicitly **the same NIKL "국제 통용 한국어 표준 교육과정" (2017)** source
  our own `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv` /
  `nikl_kiiq_2017_vocab.csv` are built from. Each headword is marked **초**
  (beginner) or **중** (intermediate) only (a coarse 2-way split, not 1-6).

This is a real, citable corroboration that our NIKL-grade-based level
assignment methodology (§C of the level bible) rests on the same underlying
government standard the Sejong Institute itself uses to grade this
dictionary — but it is a 2-way (초/중) check, not a 6-way one, and a full
headword-by-headword cross-check of all ~5,039 entries against
`korean_vocab.csv` was **out of scope for this session** (608 pages of
structured entry parsing beyond the time/cost budget available); this is
reported as a scope limitation, not attempted and silently assumed clean.

## Q-S2 update: main-series books' own stated level (OCR, 2026-09-16)

Q-S (above) could only check the *substitute* 회화 series' self-labels
(초급/중급) because the main-series 교재 were 0% text. Q-S2 OCR'd the actual
main-series 교재 (`tool/sejong/ocr_sejong_pages.py`, Windows.Media.Ocr,
2,017/2,017 target pages, 0 failures) and can now cite the main series'
*own* front matter directly:

- `세종학당 한국어 3A(영어)_(low file size).pdf` p.1: colophon reads
  **"INTERMEDIATE"** / **"중급 1 (1~10과)"** ("Intermediate 1, units 1-10")
  — i.e. 3A is 중급1 (intermediate, first half).
- `세종학당 한국어 3B(영어)_(low file size).pdf` p.1: **"중급 1 (11~20과)"**
  — 3B is 중급1, units 11-20 (the second half of the same 중급1 course).
- `세종학당 한국어4A_영어.pdf` p.1: **"중급 2(1~10과)"** — 4A is 중급2
  (intermediate, second course), units 1-10.
- `세종학당 한국어 4B(영어)_(low file size).pdf` p.1: **"중급 2(11~20과)"**
  — 4B is 중급2, units 11-20.
- `세종학당 한국어 1 익힘책_한국어.pdf` p.4: **"초급 1 익힘책"** ("Beginner 1
  workbook") — confirms level-1 content is 초급1, matching A1. (p.1's OCR
  misreads this as "조급" -- a single-consonant ㅊ/ㅈ misread, not a
  substantive content difference; p.4 repeats the same colophon line
  cleanly, cited here instead per the "never fabricate a fix" rule.)
- `세종학당 한국어 2 익힘책_영어.pdf` p.1: **"초급 2 익힘책"** — 초급2,
  matching A2.
- `세종학당 한국어 입문(영어)_(low file size).pdf` p.6: front matter states
  it is **"for a beginner who wants to learn Korean"** but, unlike every
  other book in the series, does NOT print an explicit 초급/중급/N급 grade
  anywhere OCR'd in its front matter (pp.1-11) — consistent with 입문
  ("introduction") sitting *below* the graded 1-6 (초급1 - 고급2) scale
  rather than being NIKL-grade 0. Treated as below-A1 / ungraded, not
  silently assigned A1.

This independently confirms, from the real main-series books rather than
the substitute, the same 1↔A1(초급1)/2↔A2(초급2)/3↔B1(중급1)/4↔B2(중급2)
mapping Q-S already validated against the 회화 series and
`CONTENT_LEVEL_BIBLE.md` §A — two independent Sejong-published series now
agree on this mapping.

Caveat: no standalone 교재 file for levels 1 or 2 exists anywhere in the
folder (`docs/data/sejong/inventory_2026-09-16.md`, confirmed again by a
fresh directory listing 2026-09-16) — only their 익힘책. The "초급 1/2
익힘책" labels above describe the workbook actually on disk, which
Q-S2 uses as the best-available main-series substitute for those two
levels (see `tool/sejong/build_sejong_syllabus_ocr.py`).
