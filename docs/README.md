# Documentation guide

This directory keeps only documents that are active operational references.
Completed plans, dated audits, and one-session handoffs are preserved in Git
history rather than copied into the working tree.

## Read in this order

1. [AGENTS.md](../AGENTS.md) — repository rules, architecture map, and active
   gates.
2. [SESSION_LOG.md](SESSION_LOG.md) — append-only change and verification
   history; newest entry is first.
3. The SSoT for the task at hand:
   - UI/UX: [HANDOFF_UI_OVERHAUL_2_2026-08-14.md](HANDOFF_UI_OVERHAUL_2_2026-08-14.md)
   - Content: [CONTENT_AUTHORING_GUIDE.md](CONTENT_AUTHORING_GUIDE.md),
     [CONTENT_ARCHITECTURE.md](CONTENT_ARCHITECTURE.md), and
     [CONTENT_SOURCE_POLICY.md](CONTENT_SOURCE_POLICY.md)
   - PDF, OCR, table intake: [CONTENT_REFERENCE_INTAKE_GUIDE.md](CONTENT_REFERENCE_INTAKE_GUIDE.md)
   - Visual assets: [ASSET_GENERATION_BIBLE.md](ASSET_GENERATION_BIBLE.md)
   - Hanok/decoration asset inventory (what exists, where it is used, what is
     still missing): [HANOK_ASSET_INVENTORY_2026-08-17.md](HANOK_ASSET_INVENTORY_2026-08-17.md)
     — regenerate its tables with `python3.12 tool/asset_inventory.py`
   - **⛔ 정정(2026-08-18)**: for hanok/decoration style facts specifically
     (palette, camera, gates, prompt skeletons, model routing), read
     [assets/STYLE_LOCK.json](assets/STYLE_LOCK.json) first — it outranks
     both the inventory above and the Bible (`tool/style_lock.py` is the
     reader; `tool/check_style_lock_docs.py` enforces this banner exists).
   - Release: [RELEASE_RUNBOOK_2026-08-02.md](RELEASE_RUNBOOK_2026-08-02.md)

## Maintenance rule

Do not add a new dated plan, audit, or handoff to the document root when its
facts belong in an existing SSoT or the session log. Keep only reusable
operational references here. Use `git log --all -- docs/<path>` when a
completed document must be recovered.
