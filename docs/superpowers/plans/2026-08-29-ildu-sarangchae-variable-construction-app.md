# Ildu Sarangchae Variable Construction App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not dispatch subagents unless the user explicitly requests delegation.

**Goal:** Ship a review-gated Sarangchae pilot whose twelve blueprint-led construction states, `백세청풍·탁청재` cultural Lernpfad, durable progress, and locked 2412×2622 world presentation work together without promoting any unapproved image.

**Architecture:** Keep the art pipeline and the Flutter domain separate. Python tools produce and audit a deterministic 12-stage pending-review package; after an explicit visual approval record, a fail-closed promotion tool copies the exact approved bytes into a runtime leaf. Flutter loads a versioned variable-stage plan, stores stable stage/module IDs, evaluates communicative task evidence separately from moral stance, and projects the last valid stage into the existing `IlDuWorldScreen` through a zoom-free horizontal viewport.

**Tech Stack:** Flutter/Dart 3, JSON asset catalogs, SharedPreferences, Pillow/NumPy deterministic image tooling, `flutter_test`, Python `unittest`.

**Spec:** `docs/superpowers/specs/2026-08-29-ildu-variable-construction-cultural-lernpath-design.md`

## Global Constraints

- Priority is actual construction and blueprints, building role and cultural meaning, V3 visual identity, 2026 Korean communication, then play-time convenience.
- The final Sarangchae base remains byte-identical to `assets_unused/pending_review/personal_hanok_v3/sarangchae_try07_edit.png`, SHA-256 `f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212`.
- Every stage uses the 2512×1680 common sprite canvas, center X `1250.0`, ground Y `1421`, and alpha threshold `8` until it is positioned on the 2412×2622 estate canvas.
- Runtime domain code never assumes eight stages; progress is keyed by `buildingId + planVersion + completedStageIds + completedModuleIds`.
- The estate world remains 2412×2622 logical pixels with a 1206×2622 viewport, one horizontal pan, no vertical pan, and no zoom.
- Korean is the semantic source; German and English are independently localized from the same communication event.
- Moral stance is never scored. Only required communicative function, relationship/register fit, and authored language evidence can complete a module.
- A missing or invalid stage asset displays the last valid stage; a generic Hanok substitute is forbidden.
- New visual outputs remain under `assets_unused/pending_review/personal_hanok_v3` until an explicit visual and in-world approval record names the reviewed manifest hash.
- Do not add pending-review paths to `pubspec.yaml`, runtime catalogs, Firebase, or store builds.
- Do not regenerate or redraw the supplied calligraphy. Remove chroma, composite boards, and place overlays deterministically.
- Do not modify `graphify-out/cache/last_query_stamp` as part of a feature commit.
- Commit only the files named by the current task. Do not push, merge, or deploy during this pilot plan.

## File Structure

### Review-only art and tooling

- `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/` — canonical review package: 12 stages, overlays, manifest, approval record, QA reports, and contact sheet.
- `tool/compose_ildu_hyeonpan.py` — deterministic chroma removal, board/calligraphy composition, perspective placement, and overlay hashing.
- `tool/assemble_sarangchae_variable_pilot.py` — copies approved source candidates, invokes common registration, writes the version-3 manifest, and renders the contact sheet.
- `tool/promote_ildu_sarangchae_pilot.py` — refuses incomplete or unapproved packages and copies exact approved bytes into the runtime leaf.
- `tool/test_compose_ildu_hyeonpan.py`, `tool/test_assemble_sarangchae_variable_pilot.py`, `tool/test_promote_ildu_sarangchae_pilot.py`, `tool/test_sarangchae_construction_progression.py` — deterministic art-pipeline gates.

### Flutter domain and UI

- `lib/models/ildu_construction_plan.dart` — immutable variable-stage plan, learning module, speech brief, and parser validation.
- `lib/models/ildu_construction_progress.dart` — stable-ID completion state, drafts, and recovery queue.
- `lib/services/ildu_construction_plan_repository.dart` — fail-closed bundled plan loading.
- `lib/services/ildu_construction_progress_service.dart` — ordered completion, draft preservation, reconciliation, and SharedPreferences boundary.
- `lib/services/ildu_learning_response_evaluator.dart` — unscored stance plus independently evaluated communication criteria.
- `lib/screens/ildu_learning_module_screen.dart` — history-to-2026 learning flow and Korean response action.
- `lib/widgets/sori/ildu_locked_world_viewport.dart` — exact logical viewport with horizontal-only drag.
- `lib/widgets/sori/ildu_construction_stage_layer.dart` — last-valid-stage asset projection for one building.
- `assets/data/ildu_sarangchae_construction_plan_v1.json` — 12 stages and authored learning modules.
- `assets/illustrations/personal_hanok_v3/world/construction/sarangchae/` — runtime copy created only by the promotion tool after approval.
- `lib/screens/ildu_world_screen.dart` — loads the plan/progress, replaces only the Sarangchae anchor, and opens the next module.
- `lib/models/ildu_world_manifest.dart`, `assets/data/ildu_world_manifest_v1.json` — enforce the 1206×2622 camera contract.
- `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` and generated localizations — UI chrome only; Korean learning content stays in the plan asset.

---

### Task 1: Parse and validate a variable construction plan

**Files:**
- Create: `lib/models/ildu_construction_plan.dart`
- Create: `lib/services/ildu_construction_plan_repository.dart`
- Test: `test/ildu_construction_plan_test.dart`

**Interfaces:**
- Consumes: UTF-8 JSON from `assets/data/ildu_sarangchae_construction_plan_v1.json`.
- Produces: `IlDuEstateConstructionPlan.fromJson(Object?)`, `IlDuConstructionPlanRepository.load()`, `plan.buildingFor(String)`, `building.stageFor(String)`, and `plan.moduleFor(String)`.

- [ ] **Step 1: Write parser tests for variable stage counts and stable references**

```dart
test('accepts a twelve-stage Sarangchae without an eight-stage invariant', () {
  final plan = IlDuEstateConstructionPlan.fromJson(_validPlanJson());
  expect(plan.canvas, const Size(2412, 2622));
  expect(plan.viewport, const Size(1206, 2622));
  expect(plan.buildingFor('sarangchae').stages, hasLength(12));
});

test('rejects duplicate stage IDs and unknown required module IDs', () {
  final json = _validPlanJson();
  final stages = ((json['buildings'] as List).single as Map)['stages'] as List;
  (stages.last as Map)['stageId'] = (stages.first as Map)['stageId'];
  expect(() => IlDuEstateConstructionPlan.fromJson(json), throwsFormatException);
});
```

- [ ] **Step 2: Run the tests and verify the model is absent**

Run: `flutter test test/ildu_construction_plan_test.dart`

Expected: FAIL because `IlDuEstateConstructionPlan` does not exist.

- [ ] **Step 3: Implement the immutable model and strict parser**

