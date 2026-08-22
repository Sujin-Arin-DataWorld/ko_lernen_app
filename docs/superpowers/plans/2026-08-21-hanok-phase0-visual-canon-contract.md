# Hanok Phase 0 Visual Canon Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `estate_masterplan_v2` fail closed on the approved Unjoru-derived spatial grammar and Hangul Sori compound visual-canon lineage without changing the 86 grant identities, generating images, or enabling runtime behavior.

**Architecture:** Extend the review-only JSON contract with path-free `architecturalGrammar` and `visualCanon` records, replace the detached front/service zoning with the approved integrated boundary and attached service zones, and validate all of it in the existing Python builder. The visual asset instructions remain in the linked spec; the machine contract records only semantic authority IDs so it cannot promote or reference image files.

**Tech Stack:** JSON review contracts, Python 3 standard library, `unittest`, Markdown, Git/GitHub CLI.

**Spec:** `docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md`

## Global Constraints

- Work only in `C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-level-phase0` on `session/hanok-level-phase0-2026-08-20`.
- `estate_masterplan_v2` remains `status: phase0Review` and `runtimeEnabled: false`.
- Preserve all 86 grant IDs, CanDo authority, level counts, canonical order, and `rewardConceptId` uniqueness.
- Set A1 `assetPolicy` to `rebuildFromApprovedGoldenMaster`; keep A2–C2 at `futureSocketOnly` and assign no asset IDs in Phase 0.
- Treat every `rewardConceptId` as a semantic label: no literal modern prop transfer or readable estate-overview text; require period-appropriate material translation.
- Preserve the non-authoritative three-step boundary prologue and all six representative level sockets.
- Retire `rear_garden` and independent `daecheongmaru`; do not add either as a target, zone, or asset reference.
- Do not generate, edit, copy, promote, or register images; do not change `pubspec.yaml`, runtime catalogs, renderer code, provenance ledgers, Firebase, CourseMastery, SRS, XP, or Gye state.
- The JSON contracts must contain no `assets/` paths, image extensions, Firebase strings, or Firestore strings.
- Current Personal V2 pixels remain provenance/reference material; legacy `hanok_compound` pixels are not re-bundled or directly composited.

---

### Task 1: Pin the approved architectural and visual canon in failing tests

**Files:**
- Modify: `tools/content_factory/test_hanok_phase0_contract.py`

**Interfaces:**
- Consumes: `builder._load_phase0_contract()` and the current review-only masterplan dictionary.
- Produces: exact test expectations for `architecturalGrammar`, `visualCanon`, zone IDs, socket positions, and zone ownership.

- [ ] **Step 1: Add the exact canon test**

Add this method to `HanokPhase0ContractTest`:

```python
def test_masterplan_pins_approved_architectural_and_visual_canon(self) -> None:
    self.assertEqual(
        {
            "id": "unjoru_validated_original_jongga",
            "reconstructionMode": "grammarOnly",
            "frontBoundary": "integratedHaengrangAndSotdaeulmun",
            "sarangComplex": "asymmetricalWithModestNumaru",
            "anchae": "fourWingCourtyard",
            "serviceCourt": "attachedToAnchae",
            "shrine": "separateRearEnclosure",
            "elevationBands": [
                "frontLow",
                "sarangMiddle",
                "anchaeShrineHigh",
            ],
        },
        self.masterplan["architecturalGrammar"],
    )
    self.assertEqual(
        {
            "id": "hangul_sori_compound_faceted_minhwa",
            "architectureAuthority": "unjoruSpatialGrammar",
            "visualDnaAuthority": "legacyCompoundAndCrossChannelGate",
            "geometryAuthority": "approvedSingleGoldenMaster",
            "legacyPixelReuse": False,
            "runtimeAssetPromotion": "deferred",
        },
        self.masterplan["visualCanon"],
    )
```

- [ ] **Step 2: Add the exact spatial-grammar test**

