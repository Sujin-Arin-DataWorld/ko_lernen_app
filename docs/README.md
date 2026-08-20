# Documentation guide

This directory keeps only documents that are active operational references.
Completed plans, dated audits, and one-session handoffs are preserved in Git
history rather than copied into the working tree.

## Read in this order

1. [AGENTS.md](../AGENTS.md) — repository rules, architecture map, and active
   gates.
2. [`.claude/handoffs/`](../.claude/handoffs/) — latest session handoff (read
   one file). [SESSION_LOG.md](SESSION_LOG.md) is historical search only;
   do not append on every change.
3. The SSoT for the task at hand:
   - UI/UX: [HANDOFF_UI_OVERHAUL_2_2026-08-14.md](HANDOFF_UI_OVERHAUL_2_2026-08-14.md)
     for Today/home/catalog chrome. **Content players** (listen, write, decks,
     cloze, satz, smalltalk, scenario) use
     [CONTENT_UI_BIBLE.md](CONTENT_UI_BIBLE.md) — that file supersedes the
     4-way Tinder deck in Overhaul 2 §1-1·§1-2.
   - Content: [CONTENT_AUTHORING_GUIDE.md](CONTENT_AUTHORING_GUIDE.md),
     [CONTENT_ARCHITECTURE.md](CONTENT_ARCHITECTURE.md), and
     [CONTENT_SOURCE_POLICY.md](CONTENT_SOURCE_POLICY.md)
   - PDF, OCR, table intake: [CONTENT_REFERENCE_INTAKE_GUIDE.md](CONTENT_REFERENCE_INTAKE_GUIDE.md)
   - Visual assets: [ASSET_GENERATION_BIBLE.md](ASSET_GENERATION_BIBLE.md)
   - Hanok product/runtime, in this order:
     1. [Level proof and skip recovery](superpowers/specs/2026-08-20-hanok-level-proof-and-skip-recovery-design.md)
        — approved target product and V2 direction.
     2. [Living Hanok V1 execution](plans/2026-08-16-living-hanok-v1-execution.md)
        — productive-evidence authority and the 86-core contract.
     3. [Canonical personal-Hanok assets](PERSONAL_HANOK_CANONICAL_ASSET_CONTRACT.md)
        — current legacy 4:3 runtime only, not the V2 masterplan.
     4. **⛔ 정정(2026-08-18)**: for hanok/decoration style facts specifically,
        current facts and rights follow [STYLE_LOCK](assets/STYLE_LOCK.json) >
        [asset inventory](HANOK_ASSET_INVENTORY_2026-08-17.md), plus the
        [source registry](HANOK_V1_SOURCE_REGISTRY.md) and
        [machine-readable provenance](assets/HANOK_V1_ASSET_PROVENANCE.json).
        Regenerate inventory tables with `python3.12 tool/asset_inventory.py`.
        `tool/style_lock.py` is the style reader and
        `tool/check_style_lock_docs.py` enforces the priority banner.
   - Release: [RELEASE_RUNBOOK_2026-08-02.md](RELEASE_RUNBOOK_2026-08-02.md)

## Maintenance rule

Do not add a new dated plan, audit, or handoff to the document root when its
facts belong in an existing SSoT or the session log. Keep only reusable
operational references here. Use `git log --all -- docs/<path>` when a
completed document must be recovered.