```dart
enum IlDuProcessTag {
  site,
  foundation,
  framePosts,
  frameBeams,
  raftersSanja,
  roofBed,
  roofTiles,
  floorNumaru,
  wallInfill,
  doorsChangho,
  identityFinish,
  complete,
}

final class IlDuConstructionStage {
  const IlDuConstructionStage({
    required this.stageId,
    required this.sequence,
    required this.processTags,
    required this.baseAsset,
    required this.overlayAssets,
    required this.requiredModuleIds,
    required this.optionalModuleIds,
    required this.completionEffect,
    required this.fallbackStageId,
  });

  final String stageId;
  final int sequence;
  final List<IlDuProcessTag> processTags;
  final String baseAsset;
  final List<String> overlayAssets;
  final List<String> requiredModuleIds;
  final List<String> optionalModuleIds;
  final String completionEffect;
  final String? fallbackStageId;
}

final class IlDuSpeechBrief {
  const IlDuSpeechBrief({
    required this.scene,
    required this.channel,
    required this.purpose,
    required this.speaker,
    required this.addressee,
    required this.relationship,
    required this.speechStyle,
    required this.speechAct,
    required this.knownFacts,
    required this.unresolvedFacts,
    required this.forbiddenInvention,
  });
  final String scene;
  final String channel;
  final String purpose;
  final String speaker;
  final String addressee;
  final String relationship;
  final String speechStyle;
  final String speechAct;
  final List<String> knownFacts;
  final List<String> unresolvedFacts;
  final List<String> forbiddenInvention;
}

final class IlDuLearningCriterion {
  const IlDuLearningCriterion({
    required this.id,
    required this.kind,
    required this.acceptedVariants,
    required this.requiredForCompletion,
  });
  final String id;
  final String kind;
  final List<String> acceptedVariants;
  final bool requiredForCompletion;
}

final class IlDuLearningCopy {
  const IlDuLearningCopy({
    required this.title,
    required this.history,
    required this.criticalLens,
    required this.modernScene,
    required this.sceneLine,
    required this.actionPrompt,
  });
  final String title;
  final String history;
  final String criticalLens;
  final String modernScene;
  final String sceneLine;
  final String actionPrompt;
}

final class IlDuLearningModule {
  const IlDuLearningModule({
    required this.moduleId,
    required this.sourceRefs,
    required this.levelBand,
    required this.knowledgeLenses,
    required this.copyByLanguage,
    required this.speechBrief,
    required this.targetExpressions,
    required this.acceptedVariants,
    required this.criteria,
    required this.scoredDimensions,
  });
  final String moduleId;
  final List<Uri> sourceRefs;
  final List<String> levelBand;
  final List<String> knowledgeLenses;
  final Map<String, IlDuLearningCopy> copyByLanguage;
  final IlDuSpeechBrief speechBrief;
  final List<String> targetExpressions;
  final List<String> acceptedVariants;
  final List<IlDuLearningCriterion> criteria;
  final Set<String> scoredDimensions;
}

final class IlDuBuildingConstructionPlan {
  const IlDuBuildingConstructionPlan({
    required this.buildingId,
    required this.planVersion,
    required this.canonicalAsset,
    required this.canonicalSha256,
    required this.buildingRole,
    required this.culturalMeaning,
    required this.stages,
  });
  final String buildingId;
  final String planVersion;
  final String canonicalAsset;
  final String canonicalSha256;
  final String buildingRole;
  final String culturalMeaning;
  final List<IlDuConstructionStage> stages;
}

final class IlDuEstateConstructionPlan {
  const IlDuEstateConstructionPlan({
    required this.estateId,
    required this.planVersion,
    required this.canvas,
    required this.viewport,
    required this.siteStageIds,
    required this.buildingOrder,
    required this.buildings,
    required this.modules,
  });
  final String estateId;
  final String planVersion;
  final Size canvas;
  final Size viewport;
  final List<String> siteStageIds;
  final List<String> buildingOrder;
  final List<IlDuBuildingConstructionPlan> buildings;
  final List<IlDuLearningModule> modules;
}
```

The parser must enforce schema version `1`, estate ID `ildu-gotaek-v3`, plan version `sarangchae-v1`, canvas 2412×2622, viewport 1206×2622, lowercase stable IDs, unique increasing sequences, known process tags, an earlier fallback stage, nonempty HTTPS `sourceRefs`, and required module references that resolve inside the same plan.

- [ ] **Step 4: Add a fail-closed cached repository**

```dart
final class IlDuConstructionPlanRepository {
  static const assetPath =
      'assets/data/ildu_sarangchae_construction_plan_v1.json';

  const IlDuConstructionPlanRepository({AssetBundle? bundle})
      : _bundle = bundle;

  final AssetBundle? _bundle;

  Future<IlDuEstateConstructionPlan> load() async {
    final raw = await (_bundle ?? rootBundle).loadString(assetPath);
    return IlDuEstateConstructionPlan.fromJson(jsonDecode(raw));
  }
}
```

- [ ] **Step 5: Run focused tests and analysis**

Run: `flutter test test/ildu_construction_plan_test.dart && flutter analyze`

Expected: all tests PASS and analysis reports no issues.

- [ ] **Step 6: Commit the parser boundary**

```powershell
git add -- lib/models/ildu_construction_plan.dart lib/services/ildu_construction_plan_repository.dart test/ildu_construction_plan_test.dart
git commit -m "feat: add variable Ildu construction plan model"
```

### Task 2: Author the Sarangchae 12-stage and cultural learning catalog

**Files:**
- Create: `assets/data/ildu_sarangchae_construction_plan_v1.json`
- Modify: `test/ildu_construction_plan_test.dart`
- Test: `test/ildu_sarangchae_learning_content_test.dart`

**Interfaces:**
- Consumes: the parser from Task 1 and the approved stage IDs from the spec.
- Produces: one `BuildingConstructionPlan` with twelve ordered stages and thirteen required modules, including two separate signboard modules.

- [ ] **Step 1: Add catalog tests before creating the catalog**

```dart
test('Sarangchae catalog keeps the approved twelve-stage order', () async {
  final plan = await const IlDuConstructionPlanRepository().load();
  expect(
    plan.buildingFor('sarangchae').stages.map((stage) => stage.stageId),
    const [
      'sarangchae-site',
      'sarangchae-foundation',
      'sarangchae-posts-floor-frame',
      'sarangchae-beams-purlins',
      'sarangchae-rafters-sanja',
      'sarangchae-roof-bed',
      'sarangchae-roof-tiles',
      'sarangchae-floor-numaru',
      'sarangchae-wall-infill',
      'sarangchae-changho',
      'sarangchae-hyeonpan',
      'sarangchae-complete',
    ],
  );
});

test('signboard modules do not grade a moral stance', () async {
  final plan = await const IlDuConstructionPlanRepository().load();
  for (final id in const ['baekse-cheongpung-2026', 'takcheongjae-2026']) {
    expect(plan.moduleFor(id).scoredDimensions, isNot(contains('stance')));
  }
});
```

- [ ] **Step 2: Run the catalog tests and verify the asset is missing**

Run: `flutter test test/ildu_construction_plan_test.dart test/ildu_sarangchae_learning_content_test.dart`

Expected: FAIL because the JSON catalog does not exist.