```python
def test_masterplan_uses_integrated_front_and_attached_service_zones(self) -> None:
    zones = {row["id"]: row["bounds"] for row in self.masterplan["zones"]}
    self.assertEqual(
        {
            "zone_outer_approach",
            "zone_front_haengrang_boundary",
            "zone_sarang_court",
            "zone_sarang_complex",
            "zone_inner_threshold",
            "zone_anchae_courtyard",
            "zone_attached_kitchen_service",
            "zone_rear_shrine",
            "zone_transmission_expansion",
        },
        set(zones),
    )
    self.assertEqual(
        {"x": 50, "y": 590, "width": 900, "height": 70},
        zones["zone_front_haengrang_boundary"],
    )
    self.assertEqual(
        {"x": 680, "y": 245, "width": 240, "height": 260},
        zones["zone_attached_kitchen_service"],
    )
    sockets = {row["level"]: row for row in self.masterplan["levelSockets"]}
    self.assertEqual("zone_sarang_complex", sockets["a2"]["zoneId"])
    self.assertEqual("zone_attached_kitchen_service", sockets["b2"]["zoneId"])
    self.assertEqual("zone_anchae_courtyard", sockets["c1"]["zoneId"])
    self.assertEqual(
        {
            "a1": {"x": 500, "y": 470},
            "a2": {"x": 490, "y": 325},
            "b1": {"x": 500, "y": 255},
            "b2": {"x": 790, "y": 275},
            "c1": {"x": 500, "y": 155},
            "c2": {"x": 175, "y": 170},
        },
        {level: row["position"] for level, row in sockets.items()},
    )
```

- [ ] **Step 3: Add a fail-closed mutation assertion**

Append inside `test_mutations_fail_closed`:

```python
changed_grammar = copy.deepcopy(self.masterplan)
changed_grammar["architecturalGrammar"]["frontBoundary"] = "detachedGate"
with self.assertRaisesRegex(ValueError, "architectural grammar changed"):
    builder._validate_masterplan(changed_grammar)

changed_canon = copy.deepcopy(self.masterplan)
changed_canon["visualCanon"]["legacyPixelReuse"] = True
with self.assertRaisesRegex(ValueError, "visual canon changed"):
    builder._validate_masterplan(changed_canon)
```

- [ ] **Step 4: Run the focused test and verify it fails for the new fields**

Run:

```powershell
python -m unittest tools.content_factory.test_hanok_phase0_contract.HanokPhase0ContractTest.test_masterplan_pins_approved_architectural_and_visual_canon tools.content_factory.test_hanok_phase0_contract.HanokPhase0ContractTest.test_masterplan_uses_integrated_front_and_attached_service_zones
```

Expected: `ERROR` or `FAIL` because `architecturalGrammar`, `visualCanon`, and the new zone IDs are absent.

---

### Task 2: Update the machine-readable estate masterplan

**Files:**
- Modify: `tools/content_factory/drafts/estate_masterplan_v2.json`

**Interfaces:**
- Consumes: exact dictionaries and positions defined by Task 1.
- Produces: a path-free, review-only masterplan consumed by `build_hanok_grants.py` and all Phase 0 tests.

- [ ] **Step 1: Add the path-free authority records after `retiredStructureIds`**

```json
"architecturalGrammar": {
  "id": "unjoru_validated_original_jongga",
  "reconstructionMode": "grammarOnly",
  "frontBoundary": "integratedHaengrangAndSotdaeulmun",
  "sarangComplex": "asymmetricalWithModestNumaru",
  "anchae": "fourWingCourtyard",
  "serviceCourt": "attachedToAnchae",
  "shrine": "separateRearEnclosure",
  "elevationBands": [
    "frontLow",
    "sarangMiddle",
    "anchaeShrineHigh"
  ]
},
"visualCanon": {
  "id": "hangul_sori_compound_faceted_minhwa",
  "architectureAuthority": "unjoruSpatialGrammar",
  "visualDnaAuthority": "legacyCompoundAndCrossChannelGate",
  "geometryAuthority": "approvedSingleGoldenMaster",
  "legacyPixelReuse": false,
  "runtimeAssetPromotion": "deferred"
},
```

- [ ] **Step 2: Replace the zone list with the approved nine zones**

Use these exact logical bounds:

