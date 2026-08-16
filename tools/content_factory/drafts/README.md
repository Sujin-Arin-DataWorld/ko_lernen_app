# A1-C2 content batch drafts

This directory preserves the schema-complete source for A1-C2 batches. C0 Batch
01-03, scenario Batch 04, and B2/C1/C2 Batch 05 were promoted to app assets on 2026-08-15; their drafts and ledgers are
the immutable review history, not a second app-data source. No file here may
be copied into `assets/data/` by hand.

Before editing any record, read the complete
[`CONTENT_AUTHORING_GUIDE.md`](../../../docs/CONTENT_AUTHORING_GUIDE.md). In
particular, Batch 01 has a fixed 96-record/ID/order contract: enrich an
existing record in place, but create a later batch for any additional record.

Batch 01 and Batch 02 each total 96 records. A later batch declares its own
complete count in its manifest; it may cover one level only when that is the
review scope. Batch 06 is the current review-only pilot, so the next new batch
number is **07**.

| Kind | B1 | B2 | Total |
| --- | ---: | ---: | ---: |
| Vocabulary | 12 | 12 | 24 |
| Grammar | 4 | 4 | 8 |
| Small talk | 8 | 8 | 16 |
| Cloze | 12 | 12 | 24 |
| Satzbau | 12 | 12 | 24 |

Batch 03 is a B2-only depth loop: 36 vocabulary records, 6 grammar cards, 12
small-talk turns, and 36 each of Cloze and Satzbau, for 126 review records.

| Batch | B1 scope | B2 scope | Pack order reservation |
| --- | --- | --- | --- |
| 01 | housing, tenancy, moving, practical contracts | formal agreements, obligations, precise requests | B1 #19, B2 #21 |
| 02 | workplace coordination and schedule changes | formal complaints, remedies, escalation | B1 #20, B2 #22; reserves Batch 01 |
| 03 | none | decisions and perspectives; reading responses; language in society | B2 #23-25; reserves Batch 01/02 |
| 04 | eight real-life scenarios | eight real-life scenarios | scenario-only; curriculum assess links + existing backdrops |
| 05 | none | B2/C1/C2 depth expansion | live multi-asset batch |
| 06 | scenario 1 + smalltalk 2 + cloze 4 + satz 6 + pronunciation 4 | same B2 scope plus first C1/C2 bundles | review-only cross-game pilot; 68 records + 20 embedded quests |

Batch 01's source of scope is `docs/CONTENT_PRODUCTION_TRACK_2026-08-14.md`:

- B1: housing, tenancy, moving, and practical contract communication.
- B2: formal agreements, obligations, precise requests, and negotiated terms.
- Small talk: the previously empty B1/B2 `transport`, `shopping`, `phone`,
  and `emergency` categories.
- Cloze and Satzbau: one candidate derived from every new vocabulary example.

Each `batch_XX_manifest.json` is the machine-readable handoff. It names every
draft/review pair and declares the curriculum, pack, motif, category, and
topic companions required for an approved merge. Batch 01-05 mappings are
already live; review-only Batch 06 keeps its mappings in the manifest
until the single approved multi-file transaction promotes them.

Batch 01's draft-only validator is preserved as historical regression coverage.
Batch 06 is a scenario-centred cross-game bundle, so validate its reference graph, deterministic
review projection, and disposable full-content overlay together.

```bash
python3 tools/content_factory/validate_reference_intake.py
python3 tools/content_factory/sync_review_ledgers.py
python3 tools/content_factory/audit_game_loader_coverage.py
python3 tools/content_factory/audit_game_loader_coverage.py \
  --manifest tools/content_factory/drafts/batch_06_manifest.json
python3 tools/content_factory/integrate_scenario_batch.py \
  --manifest tools/content_factory/drafts/batch_06_manifest.json
```

## Review and merge boundary

All linked sheets in `../review/` use the exact common header. Batch 01-05
rows are `approved` because they are live. A new Batch 06 starts entirely as
`draft`; Jin changes only its review status to `ok` or `approved` after
checking the full schema-complete record in this directory. Before review,
render the complete packet rather than treating the compact CSV as a second
content source.

```bash
python3 tools/content_factory/render_review_packet.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json \
  --output tools/content_factory/review/batch_XX_review_packet.md
```

Before any approved promotion, a content integrator must make the companion
curriculum mappings from the manifest available in the same reviewed change.
That is necessary because the C0 validator correctly rejects a new pack,
grammar rule, small-talk category, or cloze topic that has no curriculum route.
Use `apply_review.py` preview first, then the multi-file
`integrate_review_batches.py --manifest ...` transaction; do not bypass the
manifest/validator transaction and do not run TTS while this batch is still
review-only.