- [ ] **Step 3: Create the twelve stage records with exact asset names**

Use this stage-to-asset contract in the JSON:

| sequence | stageId | baseAsset | requiredModuleIds |
|---:|---|---|---|
| 1 | `sarangchae-site` | `stage_01_site.png` | `sarangchae-site-language` |
| 2 | `sarangchae-foundation` | `stage_02_foundation.png` | `sarangchae-foundation-language` |
| 3 | `sarangchae-posts-floor-frame` | `stage_03_posts_floor.png` | `sarangchae-posts-language` |
| 4 | `sarangchae-beams-purlins` | `stage_04_beams_purlins.png` | `sarangchae-beams-language` |
| 5 | `sarangchae-rafters-sanja` | `stage_05_rafters_sanja.png` | `sarangchae-rafters-language` |
| 6 | `sarangchae-roof-bed` | `stage_06_roof_bed.png` | `sarangchae-roof-bed-language` |
| 7 | `sarangchae-roof-tiles` | `stage_07_roof_tiles.png` | `sarangchae-roof-tiles-language` |
| 8 | `sarangchae-floor-numaru` | `stage_08_floor_numaru.png` | `sarangchae-numaru-language` |
| 9 | `sarangchae-wall-infill` | `stage_09_wall_infill.png` | `sarangchae-wall-language` |
| 10 | `sarangchae-changho` | `stage_10_changho.png` | `sarangchae-changho-language` |
| 11 | `sarangchae-hyeonpan` | `stage_10_changho.png` | `baekse-cheongpung-2026`, `takcheongjae-2026` |
| 12 | `sarangchae-complete` | `stage_12_complete_v3_base.png` | `sarangchae-complete-reflection` |

Stage 10 adds `stage_10_work_props.png`; stage 11 replaces that props layer with `stage_11_hyeonpan_work.png`; stage 12 adds `stage_12_hyeonpan_installed.png`. Every fallback points to the immediately preceding stage except stage 1, whose fallback is null.

- [ ] **Step 4: Author the two signboard modules with a shared history-to-2026 bridge**

Use these Korean communication events as semantic source:

```json
{
  "moduleId": "baekse-cheongpung-2026",
  "levelBand": ["b1", "b2", "c1", "c2"],
  "hanja": ["百", "世", "淸", "風"],
  "modernSceneKo": "동료가 보고서의 실수를 그냥 넘어가자고 합니다. 일을 키우지 않으면서도 지금 공유하자고 제안해 보세요.",
  "sceneLineKo": "동료: 이 정도는 그냥 넘어가도 되지 않을까요? 괜히 일만 커질 것 같은데요.",
  "targetExpressions": ["그냥 넘기기에는", "공유하는 게 낫지 않을까요", "먼저 말씀드리는 게 좋을 것 같아요"],
  "acceptedVariants": [
    "그냥 넘기기에는 나중에 더 커질 수도 있을 것 같아요. 지금 공유하는 게 낫지 않을까요?",
    "일을 키우자는 뜻은 아니고요. 더 늦기 전에 먼저 말씀드리는 게 좋을 것 같아요."
  ],
  "scoredDimensions": ["communicativeFunction", "relationshipRegister", "targetLanguage"]
}
```

```json
{
  "moduleId": "takcheongjae-2026",
  "levelBand": ["b1", "b2", "c1", "c2"],
  "hanja": ["濯", "淸", "齋"],
  "modernSceneKo": "단체 채팅에서 감정적인 메시지를 받았습니다. 무시하지 않되 바로 맞받아치지 않고, 생각을 정리한 뒤 답하겠다고 말해 보세요.",
  "sceneLineKo": "상대: 제 말이 그렇게 이해하기 어려웠나요? 답이 없으니까 더 답답하네요.",
  "targetExpressions": ["조금만 생각해 보고", "정리해서 다시 말씀드릴게요", "지금 바로 답하기보다"],
  "acceptedVariants": [
    "무시하려는 건 아니에요. 조금만 생각해 보고 정리해서 다시 말씀드릴게요.",
    "지금 바로 답하기보다 제가 이해한 내용을 먼저 정리해 보고 다시 말씀드리는 게 좋을 것 같아요."
  ],
  "scoredDimensions": ["communicativeFunction", "relationshipRegister", "targetLanguage"]
}
```

Each module must include the four approved HTTPS sources from spec §11, a `speechBrief` with channel/relationship/register, and independently written `copy.de` and `copy.en`. Do not put `백세청풍` or `탁청재` into the modern dialogue as an unnatural spoken slogan.

- [ ] **Step 5: Run catalog, source, speech-brief, and localization tests**

Run: `flutter test test/ildu_construction_plan_test.dart test/ildu_sarangchae_learning_content_test.dart`

Expected: PASS with 12 stages, all module references resolved, HTTPS sources present, stance absent from scored dimensions, and KO/DE/EN copy present.

- [ ] **Step 6: Commit the authored catalog**

```powershell
git add -- assets/data/ildu_sarangchae_construction_plan_v1.json test/ildu_construction_plan_test.dart test/ildu_sarangchae_learning_content_test.dart
git commit -m "feat: author Sarangchae construction Lernpfad"
```

### Task 3: Assemble the missing visual construction states

> **Execution skill:** Read and use the `imagegen` skill before Steps 4–6 because those steps create or edit visual assets.

**Files:**
- Create: `tool/assemble_sarangchae_variable_pilot.py`
- Create: `tool/test_assemble_sarangchae_variable_pilot.py`
- Modify: `tool/test_sarangchae_construction_progression.py`
- Create: `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/PROMPTS.md`
- Create: pending-review stages 1–10 under the same directory.

**Interfaces:**
- Consumes: existing v2 stages 1–5, generated candidates with pinned hashes, and new image-generation candidates for stages 7–9.
- Produces: registered 2512×1680 RGBA stage files with exact common center/ground geometry and no finished-element leakage.

- [ ] **Step 1: Write assembly tests for pinned candidate inputs**

```python
PINNED = {
    "stage_06_roof_bed": "5fc945ccee4087f532cbf0fe5a70925ed0f5693c10f6c31ac7fef21444067376",
    "stage_10_changho": "fec2b5244d8776769001e7c67b9b95e0ff3cd0686d2cfb65fd024d7e69e76d77",
    "stage_10_work_props": "307d54e1690a52c40445f5a739ce696523bf9161456c4ccc43f62c502b301e44",
}

def test_assembly_refuses_changed_pinned_input(self):
    with self.assertRaisesRegex(ValueError, "pinned source hash"):
        assemble(self.fixture_with_mutated_stage_6())
```

- [ ] **Step 2: Run the Python tests and verify the assembler is absent**

Run: `python -X utf8 -m unittest tool.test_assemble_sarangchae_variable_pilot`

Expected: FAIL because `assemble_sarangchae_variable_pilot` is not implemented.

- [ ] **Step 3: Implement the assembler around the existing alpha and registration tools**

```python
@dataclass(frozen=True)
class StageSource:
    stage_id: str
    source: Path
    expected_sha256: str

CANVAS = (2512, 1680)
TARGET_CENTER_X = 1250.0
TARGET_GROUND_Y = 1421
ALPHA_THRESHOLD = 8
```

