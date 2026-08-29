# W6 시나리오 정적 아트와 감사 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` for code/audit steps and the local `imagegen` skill for every actual image-generation or image-editing step.

**Goal:** 413개 canonical 시나리오의 전용 정적 아트 상태를 결정적 inventory로 만들고, 1536×1024·ID·중복·orphan·crop 안전성을 fail-closed 감사하며, 생성된 아트만 pending review와 runtime eligibility를 구분해 관리한다.

**Architecture:** 기존 `audit_scene_assets.py`를 단일 감사 권위로 확장하고 별도 중복 감사기를 만들지 않는다. inventory/manifest는 scenario shard를 정렬해 생성한다. image generation은 승인 style sources와 scenario별 semantic prompt를 사용하며 결과는 먼저 `assets_unused/pending_review/scenes/`에 둔다. 자동 유효성 및 사람의 시각 승인 전 runtime directory로 승격하지 않는다.

**Tech Stack:** Python 3 UTF-8, Pillow where already available, Flutter asset resolver tests, image generation tool, PNG sRGB.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §§8.1, 8.4, 10–12; `docs/ASSET_GENERATION_BIBLE.md`; applicable style-lock/inventory files.

## Global Constraints

- Start after W5-C merge, from fresh `origin/main`.
- W6 excludes every video regeneration/replacement, including `tiger_choose`.
- Do not call category fallback crops, color variants, or duplicated images scenario-specific art.
- Do not generate or edit imagery until the `imagegen` skill has been read in full and its use announced in commentary.
- New images begin in pending review. Runtime promotion requires exact automated validity plus explicit visual review; device crop approval remains Jin's final gate.
- Never claim 413 dedicated assets complete unless inventory proves 413 unique valid files.
- Python commands use `python -X utf8`.

### Task 1: deterministic canonical scene inventory

**Files:**

- Modify: `tool/audit_scene_assets.py`
- Create: `tool/test_audit_scene_assets.py`
- Generate: `docs/data/scene_asset_inventory.json`
- Regenerate: `docs/data/scene_asset_report.md`

**CLI:**

```text
python -X utf8 tool/audit_scene_assets.py [--check] [--json docs/data/scene_asset_inventory.json]
```

Default mode writes deterministic JSON and Markdown. `--check` computes the same result without rewriting and exits nonzero when strict issues exist or checked-in reports differ.

**JSON schema:** `schemaVersion`, `generatedFrom` source hashes, `scenarioCount`, `dedicatedCount`, `fallbackCount`, `missingCount`, `issues`, and sorted `scenarios`. Each scenario row contains shard, id, level, backdrop, dedicated path, resolved path, status, width, height, mode, colorSpace, alpha, sha256, duplicateOf, and runtimeEligible.

**Strict issues:** duplicate scenario ID; broken category fallback; dedicated file not 1536×1024; unreadable/non-PNG image; unexpected color mode; duplicate content hash across different scenario IDs; orphan dedicated scene asset; filename/ID mismatch; generated manifest drift. Category fallbacks remain reported coverage debt, not a broken-reference issue.

**TDD steps:**

1. Extract scan/render/exit decisions into pure functions and add temporary-directory tests for each strict issue plus deterministic ordering/newlines.
2. Confirm current script tests fail because `--check`, JSON, dimensions, and hashes are absent.
3. Implement argparse, image metadata/hash scan, stable reports, and issue-count exit.
4. Generate reports twice and prove byte-identical output on the second run.
5. Run `python -X utf8 -m unittest tool.test_audit_scene_assets` and `python -X utf8 tool/audit_scene_assets.py --check`.

**Commit:** `feat(assets): make scene inventory strict and machine readable`

### Task 2: update the normalization pipeline to dedicated 1536×1024 output

**Files:**

- Modify: `tool/scene_poster_normalize.py`
- Create: `tool/test_scene_poster_normalize.py`

