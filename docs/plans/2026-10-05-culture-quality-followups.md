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

Status: **in progress**

Resume the existing LCP rather than create a culture-specific leveling system.

### Stage C-1 — six-grade vocabulary coverage gate

Status: **complete**

The previous audit only measured NIKL grade 1/A1 and grade 2/A2 vocabulary
coverage. Grades 3–6 had no live coverage measurement or ratchet.

Implemented:
- `tool/audit_content_levels.py` now computes coverage for grades 1–6 with
  one shared resolved-lemma pass
- generated summary/report now expose B1, B2, C1, and C2 coverage
- live ratchets prevent `missing` from increasing and `at_level` from
  decreasing for every grade

2026-10-05 baseline:
- B1/grade3: total 1554 / present 310 / at-level 162 / missing 1244
- B2/grade4: total 2089 / present 276 / at-level 148 / missing 1813
- C1/grade5: total 2171 / present 154 / at-level 26 / missing 2017
- C2/grade6: total 2479 / present 129 / at-level 46 / missing 2350

Validation:
- `tool.test_audit_content_levels`: **53/53 passed**

### Stage C-2 — eliminate high-confidence grammar over2 debt

Status: **complete**

Resolved the two remaining high-confidence grammar `over2` findings without weakening the audit:

- `grammar_a1_long_negation` stays A1 because `-지 않다` is a Bible/NIKL grade-1 grammar item. The lexicon still grades standalone `않다` as B1; only sentence profiles where `grammar_a1_long_negation` is positively detected cap that auxiliary token to A1, preventing double-counting of the grammar's own lexical material.
- `grammar_b1_more_more` (`-(으)ㄹ수록`) moved B1 → B2 through relevel batch `V2G2`, matching the level-bible 4급 evidence. Curriculum routing, can-do authority/cluster membership, immutable relevel ledger, and three affected grammar-quiz distractor sets moved atomically.
- the example is now `읽을수록 더 재미있어요.` with aligned DE/EN copy.

Supporting repairs:
- regenerated can-do segments/authorities so Batch 38 live scenarios and the earlier B2 vocab fingerprint repair are canonical generator output
- hardened `relevel_bundle.py` for Windows rename locks with retry + fsynced validated overwrite fallback
- relevel staged text outputs are explicitly normalized to LF; rollback remains byte-exact
- refreshed curriculum matrix and generated level-bible tables
- lowered `CAP_OVER2` ratchets to current actuals: vocab 158 / grammar 0 / scenario 0 / cloze 20 / satz 15 / smalltalk 17 / pronunciation 0 / media 6

Validation:
- lexicon + level-audit + relevel Python bundle: **290 / 290 passed**
- `build_can_do_segments.py --check`: fresh
- `validate_content.py`: passed
- targeted Dart analysis: **0 issues**
- can-do asset/loader Flutter tests: **11 / 11 passed**
- curriculum matrix freshness: passed
- learning-phase freshness: passed
- `grammar.over2`: **2 → 0**

### Stage C-3 — scenario/grammar level regressions

Status: **complete**

Reviewed all six historical scenario→grammar level inversions against the actual
dialogue and task. No scenario was auto-promoted just to silence the warning.

Resolved:
- `a1_w10_partner`: keep A1; replace the A2 `N께` teaching owner with A1
  formal-statement/request ownership, and rewrite learner-facing `어머니께`
  material to A1 `한테/에게`.
- `a1_w10_fandom`: keep A1; replace A2 `N(이)나` with short `N도`
  turns and an A1 `주세요` response.
- `b1_w10_insurance`: keep B1; remove the relevelled B2 whether-owner and
  ask coverage directly, synchronizing scenario quests and listening copy.
- `b2_w10_travel`: keep B2; replace C1 `despite` ownership with grounded
  B2 `N에 따라` and preserve the alternative-route negotiation.
- `b2_w10_hiring`: keep B2; remove C1 `despite` and rewrite the sentence
  with `촉박해도`.
- `b2_w10_authorities`: keep B2; use the dialogue's existing
  `체류 자격과 현재 상황에 따라` as the B2 grammar anchor instead of the
  C1 negative-consequence owner.

Durability:
- all six live objects equal their W10 authoring-source mirrors
- a new global regression test rejects any live scenario whose `grammarIds`
  owner is above the scenario level
- current live scenario→grammar above-level count: **0**
- permanent review record:
  `tools/content_factory/review/lcp_c3_scenario_grammar_reconciliation_20261005.json`

Validation:
- scenario/listening/relevel Python bundle: **138/138 passed**
- content validation: **passed**
- level audit ratchets: **53/53 passed**
- curriculum matrix: **fresh**
- learning phases: **fresh; error 0**

### Stage C-4 — remaining high-confidence level debt

Status: **in progress**

Sentence-surface canonicalization is now complete:
- fixed GrammarIndex false positives including A1 `그래요`, elementary
  possession `가지고 있다`, common conjugation/homograph cases, proper nouns,
  and A1 `V-고 싶다` lexical double-counting
- simplified genuinely over-complex cloze/Satz/smalltalk/media surfaces while
  preserving the learning target and synchronizing DE/EN copy
- regenerated can-do lineage and explicitly recorded reviewed route transfers
  for relevelled cloze owners
- smalltalk edits are chained through
  `tools/content_factory/review/smalltalk_editorial_successors_20261005.json`
- cloze/Satz over2 auditing now prevents double-counting the explicitly taught
  vocab owner: suppression is allowed only when the full sentence is over2
  *and* removing that exact target leaves context below over2; genuinely hard
  surrounding context stays visible
- regression tests lock both sides of that rule

Current high-confidence `over2` ratchets:
- vocab: **158**
- grammar: **0**
- scenario: **0**
- cloze: **0**
- satz: **0**
- smalltalk: **0**
- pronunciation: **0**
- media: **0**

Low-confidence fallback remains separately visible:
- vocab fallback_over2: **45**
- smalltalk fallback_over2: **1**
- media fallback_over2: **1**

Reviewed-current-owner support:
- new canonical ledger: `tools/content_factory/relevel/reviewed_vocab_owners_20261005.json`
- first tranche: **75** reviewed keep-current decisions
  - B1 practical/work-life core: 22
  - B2 domain-core professional/civic/research/housing/policy/culture: 53
- invalid schema, duplicate IDs, stale live levels, and stale pack IDs fail closed
- raw external estimate/delta remains visible; only resolution state changes
- no native-speaker QA claim is made by this owner ledger

Validation:
- level-audit regression bundle: **59/59 passed** after reviewed-owner support
- live audit regeneration: passed
- `build_can_do_segments.py --check`: fresh
- `validate_content.py`: passed

Remaining Stage C-4 work is still the **vocab owner/backlog only**, but the
unresolved set is now much smaller.

Current raw +2-or-more vocab population by canonical state:
- unresolved high-confidence `over2`: **30** (105 → 30)
- reviewed current owner: **75**
- accepted historical relevel owner: **59**
- explicit `replacement_backlog`: **15**
- unresolved low-confidence `fallback_over2`: **45**

Replacement backlog takes precedence over an older relevel decision when both
exist. Reviewed-current-owner decisions are separate from relevel history:
they explicitly explain why a live row stays where it is despite a higher
general-literacy estimate. Ratchets now prevent unresolved high-confidence
over2 from rising above **30**.

Continue with the remaining 30 unresolved high-confidence vocab rows, then the
45 low-confidence fallback rows. For each, review prior evidence,
survival/culture exceptions, pack semantics, and whether the correct action is
move, replace, or a narrowly documented current-owner decision. Never raise a
ratchet merely to make the suite green.

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