The assembler must copy v2 stages 1–5 by verified SHA, extract the three pinned generated candidates from:

```text
C:\Users\vjinn\.codex\generated_images\01a04555-a2e8-7f02-bd28-1671e1b45d5b\exec-0c562b6f-c2c0-4714-9b71-bc1df48949fe.png
C:\Users\vjinn\.codex\generated_images\01a04555-a2e8-7f02-bd28-1671e1b45d5b\exec-220e2ba1-5bb9-4cd9-8707-3f62edf6412e.png
C:\Users\vjinn\.codex\generated_images\01a04555-a2e8-7f02-bd28-1671e1b45d5b\exec-398380fb-31a7-42ec-925d-0e24ab09190b.png
```

and call the existing `register()` function rather than duplicate registration math.

- [ ] **Step 4: Generate a roof-tiles-only stage 7 candidate**

Use the `imagegen` skill with `sarangchae_try07_edit.png`, registered stage 5, and the corrected stage 6 candidate as references. Use this exact content constraint:

```text
Preserve the exact V3 Sarangchae silhouette, six-bay rhythm, right numaru roof, foundation, posts, beams, purlins, rafters, common camera, and ground contact. Add complete dark grey clay tiles, ridge tiles, descending ridges, and eave-end tiles to both roof masses. Keep every wall bay and changho opening empty. Do not add plaster, doors, paper windows, floor boards, railings, signboards, people, tools, labels, scenery, or background. Single transparent/checkerboard-ready sprite, fully uncropped.
```

Save the raw result beside the other generated-image sources, record its SHA-256 in `PROMPTS.md`, then let the assembler create `stage_07_roof_tiles.png`.

- [ ] **Step 5: Generate a floor/numaru stage 8 candidate**

Use stage 7 as the structural source and apply this exact delta:

```text
Keep all stage-7 structure and finished roof pixels in the same coordinates. Add the timber floor, central stair landing connection, raised right numaru deck, its supports, and the V3-specific railing. Keep wall infill, plaster, doors, changho, hanji, and signboards absent. Do not change the roof, foundation, post count, camera, canvas, or ground line.
```

Register it as `stage_08_floor_numaru.png` and record the raw source hash.

- [ ] **Step 6: Generate a wall-infill stage 9 candidate**

Use stage 8 as the structural source and apply this exact delta:

```text
Keep all prior pixels registered. Add only the V3 wall infill, plaster/board wall areas, and door/window frames. Leave changho leaves visibly uninstalled: openings remain empty or show bare frames, with no complete hanji-papered lattice set. Keep the right numaru and railing complete. Do not add signboards, work props, people, labels, or scenery.
```

Register it as `stage_09_wall_infill.png`; register the approved partial-changho candidate as `stage_10_changho.png` and the refined no-stone props candidate as `stage_10_work_props.png`.

- [ ] **Step 7: Replace the eight-stage progression tests with twelve-stage visual invariants**

```python
def test_stage_7_has_finished_tiles_but_no_wall_band(self):
    self.assertGreater(dark_neutral_roof_pixels(stage(7)), 500_000)
    self.assertLess(alpha_pixels(stage(7), WALL_BAND), alpha_pixels(stage(9), WALL_BAND) * 0.55)

def test_stage_10_is_visibly_in_progress(self):
    ratio = alpha_pixels(stage(10), WALL_BAND) / alpha_pixels(master(), WALL_BAND)
    self.assertGreaterEqual(ratio, 0.82)
    self.assertLessEqual(ratio, 0.96)
```

Also assert all registered stages use RGBA, 2512×1680, center drift ≤0.5 px, ground drift 0 px, and stage 12 base hash equals the V3 master.

- [ ] **Step 8: Run the art pipeline tests**

Run: `python -X utf8 -m unittest tool.test_extract_checkerboard_alpha tool.test_register_hanok_construction_stages tool.test_assemble_sarangchae_variable_pilot tool.test_sarangchae_construction_progression`

Expected: PASS and no generated file outside the pending-review v3 directory.

- [ ] **Step 9: Commit only review assets and reproducible tooling**

```powershell
git add -- tool/assemble_sarangchae_variable_pilot.py tool/test_assemble_sarangchae_variable_pilot.py tool/test_sarangchae_construction_progression.py assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable
git commit -m "feat: assemble Sarangchae variable construction review set"
```

### Task 4: Compose exact `백세청풍·탁청재` signboard overlays

**Files:**
- Create: `tool/compose_ildu_hyeonpan.py`
- Create: `tool/test_compose_ildu_hyeonpan.py`
- Create: `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/hyeonpan_layout_v1.json`
- Create: `stage_11_hyeonpan_work.png`, `stage_12_hyeonpan_installed.png`, and intermediate board layers in the v3 review directory.

**Interfaces:**
- Consumes: the four supplied board/calligraphy files and the V3 common canvas.
- Produces: separate transparent work and installed overlays; never rewrites the stage-12 V3 base.

- [ ] **Step 1: Write tests that pin all supplied input hashes**

```python
EXPECTED = {
    "hyeonpan_calligraphy_baekse_cheongpung_v1.png": "19a774e1cf7d75e474d9bd83e251b64001ea0bfe655da4645461e38c2e9679c9",
    "hyeonpan_board_baekse_cheongpung_try01.png": "49365beadec3f5df359cf62220ea11071eae2425fa3080ad3f14eb7de7de9e3a",
    "hyeonpan_calligraphy_takcheongjae_v1.png": "9fe85b208531cd7c95c419c250004465d0101b88ccd72970ecef52a8139f983a",
    "hyeonpan_board_takcheongjae_try01.png": "86da5f8f1a88b8653ae4634a1d49a6332fee3ec4d3aa6ad8aa2c5ca57b09d144",
}
```

Tests must assert chroma becomes alpha, non-green board pixels are unchanged before resampling, the calligraphy alpha mask hash is preserved before placement, output is 2512×1680 RGBA, and base master bytes are never modified.

- [ ] **Step 2: Run the test and verify the compositor is absent**

Run: `python -X utf8 -m unittest tool.test_compose_ildu_hyeonpan`

Expected: FAIL because `compose_ildu_hyeonpan.py` does not exist.

- [ ] **Step 3: Implement deterministic chroma extraction and board composition**

```python
def remove_green_chroma(rgba: np.ndarray) -> np.ndarray:
    rgb = rgba[:, :, :3].astype(np.int16)
    green = (rgb[:, :, 1] >= 180) & (rgb[:, :, 1] - rgb[:, :, 0] >= 70) & (
        rgb[:, :, 1] - rgb[:, :, 2] >= 70
    )
    result = rgba.copy()
    result[green] = 0
    return result
```

Fit calligraphy inside the board's inner cream panel with aspect-preserving Lanczos resize and 8% horizontal/18% vertical inset. Do not recolor or synthesize strokes.

- [ ] **Step 4: Lock the first review coordinates in `hyeonpan_layout_v1.json`**

