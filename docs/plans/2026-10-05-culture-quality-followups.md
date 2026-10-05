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

Status: **next**

Current sources:
- local current-generation `Storage.completedScenarios`
- cloud-restorable bounded `CourseMasterySnapshot.scenarioCheckpoints`

Known limitation:
- `scenarioCheckpoints` is bounded attempt history, not a permanent set of unique
  completed scenarios
- heavy replay can evict old scenario IDs after cross-device restore

Decision questions:
1. Can an existing durable completion owner provide lossless scenario evidence without
   adding culture-specific progression?
2. If not, is a small presentation-only discovery receipt justified?
3. How should corpus-generation migration and account reconciliation treat it?
4. Can the receipt store scenario IDs only, deriving terms/arcs from current catalogs,
   rather than persisting cultural mastery?

Do not implement persistence until these ownership/migration questions are resolved.

## Stage C — app-wide Level Canonicalization Program

Status: **after Stage B decision**

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