**Contract:** dedicated outputs are 1536×1024 sRGB PNG, preserve source aspect by controlled cover crop, strip unstable metadata, use deterministic encoder settings, and write only to an explicit output directory. The legacy 1086×1448 category posters remain untouched unless explicitly supplied as input/output by the operator.

**TDD steps:**

1. Add landscape, portrait, alpha, odd-dimension, corrupt-input, existing-output, and deterministic-hash tests using temporary files.
2. Confirm the existing 1086×1448 behavior fails the new target test.
3. Add required `--input`, `--output`, `--scenario-id`, and optional focal coordinates; refuse in-place overwrite and IDs not present in canonical inventory.
4. Run `python -X utf8 -m unittest tool.test_scene_poster_normalize`.

**Commit:** `fix(assets): normalize dedicated scene posters to 1536x1024`

### Task 3: build semantic prompt batches without generating generic substitutes

**Files:**

- Create: `tool/build_scene_art_manifest.py`
- Create: `tool/test_build_scene_art_manifest.py`
- Generate: `docs/data/scene_art_generation_manifest.json`

**Manifest contract:** one sorted entry per canonical scenario with ID, level, category, Korean semantic summary derived from its title/dialog/goal, required setting/participants/props, forbidden text/logos, approved style reference identifiers, target path, priority, and generation status. Priority order is office (172), home (86), then cafe, station, market, convenience, restaurant, pharmacy, directions, hotel, taxi, airport, bank, salon; within a category sort by level then ID.

**TDD steps:**

1. Test exact 413 rows, unique IDs/paths, canonical-source hashes, nonempty Korean semantic anchors, and the fixed category counts from the baseline inventory.
2. Test that prompts sharing a category are not byte-identical and include scenario-specific semantic anchors.
3. Implement the builder from `assets/data/scenarios_a1.json` through `scenarios_c2.json`; no network call is part of the builder.
4. Generate twice and prove byte-stable output.

**Commit:** `feat(assets): inventory semantic prompts for every scenario`

### Task 4: generate and validate review batches

**Files:**

- Create on actual generation: `assets_unused/pending_review/scenes/{scenario_id}.png`
- Update after each actual result: `docs/data/scene_art_generation_manifest.json`

**Execution:** use the image generation tool for each scenario-specific result, beginning with a small office/home pilot that exercises compact/medium/expanded crops. Prompt from the manifest and approved Faceted Minhwa references; do not invent another style source. Inspect every returned image, normalize through Task 2, then run Task 1 audit against pending-review mode.

For each image, record actual generator result identity, source prompt hash, normalized hash, dimensions, automated issues, and `visualReview: pending`. A batch may be called generated only for its exact successful count. Failed/missing calls remain `not_generated`, never silently replaced by category art.

**Commit boundary:** one manifest commit per bounded reviewed batch; binary files and their matching manifest rows are committed together only after repository policy permits pending-review tracking.

### Task 5: runtime promotion gate and resolver verification

**Files:**

- Promote only approved files to: `assets/illustrations/scenes/{scenario_id}.png`
- Modify if required: `lib/services/scene_asset_resolver.dart`
- Modify: `test/scene_asset_resolver_test.dart`
- Modify: `tool/audit_scenario_quests.py` only where shared canonical-ID checks are needed

**TDD steps:**

1. Test dedicated-first resolution for approved files and category fallback for all non-promoted IDs.
2. Test that pending-review paths are never returned by runtime resolver and are not declared in `pubspec.yaml`.
3. Promote only rows with automated validity and explicit visual approval; rerun the strict audit after every batch.
4. Do not alter video-loop resolution.

### Task 6: W6 scene wave proof

Run both Python unittest modules, both audit scripts in check mode, `flutter test --no-pub test/scene_asset_resolver_test.dart test/scenario_loader_shard_test.dart test/scenario_player_ui_test.dart`, `flutter analyze --no-pub`, and the full Flutter suite. Record exact dedicated/fallback/pending counts. Run `graphify update .`, push, and prove current-head CI. Report human visual/device crop gates separately from automated validity.