```json
{
  "canvas": [2512, 1680],
  "installed": {
    "baekse-cheongpung": [[1038, 700], [1268, 706], [1260, 765], [1045, 758]],
    "takcheongjae": [[1548, 668], [1708, 679], [1701, 735], [1554, 724]]
  },
  "work": {
    "baekse-cheongpung": [[760, 1258], [1010, 1254], [1014, 1325], [764, 1329]],
    "takcheongjae": [[1515, 1212], [1674, 1210], [1677, 1270], [1518, 1272]]
  }
}
```

The installed quads are review coordinates, not a claim that the historical photograph supplies exact sprite pixels. The review sheet in Task 5 is the approval authority.

- [ ] **Step 5: Produce work and installed overlays**

Run:

```powershell
python -X utf8 tool/compose_ildu_hyeonpan.py --layout assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/hyeonpan_layout_v1.json --output-dir assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable
```

Expected: both overlays have transparent corners, contain both exact calligraphy layers, and stage 12 base still hashes to the V3 master.

- [ ] **Step 6: Run compositor and progression tests**

Run: `python -X utf8 -m unittest tool.test_compose_ildu_hyeonpan tool.test_sarangchae_construction_progression`

Expected: PASS.

- [ ] **Step 7: Commit deterministic signboard work**

```powershell
git add -- tool/compose_ildu_hyeonpan.py tool/test_compose_ildu_hyeonpan.py assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/hyeonpan_layout_v1.json assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/stage_11_hyeonpan_work.png assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/stage_12_hyeonpan_installed.png
git commit -m "feat: compose exact Sarangchae signboard overlays"
```

### Task 5: Produce the 12-stage review manifest and stop at the visual gate

**Files:**
- Modify: `tool/assemble_sarangchae_variable_pilot.py`
- Modify: `tool/test_assemble_sarangchae_variable_pilot.py`
- Create: `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/MANIFEST.json`
- Create: `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/qa/sarangchae_12_stage_review.png`

**Interfaces:**
- Consumes: Tasks 3–4 outputs and the exact plan stage IDs from Task 2.
- Produces: one manifest hash that the user can approve; no runtime files.

- [ ] **Step 1: Add manifest tests for all twelve distinct states**

```python
self.assertEqual([row["sequence"] for row in manifest["stages"]], list(range(1, 13)))
self.assertEqual(len({row["compositeSha256"] for row in manifest["stages"]}), 12)
self.assertEqual(manifest["master"]["sha256"], MASTER_SHA256)
self.assertEqual(manifest["status"], "pending_visual_and_in_world_approval")
```

- [ ] **Step 2: Render a two-row contact sheet with readable stage labels**

The top row contains stages 1–6; the bottom row contains stages 7–12. Use a neutral sand background, preserve every sprite's alpha without cropping, and label each cell with `sequence`, Korean process name, and `stageId`. Do not place labels on the sprites.

- [ ] **Step 3: Run the full review-only audit**

Run:

```powershell
python -X utf8 tool/assemble_sarangchae_variable_pilot.py --render-review
python -X utf8 -m unittest tool.test_extract_checkerboard_alpha tool.test_register_hanok_construction_stages tool.test_compose_ildu_hyeonpan tool.test_assemble_sarangchae_variable_pilot tool.test_sarangchae_construction_progression
```

Expected: PASS and `MANIFEST.json` reports 12 unique composite SHA-256 values, common registration, separate base/overlay hashes, and pending status.

- [ ] **Step 4: Present the contact sheet and request two explicit approvals**

Ask the user to approve both:

1. stages 1–12 as a believable cumulative Sarangchae construction sequence; and
2. the two installed signboard sizes/positions on the actual 2412×2622 estate map.

Do not execute Task 6 until both are explicit.

- [ ] **Step 5: Preserve the explicit approval message for Task 6**

Do not hand-edit an approval hash. Keep the user's explicit approval message in the active task context; Task 6's `--record-approval` command computes the manifest SHA-256 and UTC timestamp and writes both approval booleans. If either approval is absent, stop without creating `APPROVAL.json`.

### Task 6: Promote only the explicitly approved asset set

**Files:**
- Create: `tool/promote_ildu_sarangchae_pilot.py`
- Create: `tool/test_promote_ildu_sarangchae_pilot.py`
- Create after explicit approval only: `assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/APPROVAL.json`
- Create by tool: `assets/illustrations/personal_hanok_v3/world/construction/sarangchae/`
- Modify: `pubspec.yaml:157-161`

**Interfaces:**
- Consumes: `MANIFEST.json`, matching `APPROVAL.json`, and all referenced pending-review files.
- Produces: exact-byte runtime files plus `runtime_manifest.json`; refuses partial or stale approval.

- [ ] **Step 1: Write fail-closed promotion tests**

```python
def test_refuses_missing_approval(self):
    with self.assertRaisesRegex(ValueError, "approval"):
        promote(self.pending, self.runtime)

def test_refuses_manifest_changed_after_approval(self):
    record_approval(self.pending, visual=True, in_world=True)
    (self.pending / "MANIFEST.json").write_text("{}", encoding="utf-8")
    with self.assertRaisesRegex(ValueError, "manifest hash"):
        promote(self.pending, self.runtime)
```

- [ ] **Step 2: Implement all-or-nothing promotion using a temporary sibling directory**

```python
def promote(source: Path, target: Path) -> None:
    manifest = load_and_verify_approval(source)
    temp = target.with_name(f"{target.name}.staging")
    copy_and_verify_every_manifest_file(source, temp, manifest)
    replace_directory_atomically(temp, target)
```

Also implement `record_approval(source, visual, in_world)`, which refuses false flags and writes `APPROVAL.json` with the computed lowercase manifest SHA-256 and current UTC ISO-8601 timestamp. Resolve the promotion target to an absolute path under `assets/illustrations/personal_hanok_v3/world/construction/sarangchae`; reject paths outside that leaf. Do not delete or move the pending-review source. If the target already exists, succeed only when every target hash already matches; otherwise refuse replacement and preserve both directories.

- [ ] **Step 3: Run promotion tests before touching runtime assets**

Run: `python -X utf8 -m unittest tool.test_promote_ildu_sarangchae_pilot`

Expected: PASS.

- [ ] **Step 4: Add the explicit runtime leaf to pubspec and promote**

```yaml
    - assets/illustrations/personal_hanok_v3/world/construction/sarangchae/
```

Run:

```powershell
python -X utf8 tool/promote_ildu_sarangchae_pilot.py --record-approval --source assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable --visual-sequence-approved --in-world-placement-approved
python -X utf8 tool/promote_ildu_sarangchae_pilot.py --source assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable --target assets/illustrations/personal_hanok_v3/world/construction/sarangchae
flutter pub get
```

Expected: all promoted file hashes match the approved manifest and no other runtime directory changes.

- [ ] **Step 5: Commit the promotion tool and approved runtime bytes**