```json
[
  {"id": "zone_outer_approach", "bounds": {"x": 0, "y": 660, "width": 1000, "height": 90}},
  {"id": "zone_front_haengrang_boundary", "bounds": {"x": 50, "y": 590, "width": 900, "height": 70}},
  {"id": "zone_sarang_court", "bounds": {"x": 260, "y": 360, "width": 480, "height": 230}},
  {"id": "zone_sarang_complex", "bounds": {"x": 310, "y": 275, "width": 370, "height": 100}},
  {"id": "zone_inner_threshold", "bounds": {"x": 440, "y": 230, "width": 120, "height": 55}},
  {"id": "zone_anchae_courtyard", "bounds": {"x": 300, "y": 55, "width": 400, "height": 200}},
  {"id": "zone_attached_kitchen_service", "bounds": {"x": 680, "y": 245, "width": 240, "height": 260}},
  {"id": "zone_rear_shrine", "bounds": {"x": 750, "y": 45, "width": 170, "height": 170}},
  {"id": "zone_transmission_expansion", "bounds": {"x": 80, "y": 55, "width": 190, "height": 200}}
]
```

- [ ] **Step 3: Move the six overview sockets without changing their IDs or target allowlists**

Apply these exact `zoneId` and `position` values:

```json
{
  "a1": ["zone_sarang_court", 500, 470],
  "a2": ["zone_sarang_complex", 490, 325],
  "b1": ["zone_inner_threshold", 500, 255],
  "b2": ["zone_attached_kitchen_service", 790, 275],
  "c1": ["zone_anchae_courtyard", 500, 155],
  "c2": ["zone_transmission_expansion", 175, 170]
}
```

- [ ] **Step 4: Replace camera zone references and keep every viewport 4:3**

Use these exact viewports and visible zone IDs:

```json
{
  "a1": {
    "viewport": {"x": 200, "y": 300, "width": 600, "height": 450},
    "visibleZoneIds": ["zone_outer_approach", "zone_front_haengrang_boundary", "zone_sarang_court", "zone_sarang_complex"]
  },
  "a2": {
    "viewport": {"x": 240, "y": 230, "width": 520, "height": 390},
    "visibleZoneIds": ["zone_sarang_court", "zone_sarang_complex"]
  },
  "b1": {
    "viewport": {"x": 120, "y": 160, "width": 760, "height": 570},
    "visibleZoneIds": ["zone_front_haengrang_boundary", "zone_sarang_court", "zone_sarang_complex", "zone_inner_threshold", "zone_anchae_courtyard", "zone_attached_kitchen_service"]
  },
  "b2": {
    "viewport": {"x": 260, "y": 20, "width": 720, "height": 540},
    "visibleZoneIds": ["zone_anchae_courtyard", "zone_attached_kitchen_service", "zone_rear_shrine"]
  },
  "c1": {
    "viewport": {"x": 80, "y": 20, "width": 840, "height": 630},
    "visibleZoneIds": ["zone_sarang_court", "zone_sarang_complex", "zone_inner_threshold", "zone_anchae_courtyard", "zone_attached_kitchen_service", "zone_rear_shrine"]
  },
  "c2": {
    "viewport": {"x": 0, "y": 0, "width": 1000, "height": 750},
    "visibleZoneIds": ["zone_outer_approach", "zone_front_haengrang_boundary", "zone_sarang_court", "zone_sarang_complex", "zone_inner_threshold", "zone_anchae_courtyard", "zone_attached_kitchen_service", "zone_rear_shrine", "zone_transmission_expansion"]
  }
}
```

- [ ] **Step 5: Run the focused tests and confirm only validator support remains missing**

Run the Task 1 command again.

Expected: the exact-field tests pass; mutation tests still fail because `_validate_masterplan` does not yet reject canon drift.

---

### Task 3: Make the builder fail closed on canon and viewport drift

**Files:**
- Modify: `tools/content_factory/build_hanok_grants.py`
- Test: `tools/content_factory/test_hanok_phase0_contract.py`

