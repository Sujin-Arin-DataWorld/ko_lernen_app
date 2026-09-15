# Q-S progress log (resume aid, not part of the final report)

Worktree: `/c/dev/hangulsori/ko_lernen_app_worktrees/qs-sejong-syllabus-audit-20260916`
Branch: `claude/qs-sejong-syllabus-audit-20260916`
Python: `/c/dev/hangulsori/ko_lernen_app/.venv/Scripts/python.exe` (pymupdf installed there, not in requirements files)
Scratchpad (raw text, outside repo): `C:\Users\vjinn\AppData\Local\Temp\claude\C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\9ba4cf1a-a043-4558-928b-92a864ff3701\scratchpad\sejong_text\`

## Setup
- [x] worktree created from origin/main (5f7a790c)
- [x] pymupdf installed into shared venv

## Phase 1 — inventory
- [x] `tool/sejong/extract_sejong_text.py` written
- [ ] run across all PDFs in the Sejong folder, produced
      `docs/data/sejong/inventory_2026-09-16.{md,json}`
- Found 26 PDFs on disk (brief assumed 24) — two extra 핸드북(실용 한국어
  어휘와 문법) vol.2/vol.3 files, and no separate full 교재 for 입문/1/2/3A/3B
  (only 익힘책/연습문제/저용량 교재 variants). Inventory documents what's
  actually there.

## Phase 2 — syllabus extraction
- [ ] not started until Phase 1 output is inspected

## Phase 3 — comparison
- [ ] not started

## Phase 4 — report + verifier + commit/push/PR
- [ ] not started

## Key repo reference files already inspected
- `assets/data/grammar.csv` (253 rows incl header) — cols: pattern, level, ...
- `assets/data/korean_vocab.csv` (2563 rows incl header) — cols: korean, ...,
  level, ..., id
- `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv` (337 rows incl
  header) — cols: grade, category, form, variants, meaning, band_2stage,
  band_1to4
- `docs/CONTENT_LEVEL_BIBLE.md` — §B.1-B.6 per-level profiles (can-do, topics,
  grammar table for A1/A2 inline, vocab counts, sentence rules, register,
  forbidden examples)
- `docs/data/level_bible/F4_sejong1_units.md` — existing hand-written 14-unit
  table, but sourced from **"세종한국어 회화 익힘책 한국어판 1-1/1-2"**
  (a *conversation* workbook, two volumes) -- NOT the same title as the file
  on disk today (`세종학당 한국어 1 익힘책_한국어.pdf`, one 143MB volume,
  no "회화" in the name). MUST verify during Phase 3.4 whether this is the
  same underlying book (re-edition) or a genuinely different book; if
  different, F4 cannot be validated against our current PDF and that is
  itself a top finding.

## Interruption protocol
If runtime nears 2.5h: commit + push whatever is citation-verified so far,
update this log with exactly what's done/missing, and say so in the final
report to Fable.