```powershell
git add -- tool/promote_ildu_sarangchae_pilot.py tool/test_promote_ildu_sarangchae_pilot.py pubspec.yaml assets/illustrations/personal_hanok_v3/world/construction/sarangchae assets_unused/pending_review/personal_hanok_v3/sarangchae_construction_pilot_v3_variable/APPROVAL.json
git commit -m "feat: promote approved Sarangchae construction assets"
```

### Task 7: Persist stable construction progress and drafts

**Files:**
- Create: `lib/models/ildu_construction_progress.dart`
- Create: `lib/services/ildu_construction_progress_service.dart`
- Test: `test/ildu_construction_progress_service_test.dart`

**Interfaces:**
- Consumes: `IlDuEstateConstructionPlan` and a `IlDuConstructionProgressStore`.
- Produces: `load()`, `saveDraft(moduleId, text)`, `completeModule(moduleId)`, `currentStage(buildingId)`, and `reconcile(newPlan)`.

- [ ] **Step 1: Write tests for ordered completion, draft durability, and recovery**

```dart
test('completes a stage only after every required module', () async {
  final service = serviceWithTwoRequiredModules();
  await service.completeModule('module-a');
  expect(service.snapshot.completedStageIds, isEmpty);
  await service.completeModule('module-b');
  expect(service.snapshot.completedStageIds, contains('sarangchae-hyeonpan'));
});

test('keeps unknown completed IDs in the recovery queue', () async {
  final reconciled = oldSnapshotWith('removed-stage').reconcile(newPlan);
  expect(reconciled.recoveryQueue.stageIds, contains('removed-stage'));
});
```

- [ ] **Step 2: Run tests and verify the service is absent**

Run: `flutter test test/ildu_construction_progress_service_test.dart`

Expected: FAIL because the progress types do not exist.

- [ ] **Step 3: Implement a canonical JSON snapshot**

```dart
final class IlDuConstructionProgress {
  const IlDuConstructionProgress({
    required this.schemaVersion,
    required this.planVersion,
    required this.completedStageIds,
    required this.completedModuleIds,
    required this.draftsByModuleId,
    required this.recoveryQueue,
  });

  final int schemaVersion;
  final String planVersion;
  final Set<String> completedStageIds;
  final Set<String> completedModuleIds;
  final Map<String, String> draftsByModuleId;
  final IlDuConstructionRecoveryQueue recoveryQueue;
}

final class IlDuConstructionRecoveryQueue {
  const IlDuConstructionRecoveryQueue({
    required this.stageIds,
    required this.moduleIds,
  });
  final Set<String> stageIds;
  final Set<String> moduleIds;
}

final class IlDuConstructionProgressWriteException implements Exception {
  const IlDuConstructionProgressWriteException(this.cause);
  final Object? cause;
}
```

Serialize sets in sorted order so repeated writes are byte-stable. Limit each draft to 600 Unicode code points and the whole snapshot to 64 KiB.

- [ ] **Step 4: Implement an injectable SharedPreferences store**

```dart
abstract interface class IlDuConstructionProgressStore {
  Future<String?> read();
  Future<void> write(String encoded);
}

final class SharedPreferencesIlDuConstructionProgressStore
    implements IlDuConstructionProgressStore {
  static const key = 'kl_ildu_construction_progress_v1';
}
```

The coordinating service has this exact constructor and public boundary:

```dart
final class IlDuConstructionProgressService {
  IlDuConstructionProgressService({
    required IlDuEstateConstructionPlan plan,
    required IlDuConstructionProgressStore store,
  });

  IlDuConstructionProgress get snapshot;
  Future<void> initialize();
  Future<void> saveDraft(String moduleId, String text);
  Future<void> completeModule(String moduleId);
  IlDuConstructionStage currentStage(String buildingId);
  Future<void> reconcile(IlDuEstateConstructionPlan newPlan);
}
```

Treat a rejected `setString` as a failed module completion: retain the prior in-memory snapshot and throw `IlDuConstructionProgressWriteException`.

- [ ] **Step 5: Implement ordered current-stage projection**

`currentStage(buildingId)` returns the first incomplete stage, or the final stage when all required modules are complete. Asset validity is deliberately outside persistence; Task 11 follows `fallbackStageId` when a base or overlay cannot load.

The test file defines its in-memory store explicitly:

```dart
final class MemoryIlDuConstructionProgressStore
    implements IlDuConstructionProgressStore {
  String? value;
  bool rejectWrites = false;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encoded) async {
    if (rejectWrites) {
      throw StateError('rejected test write');
    }
    value = encoded;
  }
}
```

- [ ] **Step 6: Run focused tests and analysis**

Run: `flutter test test/ildu_construction_progress_service_test.dart && flutter analyze`

Expected: PASS and no issues.

- [ ] **Step 7: Commit progress persistence**

```powershell
git add -- lib/models/ildu_construction_progress.dart lib/services/ildu_construction_progress_service.dart test/ildu_construction_progress_service_test.dart
git commit -m "feat: persist stable Ildu construction progress"
```

### Task 8: Evaluate communication without grading values

**Files:**
- Create: `lib/services/ildu_learning_response_evaluator.dart`
- Test: `test/ildu_learning_response_evaluator_test.dart`

**Interfaces:**
- Consumes: an `IlDuLearningModule`, learner text, and an optional `stanceId` used only for reflection.
- Produces: `IlDuLearningResponseResult(taskComplete, matchedCriterionIds, missingCriterionIds, normalizedInput, stanceId)`.

- [ ] **Step 1: Write tests that separate stance from communicative evidence**

```dart
test('opposite stances pass when both satisfy the same communication task', () {
  final first = evaluator.evaluate(module, input: acceptedA, stanceId: 'report-now');
  final second = evaluator.evaluate(module, input: acceptedB, stanceId: 'ask-first');
  expect(first.taskComplete, isTrue);
  expect(second.taskComplete, isTrue);
});

test('a stance choice without Korean action does not complete the module', () {
  final result = evaluator.evaluate(module, input: '', stanceId: 'report-now');
  expect(result.taskComplete, isFalse);
});
```

- [ ] **Step 2: Run the tests and verify the evaluator is absent**

Run: `flutter test test/ildu_learning_response_evaluator_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement NFC normalization and authored criteria matching**

```dart
final class IlDuLearningResponseResult {
  const IlDuLearningResponseResult({
    required this.taskComplete,
    required this.matchedCriterionIds,
    required this.missingCriterionIds,
    required this.normalizedInput,
    required this.stanceId,
  });

  final bool taskComplete;
  final Set<String> matchedCriterionIds;
  final Set<String> missingCriterionIds;
  final String normalizedInput;
  final String? stanceId;
}
```

Support only three authored criterion kinds for the pilot: `meaningSlot`, `tokenSequence`, and `sentenceEnding`. Match normalized accepted variants and bounded Korean phrases. Do not infer intent from a moral stance ID and do not fabricate a score.

- [ ] **Step 4: Run tests and analysis**

Run: `flutter test test/ildu_learning_response_evaluator_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit the evaluator**

```powershell
git add -- lib/services/ildu_learning_response_evaluator.dart test/ildu_learning_response_evaluator_test.dart
git commit -m "feat: evaluate Ildu communication tasks without moral scoring"
```

