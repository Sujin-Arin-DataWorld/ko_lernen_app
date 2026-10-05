# Culture quality follow-ups — 2026-10-05

> Owner: project manager follow-up after the original 9/9 culture-world rollout.
> Branch: `session/culture-links-20261005-2026-10-05`
> TTS is explicitly excluded: Jin will do TTS work directly in VS Code.

## Goal

Improve the completed culture-world system without creating a second mastery,
reward, or progression authority.

Priority order:

1. expand culture story arcs using already-reviewed live scenarios
2. audit durable/cross-device culture discovery and decide whether persistence is justified
3. resume the existing app-wide Level Canonicalization Program (LCP)

## Non-negotiable boundaries

- culture discovery never proves CanDo mastery
- culture discovery never grants XP, Yeopjeon, Bojagi, Hanok progress, or rewards
- existing Scenario / CourseMastery / reward owners stay authoritative
- new arc metadata must reference only live scenario-culture links
- merged Batch 38 draft payload stays frozen; follow-up arcs are independent live grouping metadata
- do not generate or overwrite TTS in this program

## Stage A — arc expansion

Status: **complete**

The first live arc, `found_around_nammun`, remains the broad introduction.

Added two thematic paths:

### `made_by_hand_in_korea` — 손으로 만드는 한국

- B1 Maya × Dongsun: norigae + maedeup
- B2 Daniel × Hyuna: hanji
- focus: handmade objects, correct maker attribution, respectful filming

### `memory_to_record` — 기억에서 기록으로

- B1 Hyuna × Byeongcheol: personal memory vs checked Hwaseong information
- A2 Jun × Christian: school source checking
- C1 Maya × Hyuna × Daniel: talchum documentation vs reinterpretation
- focus: memory, evidence, documentation, representation responsibility

Live arc count: **3**.

All remain `derived_read_only`. No arc owns persistence, mastery, or rewards.

Validation:
- live catalog parsing and reference-contract tests
- every arc step backed by the live scenario-culture registry
- focused culture arc/discovery/UI tests: **19/19 passed**

## Stage B — durable culture discovery design audit

Status: **complete**

Decision: **do not create a culture-specific discovery ledger.**

Root cause:
- `Storage.completedScenarios` is already the canonical current-generation scenario
  completion owner
- culture discovery correctly derives from it
- the durability gap existed because this owner was not included in root cloud backup

Implemented:
- cloud `progress` now carries `scenario_corpus_generation`
- cloud `progress` now carries `completed_scenarios`
- direct restore unions completed scenario IDs only when the generations match
- account reconciliation already provides the correct semantics:
  - same generation string + list values => deterministic union
  - different generation strings => conflict rather than cross-generation resurrection
- `CourseMasterySnapshot.scenarioCheckpoints` remain supplementary evidence, not the
  permanent archive

Result:
- cross-device culture discovery becomes durable through the existing scenario-completion
  owner
- no culture-specific persistence key, mastery denominator, reward source, or second
  progression system was introduced

Validation:
- targeted Dart analysis: **0 issues**
- CloudSync + account reconciliation test bundle: **116/116 passed**
- matching-generation union and mismatched-generation fail-closed behavior are locked by tests

## Stage C — app-wide Level Canonicalization Program

Status: **next**

Resume the existing LCP rather than create a culture-specific leveling system.

Use:
- `AGENTS.md` LCP gate
- latest LCP handoff / level-bible evidence
- `tool/audit_content_levels.py`
- `tool/cefr_lexicon.py`
- current ratchet tests

Quality dimensions include:
- lexical level
- grammar
- sentence burden
- task complexity
- register / relationship
- distractor difficulty
- listening burden
- cultural/proper-noun exceptions

Rule: fix real content debt or document a justified exception; do not relax ratchets merely
to make tests green.
