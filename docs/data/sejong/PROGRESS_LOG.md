# Q-S progress log (resume aid, not part of the final report)

Worktree: `/c/dev/hangulsori/ko_lernen_app_worktrees/qs-sejong-syllabus-audit-20260916`
Branch: `claude/qs-sejong-syllabus-audit-20260916`
PR: https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/pull/354
Head SHA: 49b7b7926090f7918055e799c6cb86e77ca897b3

## Status: ALL 4 PHASES COMPLETE, PR OPEN (not merged)

- [x] Setup: worktree from origin/main (5f7a790c), pymupdf installed into
      the shared venv
- [x] Phase 1: `tool/sejong/extract_sejong_text.py` -> inventory (39 PDFs
      found on disk, folder grew 26->39 mid-session; 31.2% pages
      extractable overall, very uneven -- see inventory_2026-09-16.md)
- [x] Phase 2: `tool/sejong/build_sejong_syllabus.py` -> syllabus_sejong{1-6}.json
      (grammar+vocab for levels 1-4 via the 세종한국어 회화 익힘책 series;
      grammar-only for 5-6 via 세종학당 한국어 익힘책; 입문 NOT_EXTRACTABLE)
- [x] Phase 3: `tool/sejong/compare_sejong_vs_app.py` -> comparison_2026-09-16.{md,json}
      (3-way grammar table, vocab coverage, sentence benchmark, bible + F4 audits)
- [x] Phase 4: `docs/data/sejong/REPORT_2026-09-16.md` (15 cited findings,
      prioritized fix list), citations verified 943/943, committed, pushed,
      PR #354 opened (not merged)

## If resuming further work

- Full 5,039-word vocab-dictionary cross-check (§ Prioritized fix list
  item 6) is the highest-value next extraction task -- not attempted this
  session (608 pages of structured entry parsing was out of budget).
- F4-style hand tables for levels 2-4 could reuse syllabus_sejong{2,3,4}.json
  directly (fix list item 4).
- Do not attempt OCR on the 0%-text 세종학당 한국어 3A/3B/4A/4B files without
  explicit approval -- out of this audit's stated scope.

## Q-S2 (2026-09-16, follow-up): OCR of the main-series 교재, redo A1-B2

Worktree: `/c/dev/hangulsori/ko_lernen_app_worktrees/qs2-sejong-ocr-20260916`
Branch: `claude/qs2-sejong-ocr-20260916`, based on origin/main after #354
merged (7bbe761e).

- [x] Confirmed Windows.Media.Ocr (`ko` recognizer) available without DISM
      elevation; no cloud OCR, easyocr/rapidocr not needed.
- [x] `tool/sejong/ocr_sejong_pages.py` + `ocr_batch.ps1`: rendered (PyMuPDF,
      200dpi) + OCR'd all 7 target books, 2,017/2,017 pages, 0 failures,
      ~20 chunked <=100-page invocations, resumable per-book progress.json
      in the scratchpad (`sejong_ocr/<book_key>/progress.json`).
- [x] Confirmed levels 1/2 have NO standalone 교재 file in the folder (only
      익힘책) -- used as best-available substitute, labeled as such.
- [x] `tool/sejong/build_sejong_syllabus_ocr.py` -> syllabus_sejong{1,2,3,4}_ocr.json
      (vocab all 4 levels; grammar B1/B2 only, A1/A2 workbook house-style has
      no inline pattern label). 2 OCR-noise-correction rules visually
      confirmed via bbox crops before being applied; a 3rd candidate rule
      was tested and rejected after a counter-example.
- [x] `tool/sejong/compare_sejong_vs_app_ocr.py` -> comparison_2026-09-16_ocr.{md,json}
      (B1/B2 grammar now comparable for the first time: 14.8%/12.3% matched).
- [x] Extended `tool/verify_sejong_citations.py` with a fuzzy (Levenshtein
      similarity >=0.9) `"tag":"ocr"` path against the OCR text files;
      citations verified 1299/1299 (exact 943/943, ocr 356/356).
- [x] 20 bbox-cropped PNGs saved to the scratchpad (`sejong_ocr/crops/`,
      not committed) for the most consequential findings.
- [x] `sejong_level_map.md` updated with the main series' own front-matter
      level self-labels (초급1/초급2/중급1/중급2), independently confirming
      the mapping Q-S already validated via the 회화 series.
- [x] `REPORT_2026-09-16_ocr.md` written: 10 cited findings, bible §B.1-B.4
      confirm/contradict, 40/level real sentence benchmark (corrects Q-S
      finding #14 -- ours are LONGER not shorter once real dialogues are
      used), prioritized fixes.

### If resuming further work

- A1/A2 grammar extraction from the workbook substitute was not attempted
  (different house style, no inline label) -- would need matching against
  unit-title example sentences instead, a fuzzier method not attempted here.
- 익힘책/연습문제 OCR for levels 3-4 (beyond the 교재 already done) and the
  두 실용 어휘·문법 핸드북 (levels 3/4) were not OCR'd this session -- next
  candidates if further budget is approved.
- The single-character grammar-label fragments noted in the report ("고",
  "하") are residual parsing noise, not yet root-caused.