### Task 9: Build the history-to-2026 learning module screen

**Files:**
- Create: `lib/screens/ildu_learning_module_screen.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Generated: `lib/l10n/generated/app_localizations.dart`, `app_localizations_de.dart`, `app_localizations_en.dart`
- Test: `test/ildu_learning_module_screen_test.dart`

**Interfaces:**
- Consumes: one module, current draft, `IlDuLearningResponseEvaluator`, and callbacks `onDraftChanged(String)` / `onCompleted(IlDuLearningResponseResult)`.
- Produces: a scrollable, accessible module flow and completion callback; it owns no progress authority.

- [ ] **Step 1: Write widget tests for the required learning sequence**

```dart
expect(find.byKey(const ValueKey('ildu-module-hanja')), findsOneWidget);
expect(find.byKey(const ValueKey('ildu-module-history')), findsOneWidget);
expect(find.byKey(const ValueKey('ildu-module-critical-lens')), findsOneWidget);
expect(find.byKey(const ValueKey('ildu-module-2026-scene')), findsOneWidget);
expect(find.byKey(const ValueKey('ildu-module-korean-action')), findsOneWidget);
expect(find.byType(TextField), findsOneWidget);
```

Also test that an injected draft is restored, a failed response keeps the typed sentence, both signboard scenarios display the authored counterpart line, and completion never displays a numeric morality score.

- [ ] **Step 2: Run the test and verify the screen is absent**

Run: `flutter test test/ildu_learning_module_screen_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add DE/EN UI chrome keys**

Add keys for: module progress, source disclosure, Hanja observation, Joseon context, critical lens, 2026 scene, Korean action, response hint, check response, missing expression feedback, save retry, and install building part. Keep Korean target sentences in the JSON plan, not ARB.

Run: `flutter gen-l10n`.

- [ ] **Step 4: Implement the screen with existing Sori components**

Use `SoriAppBar`, `SoriCard`, `SoriButton`, `SoriTextField`, and `SoriTextTheme`. The response area must use:

```dart
SoriTextField(
  fieldKey: const ValueKey('ildu-module-korean-action-input'),
  controller: _controller,
  minLines: 3,
  maxLines: 6,
  maxLength: 600,
  textInputAction: TextInputAction.newline,
  onChanged: widget.onDraftChanged,
)
```

When evaluation fails, show missing communicative hints without replacing the learner's text. When persistence fails, retain the text and expose a retry button.

- [ ] **Step 5: Run screen and localization tests**

Run: `flutter test test/ildu_learning_module_screen_test.dart && flutter analyze`

Expected: PASS with no overflow at 393×852 logical pixels and text scale 1.3.

- [ ] **Step 6: Commit the learning screen**

```powershell
git add -- lib/screens/ildu_learning_module_screen.dart lib/l10n/app_de.arb lib/l10n/app_en.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_de.dart lib/l10n/generated/app_localizations_en.dart test/ildu_learning_module_screen_test.dart
git commit -m "feat: add Sarangchae cultural learning flow"
```

### Task 10: Lock the estate camera to one horizontal pan

**Files:**
- Create: `lib/widgets/sori/ildu_locked_world_viewport.dart`
- Modify: `lib/models/ildu_world_manifest.dart:274-299,374-380`
- Modify: `assets/data/ildu_world_manifest_v1.json:9-20`
- Modify: `test/ildu_world_manifest_test.dart`
- Test: `test/ildu_locked_world_viewport_test.dart`

**Interfaces:**
- Consumes: a 2412×2622 logical child and viewport constraints.
- Produces: horizontal offset clamped to 0–1206 logical pixels; no scale or vertical offset mutation.

- [ ] **Step 1: Update manifest tests to require 1206 logical viewport width**

```dart
expect(manifest.canvas.width, 2412);
expect(manifest.canvas.height, 2622);
expect(manifest.canvas.mobileContentWidth, 1206);
```

- [ ] **Step 2: Write gesture tests for a single horizontal pan**

```dart
await tester.drag(find.byKey(const ValueKey('ildu-locked-world')), const Offset(-2000, 0));
expect(controller.logicalX, 1206);
await tester.drag(find.byKey(const ValueKey('ildu-locked-world')), const Offset(0, -500));
expect(controller.logicalY, 0);
expect(controller.scale, 1);
```

- [ ] **Step 3: Run tests and verify the viewport is absent/current width fails**

Run: `flutter test test/ildu_world_manifest_test.dart test/ildu_locked_world_viewport_test.dart`

Expected: FAIL because the manifest says 620 and the widget does not exist.

- [ ] **Step 4: Implement a logical-coordinate horizontal viewport**

```dart
final class IlDuWorldViewportController extends ChangeNotifier {
  double _logicalX = 0;
  double get logicalX => _logicalX;
  double get logicalY => 0;
  double get scale => 1;

  void moveBy(double deltaLogicalX) {
    final next = (_logicalX + deltaLogicalX).clamp(0.0, 1206.0);
    if (next == _logicalX) return;
    _logicalX = next;
    notifyListeners();
  }
}
```

Render the 2412×2622 child with aspect-preserving fit into a logical 1206×2622 viewport. Handle only `onHorizontalDragUpdate`; do not install scale or vertical-drag recognizers.

- [ ] **Step 5: Change `mobileContentWidth` from 620 to 1206 and validate it in Dart**

`IlDuWorldManifest._validateReferences()` must reject any canvas width, height, or mobile content width that differs from 2412, 2622, and 1206.

- [ ] **Step 6: Run focused tests and analysis**

Run: `flutter test test/ildu_world_manifest_test.dart test/ildu_locked_world_viewport_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 7: Commit the camera contract**

```powershell
git add -- lib/widgets/sori/ildu_locked_world_viewport.dart lib/models/ildu_world_manifest.dart assets/data/ildu_world_manifest_v1.json test/ildu_world_manifest_test.dart test/ildu_locked_world_viewport_test.dart
git commit -m "fix: lock Ildu world to one horizontal pan"
```

### Task 11: Project construction progress into `IlDuWorldScreen`

**Files:**
- Create: `lib/widgets/sori/ildu_construction_stage_layer.dart`
- Modify: `lib/screens/ildu_world_screen.dart:17-88,163-176,213-357,417-480,639-829`
- Modify: `test/ildu_world_screen_test.dart`
- Test: `test/ildu_construction_stage_layer_test.dart`

**Interfaces:**
- Consumes: plan repository, progress service/store, approved runtime assets, and existing world manifest/projection.
- Produces: staged Sarangchae rendering, current-stage CTA, next-module navigation, and automatic refresh after durable completion.

- [ ] **Step 1: Write stage-layer fail-closed tests**

```dart
testWidgets('falls back to the last valid stage when the requested asset fails', (tester) async {
  await tester.pumpWidget(stageLayer(requested: stage10, invalidAssets: {stage10.baseAsset}));
  expect(find.byKey(const ValueKey('stage-sarangchae-wall-infill')), findsOneWidget);
  expect(find.text('generic hanok'), findsNothing);
});
```

- [ ] **Step 2: Write world-screen flow tests**

Cover these cases:

1. fresh progress shows stage 1 at the existing Sarangchae anchor;
2. completing a required module advances exactly one stage after the progress write succeeds;
3. rejected progress write keeps the old stage and draft;
4. stage 10 renders its separate props overlay;
5. stage 12 renders the byte-identical base plus installed signboard overlay;
6. other buildings and decoration behavior remain unchanged;
7. the world contains `IlDuLockedWorldViewport` and no `InteractiveViewer`.

- [ ] **Step 3: Run tests and verify integration is absent**

Run: `flutter test test/ildu_construction_stage_layer_test.dart test/ildu_world_screen_test.dart`

Expected: FAIL.

- [ ] **Step 4: Implement `IlDuConstructionStageLayer`**

```dart
class IlDuConstructionStageLayer extends StatelessWidget {
  const IlDuConstructionStageLayer({
    super.key,
    required this.stage,
    required this.assetRoot,
    required this.width,
    required this.onAssetFailure,
  });