**Interfaces:**
- Consumes: `architecturalGrammar`, `visualCanon`, nine zones, six sockets, and six camera viewports from Task 2.
- Produces: `_validate_masterplan(masterplan: dict) -> dict[str, dict]` with exact canon and 4:3 viewport enforcement.

- [ ] **Step 1: Add exact constants next to `RETIRED_V2_STRUCTURES`**

```python
EXPECTED_ARCHITECTURAL_GRAMMAR = {
    "id": "unjoru_validated_original_jongga",
    "reconstructionMode": "grammarOnly",
    "frontBoundary": "integratedHaengrangAndSotdaeulmun",
    "sarangComplex": "asymmetricalWithModestNumaru",
    "anchae": "fourWingCourtyard",
    "serviceCourt": "attachedToAnchae",
    "shrine": "separateRearEnclosure",
    "elevationBands": ["frontLow", "sarangMiddle", "anchaeShrineHigh"],
}
EXPECTED_VISUAL_CANON = {
    "id": "hangul_sori_compound_faceted_minhwa",
    "architectureAuthority": "unjoruSpatialGrammar",
    "visualDnaAuthority": "legacyCompoundAndCrossChannelGate",
    "geometryAuthority": "approvedSingleGoldenMaster",
    "legacyPixelReuse": False,
    "runtimeAssetPromotion": "deferred",
}
EXPECTED_ZONE_IDS = {
    "zone_outer_approach",
    "zone_front_haengrang_boundary",
    "zone_sarang_court",
    "zone_sarang_complex",
    "zone_inner_threshold",
    "zone_anchae_courtyard",
    "zone_attached_kitchen_service",
    "zone_rear_shrine",
    "zone_transmission_expansion",
}
```

- [ ] **Step 2: Validate the exact authority dictionaries before zones**

```python
if masterplan.get("architecturalGrammar") != EXPECTED_ARCHITECTURAL_GRAMMAR:
    raise ValueError("estate masterplan architectural grammar changed")
if masterplan.get("visualCanon") != EXPECTED_VISUAL_CANON:
    raise ValueError("estate masterplan visual canon changed")
```

- [ ] **Step 3: Reject missing, renamed, or legacy zones**

Immediately after `_require_unique_rows` builds `zones`, add:

```python
if set(zones) != EXPECTED_ZONE_IDS:
    raise ValueError("estate masterplan zones changed")
```

- [ ] **Step 4: Enforce 4:3 camera viewports**

Immediately after this existing line:

```python
_validate_rect(viewport, width, height, f"camera {camera.get('id')}")
```

add:

```python
if viewport["width"] * 3 != viewport["height"] * 4:
    raise ValueError(f"camera {camera.get('id')} viewport must stay 4:3")
```

- [ ] **Step 5: Run all Phase 0 unit tests**

Run:

```powershell
python -m unittest tools.content_factory.test_build_hanok_grants tools.content_factory.test_hanok_phase0_contract
```

Expected: all tests pass.

---

### Task 4: Normalize and verify the complete Phase 0 slice

**Files:**
- Modify only if normalization changes whitespace: `tools/content_factory/drafts/estate_masterplan_v2.json`
- Verify unchanged identities: `tools/content_factory/drafts/hanok_grant_remapping_v2.json`
- Verify approved Work prompt: `docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md`

**Interfaces:**
- Consumes: the validated masterplan and unchanged 86-row remapping.
- Produces: normalized review contracts and evidence that the visual instructions do not alter runtime assets or grant authority.

- [ ] **Step 1: Normalize all three draft contracts through the builder**

```powershell
python tools/content_factory/build_hanok_grants.py
```

Expected: `hanok_grants.json`, `estate_masterplan_v2.json`, and `hanok_grant_remapping_v2.json` are UTF-8, two-space-indented, newline-terminated JSON.

- [ ] **Step 2: Run the fail-closed source and history check**

```powershell
python tools/content_factory/build_hanok_grants.py --check --verify-git-history --base-revision HEAD
```

Expected: exit 0 and no output.

- [ ] **Step 3: Run the complete local verification set**

```powershell
python -m unittest tools.content_factory.test_build_hanok_grants tools.content_factory.test_hanok_phase0_contract
python tool/check_style_lock_docs.py
git diff --check
```

