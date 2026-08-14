# Batch 01 — B1/B2 Review-only Content Draft

This directory contains the first **review-only** B1/B2 content batch. It is
not an app asset and must not be copied into `assets/data/` by hand.

Before editing any record, read the complete
[`CONTENT_AUTHORING_GUIDE.md`](../../../docs/CONTENT_AUTHORING_GUIDE.md). In
particular, Batch 01 has a fixed 96-record/ID/order contract: enrich an
existing record in place, but create Batch 02 for any additional record.

The batch totals 96 records:

| Kind | B1 | B2 | Total |
| --- | ---: | ---: | ---: |
| Vocabulary | 12 | 12 | 24 |
| Grammar | 4 | 4 | 8 |
| Small talk | 8 | 8 | 16 |
| Cloze | 12 | 12 | 24 |
| Satzbau | 12 | 12 | 24 |

Its source of scope is `docs/CONTENT_PRODUCTION_TRACK_2026-08-14.md`:

- B1: housing, tenancy, moving, and practical contract communication.
- B2: formal agreements, obligations, precise requests, and negotiated terms.
- Small talk: the previously empty B1/B2 `transport`, `shopping`, `phone`,
  and `emergency` categories.
- Cloze and Satzbau: one candidate derived from every new vocabulary example.

`batch_01_manifest.json` is the machine-readable handoff. It names every
draft/review pair and declares the curriculum, pack, motif, category, and
topic companions required for a later approved merge. Those companion
mappings are intentionally not applied to the live curriculum in this batch.

## Review and merge boundary

All linked sheets in `../review/` use the exact common header and every row is
currently `draft`. Jin changes only the review status to `ok` or `approved`
after checking the full schema-complete record in this directory.

Before any approved append, a content integrator must make the companion
curriculum mappings from the manifest available in the same reviewed change.
That is necessary because the C0 validator correctly rejects a new pack,
grammar rule, small-talk category, or cloze topic that has no curriculum route.
Use `apply_review.py` preview first; do not bypass the manifest/validator
transaction and do not run TTS while this batch is still review-only.