  final IlDuConstructionStage stage;
  final String assetRoot;
  final double width;
  final ValueChanged<String> onAssetFailure;
}
```

Use one `Stack` for base and overlays. Every `Image.asset` gets an `errorBuilder` that reports failure to the owner; the owner selects `fallbackStageId`. Do not silently render an empty latest stage while claiming progress.

- [ ] **Step 5: Inject construction dependencies into `IlDuWorldScreen`**

Add optional test seams:

```dart
final Future<IlDuEstateConstructionPlan> Function()? loadConstructionPlan;
final IlDuConstructionProgressStore constructionProgressStore;
```

Load manifest, legacy projection, construction plan, progress, and decorations as one guarded operation. Keep legacy projection as availability evidence for non-pilot buildings; Sarangchae stage visibility comes only from construction progress.

- [ ] **Step 6: Replace the existing interactive camera**

Replace `InteractiveViewer` at current lines 288–307 with `IlDuLockedWorldViewport`. Preserve approved anchor percentages, estate background, building ordering, and decoration hit areas.

- [ ] **Step 7: Open the next required Lernpfad module from the Sarangchae sheet**

Push `IlDuLearningModuleScreen` with the plan's next incomplete module, current saved draft, evaluator, and callbacks. The completion callback must await `completeModule`; only then refresh the visible stage and pop or show the installation effect.

- [ ] **Step 8: Run focused and existing Ildu tests**

Run:

```powershell
flutter test test/ildu_construction_stage_layer_test.dart test/ildu_world_screen_test.dart test/ildu_world_manifest_test.dart test/ildu_world_projection_adapter_test.dart test/ildu_decoration_placement_test.dart
flutter analyze
```

Expected: PASS and no changes to legacy grant/evidence semantics.

- [ ] **Step 9: Commit world integration**

```powershell
git add -- lib/widgets/sori/ildu_construction_stage_layer.dart lib/screens/ildu_world_screen.dart test/ildu_construction_stage_layer_test.dart test/ildu_world_screen_test.dart
git commit -m "feat: connect Sarangchae construction to Ildu world"
```

### Task 12: Verify the pilot as one durable journey

**Files:**
- Create: `test/ildu_sarangchae_construction_journey_test.dart`
- Modify: `docs/superpowers/specs/2026-08-29-ildu-variable-construction-cultural-lernpath-design.md`
- Modify only through command: `graphify-out/` generated graph state.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: evidence that one learner can start at bare site, complete authored modules, survive reload/failure, install both signboards, and reach stage 12 without unlocking other buildings falsely.

- [ ] **Step 1: Write the end-to-end widget journey**

```dart
testWidgets('builds Sarangchae through variable stages and survives reload', (tester) async {
  final store = MemoryIlDuConstructionProgressStore();
  await pumpIlduWorld(tester, store: store);
  expect(find.byKey(const ValueKey('stage-sarangchae-site')), findsOneWidget);

  await completeEveryRequiredModule(tester, throughStage: 12);
  await pumpIlduWorld(tester, store: store);
  expect(find.byKey(const ValueKey('stage-sarangchae-complete')), findsOneWidget);
  expect(find.byKey(const ValueKey('overlay-baekse-cheongpung')), findsOneWidget);
  expect(find.byKey(const ValueKey('overlay-takcheongjae')), findsOneWidget);
});
```

Add separate assertions for failed write retry, missing latest asset fallback, no zoom/vertical movement, and no moral stance scoring.

- [ ] **Step 2: Run every focused Dart and Python test**

Run:

```powershell
python -X utf8 -m unittest tool.test_extract_checkerboard_alpha tool.test_register_hanok_construction_stages tool.test_compose_ildu_hyeonpan tool.test_assemble_sarangchae_variable_pilot tool.test_promote_ildu_sarangchae_pilot tool.test_sarangchae_construction_progression
flutter test test/ildu_construction_plan_test.dart test/ildu_sarangchae_learning_content_test.dart test/ildu_construction_progress_service_test.dart test/ildu_learning_response_evaluator_test.dart test/ildu_learning_module_screen_test.dart test/ildu_locked_world_viewport_test.dart test/ildu_construction_stage_layer_test.dart test/ildu_world_manifest_test.dart test/ildu_world_screen_test.dart test/ildu_sarangchae_construction_journey_test.dart
flutter analyze
```

Expected: all focused tests PASS; repository-wide analysis has no new issues. Record any pre-existing unrelated failure separately.

- [ ] **Step 3: Inspect the in-app pilot at phone size**

Run the Flutter app and verify at 393×852 logical pixels:

- world starts at logical X 0 and stops at X 1206;
- vertical drag and pinch do not move/scale the estate;
- all Sarangchae eaves remain uncropped at both horizontal endpoints;
- the module sheet does not obscure the selected building permanently;
- stages 6, 7, 8, 9, 10, 11, and 12 are visually distinct;
- stage 12 shows both exact signboards and keeps the V3 base unchanged.

- [ ] **Step 4: Run Graphify end bookend and inspect generated changes**

Run: `graphify update .`

Inspect `git status --short` and keep Graphify churn separate from feature staging. Do not stage `graphify-out/cache/last_query_stamp` with the feature.

- [ ] **Step 5: Mark only the Sarangchae pilot implementation status in the spec**

Change the spec status to state exactly which gates passed: local tests, visual sequence approval, in-world placement approval, and phone inspection. Do not state Android/iOS internal distribution, full-estate completion, or other-building approval.

- [ ] **Step 6: Commit final pilot verification files**

```powershell
git add -- test/ildu_sarangchae_construction_journey_test.dart docs/superpowers/specs/2026-08-29-ildu-variable-construction-cultural-lernpath-design.md
git commit -m "test: verify Sarangchae construction journey"
```

## Plan Completion Boundary

This plan ends after the Sarangchae twelve-stage visual, language, persistence, and in-world pilot is verified. It does not profile or generate the remaining buildings, change Firebase, push/merge branches, build store artifacts, or distribute Android/iOS internal tests. Those actions require the Sarangchae pilot approval plus a separate implementation and release plan.
