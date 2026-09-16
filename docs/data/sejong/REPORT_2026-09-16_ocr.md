# Q-S2 — OCR of the scanned Sejong main-series textbooks + redone A1–B2 syllabus comparison

2026-09-16. Follow-up to Q-S (`REPORT_2026-09-16.md`, PR #354), which found
the main-course `세종학당 한국어` 교재/익힘책/연습문제 (입문, 1, 2, 3A, 3B,
4A, 4B) were scanned images with 0% PyMuPDF text layer, and had to substitute
the separate `세종한국어 회화 익힘책` series for A1–B2 conclusions. This
session OCR's the actual main-series books and rebuilds A1–B2 grammar/vocab
data from them for the first time.

Tools: `tool/sejong/ocr_sejong_pages.py` (render + OCR driver, resumable),
`tool/sejong/ocr_batch.ps1` (Windows OCR worker), `tool/sejong/build_sejong_syllabus_ocr.py`
(syllabus extraction), `tool/sejong/compare_sejong_vs_app_ocr.py` (comparison),
`tool/verify_sejong_citations.py` (extended with a fuzzy `"tag":"ocr"` path).
Raw renders/OCR text stay OUTSIDE the repo (copyright) in the session
scratchpad; only structured facts, citations and PNG **crop paths** (not the
images themselves) are referenced here.

## Engine

**Windows.Media.Ocr** (WinRT, `ko` recognizer), the first-choice engine per
the brief. `Get-WindowsCapability` (the brief's suggested check) requires
admin elevation and could not run, but the recognizer itself is already
installed and loadable: `OcrEngine.AvailableRecognizerLanguages` returned
`de-DE, ko` and `OcrEngine.TryCreateFromLanguage("ko")` succeeded directly.
No cloud OCR was used; `easyocr`/`rapidocr_onnxruntime` were not installed
and were never needed. Pages rendered with PyMuPDF at 200dpi.

Windows.Media.Ocr does **not** expose per-word/line confidence anywhere in
its public API (confirmed by .NET reflection on `OcrWord`/`OcrLine`/
`OcrResult` on this machine: only `Text`/`BoundingRect`). Per-page
**`ocr_quality_proxy`** below is a documented substitute, not a native
confidence score: the fraction of non-whitespace recognized characters that
are Hangul/Latin/digit/common-punctuation versus encoding-garbage. It
correlates with gross corruption (blank/near-blank pages), not with
word-level correctness — see the "OCR noise" discussion below for cases it
does NOT catch.

## Pages OCR'd

**2,017/2,017 target pages, 0 failures.** All 7 requested main-series 교재
were completed (no B2-pending triage needed — total wall time for OCR was
well under the 4h budget, run in ~20 chunked invocations of ≤100 pages each
per the resumable-progress-file design).

| Book (role) | File | Pages | OCR quality proxy (mean) | Pages <0.6 |
|---|---|---|---|---|
| 입문 (main textbook) | 세종학당 한국어 입문(영어)_(low file size).pdf | 261/261 | 0.962 | 1 (0.4%) |
| A1 substitute (workbook — **no standalone 교재 exists**) | 세종학당 한국어 1 익힘책_한국어.pdf | 392/392 | 0.989 | 1 (0.3%) |
| A2 substitute (workbook — **no standalone 교재 exists**) | 세종학당 한국어 2 익힘책_영어.pdf | 404/404 | 0.988 | 1 (0.2%) |
| B1 (main textbook) | 세종학당 한국어 3A(영어)_(low file size).pdf | 240/240 | 0.986 | 0 (0.0%) |
| B1 (main textbook) | 세종학당 한국어 3B(영어)_(low file size).pdf | 240/240 | 0.983 | 1 (0.4%) |
| B2 (main textbook) | 세종학당 한국어4A_영어.pdf | 240/240 | 0.988 | 0 (0.0%) |
| B2 (main textbook) | 세종학당 한국어 4B(영어)_(low file size).pdf | 240/240 | 0.983 | 1 (0.4%) |

The 5 pages below 0.6 are all `chars=0` (blank pages: section dividers or a
back-cover page), not misrecognitions — excluded from every conclusion, not
silently included.

**Discrepancy vs the Q-S2 brief's assumed 7-book scope**: standalone 교재
files for levels **1 and 2 do not exist anywhere in the folder** — only
their 익힘책. This was already noted in Q-S's Phase-1 inventory and is
re-confirmed by a fresh directory listing today. The 익힘책 above are used
as the best-available main-series substitute for A1/A2, clearly labeled as
such everywhere downstream (never silently presented as the missing 교재).

**Extractable share, updated**: 1,967 (PyMuPDF text layer, Q-S) + 2,017
(OCR, Q-S2) = **3,984/6,311 pages = 63.1%** extractable overall (up from
31.2%), by two different methods — reported as such, not merged into one
undifferentiated number.

## Headline per-level numbers (real main series, first time available for B1/B2)

**Grammar** (B1/B2 only — A1/A2's workbook substitute uses unlabeled
"문법 연습 #N" practice, no inline pattern string to extract; see
`build_sejong_syllabus_ocr.py`):

| Level | Sejong (OCR, normalized) | OCR-noise excluded | Ours at level | Matched | Missing from ours | Misleveled (ours-here-Sejong-elsewhere) |
|---|---|---|---|---|---|---|
| B1 | 54 | 2 | 35 | 8 (14.8%) | 46 | 3 |
| B2 | 57 | 2 | 56 | 7 (12.3%) | 50 | 2 |

Previously (Q-S, substitute series): B1/B2 grammar comparison was
**impossible** (0% extractable). This is a first, not a revision.

**Vocabulary** (A1–B2, all four extracted from the "어휘" answer-key
numbered word lists):

| Level | Sejong unique words (OCR) | Coverage % at level | Found at another of our levels | Absent from ours entirely |
|---|---|---|---|---|
| A1 | 48 | 20.8% | 11 | 27 |
| A2 | 52 | 23.1% | 8 | 32 |
| B1 | 65 | 9.2% | 6 | 53 |
| B2 | 68 | 1.5% | 10 | 57 |

**NIKL cross-check (bonus 3rd axis)**: of our 24 (B1) / 47 (B2) grammar
patterns not found in Sejong's OCR'd content at any level, most have no NIKL
grade tag (out of scope of the 337-row NIKL grammar table), but 1 B1 item
and 6 B2 items do: `V-거든요` = NIKL grade 3 (B1, consistent), but 5 of the
6 B2-tagged items are NIKL **grade 5 (C1)** — `N에도 불구하고`,
`V-기 마련이다`, `N에 관하여`, `V-기 나름이다`, `V-다가는` — flagged as a
possible over-early placement, independently of the Sejong comparison.

## Sentence benchmark (40/level, real dialogue, not padded)

Extracted from the books' own "듣기대본"/"듣기 지문" (listening-script)
answer-key sections — full, un-blanked dialogue turns, deduplicated, capped
at 40/level; all 4 levels reached 40/40 (unlike Q-S's substitute-series
attempt, which got a reduced sample).

| Level | Sejong mean sentence length (chars) | Ours mean example-sentence length (chars) |
|---|---|---|
| A1 | 10.1 | 12.5 |
| A2 | 15.4 | 16.0 |
| B1 | 16.0 | 19.5 |
| B2 | 18.4 | 23.7 |

**This corrects Q-S finding #14** ("our example sentences run noticeably
shorter than Sejong's... at every level") — that used the *substitute*
회화 series. Against the *real* main series, **ours are longer at every
level**, not shorter. Full sentence lists: `docs/data/sejong/comparison_2026-09-16_ocr.json`
is grammar/vocab only; the sentence sample lives in the session scratchpad
(`_sentence_benchmark.json`) per the copyright rule (raw book sentences are
not committed verbatim beyond the short cited excerpts above).

## Level bible §B.1–B.4 (confirmed / contradicted)

- **CONFIRMED, §B.3⑥** ("간접화법(-다고 하다류) 도입" at B1): the
  indirect-quotation ending family `-는다고2, -나고, -으라고, -자고` is
  genuinely taught in Sejong's real B1 main-series text (3B p.231) —
  confirming the bible's claim. **But it is entirely absent from
  `grammar.csv` at B1** (or any level) — the principle is right, the content
  is missing. Actionable gap, not a bible error.
- **PARTIALLY CONFIRMED, §B.3⑤/§B.4⑤** (B1 ≤16-word / B2 ≤22-word sentence
  caps, condition/concession/reason clauses at B2): Sejong's real B2 grammar
  set is rich in exactly this family (`-을수록`, `-거니와`, `-는 통에`,
  `-다니`, `-어서인지`) — the *category* claim holds. Word-count itself
  wasn't independently measured (only character length, see benchmark
  above) — reported as directionally consistent, not verified word-for-word.
- **NOT INDEPENDENTLY CONFIRMABLE, §B.4⑥** (`-아/어 주시겠어요`, `-을 수
  있을까요` named as B2 request/negotiation forms): neither string appears
  as its own "문법(...)" answer-key entry in 4A/4B — plausible because both
  are compositions of morphemes taught earlier (-겠-, -을 수 있다, -아/어
  주다) rather than a book-internal "new pattern," so the answer-key format
  wouldn't list them separately. Reported as unverifiable by this method,
  not as a contradiction.
- No direct contradiction of a §B.1–B.4 *principle* was found this session
  (Q-S's one confirmed contradiction, honorific vocab at A1 vs B2 in
  `korean_vocab.csv`, stands from the original report and is not re-litigated
  here).

## 10 findings (cited; crop paths in the session scratchpad, `sejong_ocr/crops/`, filenames below — not committed, per copyright)

1. **B1 main-series (3A+3B) is extractable for the first time**: 0% (Q-S)
   → 240/240 + 240/240 pages OCR'd, mean quality 0.986/0.983.
2. **B2 main-series (4A+4B) is extractable for the first time**: 0% (Q-S)
   → 240/240 + 240/240 pages OCR'd, mean quality 0.988/0.983.
3. **No standalone 교재 exists for levels 1 or 2** anywhere in the folder —
   confirmed by a fresh listing today, not just inherited from Q-S; crops
   `16_levelmap_b1wb_chogeup1.png`, `17_levelmap_b2wb_chogeup2.png` show the
   workbook substitutes' own "초급 1/2 익힘책" colophon instead.
4. **Front matter, two independent Sejong series now agree**: 3A/3B
   self-label "INTERMEDIATE"/"중급 1" (crop `13_levelmap_b3a_intermediate.png`,
   `14_levelmap_b3a_junggeup1.png`), 4A/4B "중급 2" (crop
   `15_levelmap_b4a_junggeup2.png`) — matches `CONTENT_LEVEL_BIBLE.md` §A
   and Q-S's 회화-series finding.
5. **Indirect-speech family `-는다고/-냐고/-으라고/-자고` (3B p.231) is
   B1-taught by Sejong, absent from `grammar.csv` at any level** — confirms
   bible §B.3⑥, flags a real content gap.
6. **The book distinguishes two senses of `-거든` by its own numbering**:
   `-거든1` at B1 (3A p.237, crop `03_b1grammar_geodeun1.png`) and `-거든2`
   at B1 (3B p.227, crop `04_b1grammar_geodeun2.png`) — neither in
   `grammar.csv` at any level.
7. **Misleveled (ours B1, Sejong B2)**: `V-(으)ㄴ/는지` (4A p.228, crop
   `06_b1_mislevel_-neunji_sejongB2.png`), `V-는 대로` (4A p.235, crop
   `07_b1_mislevel_-neundaero_sejongB2.png`), `V-는 바람에` (4A p.237, crop
   `08_b1_mislevel_-neunbarame_sejongB2.png`).
8. **Misleveled the other direction (ours B2, Sejong B1)**: `V-는 반면에`
   (3B p.235, crop `09_b2_mislevel_banmyeon_sejongB1.png`), `V-도록 하다`
   (3B p.228, crop `10_b2_mislevel_dorok_sejongB1.png`).
9. **Grammar match rate is low even against the real main series**: B1
   8/54 (14.8%), B2 7/57 (12.3%) — most Sejong-taught B1/B2 grammar is
   simply missing from our content at that level, not just misleveled.
10. **Sentence-length finding reversed vs Q-S's substitute-based result**:
    with the real main-series dialogues, our example sentences are LONGER
    at every level (A1 12.5 vs 10.1 chars; B2 23.7 vs 18.4 chars), not
    shorter as Q-S reported using the 회화 substitute.

## OCR-noise methodology (so findings above aren't taken as pixel-perfect)

Two character-level OCR misreads were confirmed real by cropping the
source-page bbox and visually inspecting it, then applied as blanket fixes
(crops `18_ocr_verify_seun_to_neun.png`, `19_ocr_verify_0F_to_ya.png`): a
leading "슨" → "-는" (dash-drop + ㄴ/ㅅ confusion) and "0F" → "야". A third
candidate rule ("떠" → "-어") was tested and **rejected**: it held for one
sample (3A p.229 "떠도"→"-어도") but was falsified by a second (4A p.231
"떠니" is genuinely "-더니", crop `20_ocr_verify_tteo_ambiguous.png`) — "떠"
is ambiguous between two source consonants and is left un-normalized (2
B1 + 2 B2 grammar labels excluded from comparison on this basis, not
guessed). A handful of single-character grammar-label fragments (e.g. "고",
"하" in the B2 list) are suspected further OCR/parsing residue below the
threshold this session's validity filter catches — flagged here rather than
silently trusted.

## Prioritized fixes

1. Add the B1 indirect-quotation family (`-는다고/-냐고/-으라고/-자고`) and
   the `-거든1`/`-거든2` distinction — real, cited B1 gaps (findings 5–6).
2. Re-examine the 5 cross-leveled grammar patterns (findings 7–8): 3 look
   B2-not-B1 by Sejong's own sequencing, 2 look B1-not-B2.
3. Investigate the 5 NIKL-grade-5-tagged B2 patterns (에도 불구하고, 기
   마련이다, 에 관하여, 기 나름이다, 다가는) for possible C1 placement.
4. Given only 8–15% grammar match even against the real main series, treat
   the B1/B2 grammar gap as the single biggest actionable item from this
   audit — full missing-list in `comparison_2026-09-16_ocr.md`.
5. Do NOT re-litigate the sentence-length finding using the substitute
   series — this session's real-dialogue numbers supersede it (finding 10).

## Verifier

citations verified 1299/1299 (exact 943/943, ocr 356/356)