Expected: all unit tests pass, STYLE_LOCK documentation check exits 0, and `git diff --check` prints nothing.

- [ ] **Step 4: Confirm forbidden scope stayed untouched**

```powershell
git diff --name-only
```

Expected changed paths are limited to:

```text
docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md
docs/superpowers/plans/2026-08-21-hanok-phase0-visual-canon-contract.md
tools/content_factory/build_hanok_grants.py
tools/content_factory/test_build_hanok_grants.py
tools/content_factory/test_hanok_phase0_contract.py
tools/content_factory/drafts/estate_masterplan_v2.json
tools/content_factory/drafts/hanok_grant_remapping_v2.json
```

`tools/content_factory/drafts/hanok_grants.json` may be rewritten byte-identically by normalization but must not appear in the final diff.

---

### Task 5: Rebase, record handoff, commit, push, and open the PR without merging

**Files:**
- Create: `.claude/handoffs/2026-08-21-hanok-phase0-visual-canon.md`
- Stage only the paths listed in Task 4 plus the handoff.

**Interfaces:**
- Consumes: a green local Phase 0 slice on the task branch.
- Produces: one reviewable branch and open pull request; no merge, deployment, Firebase change, or image promotion.

- [ ] **Step 1: Commit the task-owned Phase 0 implementation before rebasing**

```powershell
git add docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md docs/superpowers/plans/2026-08-21-hanok-phase0-visual-canon-contract.md tools/content_factory/build_hanok_grants.py tools/content_factory/test_build_hanok_grants.py tools/content_factory/test_hanok_phase0_contract.py tools/content_factory/drafts/estate_masterplan_v2.json tools/content_factory/drafts/hanok_grant_remapping_v2.json
git commit -m "feat: define Hanok Phase 0 estate contracts"
```

Expected: one commit containing only the Phase 0 spec, plan, builder, tests, and review contracts.

- [ ] **Step 2: Rebase onto the latest `origin/main`**

```powershell
git fetch origin --prune
git rebase origin/main
```

Expected: clean rebase. If a conflict touches a task-owned file, resolve by preserving the approved contract and current `origin/main` changes; abort and report if the conflict changes product authority or scope.

- [ ] **Step 3: Rerun Task 4 verification on the rebased final head**

Expected: the same checks pass after rebase.

- [ ] **Step 4: Write the handoff**

Create `.claude/handoffs/2026-08-21-hanok-phase0-visual-canon.md` with these sections and concrete final values:

```markdown
# Handoff: Hanok Phase 0 visual canon and estate contract

## Current state
- Branch and final head
- `phase0Review`, `runtimeEnabled: false`
- 86 grant IDs/order preserved
- Approved canon: Unjoru grammar + compound visual DNA + single Golden Master

## Verification
- Exact commands and pass counts
- `git diff --check`
- CI link/status after push

## Out of scope
- No image generation or promotion
- No runtime renderer/catalog/pubspec changes
- No Firebase, CourseMastery, SRS, XP, or Gye changes

## Next
- Run the spec's Work prompt to create exactly one `hanok_visual_keyframe_01`
- Do not create the Golden Master until Jin visually approves the keyframe
```

- [ ] **Step 5: Commit the handoff**

```powershell
git add .claude/handoffs/2026-08-21-hanok-phase0-visual-canon.md
git commit -m "docs: hand off Hanok Phase 0 contract"
```

- [ ] **Step 6: Push and create the PR**

```powershell
git push -u origin session/hanok-level-phase0-2026-08-20
gh pr create --base main --head session/hanok-level-phase0-2026-08-20 --title "feat: define Hanok Phase 0 estate contracts" --body-file .claude/handoffs/2026-08-21-hanok-phase0-visual-canon.md
```

Expected: an open PR targeting `main`. Do not merge it.

- [ ] **Step 7: Inspect final PR checks once, without starting duplicate runs**

```powershell
gh pr checks --watch
```

Expected: report current-head check results accurately. Do not claim Firebase, deployment, device, Play Internal, or asset-generation proof from these checks.
