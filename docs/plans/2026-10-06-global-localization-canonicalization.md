# Global Localization Canonicalization — KO → EN / DE

Date: 2026-10-06  
Status: ACTIVE  
Owner boundary: TTS synthesis remains Jin-owned. This program may author spoken-surface text/notes but must not generate or overwrite audio.

## Goal

Make the trilingual native-usage corpus a production localization layer for the whole Hangul Sori content system, not only Living Korea.

The target is not “every row has an English and German string.” The target is:

- Korean remains the semantic/pragmatic source of truth.
- English is authored/reviewed directly from Korean.
- German is authored/reviewed directly from Korean.
- EN and DE never form a translation chain.
- word/expression sense, example meaning, relationship, register and pedagogical contrast are preserved.
- display text and spoken/TTS surfaces are distinct where chat orthography would sound unnatural.
- derived exercises consume a canonical localization owner instead of drifting independently.
- no content is promoted merely because research coverage exists.

## Canonical dependencies

- `tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json`
- `tools/content_factory/canonical_scenarios/dialogue_localization_contract_20261006.json`
- `tools/content_factory/canonical_scenarios/global_localization_contract_20261006.json`
- `tools/content_factory/review/trilingual_content_topic_coverage_20261006.json`

## Owner-first localization model

### Owner surfaces

These may own EN/DE copy and therefore receive semantic/native QA directly:

1. vocab headword sense / expression meaning
2. vocab example sentence
3. smalltalk/expression source utterance and its canonical reply/follow-up
4. scenario/dialogue turn
5. listening source dialogue / source meaning
6. culture/editorial copy where it is not mechanically derived
7. Living Korea localized scene turn

### Derived surfaces

These should inherit or be regenerated from an owner whenever possible:

- cloze translation from the canonical vocab/example owner
- sentence-building prompt from the canonical example owner
- listening questions/options that quote or paraphrase a source scene
- scenario quests/options derived from the canonical scene
- repeated meaning prompts/explanations

A derived surface must not be “fixed” independently if the owner is wrong. Fix the owner, regenerate/reconcile the consumer, then test parity.

## Program stages

### G-0 — inventory + owner graph

Status: **baseline complete — 2026-10-06**

Create a generated ledger that records every live localization-bearing surface and the canonical owner relationship where known.

Required summary:

- count by surface family
- count with KO/EN/DE present
- topic mapping status
- native-usage profile readiness
- owner vs derived
- explicit unresolved owner mapping; no silent omissions
- QA/promotion status tracked separately from research coverage

### G-1 — Living Korea reference batch

Status: **complete + live promoted as batch 39 — 2026-10-06**

Target: 23/23 scenes, 138 Korean turns.

For every scene:

1. create the localization spine:
   - semanticCore
   - speechAct
   - relationship
   - authority
   - tone
   - humanBeat
   - mustPreserve
   - mayAdapt
   - mustNotBecome
   - registerLane
2. author EN directly from KO.
3. author DE directly from KO.
4. create display and spoken surfaces where needed.
5. run semantic/register/persona/translationese/native-usage/pedagogical QA.
6. do not claim human-native sign-off unless a human native reviewer actually reviewed it.
7. only promote when the automated/corpus QA gate passes and the release decision is explicit.

Living Korea is the reference implementation for the rest of the repo.

### G-2 — existing vocab + expressions + every canonical example

Status: **in progress**

Baseline owner audit now tracks 7,706 surfaces: vocab lexeme 2,968 + vocab example 2,968 + smalltalk expression/variant/follow-up 590 each. Structural owner linkage currently passes 7,706/7,706, and canonical native-usage topic mapping is now complete for 7,706/7,706 owner surfaces with explicit source-taxonomy or phrase-level mapping evidence where the older content-topic ledger had no canonical topic. Manual owner-topic review debt is 0. 444 rows still carry explicit language-review flags (mostly example target-surface anchoring plus intentional Korean metalanguage candidates). This is not human-native sign-off and corpus/native QA remains open.

Audit the canonical localization owners first:

- `assets/data/korean_vocab.csv`
  - headword/expression DE + EN sense
  - example Korean ↔ DE/EN example alignment
  - POS
  - register
  - sense consistency
  - natural collocation
- `assets/data/smalltalk.json`
  - primary expressions
  - safe alternative questions
  - follow-ups/replies

Do not mechanically require a 1:1 dictionary equivalent when the Korean expression is pragmatic.

### G-3 — derived exercise reconciliation

Status: **owner-parity baseline complete — 2026-10-06**

Cloze 2,365 + Satz 2,885 = 5,250 derived surfaces are tracked. 4,641 have resolved vocab-example owners and were regenerated/reconciled to exact EN/DE owner parity (post-reconcile drift 0); 609 remain explicitly unresolved rather than guessed. One confirmed owner semantic mismatch (`vocab_a1_0218`, 호칭 example) was corrected before propagation.

Reconcile:

- `assets/data/cloze.json`
- `assets/data/satz_sentences.json`
- smalltalk lessons
- listening lessons
- scenario quest copy

Derived consumers must match their canonical owner’s meaning and current EN/DE copy.

### G-4 — remaining dialogues/editorial surfaces

Audit existing:

- scenarios
- listening source dialogue
- persona dialogue
- culture-linked dialogue/cards
- other learner-facing localized editorial copy

### G-5 — correction + regression

For each correction:

1. preserve Korean unless the Korean owner itself is wrong and separately approved for revision.
2. correct canonical EN and/or DE owner.
3. regenerate/reconcile derived consumers.
4. run CEFR/LCP and task-correctness checks.
5. run localization QA and translationese checks.
6. keep TTS audio untouched.

### G-6 — permanent promotion gate

Future materially revised localized content must declare:

- canonical localization contract
- canonical native-usage topic ids
- owner/derived relationship
- QA status
- spoken-surface status when relevant

Fail closed on:

- EN authored from DE or DE authored from EN
- missing KO source
- missing deep native-usage profile
- missing required localization-spine fields for dialogue
- silent missing localized surface
- derived/owner semantic drift
- chat-only orthography passed straight to spoken surface when a spoken form is required

## Definition of done

The whole program is done only when:

- Living Korea 23/23 has complete EN/DE localization spines and QA.
- every live vocab/expression owner is audited.
- every canonical vocab example is audited.
- every derived cloze/satz item is reconciled to an owner or explicitly unresolved.
- remaining live dialogue/listening/exercise/editorial surfaces are audited.
- the global coverage ledger has zero silent omissions.
- correction tests and content validation pass.
- Graphify/handoff docs reflect the final state.
- changes are committed and pushed in reviewable phases.

Research coverage, localization QA, live approval and TTS are four separate axes.