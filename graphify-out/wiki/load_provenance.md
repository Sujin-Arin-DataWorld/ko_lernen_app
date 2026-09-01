# load_provenance

> 23 nodes · cohesion 0.23

## Key Concepts

- **load_provenance()** (34 connections) — `tool/hanok_v1_asset_contract.py`
- **compose_state()** (28 connections) — `tool/compose_hanok_a1_state.py`
- **ComposeHanokA1StateTest** (20 connections) — `tool/test_compose_hanok_a1_state.py`
- **_layer()** (16 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_a_rejected_composite_leaves_no_file_at_the_qa_path()** (5 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_lineage_is_checked_by_default()** (5 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_compose_stack_on_previous_requires_previous_layer_and_reports()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_composes_true_alpha_layer_without_touching_outside_socket()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_lineage_outside_repo_raises_composition_error()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_lineage_rejects_approved_output_digest_on_an_unbound_path()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_lineage_rejects_unknown_raw_sha()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_rejects_a_layer_that_builds_nothing_visible()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_rejects_output_that_would_overwrite_its_own_input()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_site_base_is_resolved_by_role_not_array_order()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_stack_mode_is_refused_outside_the_upward_stages()** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **test_compose_hanok_a1_state.py** (4 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_continuity_keeps_growing_footprint_and_rejects_shrink()** (3 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_lineage_rejects_allowlisted_digest_on_a_fake_path()** (3 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_same_size_layer_must_still_cover_the_local_anchor()** (3 connections) — `tool/test_compose_hanok_a1_state.py`
- **.test_rejects_rgb_without_alpha()** (2 connections) — `tool/test_compose_hanok_a1_state.py`
- **Image** (1 connections)
- **Regression: the lineage gate used to be opt-in, so the documented workflow…** (1 connections) — `tool/test_compose_hanok_a1_state.py`
- **The QA path is where promotion looks; a failed compose must not seed it.** (1 connections) — `tool/test_compose_hanok_a1_state.py`

## Relationships

- [hanok_v1_asset_contract.py](hanok_v1_asset_contract.py.md) (20 shared connections)
- [compose_hanok_a1_state.py](compose_hanok_a1_state.py.md) (19 shared connections)
- [promote_states](promote_states.md) (3 shared connections)
- [derive_hanok_a1_kit.py](derive_hanok_a1_kit.py.md) (1 shared connections)
- [hanok_a1_kit.py](hanok_a1_kit.py.md) (1 shared connections)

## Source Files

- `tool/compose_hanok_a1_state.py`
- `tool/hanok_v1_asset_contract.py`
- `tool/test_compose_hanok_a1_state.py`

## Audit Trail

- EXTRACTED: 60 (58%)
- INFERRED: 43 (42%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
