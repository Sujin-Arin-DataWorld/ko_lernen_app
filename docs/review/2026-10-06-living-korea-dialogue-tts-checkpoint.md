# Living Korea Dialogue + TTS Review Checkpoint

Date: 2026-10-06

## Why this checkpoint exists

This document records the current user-reviewed Korean dialogue direction,
relationship/register decisions, TTS display-vs-spoken policy, and the next
research phase before DE/EN localization and live promotion.

It is a **checkpoint**, not a live-release claim.

## Korean dialogue review state

The current Korean Living Korea program contains:
- 11 canonical personas
- 11 contemporary-Korea topics
- 10 arcs
- 23 scenes
- 138 Korean dialogue turns
- 11 source-backed culture cards

Two rounds of user review materially changed the dialogue quality standard:
1. relationship/register corrections and natural Korean phrasing
2. relationship-driven humor, banter, dry reactions, and removal of
   textbook-style exposition

The latest follow-up also corrected:
- Hyuna/Byeongcheol Gyeongju field-trip pairing -> Hyuna/Sujin old-friend
  field-note scene
- Byeongcheol/Sujin electrical-safety scene -> household electricity question
  with technically correct overload/breaker language
- electrical-safety scene B1 -> B2 so natural terms such as
  `과부하/차단기/콘센트` remain intact

The durable authoring contract is:
`tools/content_factory/canonical_scenarios/dialogue_authoring_contract_20261006.json`

## Relationship/register canon locked by review

### Sujin ↔ Christian
- first meeting / early relationship: polite haeyo
- current one-year dating timeline: mutual banmal

### Andrea ↔ Minho
- private married-life/home scenes: mutual banmal
- workplace/formal register applies to actual work relationships, not to each
  other at home

## Dialogue quality rule learned from review

Future persona dialogue must be written in this order:

1. relationship / chronology / register
2. real-life task or friction
3. character-specific human beat
4. natural Korean dialogue
5. only then vocab / grammar / pragmatics / register mining
6. CEFR/LCP audit
7. if the Korean copy changes after human review, discard stale mining and
   re-mine/re-audit

A human beat is not a mandatory joke. It may be:
- teasing
- dry humor
- warm reaction
- affection
- a small complaint
- surprise
- self-deprecation
- a character-specific callback
- gentle disagreement

Safety/fraud/health/legal/electrical scenes keep relationship texture but do
not joke about the danger itself.

## TTS: display text and spoken text are different surfaces

This checkpoint adds an explicit rule that was missing from the earlier
dialogue review:

> **Never synthesize `ㅋㅋ/ㅎㅎ` literally.**

A learner-facing dialogue may contain display-only paralinguistic markers such
as:
- `ㅋㅋ`
- `ㅎㅎ`
- repeated punctuation
- emoji

These markers can carry warmth, teasing, embarrassment, or non-seriousness on
screen. They are **not automatically lexical TTS content**.

### Default spoken-surface rule

If the humor or warmth already exists in the wording:
- display: `그건 올려야겠네 ㅋㅋ.`
- spoken surface: `그건 올려야겠네.`

Do **not** generate:
- `크크`
- `흐흐`
- automatic `하하`
- automatic `호호`

### Audible laughter exception

If actual laughter is important to the scene, author it deliberately as a
performance event or spoken-stage direction. It must be an intentional
performance choice, not a mechanical conversion of chat text.

### Ownership

TTS remains Jin-owned.
The content pipeline must not synthesize or overwrite TTS.

Before future TTS generation, any line containing display-only markers must
have a reviewed spoken-surface equivalent.

Canonical rule:
`dialogue_authoring_contract_20261006.json -> ttsSurfacePolicy`

## Current quality gates

Current Living Korea dialogue and authoring infrastructure are protected by:
- relationship/persona tests
- scene-first tests
- language-mining attestation tests
- CEFR/LCP tests
- culture-card source/freshness tests
- relationship-graph tests
- dialogue authoring contract tests
- content validation

No live promotion, DE/EN localization, mastery/reward ownership change, or TTS
generation is claimed by this checkpoint.

## Next localization/research dependency

Before scaling DE/EN localization across the app, the trilingual native-usage
corpus must be built out beyond Living Korea.

Canonical registry:
`tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json`

Execution plan:
`docs/plans/2026-10-06-trilingual-native-usage-corpus.md`

The corpus includes reviewed **and unreviewed** content. Research coverage does
not imply content approval.
