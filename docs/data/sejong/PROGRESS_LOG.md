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
