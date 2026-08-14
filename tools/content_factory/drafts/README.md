# B1/B2 review-only content drafts

This directory contains schema-complete **review-only** B1/B2 batches. None is
an app asset, and no file here may be copied into `assets/data/` by hand.

Before editing any record, read the complete
[`CONTENT_AUTHORING_GUIDE.md`](../../../docs/CONTENT_AUTHORING_GUIDE.md). In
particular, Batch 01 has a fixed 96-record/ID/order contract: enrich an
existing record in place, but create a later batch for any additional record.

Every current batch totals 96 records:

| Kind | B1 | B2 | Total |
| --- | ---: | ---: | ---: |
| Vocabulary | 12 | 12 | 24 |
| Grammar | 4 | 4 | 8 |
| Small talk | 8 | 8 | 16 |
| Cloze | 12 | 12 | 24 |
| Satzbau | 12 | 12 | 24 |

| Batch | B1 scope | B2 scope | Pack order reservation |
| --- | --- | --- | --- |
| 01 | housing, tenancy, moving, practical contracts | formal agreements, obligations, precise requests | B1 #19, B2 #18 |
| 02 | workplace coordination and schedule changes | formal complaints, remedies, escalation | B1 #20, B2 #19; reserves Batch 01 |

Batch 01's source of scope is `docs/CONTENT_PRODUCTION_TRACK_2026-08-14.md`:

- B1: housing, tenancy, moving, and practical contract communication.
- B2: formal agreements, obligations, precise requests, and negotiated terms.
- Small talk: the previously empty B1/B2 `transport`, `shopping`, `phone`,
  and `emergency` categories.
- Cloze and Satzbau: one candidate derived from every new vocabulary example.

Each `batch_XX_manifest.json` is the machine-readable handoff. It names every
draft/review pair and declares the curriculum, pack, motif, category, and
topic companions required for a later approved merge. Those companion mappings
are intentionally not applied to the live curriculum in a review-only batch.

Validate Batch 01 with its immutable contract. Validate every later batch with
the generic manifest-driven overlay.

```bash
python3 tools/content_factory/validate_batch_01.py
python3 tools/content_factory/validate_review_batch.py \
  --manifest tools/content_factory/drafts/batch_02_manifest.json
```

## Review and merge boundary

All linked sheets in `../review/` use the exact common header and every row is
currently `draft`. Jin changes only the review status to `ok` or `approved`
after checking the full schema-complete record in this directory. Before
review, render the complete packet rather than treating the compact CSV as a
second content source.

```bash
python3 tools/content_factory/render_review_packet.py \
  --manifest tools/content_factory/drafts/batch_02_manifest.json \
  --output tools/content_factory/review/batch_02_review_packet.md
```

Before any approved append, a content integrator must make the companion
curriculum mappings from the manifest available in the same reviewed change.
That is necessary because the C0 validator correctly rejects a new pack,
grammar rule, small-talk category, or cloze topic that has no curriculum route.
Use `apply_review.py` preview first; do not bypass the manifest/validator
transaction and do not run TTS while this batch is still review-only.
